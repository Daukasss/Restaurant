import 'package:flutter/material.dart';
import '../../models/category_closure.dart';

abstract class AbstractCategoryClosureService {
  /// Создать блокировку категории
  Future<CategoryClosure> createClosure(CategoryClosure closure);

  /// Получить все блокировки для конкретной категории ресторана
  Future<List<CategoryClosure>> getClosuresForCategory({
    required String restaurantId,
    required String categoryId,
  });

  /// Получить все блокировки для конкретной даты (все категории ресторана)
  Future<List<CategoryClosure>> getClosuresForDate({
    required String restaurantId,
    required DateTime date,
  });

  /// Получить все блокировки ресторана
  Future<List<CategoryClosure>> getAllClosures(String restaurantId);

  /// Удалить блокировку по ID
  Future<void> deleteClosure(String closureId);

  /// Проверяет, заблокирована ли категория для указанного времени
  Future<bool> isCategoryBlocked({
    required String restaurantId,
    required String categoryId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  });
}
