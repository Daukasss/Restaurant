import '../../models/menu_category.dart';
import '../../models/menu_item.dart';

abstract class AbstractMenuService {
  Future<List<MenuCategory>> getMenuCategories(int restaurantId);
  Future<void> addCategory(MenuCategory category);
  Future<void> updateCategory(int categoryId, MenuCategory category);
  Future<void> deleteCategory(int categoryId);

  Future<void> addMenuItem(MenuItem menuItem);
  Future<List<Map<String, dynamic>>> loadMenuSelections(
      List<Map<String, dynamic>> menuSelections);
  Future<void> updateMenuItem(int menuItemId, MenuItem menuItem);
  Future<void> deleteMenuItem(int menuItemId);
  Future<List<Map<String, dynamic>>> fetchMenuSelections(
      Map<String, dynamic> booking);
}
