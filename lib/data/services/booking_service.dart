import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restauran/data/services/abstract/service_export.dart';
import 'package:restauran/data/services/category_closure_service.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_state.dart';
import '../models/booking.dart';

class ValidationResult {
  final bool isValid;
  final String message;
  final List<TimeSlot>? availableSlots;

  ValidationResult({
    required this.isValid,
    required this.message,
    this.availableSlots,
  });
}

class BookingService implements AbstractBookingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CategoryClosureService _closureService = CategoryClosureService();

  @override
  Future<ValidationResult> validateBooking({
    required String restaurantId,
    required String restaurantCategoryId,
    required DateTime bookingDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? excludeBookingId,
  }) async {
    try {
      final startMinutes = startTime.hour * 60 + startTime.minute;
      final endMinutes = endTime.hour * 60 + endTime.minute;

      if (endMinutes <= startMinutes) {
        return ValidationResult(
          isValid: false,
          message: 'Время окончания должно быть позже времени начала',
        );
      }

      // Проверяем блокировки селлера для этой категории
      final isBlocked = await _closureService.isCategoryBlocked(
        restaurantId: restaurantId,
        categoryId: restaurantCategoryId,
        date: bookingDate,
        startTime: startTime,
        endTime: endTime,
      );

      if (isBlocked) {
        return ValidationResult(
          isValid: false,
          message:
              'Выбранное время недоступно для бронирования в данной категории',
        );
      }

      final categoryDoc = await _firestore
          .collection('restaurant_categories')
          .doc(restaurantCategoryId)
          .get();

      if (!categoryDoc.exists) {
        return ValidationResult(
          isValid: false,
          message: 'Категория не найдена',
        );
      }

      final categorySection = (categoryDoc.data()?['section'] ?? 0) as int;

      final startOfDay = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('booking_date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('booking_date', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed']).get();

      // Исключаем текущую бронь при редактировании (защита от null и пустой строки)
      final effectiveExcludeId =
          (excludeBookingId != null && excludeBookingId.isNotEmpty)
              ? excludeBookingId
              : null;

      final existingBookings = bookingsSnapshot.docs
          .where((doc) =>
              effectiveExcludeId == null || doc.id != effectiveExcludeId)
          .map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Booking.fromJson(data);
      }).toList();

      if (existingBookings.length >= 2) {
        return ValidationResult(
          isValid: false,
          message: 'На выбранную дату уже есть максимум бронирований (2)',
        );
      }

      final sameSection = existingBookings
          .where((b) => b.categorySection == categorySection)
          .toList();

      if (sameSection.isNotEmpty) {
        return ValidationResult(
          isValid: false,
          message:
              'На эту дату уже забронирована категория с section $categorySection',
        );
      }

      final proposedBooking = Booking(
        restaurantId,
        bookingDate: bookingDate,
        startTime: startTime,
        endTime: endTime,
        categorySection: categorySection,
        name: '',
        phone: '',
        guests: 0,
        status: 'pending',
        menu_selections: {},
        totalPrice: 0,
      );

      for (final existing in existingBookings) {
        if (proposedBooking.hasTimeConflict(existing)) {
          return ValidationResult(
            isValid: false,
            message:
                'Выбранное время пересекается с существующим бронированием',
          );
        }

        if (!proposedBooking.hasMinimumGap(existing, gapMinutes: 60)) {
          return ValidationResult(
            isValid: false,
            message: 'Между бронированиями должен быть интервал минимум 1 час',
          );
        }
      }

      final availableSlots =
          _calculateAvailableSlots(existingBookings, categorySection);

      return ValidationResult(
        isValid: true,
        message: 'Бронирование доступно',
        availableSlots: availableSlots,
      );
    } catch (e) {
      print('Ошибка валидации: $e');
      return ValidationResult(
        isValid: false,
        message: 'Ошибка проверки доступности: $e',
      );
    }
  }

  List<TimeSlot> _calculateAvailableSlots(
    List<Booking> existingBookings,
    int categorySection,
  ) {
    if (existingBookings.isEmpty) {
      return [
        TimeSlot(
          startTime: const TimeOfDay(hour: 0, minute: 0),
          endTime: const TimeOfDay(hour: 23, minute: 59),
          isAvailable: true,
        ),
      ];
    }

    existingBookings
        .sort((a, b) => a.startTimeInMinutes.compareTo(b.startTimeInMinutes));

    final List<TimeSlot> slots = [];
    int currentMinute = 0;

    for (final booking in existingBookings) {
      int slotEnd = booking.startTimeInMinutes - 60;

      if (slotEnd > currentMinute) {
        slots.add(TimeSlot(
          startTime: _minutesToTimeOfDay(currentMinute),
          endTime: _minutesToTimeOfDay(slotEnd),
          isAvailable: true,
        ));
      }

      slots.add(TimeSlot(
        startTime: booking.startTime,
        endTime: _minutesToTimeOfDay(booking.endTimeInMinutes + 60),
        isAvailable: false,
        reason: 'Занято (section ${booking.categorySection})',
      ));

      currentMinute = booking.endTimeInMinutes + 60;
    }

    if (currentMinute < 24 * 60) {
      slots.add(TimeSlot(
        startTime: _minutesToTimeOfDay(currentMinute),
        endTime: const TimeOfDay(hour: 23, minute: 59),
        isAvailable: true,
      ));
    }

    return slots;
  }

  TimeOfDay _minutesToTimeOfDay(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    return TimeOfDay(hour: hour.clamp(0, 23), minute: minute.clamp(0, 59));
  }

  @override
  Future<List<Booking>> getBookingsForDate({
    required String restaurantId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('bookings')
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('booking_date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('booking_date', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed']).get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Booking.fromJson(data);
      }).toList();
    } catch (e) {
      print('Ошибка получения бронирований на дату: $e');
      return [];
    }
  }

  @override
  Future<List<Booking>> getBookingsByUser() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final querySnapshot = await _firestore
          .collection('bookings')
          .where('user_id', isEqualTo: currentUser.uid)
          .orderBy('booking_date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Booking.fromJson(data);
      }).toList();
    } catch (e) {
      print('Ошибка получения бронирований: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> createBooking(Booking booking) async {
    try {
      // Дополнительная проверка блокировок при создании
      if (booking.restaurantCategoryId != null) {
        final isBlocked = await _closureService.isCategoryBlocked(
          restaurantId: booking.restaurantId,
          categoryId: booking.restaurantCategoryId!,
          date: booking.bookingDate,
          startTime: booking.startTime,
          endTime: booking.endTime,
        );

        if (isBlocked) {
          throw Exception(
              'Выбранное время недоступно для бронирования. Выберите другое время или дату.');
        }
      }

      final docData = booking.toJson();
      docData.remove('id');

      final docRef = await _firestore.collection('bookings').add(docData);

      // Сохраняем extras в подколлекцию
      if (booking.selectedExtraIds != null &&
          booking.selectedExtraIds!.isNotEmpty) {
        final extrasResponse = await _firestore
            .collection('restaurant_extras')
            .where(FieldPath.documentId,
                whereIn: booking.selectedExtraIds!
                    .map((id) => id.toString())
                    .toList())
            .get();

        final extraPrices = <String, double>{};
        for (var doc in extrasResponse.docs) {
          extraPrices[doc.id] = (doc.data()['price'] as num).toDouble();
        }

        final batch = _firestore.batch();
        for (final extraId in booking.selectedExtraIds!) {
          final extraRef = _firestore
              .collection('bookings')
              .doc(docRef.id)
              .collection('booking_extras')
              .doc(extraId);

          batch.set(extraRef, {
            'booking_id': docRef.id,
            'extra_id': extraId,
            'price_at_booking': extraPrices[extraId] ?? 0.0,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }

      return {'id': docRef.id, 'success': true};
    } catch (e) {
      print('Ошибка создания бронирования: $e');
      throw Exception('Ошибка создания бронирования: $e');
    }
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('user_id', isEqualTo: userId)
          .orderBy('booking_date', descending: true)
          .get();

      final bookings = <Booking>[];

      for (var doc in querySnapshot.docs) {
        final bookingData = doc.data();
        bookingData['id'] = doc.id;

        final extrasSnapshot = await _firestore
            .collection('bookings')
            .doc(doc.id)
            .collection('booking_extras')
            .get();

        final selectedExtraIds = extrasSnapshot.docs
            .map((e) => e.data()['extra_id'].toString())
            .toList();

        bookingData['selected_extra_ids'] = selectedExtraIds;
        bookings.add(Booking.fromJson(bookingData));
      }

      return bookings;
    } catch (error) {
      print('Ошибка получения бронирований пользователя: $error');
      return [];
    }
  }

  @override
  Future<void> updateBooking({
    required String? bookingId,
    required String name,
    required String phone,
    required int guests,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String restaurantId,
    required Map<String, String> menuItems,
    required String restaurantCategoryId,
    required List<String> selectedExtraIds,
    required int? totalPrice,
  }) async {
    try {
      final validation = await validateBooking(
        restaurantId: restaurantId,
        restaurantCategoryId: restaurantCategoryId,
        bookingDate: date,
        startTime: startTime,
        endTime: endTime,
        excludeBookingId: bookingId,
      );

      if (!validation.isValid) {
        throw Exception(validation.message);
      }

      int? categorySection;
      final categoryDoc = await _firestore
          .collection('restaurant_categories')
          .doc(restaurantCategoryId)
          .get();

      if (categoryDoc.exists) {
        categorySection = categoryDoc.data()!['section'] as int;
      }

      final encodedMenuItems = menuItems.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      final updateData = {
        'name': name,
        'phone': phone,
        'guests': guests,
        'booking_date': Timestamp.fromDate(date),
        'start_time':
            '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
        'end_time':
            '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
        'menu_selections': encodedMenuItems,
        'updated_at': FieldValue.serverTimestamp(),
        'restaurant_category_id': restaurantCategoryId,
        'category_section': categorySection,
        'selected_extras': selectedExtraIds,
        'totalPrice': totalPrice,
      };

      await _firestore
          .collection('bookings')
          .doc(bookingId.toString())
          .update(updateData);

      final extrasSnapshot = await _firestore
          .collection('bookings')
          .doc(bookingId.toString())
          .collection('booking_extras')
          .get();

      final batch = _firestore.batch();
      for (var doc in extrasSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      if (selectedExtraIds.isNotEmpty) {
        final extrasResponse = await _firestore
            .collection('restaurant_extras')
            .where(FieldPath.documentId,
                whereIn: selectedExtraIds.map((id) => id.toString()).toList())
            .get();

        final extraPrices = <String, double>{};
        for (var doc in extrasResponse.docs) {
          final data = doc.data();
          extraPrices[(doc.id)] = (data['price'] as num).toDouble();
        }

        final newBatch = _firestore.batch();
        for (final extraId in selectedExtraIds) {
          final extraRef = _firestore
              .collection('bookings')
              .doc(bookingId.toString())
              .collection('booking_extras')
              .doc(extraId.toString());

          newBatch.set(extraRef, {
            'booking_id': bookingId.toString(),
            'extra_id': extraId,
            'price_at_booking': extraPrices[extraId] ?? 0.0,
            'created_at': FieldValue.serverTimestamp(),
          });
        }
        await newBatch.commit();
      }
    } catch (e) {
      print('Ошибка обновления бронирования: $e');
      throw Exception('Ошибка обновления бронирования: $e');
    }
  }

  @override
  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    try {
      await _firestore.collection('bookings').doc(bookingId.toString()).update({
        'status': newStatus,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Ошибка обновления статуса бронирования');
    }
  }

  @override
  Future<List<Booking>> getBookingsByUserId(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('user_id', isEqualTo: userId)
          .orderBy('booking_date', descending: true)
          .get();

      final bookings = <Booking>[];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        if (data['restaurant_id'] != null) {
          try {
            final restaurantDoc = await _firestore
                .collection('restaurants')
                .doc(data['restaurant_id'].toString())
                .get();

            if (restaurantDoc.exists) {
              data['restaurants'] = restaurantDoc.data();
            }
          } catch (e) {
            print('Ошибка загрузки ресторана: $e');
          }
        }

        bookings.add(Booking.fromJson(data));
      }

      return bookings;
    } catch (e) {
      print('Ошибка получения бронирований пользователя: $e');
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getBookings(String restaurantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('bookings')
          .where('restaurant_id', isEqualTo: restaurantId)
          .orderBy('booking_date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (error) {
      throw Exception('Failed to load bookings');
    }
  }

  @override
  Future<int> getRestaurantIdFromBooking(String bookingId) async {
    try {
      final doc = await _firestore
          .collection('bookings')
          .doc(bookingId.toString())
          .get();

      if (!doc.exists) {
        throw Exception('Бронирование не найдено');
      }

      return doc.data()!['restaurant_id'];
    } catch (error) {
      throw Exception('Failed to get restaurant ID from booking');
    }
  }
}
