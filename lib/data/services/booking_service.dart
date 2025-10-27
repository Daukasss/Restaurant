import 'package:restauran/data/services/abstract/service_export.dart';

import '../../theme/aq_toi.dart';
import '../models/booking.dart';

class BookingService implements AbstractBookingService {
  @override
  Future<List<Booking>> getBookingsByUser() async {
    final response = await supabase
        .from('bookings')
        .select('*, restaurants(name, image_url)')
        .eq('user_id', supabase.auth.currentUser!.id)
        .order('booking_time', ascending: false);

    return List<Map<String, dynamic>>.from(response)
        .map((json) => Booking.fromJson(json))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> createBooking(Booking booking) async {
    try {
      print(
          '[v0] Creating booking with selectedExtraIds: ${booking.selectedExtraIds}');

      final insertData = {
        'user_id': booking.userId,
        'restaurant_id': booking.restaurantId,
        'name': booking.name,
        'phone': booking.phone,
        'guests': booking.guests,
        'booking_time': booking.bookingTime.toIso8601String(),
        'status': booking.status,
        'menu_selections': booking.menu_selections.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
        'restaurant_category_id': booking.restaurantCategoryId,
      };

      if (booking.selectedExtraIds != null &&
          booking.selectedExtraIds!.isNotEmpty) {
        insertData['selected_extras'] = booking.selectedExtraIds;
      }

      print('[v0] Insert data: $insertData');

      final response =
          await supabase.from('bookings').insert(insertData).select().single();

      print('[v0] Booking created successfully: ${response['id']}');

      if (booking.selectedExtraIds != null &&
          booking.selectedExtraIds!.isNotEmpty) {
        final bookingId = response['id'] as int;

        final extrasResponse = await supabase
            .from('restaurant_extras')
            .select('id, price')
            .inFilter('id', booking.selectedExtraIds!);

        final extraPrices = Map<int, double>.fromEntries(
            (extrasResponse as List).map((extra) => MapEntry(
                extra['id'] as int, (extra['price'] as num).toDouble())));

        final extrasData = booking.selectedExtraIds!.map((extraId) {
          return {
            'booking_id': bookingId,
            'extra_id': extraId,
            'price_at_booking': extraPrices[extraId] ?? 0.0,
          };
        }).toList();

        await supabase.from('booking_extras').insert(extrasData);
      }

      return response;
    } catch (e) {
      print('[v0] Error in createBooking: $e');
      throw Exception('Ошибка создания бронирования: $e');
    }
  }

  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final response = await supabase
          .from('bookings')
          .select('*')
          .eq('user_id', userId)
          .order('booking_time', ascending: false);

      final bookings = <Booking>[];

      for (var bookingJson in response as List) {
        final bookingId = bookingJson['id'] as int;

        final extrasResponse = await supabase
            .from('booking_extras')
            .select('extra_id')
            .eq('booking_id', bookingId);

        final selectedExtraIds =
            (extrasResponse as List).map((e) => e['extra_id'] as int).toList();

        final bookingData = Map<String, dynamic>.from(bookingJson);
        bookingData['selected_extra_ids'] = selectedExtraIds;

        bookings.add(Booking.fromJson(bookingData));
      }

      return bookings;
    } catch (error) {
      return [];
    }
  }

  Future<void> updateBooking({
    required int bookingId,
    required String name,
    required String phone,
    required int guests,
    required DateTime date,
    required int restaurantId,
    required Map<int, int> menuItems,
    required int restaurantCategoryId,
    required List<int> selectedExtraIds,
  }) async {
    try {
      final encodedMenuItems = menuItems.map(
        (key, value) => MapEntry(key.toString(), value),
      );

      final updateData = {
        'name': name,
        'phone': phone,
        'guests': guests,
        'booking_time': date.toIso8601String(),
        'menu_selections': encodedMenuItems,
        'updated_at': DateTime.now().toIso8601String(),
        'restaurant_category_id': restaurantCategoryId,
        'selected_extras': selectedExtraIds, // Always set, even if empty
      };

      await supabase.from('bookings').update(updateData).eq('id', bookingId);

      await supabase
          .from('booking_extras')
          .delete()
          .eq('booking_id', bookingId);

      if (selectedExtraIds.isNotEmpty) {
        final extrasResponse = await supabase
            .from('restaurant_extras')
            .select('id, price')
            .inFilter('id', selectedExtraIds);

        final extraPrices = Map<int, double>.fromEntries(
            (extrasResponse as List).map((extra) => MapEntry(
                extra['id'] as int, (extra['price'] as num).toDouble())));

        final extrasData = selectedExtraIds.map((extraId) {
          return {
            'booking_id': bookingId,
            'extra_id': extraId,
            'price_at_booking': extraPrices[extraId] ?? 0.0,
          };
        }).toList();

        await supabase.from('booking_extras').insert(extrasData);
      }
    } catch (e) {
      throw Exception('Ошибка обновления бронирования: $e');
    }
  }

  @override
  Future<void> updateBookingStatus(int bookingId, String newStatus) async {
    try {
      await supabase.from('bookings').update({
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', bookingId);
    } catch (e) {
      throw Exception('Ошибка обновления статуса бронирования');
    }
  }

  @override
  Future<List<Booking>> getBookingsByUserId(String userId) async {
    final response = await supabase
        .from('bookings')
        .select('*, restaurants(name, image_url)')
        .eq('user_id', userId)
        .order('booking_time', ascending: false);

    return List<Map<String, dynamic>>.from(response)
        .map((json) => Booking.fromJson(json))
        .toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getBookings(int restaurantId) async {
    try {
      final response = await supabase
          .from('bookings')
          .select()
          .eq('restaurant_id', restaurantId)
          .order('booking_time', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to load bookings');
    }
  }

  @override
  Future<int> getRestaurantIdFromBooking(int bookingId) async {
    try {
      final response = await supabase
          .from('bookings')
          .select('restaurant_id')
          .eq('id', bookingId)
          .single();

      return response['restaurant_id'] as int;
    } catch (error) {
      throw Exception('Failed to get restaurant ID from booking');
    }
  }
}
