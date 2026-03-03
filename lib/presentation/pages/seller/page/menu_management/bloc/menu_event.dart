import 'package:equatable/equatable.dart';

import '../../../../../../data/models/menu_category.dart';
import '../../../../../../data/models/menu_item.dart';

abstract class MenuEvent extends Equatable {
  const MenuEvent();

  @override
  List<Object?> get props => [];
}

class LoadMenuCategories extends MenuEvent {
  final String restaurantId;
  final String? restaurantCategoryId;

  const LoadMenuCategories(this.restaurantId, {this.restaurantCategoryId});

  @override
  List<Object?> get props => [restaurantId, restaurantCategoryId];
}

class LoadRestaurantCategories extends MenuEvent {
  final String restaurantId;

  const LoadRestaurantCategories(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

class SelectRestaurantCategory extends MenuEvent {
  final String restaurantId;
  final String restaurantCategoryId;

  const SelectRestaurantCategory(this.restaurantId, this.restaurantCategoryId);

  @override
  List<Object?> get props => [restaurantId, restaurantCategoryId];
}

class AddMenuCategory extends MenuEvent {
  final MenuCategory category;

  const AddMenuCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class UpdateMenuCategory extends MenuEvent {
  final String categoryId;
  final MenuCategory category;

  const UpdateMenuCategory(this.categoryId, this.category);

  @override
  List<Object?> get props => [categoryId, category];
}

class DeleteMenuCategory extends MenuEvent {
  final String categoryId;

  const DeleteMenuCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class AddMenuItem extends MenuEvent {
  final MenuItem menuItem;

  const AddMenuItem(this.menuItem);

  @override
  List<Object?> get props => [menuItem];
}

class UpdateMenuItem extends MenuEvent {
  final String menuItemId;
  final MenuItem menuItem;

  const UpdateMenuItem(this.menuItemId, this.menuItem);

  @override
  List<Object?> get props => [menuItemId, menuItem];
}

class DeleteMenuItem extends MenuEvent {
  final String menuItemId;

  const DeleteMenuItem(this.menuItemId);

  @override
  List<Object?> get props => [menuItemId];
}
