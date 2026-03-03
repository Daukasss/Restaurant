abstract class HomeEvent {}

class LoadRestaurants extends HomeEvent {}

class ApplySearchQuery extends HomeEvent {
  final String searchQuery;
  ApplySearchQuery(this.searchQuery);
}

class ApplyCategoryAndDateFilter extends HomeEvent {
  final String? globalCategoryId; // null = все категории
  final DateTime? selectedDate; // null = без фильтра по дате
  ApplyCategoryAndDateFilter({
    this.globalCategoryId,
    this.selectedDate,
  });
}

class ResetAllFilters extends HomeEvent {}
