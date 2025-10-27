import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../../../../../theme/aq_toi.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(const HomeState()) {
    on<LoadRestaurants>(_onLoadRestaurants);
    on<ApplyFilters>(_onApplyFilters);
    on<ResetFilters>(_onResetFilters);
  }

  Future<void> _onLoadRestaurants(
    LoadRestaurants event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final response = await supabase
          .from('restaurants')
          .select()
          .order('rating', ascending: false);

      final restaurants = List<Map<String, dynamic>>.from(response);

      emit(state.copyWith(
        restaurants: restaurants,
        filteredRestaurants: restaurants,
        isLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _onApplyFilters(
    ApplyFilters event,
    Emitter<HomeState> emit,
  ) {
    // Создаем новое состояние с переданными параметрами
    final newState = state.copyWith(
      // selectedCategory: event.category,
      searchQuery: event.searchQuery,
    );

    // Применяем фильтры
    List<Map<String, dynamic>> filtered = List.from(state.restaurants);

    if (event.searchQuery.isNotEmpty) {
      final query = event.searchQuery.toLowerCase();
      filtered = filtered
          .where(
              (restaurant) => restaurant['name'].toLowerCase().contains(query))
          .toList();
    }

    // Эмитим новое состояние с отфильтрованными ресторанами
    emit(newState.copyWith(filteredRestaurants: filtered));

    // Проверяем состояние после эмита
    debugPrint(
        'State after apply: category=${state.selectedCategory}, query=${state.searchQuery}');
  }

  void _onResetFilters(
    ResetFilters event,
    Emitter<HomeState> emit,
  ) {
    debugPrint('Resetting filters in bloc');

    // Создаем полностью новое состояние
    final newState = HomeState(
      restaurants: state.restaurants,
      filteredRestaurants: state.restaurants,
      isLoading: false,
      selectedCategory: null,
      searchQuery: '',
    );

    emit(newState);

    // Проверяем состояние после эмита
    debugPrint(
        'State after reset: category=${state.selectedCategory}, query=${state.searchQuery}');
  }
}
