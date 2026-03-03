import 'package:equatable/equatable.dart';
import 'package:restauran/data/models/global_category.dart';
import 'package:restauran/data/models/restaurant.dart';

abstract class AdminCategoryState extends Equatable {
  const AdminCategoryState();

  @override
  List<Object?> get props => [];
}

/// Начальное состояние
class AdminCategoryInitial extends AdminCategoryState {}

/// Загрузка данных
class AdminCategoryLoading extends AdminCategoryState {}

/// Загрузка списка ресторанов
class AdminCategoryRestaurantsLoading extends AdminCategoryState {}

/// Данные загружены
class AdminCategoryLoaded extends AdminCategoryState {
  final List<GlobalCategory> categories;
  final List<GlobalCategory> filteredCategories;
  final String searchQuery;
  final int? selectedSection; // null - все разделы
  final List<Restaurant> availableRestaurants; // ✅ список ресторанов для выбора

  const AdminCategoryLoaded({
    required this.categories,
    required this.filteredCategories,
    this.searchQuery = '',
    this.selectedSection,
    this.availableRestaurants = const [],
  });

  AdminCategoryLoaded copyWith({
    List<GlobalCategory>? categories,
    List<GlobalCategory>? filteredCategories,
    String? searchQuery,
    int? selectedSection,
    List<Restaurant>? availableRestaurants,
    bool clearSection = false,
  }) {
    return AdminCategoryLoaded(
      categories: categories ?? this.categories,
      filteredCategories: filteredCategories ?? this.filteredCategories,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSection:
          clearSection ? null : (selectedSection ?? this.selectedSection),
      availableRestaurants: availableRestaurants ?? this.availableRestaurants,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        filteredCategories,
        searchQuery,
        selectedSection,
        availableRestaurants,
      ];
}

/// Ошибка
class AdminCategoryError extends AdminCategoryState {
  final String message;

  const AdminCategoryError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Успешное действие
class AdminCategorySuccess extends AdminCategoryState {
  final String message;

  const AdminCategorySuccess(this.message);

  @override
  List<Object?> get props => [message];
}
