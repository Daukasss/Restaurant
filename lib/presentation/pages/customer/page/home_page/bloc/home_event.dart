abstract class HomeEvent {}

class LoadRestaurants extends HomeEvent {}

class ApplyFilters extends HomeEvent {
  // final String? category;
  final String searchQuery;

  ApplyFilters({
    // this.category,
    this.searchQuery = '',
  });
}

class ResetFilters extends HomeEvent {}
