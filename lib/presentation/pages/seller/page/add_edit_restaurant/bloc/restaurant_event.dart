import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

abstract class RestaurantEvent extends Equatable {
  const RestaurantEvent();

  @override
  List<Object?> get props => [];
}

class LoadRestaurantData extends RestaurantEvent {
  final Map<String, dynamic>? restaurant;
  final String restaurantId;

  const LoadRestaurantData({
    this.restaurant,
    required this.restaurantId,
  });

  @override
  List<Object?> get props => [restaurant, restaurantId];
}

class LoadBookedDates extends RestaurantEvent {
  final String restaurantId;

  const LoadBookedDates({required this.restaurantId});

  @override
  List<Object?> get props => [restaurantId];
}

class UpdateName extends RestaurantEvent {
  final String name;

  const UpdateName(this.name);

  @override
  List<Object?> get props => [name];
}

class UpdateDescription extends RestaurantEvent {
  final String description;

  const UpdateDescription(this.description);

  @override
  List<Object?> get props => [description];
}

class UpdateLocation extends RestaurantEvent {
  final String location;

  const UpdateLocation(this.location);

  @override
  List<Object?> get props => [location];
}

class UpdatePhone extends RestaurantEvent {
  final String phone;

  const UpdatePhone(this.phone);

  @override
  List<Object?> get props => [phone];
}

class UpdateWorkingHours extends RestaurantEvent {
  final String workingHours;

  const UpdateWorkingHours(this.workingHours);

  @override
  List<Object?> get props => [workingHours];
}

class UpdatePriceRange extends RestaurantEvent {
  final String priceRange;

  const UpdatePriceRange(this.priceRange);

  @override
  List<Object?> get props => [priceRange];
}

class UpdateSumPeople extends RestaurantEvent {
  final String sumPeople;

  const UpdateSumPeople(this.sumPeople);

  @override
  List<Object?> get props => [sumPeople];
}

class UpdateCategory extends RestaurantEvent {
  final String category;

  const UpdateCategory(this.category);

  @override
  List<Object?> get props => [category];
}

class AddPhoto extends RestaurantEvent {
  final String restaurantId;

  const AddPhoto({required this.restaurantId});

  @override
  List<Object?> get props => [restaurantId];
}

class RemovePhoto extends RestaurantEvent {
  final int index;

  const RemovePhoto(this.index);

  @override
  List<Object?> get props => [index];
}

class UpdateTempBookedDates extends RestaurantEvent {
  final List<DateTime> dates;

  const UpdateTempBookedDates(this.dates);

  @override
  List<Object?> get props => [dates];
}

class UpdateBookedDates extends RestaurantEvent {
  final List<DateTime> dates;

  const UpdateBookedDates(this.dates);

  @override
  List<Object?> get props => [dates];
}

class SaveRestaurant extends RestaurantEvent {
  final BuildContext context;

  const SaveRestaurant(this.context);

  @override
  List<Object?> get props => [context];
}

// ==================== НОВЫЕ СОБЫТИЯ ДЛЯ КАТЕГОРИЙ ====================

/// Загрузить доступные глобальные категории для ресторана
class LoadAvailableGlobalCategories extends RestaurantEvent {
  final String restaurantId;

  const LoadAvailableGlobalCategories(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

/// Загрузить категории ресторана
class LoadRestaurantCategories extends RestaurantEvent {
  final String restaurantId;

  const LoadRestaurantCategories(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

/// Активировать глобальную категорию для ресторана
class ActivateRestaurantCategory extends RestaurantEvent {
  final String globalCategoryId;
  final double price;
  final String? description;

  const ActivateRestaurantCategory({
    required this.globalCategoryId,
    required this.price,
    this.description,
  });

  @override
  List<Object?> get props => [globalCategoryId, price, description];
}

/// Обновить категорию ресторана (цена, описание, активность)
class UpdateRestaurantCategory extends RestaurantEvent {
  final String categoryId;
  final double? price;
  final String? description;
  final bool? isActive;

  const UpdateRestaurantCategory({
    required this.categoryId,
    this.price,
    this.description,
    this.isActive,
  });

  @override
  List<Object?> get props => [categoryId, price, description, isActive];
}

/// Деактивировать категорию ресторана
class DeactivateRestaurantCategory extends RestaurantEvent {
  final String categoryId;

  const DeactivateRestaurantCategory(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

// ==================== СОБЫТИЯ ДЛЯ EXTRAS ====================

class AddRestaurantExtra extends RestaurantEvent {
  final String name;
  final double price;
  final String? description;

  const AddRestaurantExtra({
    required this.name,
    required this.price,
    this.description,
  });

  @override
  List<Object?> get props => [name, price, description];
}

class UpdateRestaurantExtra extends RestaurantEvent {
  final String extraId;
  final String? name;
  final double? price;
  final String? description;
  final bool? isActive;

  const UpdateRestaurantExtra({
    required this.extraId,
    this.name,
    this.price,
    this.description,
    this.isActive,
  });

  @override
  List<Object?> get props => [extraId, name, price, description, isActive];
}

class RemoveRestaurantExtra extends RestaurantEvent {
  final String extraId;

  const RemoveRestaurantExtra(this.extraId);

  @override
  List<Object?> get props => [extraId];
}

class LoadRestaurantExtras extends RestaurantEvent {
  final String restaurantId;

  const LoadRestaurantExtras(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}
