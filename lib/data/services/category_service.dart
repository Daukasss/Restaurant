import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/global_category.dart';
import '../models/restaurant_category.dart';

abstract class AbstractCategoryService {
  // Глобальные категории (для админа)
  Future<List<GlobalCategory>> getGlobalCategories();
  Future<GlobalCategory?> getGlobalCategoryById(String categoryId);
  Future<GlobalCategory> addGlobalCategory(GlobalCategory category);
  Future<GlobalCategory> updateGlobalCategory(GlobalCategory category);
  Future<void> deleteGlobalCategory(String categoryId);

  // Категории ресторана (для seller)
  Future<List<GlobalCategory>> getAvailableGlobalCategories(
      String restaurantId);
  Future<List<RestaurantCategory>> getRestaurantCategories(String restaurantId);
  Future<RestaurantCategory> activateCategory(
    String restaurantId,
    String globalCategoryId,
    double price,
    String? description,
  );
  Future<RestaurantCategory> updateRestaurantCategory(
      RestaurantCategory category);
  Future<void> deactivateRestaurantCategory(String categoryId);
}

class CategoryService implements AbstractCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ==================== ГЛОБАЛЬНЫЕ КАТЕГОРИИ ====================

  @override
  Future<List<GlobalCategory>> getGlobalCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('global_categories')
          .where('is_active', isEqualTo: true)
          .orderBy('section')
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return GlobalCategory.fromJson(data);
      }).toList();
    } catch (error) {
      debugPrint('Ошибка загрузки глобальных категорий: $error');
      throw Exception('Failed to load global categories: $error');
    }
  }

  @override
  Future<GlobalCategory?> getGlobalCategoryById(String categoryId) async {
    try {
      final doc = await _firestore
          .collection('global_categories')
          .doc(categoryId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      data['id'] = doc.id;
      return GlobalCategory.fromJson(data);
    } catch (error) {
      debugPrint('Ошибка загрузки глобальной категории: $error');
      throw Exception('Failed to load global category: $error');
    }
  }

  @override
  Future<GlobalCategory> addGlobalCategory(GlobalCategory category) async {
    try {
      final data = category.toJson();
      data['created_at'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('global_categories').add(data);

      final doc = await docRef.get();
      final responseData = doc.data()!;
      responseData['id'] = doc.id;

      return GlobalCategory.fromJson(responseData);
    } catch (error) {
      debugPrint('Ошибка добавления глобальной категории: $error');
      throw Exception('Failed to add global category: $error');
    }
  }

  @override
  Future<GlobalCategory> updateGlobalCategory(GlobalCategory category) async {
    try {
      final data = category.toJson();
      data.remove('id');
      data['updated_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('global_categories')
          .doc(category.id)
          .update(data);

      final doc = await _firestore
          .collection('global_categories')
          .doc(category.id)
          .get();

      final responseData = doc.data()!;
      responseData['id'] = doc.id;

      return GlobalCategory.fromJson(responseData);
    } catch (error) {
      debugPrint('Ошибка обновления глобальной категории: $error');
      throw Exception('Failed to update global category: $error');
    }
  }

  @override
  Future<void> deleteGlobalCategory(String categoryId) async {
    try {
      await _firestore.collection('global_categories').doc(categoryId).update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('Ошибка удаления глобальной категории: $error');
      throw Exception('Failed to delete global category: $error');
    }
  }

  // ==================== КАТЕГОРИИ РЕСТОРАНА ====================

  @override
  Future<List<GlobalCategory>> getAvailableGlobalCategories(
      String restaurantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('global_categories')
          .where('is_active', isEqualTo: true)
          .get();

      final allCategories = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return GlobalCategory.fromJson(data);
      }).toList();

      // Фильтруем категории: глобальные или назначенные этому ресторану
      return allCategories.where((category) {
        return category.isGlobal ||
            category.restaurantIds.contains(restaurantId);
      }).toList();
    } catch (error) {
      debugPrint('Ошибка загрузки доступных категорий: $error');
      throw Exception('Failed to load available categories: $error');
    }
  }

  @override
  Future<List<RestaurantCategory>> getRestaurantCategories(
      String restaurantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('restaurant_categories')
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('is_active', isEqualTo: true)
          .orderBy('section')
          .orderBy('created_at')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RestaurantCategory.fromJson(data);
      }).toList();
    } catch (error) {
      debugPrint('Ошибка загрузки категорий ресторана: $error');
      throw Exception('Failed to load restaurant categories: $error');
    }
  }

  @override
  Future<RestaurantCategory> activateCategory(
    String restaurantId,
    String globalCategoryId,
    double price,
    String? description,
  ) async {
    try {
      // Получаем глобальную категорию
      final globalCategory = await getGlobalCategoryById(globalCategoryId);
      if (globalCategory == null) {
        throw Exception('Global category not found');
      }

      // Создаем категорию ресторана
      final category = RestaurantCategory(
        restaurantId: restaurantId,
        globalCategoryId: globalCategoryId,
        name: globalCategory.name,
        section: globalCategory.section,
        priceRange: price,
        description: description ?? globalCategory.description,
        isActive: true,
      );

      final data = category.toJson();
      data['created_at'] = FieldValue.serverTimestamp();

      final docRef =
          await _firestore.collection('restaurant_categories').add(data);

      final doc = await docRef.get();
      final responseData = doc.data()!;
      responseData['id'] = doc.id;

      return RestaurantCategory.fromJson(responseData);
    } catch (error) {
      debugPrint('Ошибка активации категории: $error');
      throw Exception('Failed to activate category: $error');
    }
  }

  @override
  Future<RestaurantCategory> updateRestaurantCategory(
      RestaurantCategory category) async {
    try {
      final data = category.toJson();
      data.remove('id');
      data['updated_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('restaurant_categories')
          .doc(category.id)
          .update(data);

      final doc = await _firestore
          .collection('restaurant_categories')
          .doc(category.id)
          .get();

      final responseData = doc.data()!;
      responseData['id'] = doc.id;

      return RestaurantCategory.fromJson(responseData);
    } catch (error) {
      debugPrint('Ошибка обновления категории ресторана: $error');
      throw Exception('Failed to update restaurant category: $error');
    }
  }

  @override
  Future<void> deactivateRestaurantCategory(String categoryId) async {
    try {
      await _firestore
          .collection('restaurant_categories')
          .doc(categoryId)
          .update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      debugPrint('Ошибка деактивации категории ресторана: $error');
      throw Exception('Failed to deactivate restaurant category: $error');
    }
  }
}
