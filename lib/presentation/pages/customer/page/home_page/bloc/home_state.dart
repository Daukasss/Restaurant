import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final List<Map<String, dynamic>> restaurants;
  final List<Map<String, dynamic>> filteredRestaurants;
  final bool isLoading;
  final String? selectedCategory;
  final String searchQuery;

  const HomeState({
    this.restaurants = const [],
    this.filteredRestaurants = const [],
    this.isLoading = false,
    this.selectedCategory,
    this.searchQuery = '',
  });

  HomeState copyWith({
    List<Map<String, dynamic>>? restaurants,
    List<Map<String, dynamic>>? filteredRestaurants,
    bool? isLoading,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return HomeState(
      restaurants: restaurants ?? this.restaurants,
      filteredRestaurants: filteredRestaurants ?? this.filteredRestaurants,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        restaurants,
        filteredRestaurants,
        isLoading,
        selectedCategory,
        searchQuery,
      ];
}
