import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:restauran/data/models/category_closure.dart';
import 'package:restauran/data/services/abstract/abstract_category_closure_service.dart';

class CategoryClosureService implements AbstractCategoryClosureService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Коллекция в Firestore
  CollectionReference get _closures =>
      _firestore.collection('category_closures');

  @override
  Future<CategoryClosure> createClosure(CategoryClosure closure) async {
    try {
      final docRef = await _closures.add(closure.toJson());
      return closure.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Ошибка создания блокировки: $e');
    }
  }

  @override
  Future<List<CategoryClosure>> getClosuresForCategory({
    required String restaurantId,
    required String categoryId,
  }) async {
    try {
      final snapshot = await _closures
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('category_id', isEqualTo: categoryId)
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CategoryClosure.fromJson(data);
      }).toList();
    } catch (e) {
      print('Ошибка получения блокировок для категории: $e');
      return [];
    }
  }

  @override
  Future<List<CategoryClosure>> getClosuresForDate({
    required String restaurantId,
    required DateTime date,
  }) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _closures
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CategoryClosure.fromJson(data);
      }).toList();
    } catch (e) {
      print('Ошибка получения блокировок для даты: $e');
      return [];
    }
  }

  @override
  Future<List<CategoryClosure>> getAllClosures(String restaurantId) async {
    try {
      final snapshot = await _closures
          .where('restaurant_id', isEqualTo: restaurantId)
          .orderBy('date', descending: false)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return CategoryClosure.fromJson(data);
      }).toList();
    } catch (e) {
      print('Ошибка получения всех блокировок: $e');
      return [];
    }
  }

  @override
  Future<void> deleteClosure(String closureId) async {
    try {
      await _closures.doc(closureId).delete();
    } catch (e) {
      throw Exception('Ошибка удаления блокировки: $e');
    }
  }

  @override
  Future<bool> isCategoryBlocked({
    required String restaurantId,
    required String categoryId,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
  }) async {
    try {
      final closures = await getClosuresForDate(
        restaurantId: restaurantId,
        date: date,
      );

      // Фильтруем только для нужной категории
      final categoryClosures =
          closures.where((c) => c.categoryId == categoryId).toList();

      // Проверяем, блокирует ли хоть одна блокировка запрошенное время
      for (final closure in categoryClosures) {
        if (closure.blocksTime(
          requestDate: date,
          requestStart: startTime,
          requestEnd: endTime,
        )) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print('Ошибка проверки блокировки: $e');
      return false;
    }
  }
}
