import '../../models/restaurant.dart';
import '../../models/restaurant_category.dart';
import '../../models/restaurant_extra.dart';

abstract class AbstractRestaurantService {
  // Restaurant methods
  Future<List<Map<String, dynamic>>> getRestaurants();
  Future<List<Map<String, dynamic>>> getRestaurantsByUserId(String userId);
  Future<void> deleteRestaurant(String restaurantId);
  Future<void> saveRestaurant(Restaurant restaurant, {String? existingId});
  Future<Map<String, dynamic>> getRestaurantData(String restaurantId);

  // Restaurant Category methods
  Future<RestaurantCategory?> getRestaurantCategoryById(String categoryId);
  Future<List<RestaurantCategory>> getRestaurantCategories(String restaurantId);
  Future<RestaurantCategory> addRestaurantCategory(RestaurantCategory category);
  Future<RestaurantCategory> updateRestaurantCategory(
      RestaurantCategory category);
  Future<void> deleteRestaurantCategory(String categoryId);

  // Restaurant Extra methods (дополнительные опции)
  Future<List<RestaurantExtra>> getRestaurantExtras(String restaurantId);
  Future<RestaurantExtra> addRestaurantExtra(RestaurantExtra extra);
  Future<RestaurantExtra> updateRestaurantExtra(RestaurantExtra extra);
  Future<void> deleteRestaurantExtra(String extraId);

  // Booked dates methods
  Future<List<DateTime>> getRestaurantBookedDates(String restaurantId);
  Future<List<DateTime>> getBookedDates(String restaurantId);
  Future<void> updateRestaurantBookedDates(
      String restaurantId, DateTime newDate);
}
