import 'package:equatable/equatable.dart';

abstract class AdminCategoryEvent extends Equatable {
  const AdminCategoryEvent();

  @override
  List<Object?> get props => [];
}

/// Загрузить все глобальные категории
class LoadGlobalCategoriesEvent extends AdminCategoryEvent {}

/// Загрузить список доступных ресторанов для выбора
class LoadAvailableRestaurantsEvent extends AdminCategoryEvent {}

/// Добавить новую глобальную категорию
class AddGlobalCategoryEvent extends AdminCategoryEvent {
  final String name;
  final int section;
  final double defaultPrice;
  final String? description;
  final bool isGlobal;
  final List<String> restaurantIds;

  const AddGlobalCategoryEvent({
    required this.name,
    required this.section,
    required this.defaultPrice,
    this.description,
    this.isGlobal = true,
    this.restaurantIds = const [],
  });

  @override
  List<Object?> get props => [
        name,
        section,
        defaultPrice,
        description,
        isGlobal,
        restaurantIds,
      ];
}

/// Обновить глобальную категорию
class UpdateGlobalCategoryEvent extends AdminCategoryEvent {
  final String categoryId;
  final String? name;
  final int? section;
  final double? defaultPrice;
  final String? description;
  final bool? isGlobal;
  final List<String>? restaurantIds;
  final bool? isActive;

  const UpdateGlobalCategoryEvent({
    required this.categoryId,
    this.name,
    this.section,
    this.defaultPrice,
    this.description,
    this.isGlobal,
    this.restaurantIds,
    this.isActive,
  });

  @override
  List<Object?> get props => [
        categoryId,
        name,
        section,
        defaultPrice,
        description,
        isGlobal,
        restaurantIds,
        isActive,
      ];
}

/// Удалить (деактивировать) глобальную категорию
class DeleteGlobalCategoryEvent extends AdminCategoryEvent {
  final String categoryId;

  const DeleteGlobalCategoryEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

/// Поиск категорий
class SearchGlobalCategoriesEvent extends AdminCategoryEvent {
  final String query;

  const SearchGlobalCategoriesEvent(this.query);

  @override
  List<Object?> get props => [query];
}

/// Фильтрация по разделу
class FilterCategoriesBySectionEvent extends AdminCategoryEvent {
  final int? section; // null - показать все

  const FilterCategoriesBySectionEvent(this.section);

  @override
  List<Object?> get props => [section];
}
