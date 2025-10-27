import '../../models/restaurant.dart';
import '../../models/restaurant_category.dart';
import '../../models/restaurant_extra.dart';

abstract class AbstractRestaurantService {
  // Restaurant methods
  Future<List<Map<String, dynamic>>> getRestaurants();
  Future<List<Map<String, dynamic>>> getRestaurantsByUserId(String userId);
  Future<void> deleteRestaurant(int restaurantId);
  Future<void> saveRestaurant(Restaurant restaurant, {int? existingId});
  Future<Map<String, dynamic>> getRestaurantData(int restaurantId);

  // Restaurant Category methods
  Future<RestaurantCategory?> getRestaurantCategoryById(int categoryId);
  Future<List<RestaurantCategory>> getRestaurantCategories(int restaurantId);
  Future<RestaurantCategory> addRestaurantCategory(RestaurantCategory category);
  Future<RestaurantCategory> updateRestaurantCategory(
      RestaurantCategory category);
  Future<void> deleteRestaurantCategory(int categoryId);

  // Restaurant Extra methods (дополнительные опции)
  Future<List<RestaurantExtra>> getRestaurantExtras(int restaurantId);
  Future<RestaurantExtra> addRestaurantExtra(RestaurantExtra extra);
  Future<RestaurantExtra> updateRestaurantExtra(RestaurantExtra extra);
  Future<void> deleteRestaurantExtra(int extraId);

  // Booked dates methods
  Future<List<DateTime>> getRestaurantBookedDates(int restaurantId);
  Future<List<DateTime>> getBookedDates(int restaurantId);
  Future<void> updateRestaurantBookedDates(int restaurantId, DateTime newDate);
}
