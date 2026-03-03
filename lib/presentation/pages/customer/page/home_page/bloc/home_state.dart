import 'package:equatable/equatable.dart';

// Sentinel object to distinguish "not passed" from "explicitly null"
const _absent = Object();

class HomeState extends Equatable {
  final List<Map<String, dynamic>> restaurants;
  final List<Map<String, dynamic>> filteredRestaurants;
  final bool isLoading;

  // Фильтры
  final String searchQuery;
  final String? selectedGlobalCategoryId;
  final DateTime? selectedDate;

  const HomeState({
    this.restaurants = const [],
    this.filteredRestaurants = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.selectedGlobalCategoryId,
    this.selectedDate,
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedGlobalCategoryId != null ||
      selectedDate != null;

  HomeState copyWith({
    List<Map<String, dynamic>>? restaurants,
    List<Map<String, dynamic>>? filteredRestaurants,
    bool? isLoading,
    String? searchQuery,
    // Используем Object? чтобы можно было явно передать null
    Object? selectedGlobalCategoryId = _absent,
    Object? selectedDate = _absent,
  }) {
    return HomeState(
      restaurants: restaurants ?? this.restaurants,
      filteredRestaurants: filteredRestaurants ?? this.filteredRestaurants,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedGlobalCategoryId: selectedGlobalCategoryId == _absent
          ? this.selectedGlobalCategoryId
          : selectedGlobalCategoryId as String?,
      selectedDate: selectedDate == _absent
          ? this.selectedDate
          : selectedDate as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
        restaurants,
        filteredRestaurants,
        isLoading,
        searchQuery,
        selectedGlobalCategoryId,
        selectedDate,
      ];
}
