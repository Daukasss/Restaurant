import '../../models/menu_category.dart';
import '../../models/menu_item.dart';

abstract class AbstractMenuService {
  Future<List<MenuCategory>> getMenuCategories(
    String restaurantId, {
    String? restaurantCategoryId,
  });

  Future<void> addCategory(MenuCategory category);
  Future<void> updateCategory(String categoryId, MenuCategory category);
  Future<void> deleteCategory(String categoryId);

  Future<void> addMenuItem(MenuItem menuItem);
  Future<List<Map<String, dynamic>>> loadMenuSelections(
      List<Map<String, dynamic>> menuSelections);
  Future<void> updateMenuItem(String menuItemId, MenuItem menuItem);
  Future<void> deleteMenuItem(String menuItemId);
  Future<List<Map<String, dynamic>>> fetchMenuSelections(
      Map<String, dynamic> booking);
}
