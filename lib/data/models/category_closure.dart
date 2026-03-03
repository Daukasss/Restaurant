import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Модель для блокировки категории селлером на определённую дату и время.
/// Когда селлер создаёт CategoryClosure — обычные пользователи не могут
/// выбрать эту категорию в указанный временной диапазон.
class CategoryClosure extends Equatable {
  final String? id;
  final String restaurantId;
  final String categoryId;
  final String categoryName; // Для отображения в UI
  final DateTime date; // Дата блокировки (только год/месяц/день)
  final TimeOfDay startTime; // Начало блокировки
  final TimeOfDay endTime; // Конец блокировки
  final String? reason; // Причина (опционально)
  final DateTime? createdAt;

  const CategoryClosure({
    this.id,
    required this.restaurantId,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.reason,
    this.createdAt,
  });

  // Преобразование TimeOfDay в минуты
  int get startTimeInMinutes => startTime.hour * 60 + startTime.minute;
  int get endTimeInMinutes => endTime.hour * 60 + endTime.minute;

  /// Проверяет, попадает ли запрошенное время в диапазон блокировки
  bool blocksTime({
    required DateTime requestDate,
    required TimeOfDay requestStart,
    required TimeOfDay requestEnd,
  }) {
    // Проверяем дату
    if (date.year != requestDate.year ||
        date.month != requestDate.month ||
        date.day != requestDate.day) {
      return false;
    }

    final reqStartMin = requestStart.hour * 60 + requestStart.minute;
    final reqEndMin = requestEnd.hour * 60 + requestEnd.minute;

    // Пересечение временных интервалов
    return !(reqEndMin <= startTimeInMinutes ||
        reqStartMin >= endTimeInMinutes);
  }

  String formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String get timeRangeText =>
      '${formatTime(startTime)} – ${formatTime(endTime)}';

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'restaurant_id': restaurantId,
      'category_id': categoryId,
      'category_name': categoryName,
      'date': Timestamp.fromDate(DateTime(date.year, date.month, date.day)),
      'start_time': formatTime(startTime),
      'end_time': formatTime(endTime),
      if (reason != null) 'reason': reason,
      'created_at': FieldValue.serverTimestamp(),
    };
  }

  factory CategoryClosure.fromJson(Map<String, dynamic> json) {
    TimeOfDay _parseTime(String? timeStr, TimeOfDay fallback) {
      if (timeStr == null) return fallback;
      final parts = timeStr.split(':');
      if (parts.length != 2) return fallback;
      return TimeOfDay(
        hour: int.tryParse(parts[0]) ?? fallback.hour,
        minute: int.tryParse(parts[1]) ?? fallback.minute,
      );
    }

    DateTime date = DateTime.now();
    if (json['date'] != null) {
      date = (json['date'] as Timestamp).toDate();
    }

    return CategoryClosure(
      id: json['id']?.toString(),
      restaurantId: json['restaurant_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
      date: DateTime(date.year, date.month, date.day),
      startTime: _parseTime(
        json['start_time']?.toString(),
        const TimeOfDay(hour: 12, minute: 0),
      ),
      endTime: _parseTime(
        json['end_time']?.toString(),
        const TimeOfDay(hour: 15, minute: 0),
      ),
      reason: json['reason']?.toString(),
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  CategoryClosure copyWith({
    String? id,
    String? restaurantId,
    String? categoryId,
    String? categoryName,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? reason,
    DateTime? createdAt,
  }) {
    return CategoryClosure(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        categoryId,
        categoryName,
        date,
        startTime,
        endTime,
        reason,
        createdAt,
      ];
}
