import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/services/restaurant_service.dart';
import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final RestaurantService _restaurantService;

  HomeBloc({required RestaurantService restaurantService})
      : _restaurantService = restaurantService,
        super(const HomeState()) {
    on<LoadRestaurants>(_onLoadRestaurants);
    on<ApplySearchQuery>(_onApplySearch);
    on<ApplyCategoryAndDateFilter>(_onApplyCategoryAndDateFilter);
    on<ResetAllFilters>(_onResetAllFilters);
  }

  Future<void> _onLoadRestaurants(
    LoadRestaurants event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      final querySnapshot = await _firestore
          .collection('restaurants')
          .orderBy('rating', descending: true)
          .get();

      final restaurants = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      emit(state.copyWith(
        restaurants: restaurants,
        filteredRestaurants: restaurants,
        isLoading: false,
      ));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _onApplySearch(
    ApplySearchQuery event,
    Emitter<HomeState> emit,
  ) {
    final updatedState = state.copyWith(searchQuery: event.searchQuery);
    final filtered = _applySearchFilter(updatedState);
    emit(updatedState.copyWith(filteredRestaurants: filtered));
  }

  Future<void> _onApplyCategoryAndDateFilter(
    ApplyCategoryAndDateFilter event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    final updatedState = state.copyWith(
      selectedGlobalCategoryId: event.globalCategoryId,
      selectedDate: event.selectedDate,
    );

    try {
      final filtered = await _applyAllFiltersAsync(updatedState);

      emit(updatedState.copyWith(
        filteredRestaurants: filtered,
        isLoading: false,
      ));
    } catch (e) {
      debugPrint('Ошибка фильтрации: $e');
      // Сбрасываем загрузку, показываем все рестораны без фильтра
      emit(updatedState.copyWith(
        filteredRestaurants: state.restaurants,
        isLoading: false,
      ));
    }
  }

  List<Map<String, dynamic>> _applySearchFilter(HomeState current) {
    List<Map<String, dynamic>> result = List.from(current.restaurants);

    if (current.searchQuery.isNotEmpty) {
      final q = current.searchQuery.toLowerCase();
      result = result
          .where((r) => (r['name'] as String).toLowerCase().contains(q))
          .toList();
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> _applyAllFiltersAsync(
      HomeState current) async {
    List<Map<String, dynamic>> result = _applySearchFilter(current);

    // Фильтруем только если выбрана категория (дата опциональна внутри сервиса)
    if (current.selectedGlobalCategoryId != null) {
      int? requiredSection;

      final catDoc = await _firestore
          .collection('global_categories')
          .doc(current.selectedGlobalCategoryId)
          .get();

      if (catDoc.exists) {
        requiredSection = catDoc.data()?['section'] as int?;
      }

      final availableIds =
          await _restaurantService.getRestaurantsAvailableForDateAndSection(
        date: current.selectedDate,
        section: requiredSection,
        globalCategoryId: current.selectedGlobalCategoryId,
      );

      result = result
          .where((r) => availableIds.contains(r['id'] as String))
          .toList();
    }

    return result;
  }

  void _onResetAllFilters(
    ResetAllFilters event,
    Emitter<HomeState> emit,
  ) {
    emit(HomeState(
      restaurants: state.restaurants,
      filteredRestaurants: state.restaurants,
      isLoading: false,
    ));
  }
}
