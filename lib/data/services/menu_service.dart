import 'package:restauran/data/services/abstract/service_export.dart';

import '../../theme/aq_toi.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';

class MenuService implements AbstractMenuService {
  @override
  Future<List<MenuCategory>> getMenuCategories(int restaurantId) async {
    final response = await supabase
        .from('menu_categories')
        .select('*, menu_items(*)')
        .eq('restaurant_id', restaurantId)
        .order('display_order', ascending: true);

    return List<Map<String, dynamic>>.from(response)
        .map((json) => MenuCategory.fromJson(json))
        .toList();
  }

  Future<List<MenuCategory>> getMenuCategoriesByRestaurantCategory(
      int restaurantId, int restaurantCategoryId) async {
    final response = await supabase
        .from('menu_categories')
        .select('*, menu_items(*)')
        .eq('restaurant_id', restaurantId)
        .eq('restaurant_category_id', restaurantCategoryId)
        .order('display_order', ascending: true);

    return List<Map<String, dynamic>>.from(response)
        .map((json) => MenuCategory.fromJson(json))
        .toList();
  }

  @override
  Future<void> addCategory(MenuCategory category) async {
    await supabase.from('menu_categories').insert(category.toJson());
  }

  @override
  Future<void> updateCategory(int categoryId, MenuCategory category) async {
    await supabase
        .from('menu_categories')
        .update(category.toJson())
        .eq('id', categoryId);
  }

  @override
  Future<void> deleteCategory(int categoryId) async {
    await supabase.from('menu_items').delete().eq('category_id', categoryId);
    await supabase.from('menu_categories').delete().eq('id', categoryId);
  }

  @override
  Future<void> addMenuItem(MenuItem menuItem) async {
    await supabase.from('menu_items').insert(menuItem.toJson());
  }

  @override
  Future<void> updateMenuItem(int menuItemId, MenuItem menuItem) async {
    await supabase
        .from('menu_items')
        .update(menuItem.toJson())
        .eq('id', menuItemId);
  }

  @override
  Future<void> deleteMenuItem(int menuItemId) async {
    await supabase.from('menu_items').delete().eq('id', menuItemId);
  }

  @override
  Future<List<Map<String, dynamic>>> loadMenuSelections(
      List<Map<String, dynamic>> menuSelections) async {
    try {
      final menuItemIds =
          menuSelections.map((selection) => selection['id']).toList();

      final response = await supabase
          .from('menu_items')
          .select('*, menu_categories(name)')
          .contains('id', menuItemIds);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to load menu selections');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchMenuSelections(
      Map<String, dynamic> booking) async {
    final List<Map<String, dynamic>> result = [];

    // Check if menu_selections exists and is not null
    if (booking['menu_selections'] == null) {
      return result;
    }

    try {
      // Parse the JSONB data
      final Map<String, dynamic> menuSelections = booking['menu_selections'];

      // For each category-item pair
      for (final categoryId in menuSelections.keys) {
        final itemId = menuSelections[categoryId];

        // Fetch category name
        final categoryResponse = await supabase
            .from('menu_categories')
            .select('name')
            .eq('id', int.parse(categoryId))
            .single();

        // Fetch item name
        final itemResponse = await supabase
            .from('menu_items')
            .select('name')
            .eq('id', itemId)
            .single();

        result.add({
          'category': categoryResponse['name'],
          'item': itemResponse['name']
        });
      }

      return result;
    } catch (error) {
      return result;
    }
  }

  Future<List<Map<String, dynamic>>> getRestaurantCategories(
      int restaurantId) async {
    try {
      final response = await supabase
          .from('restaurant_categories')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to load restaurant categories: $error');
    }
  }

  Future<Map<String, dynamic>> getRestaurantCategoryWithMenus(
      int restaurantId, int restaurantCategoryId) async {
    try {
      // Получаем информацию о категории ресторана
      final categoryResponse = await supabase
          .from('restaurant_categories')
          .select()
          .eq('id', restaurantCategoryId)
          .single();

      // Получаем категории меню для этой категории ресторана
      final menuCategories = await getMenuCategoriesByRestaurantCategory(
          restaurantId, restaurantCategoryId);

      return {
        'restaurant_category': categoryResponse,
        'menu_categories': menuCategories,
      };
    } catch (error) {
      throw Exception('Failed to load restaurant category with menus: $error');
    }
  }
}
