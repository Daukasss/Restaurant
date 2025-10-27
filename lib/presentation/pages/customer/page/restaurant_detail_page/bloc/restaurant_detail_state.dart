import 'package:equatable/equatable.dart';
import '../../../../../../data/models/restaurant_category.dart';

class RestaurantDetailState extends Equatable {
  final Map<String, dynamic>? restaurant;
  final List<Map<String, dynamic>> menuItems;
  final List<String> photoUrls;
  final bool isLoading;
  final bool isFavorite;
  final String? error;
  final Map<String, List<Map<String, dynamic>>> categorizedMenuItems;
  final List<Map<String, dynamic>> categories;
  final Map<int, List<Map<String, dynamic>>> menuItemsByCategory;
  final List<RestaurantCategory> restaurantCategories;
  final Map<int, Map<String, dynamic>> menuByRestaurantCategory;

  const RestaurantDetailState({
    this.restaurant,
    this.menuItems = const [],
    this.photoUrls = const [],
    this.isLoading = true,
    this.isFavorite = false,
    this.error,
    this.categorizedMenuItems = const {},
    this.categories = const [],
    this.menuItemsByCategory = const {},
    this.restaurantCategories = const [],
    this.menuByRestaurantCategory = const {},
  });

  RestaurantDetailState copyWith({
    Map<String, dynamic>? restaurant,
    List<Map<String, dynamic>>? menuItems,
    List<String>? photoUrls,
    bool? isLoading,
    bool? isFavorite,
    String? error,
    Map<String, List<Map<String, dynamic>>>? categorizedMenuItems,
    List<Map<String, dynamic>>? categories,
    Map<int, List<Map<String, dynamic>>>? menuItemsByCategory,
    List<RestaurantCategory>? restaurantCategories,
    Map<int, Map<String, dynamic>>? menuByRestaurantCategory,
  }) {
    return RestaurantDetailState(
      restaurant: restaurant ?? this.restaurant,
      menuItems: menuItems ?? this.menuItems,
      photoUrls: photoUrls ?? this.photoUrls,
      isLoading: isLoading ?? this.isLoading,
      isFavorite: isFavorite ?? this.isFavorite,
      error: error,
      categorizedMenuItems: categorizedMenuItems ?? this.categorizedMenuItems,
      categories: categories ?? this.categories,
      menuItemsByCategory: menuItemsByCategory ?? this.menuItemsByCategory,
      restaurantCategories: restaurantCategories ?? this.restaurantCategories,
      menuByRestaurantCategory:
          menuByRestaurantCategory ?? this.menuByRestaurantCategory,
    );
  }

  @override
  List<Object?> get props => [
        restaurant,
        menuItems,
        photoUrls,
        isLoading,
        isFavorite,
        error,
        categorizedMenuItems,
        categories,
        menuItemsByCategory,
        restaurantCategories,
        menuByRestaurantCategory,
      ];
}
