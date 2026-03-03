import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Booking {
  final String? id;
  final String? userId;
  final String name;
  final String phone;
  final int guests;
  final DateTime bookingDate; // Дата бронирования (без времени)
  final TimeOfDay startTime; // Время начала
  final TimeOfDay endTime; // Время окончания
  final String status;
  final Map<String, String> menu_selections;
  final String restaurantId;
  final int? totalPrice;
  final String? restaurantCategoryId;
  final List<String>? selectedExtraIds;
  final int? categorySection; // 1 или 2 - секция категории
  final bool isSellerBooking; // true если бронирование создано продавцом

  Booking(
    this.restaurantId, {
    this.id,
    this.userId,
    required this.name,
    required this.phone,
    required this.guests,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.menu_selections,
    required this.totalPrice,
    this.restaurantCategoryId,
    this.selectedExtraIds,
    this.categorySection,
    this.isSellerBooking = false,
  });

  // Преобразование TimeOfDay в минуты для удобства сравнения
  int get startTimeInMinutes => startTime.hour * 60 + startTime.minute;
  int get endTimeInMinutes => endTime.hour * 60 + endTime.minute;

  // Проверка пересечения времени с другим бронированием
  bool hasTimeConflict(Booking other) {
    // Если разные даты - нет конфликта
    if (!isSameDate(bookingDate, other.bookingDate)) {
      return false;
    }

    // Проверяем пересечение временных интервалов
    return !(endTimeInMinutes <= other.startTimeInMinutes ||
        startTimeInMinutes >= other.endTimeInMinutes);
  }

  // Проверка наличия минимального интервала (60 минут) между бронированиями
  bool hasMinimumGap(Booking other, {int gapMinutes = 60}) {
    if (!isSameDate(bookingDate, other.bookingDate)) {
      return true;
    }

    // Если это одна секция - должен быть полный непересекающийся интервал
    if (categorySection == other.categorySection) {
      return !hasTimeConflict(other);
    }

    // Для разных секций проверяем минимальный интервал
    int gap1 = other.startTimeInMinutes - endTimeInMinutes;
    int gap2 = startTimeInMinutes - other.endTimeInMinutes;

    // Проверяем, что есть интервал минимум gapMinutes между бронированиями
    return (gap1 >= gapMinutes && gap1 >= 0) ||
        (gap2 >= gapMinutes && gap2 >= 0);
  }

  static bool isSameDate(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'guests': guests,
      'booking_date': Timestamp.fromDate(bookingDate),
      'start_time':
          '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'end_time':
          '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'status': status,
      'menu_selections': menu_selections,
      'restaurant_id': restaurantId,
      'restaurant_category_id': restaurantCategoryId,
      'selected_extras': selectedExtraIds,
      'category_section': categorySection,
      'totalPrice': totalPrice,
      'is_seller_booking': isSellerBooking,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Parse menu_selections
    Map<String, String> parsedMenuSelections = {};
    final menuData = json['menu_selections'];
    if (menuData != null && menuData is Map) {
      menuData.forEach((key, value) {
        try {
          parsedMenuSelections[key.toString()] = value.toString();
        } catch (e) {
          print('Ошибка парсинга menu_selections: $e');
        }
      });
    }

    // Parse selected_extras
    List<String>? parsedExtras;
    if (json['selected_extras'] != null) {
      parsedExtras =
          (json['selected_extras'] as List).map((e) => e.toString()).toList();
    } else if (json['selected_extra_ids'] != null) {
      parsedExtras = (json['selected_extra_ids'] as List)
          .map((e) => e.toString())
          .toList();
    }

    // Parse times
    TimeOfDay startTime = const TimeOfDay(hour: 12, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 15, minute: 0);

    if (json['start_time'] != null) {
      final parts = json['start_time'].toString().split(':');
      if (parts.length == 2) {
        startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    if (json['end_time'] != null) {
      final parts = json['end_time'].toString().split(':');
      if (parts.length == 2) {
        endTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    // Для обратной совместимости: если есть старое поле booking_time
    DateTime bookingDate = DateTime.now();
    if (json['booking_date'] != null) {
      bookingDate = (json['booking_date'] as Timestamp).toDate();
    } else if (json['booking_time'] != null) {
      // Для старых записей используем booking_time
      bookingDate = (json['booking_time'] as Timestamp).toDate();
    }

    return Booking(
      json['restaurant_id']?.toString() ?? '',
      id: json['id']?.toString(),
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String,
      guests: json['guests'] as int,
      bookingDate: bookingDate,
      startTime: startTime,
      endTime: endTime,
      totalPrice: (json['totalPrice'] as num?)?.toInt(),
      status: json['status'] as String,
      menu_selections: parsedMenuSelections,
      restaurantCategoryId: json['restaurant_category_id']?.toString(),
      selectedExtraIds: parsedExtras,
      categorySection: json['category_section'] as int?,
      isSellerBooking: json['is_seller_booking'] as bool? ?? false,
    );
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    int? guests,
    DateTime? bookingDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? status,
    Map<String, String>? menu_selections,
    String? restaurantId,
    String? restaurantCategoryId,
    List<String>? selectedExtraIds,
    int? categorySection,
    bool? isSellerBooking,
  }) {
    return Booking(
      restaurantId ?? this.restaurantId,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      guests: guests ?? this.guests,
      bookingDate: bookingDate ?? this.bookingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalPrice: totalPrice,
      status: status ?? this.status,
      menu_selections: menu_selections ?? this.menu_selections,
      restaurantCategoryId: restaurantCategoryId ?? this.restaurantCategoryId,
      selectedExtraIds: selectedExtraIds ?? this.selectedExtraIds,
      categorySection: categorySection ?? this.categorySection,
      isSellerBooking: isSellerBooking ?? this.isSellerBooking,
    );
  }
}
