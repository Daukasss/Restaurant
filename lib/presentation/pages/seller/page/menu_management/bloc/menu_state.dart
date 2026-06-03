import 'package:equatable/equatable.dart';

import '../../../../../../data/models/menu_category.dart';

abstract class MenuState extends Equatable {
  const MenuState();

  @override
  List<Object?> get props => [];
}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final List<MenuCategory> categories;
  final List<Map<String, dynamic>> restaurantCategories;
  final String? selectedRestaurantCategoryId;
  final bool isCategoryLoading;

  const MenuLoaded(
    this.categories, {
    this.restaurantCategories = const [],
    this.selectedRestaurantCategoryId,
    this.isCategoryLoading = false,
  });

  MenuLoaded copyWith({
    List<MenuCategory>? categories,
    List<Map<String, dynamic>>? restaurantCategories,
    String? selectedRestaurantCategoryId,
    bool? isCategoryLoading,
  }) {
    return MenuLoaded(
      categories ?? this.categories,
      restaurantCategories: restaurantCategories ?? this.restaurantCategories,
      selectedRestaurantCategoryId:
          selectedRestaurantCategoryId ?? this.selectedRestaurantCategoryId,
      isCategoryLoading: isCategoryLoading ?? this.isCategoryLoading,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        restaurantCategories,
        selectedRestaurantCategoryId,
        isCategoryLoading,
      ];
}

class RestaurantCategoriesLoaded extends MenuState {
  final List<Map<String, dynamic>> restaurantCategories;

  const RestaurantCategoriesLoaded(this.restaurantCategories);

  @override
  List<Object?> get props => [restaurantCategories];
}

class MenuError extends MenuState {
  final String message;

  const MenuError(this.message);

  @override
  List<Object?> get props => [message];
}

class CategoryAdded extends MenuState {}

class CategoryUpdated extends MenuState {}

class CategoryDeleted extends MenuState {}

class MenuItemAdded extends MenuState {}

class MenuItemUpdated extends MenuState {}

class MenuItemDeleted extends MenuState {}
