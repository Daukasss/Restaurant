import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restauran/data/services/abstract/service_export.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';

class MenuService implements AbstractMenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<MenuCategory>> getMenuCategories(
    String restaurantId, {
    String? restaurantCategoryId,
  }) async {
    if (restaurantCategoryId != null) {
      return getMenuCategoriesByRestaurantCategory(
          restaurantId, restaurantCategoryId);
    }

    try {
      final querySnapshot = await _firestore
          .collection('menu_categories')
          .where('restaurant_id', isEqualTo: restaurantId)
          .orderBy('display_order')
          .get();

      return await _buildCategories(querySnapshot.docs);
    } catch (error) {
      print('Ошибка загрузки категорий меню: $error');
      throw Exception('Failed to load menu categories: $error');
    }
  }

  /// Фильтрация по одной категории ресторана.
  /// Использует array-contains, чтобы поддерживать новый формат (список ID).
  Future<List<MenuCategory>> getMenuCategoriesByRestaurantCategory(
    String restaurantId,
    String restaurantCategoryId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('menu_categories')
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('restaurant_category_ids', arrayContains: restaurantCategoryId)
          .orderBy('display_order')
          .get();

      return await _buildCategories(querySnapshot.docs);
    } catch (error) {
      print('Ошибка загрузки категорий меню по категории ресторана: $error');
      throw Exception(
          'Failed to load menu categories by restaurant category: $error');
    }
  }

  /// Внутренний хелпер: строит List<MenuCategory> из документов Firestore,
  /// подгружая menu_items для каждой категории.
  Future<List<MenuCategory>> _buildCategories(
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) async {
    final categories = <MenuCategory>[];

    for (var doc in docs) {
      final data = doc.data();
      data['id'] = doc.id;

      // Миграция: если старое поле restaurant_category_id ещё есть — конвертируем
      if (data['restaurant_category_ids'] == null &&
          data['restaurant_category_id'] != null) {
        data['restaurant_category_ids'] = [data['restaurant_category_id']];
      }

      final menuItemsSnapshot = await _firestore
          .collection('menu_items')
          .where('category_id', isEqualTo: doc.id)
          .get();

      data['menu_items'] = menuItemsSnapshot.docs.map((itemDoc) {
        final itemData = itemDoc.data();
        itemData['id'] = itemDoc.id;
        return itemData;
      }).toList();

      categories.add(MenuCategory.fromJson(data));
    }

    return categories;
  }

  @override
  Future<void> addCategory(MenuCategory category) async {
    try {
      final data = category.toJson();
      data['created_at'] = FieldValue.serverTimestamp();
      await _firestore.collection('menu_categories').add(data);
    } catch (error) {
      print('Ошибка добавления категории меню: $error');
      throw Exception('Failed to add menu category: $error');
    }
  }

  @override
  Future<void> updateCategory(String categoryId, MenuCategory category) async {
    try {
      final data = category.toJson();
      data.remove('id');
      data['updated_at'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('menu_categories')
          .doc(categoryId)
          .update(data);
    } catch (error) {
      print('Ошибка обновления категории меню: $error');
      throw Exception('Failed to update menu category: $error');
    }
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    try {
      final menuItemsSnapshot = await _firestore
          .collection('menu_items')
          .where('category_id', isEqualTo: categoryId)
          .get();

      for (var doc in menuItemsSnapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('menu_categories').doc(categoryId).delete();
    } catch (error) {
      print('Ошибка удаления категории меню: $error');
      throw Exception('Failed to delete menu category: $error');
    }
  }

  @override
  Future<void> addMenuItem(MenuItem menuItem) async {
    try {
      final data = menuItem.toJson();
      data['created_at'] = FieldValue.serverTimestamp();
      await _firestore.collection('menu_items').add(data);
    } catch (error) {
      print('Ошибка добавления элемента меню: $error');
      throw Exception('Failed to add menu item: $error');
    }
  }

  @override
  Future<void> updateMenuItem(String menuItemId, MenuItem menuItem) async {
    try {
      final data = menuItem.toJson();
      data.remove('id');
      data['updated_at'] = FieldValue.serverTimestamp();
      await _firestore.collection('menu_items').doc(menuItemId).update(data);
    } catch (error) {
      print('Ошибка обновления элемента меню: $error');
      throw Exception('Failed to update menu item: $error');
    }
  }

  @override
  Future<void> deleteMenuItem(String menuItemId) async {
    try {
      await _firestore.collection('menu_items').doc(menuItemId).delete();
    } catch (error) {
      print('Ошибка удаления элемента меню: $error');
      throw Exception('Failed to delete menu item: $error');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> loadMenuSelections(
      List<Map<String, dynamic>> menuSelections) async {
    try {
      final menuItemIds =
          menuSelections.map((s) => s['id'].toString()).toList();
      if (menuItemIds.isEmpty) return [];

      final results = <Map<String, dynamic>>[];
      for (var itemId in menuItemIds) {
        final doc = await _firestore.collection('menu_items').doc(itemId).get();
        if (doc.exists) {
          final data = doc.data()!;
          data['id'] = doc.id;
          final categoryDoc = await _firestore
              .collection('menu_categories')
              .doc(data['category_id'].toString())
              .get();
          if (categoryDoc.exists) {
            data['menu_categories'] = {'name': categoryDoc.data()!['name']};
          }
          results.add(data);
        }
      }
      return results;
    } catch (error) {
      print('Ошибка загрузки выбранных элементов меню: $error');
      throw Exception('Failed to load menu selections');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMenuSelections(
      Map<String, dynamic> booking) async {
    final List<Map<String, dynamic>> result = [];
    if (booking['menu_selections'] == null) return result;

    try {
      final Map<String, dynamic> menuSelections = booking['menu_selections'];
      for (final categoryId in menuSelections.keys) {
        final itemId = menuSelections[categoryId];
        final categoryDoc = await _firestore
            .collection('menu_categories')
            .doc(categoryId.toString())
            .get();
        if (!categoryDoc.exists) continue;
        final itemDoc = await _firestore
            .collection('menu_items')
            .doc(itemId.toString())
            .get();
        if (!itemDoc.exists) continue;
        result.add({
          'category': categoryDoc.data()!['name'],
          'item': itemDoc.data()!['name'],
        });
      }
      return result;
    } catch (error) {
      print('Ошибка получения выбранных элементов меню: $error');
      return result;
    }
  }

  Future<List<Map<String, dynamic>>> getRestaurantCategories(
      String restaurantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('restaurant_categories')
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (error) {
      print('Ошибка загрузки категорий ресторана: $error');
      throw Exception('Failed to load restaurant categories: $error');
    }
  }

  Future<Map<String, dynamic>> getRestaurantCategoryWithMenus(
      String restaurantId, String restaurantCategoryId) async {
    try {
      final categoryDoc = await _firestore
          .collection('restaurant_categories')
          .doc(restaurantCategoryId)
          .get();

      if (!categoryDoc.exists) {
        throw Exception('Категория ресторана не найдена');
      }

      final categoryData = categoryDoc.data()!;
      categoryData['id'] = categoryDoc.id;

      final menuCategories = await getMenuCategoriesByRestaurantCategory(
          restaurantId, restaurantCategoryId);

      return {
        'restaurant_category': categoryData,
        'menu_categories': menuCategories,
      };
    } catch (error) {
      print('Ошибка загрузки категории ресторана с меню: $error');
      throw Exception('Failed to load restaurant category with menus: $error');
    }
  }
}
