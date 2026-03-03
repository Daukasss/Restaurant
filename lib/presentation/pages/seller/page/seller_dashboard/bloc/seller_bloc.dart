import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/services/service_locator.dart';

import '../../../../../../data/services/abstract/abstract_restaurant_service.dart';
import 'seller_event.dart';
import 'seller_state.dart';

class SellerBloc extends Bloc<SellerEvent, SellerState> {
  // final SellerRepository repository;
  final _restaurantService = getIt<AbstractRestaurantService>();

  SellerBloc() : super(SellerInitial()) {
    on<LoadRestaurants>(_onLoadRestaurants);
    on<DeleteRestaurant>(_onDeleteRestaurant);
    on<RestaurantUpdated>(_onRestaurantUpdated);
  }

  Future<void> _onLoadRestaurants(
    LoadRestaurants event,
    Emitter<SellerState> emit,
  ) async {
    emit(SellerLoading());
    try {
      debugPrint('Loading restaurants for userId: ${event.userId}');

      final restaurants =
          await _restaurantService.getRestaurantsByUserId(event.userId);

      debugPrint(' Successfully loaded ${restaurants.length} restaurants');

      emit(SellerLoaded(restaurants));
    } catch (error) {
      debugPrint(' Error in _onLoadRestaurants: $error');
      debugPrint(' Error type: ${error.runtimeType}');
      emit(const SellerError(
          'Ошибка загрузки данных! Проверьте структуру базы данных.'));
    }
  }

  Future<void> _onDeleteRestaurant(
    DeleteRestaurant event,
    Emitter<SellerState> emit,
  ) async {
    try {
      await _restaurantService.deleteRestaurant(event.restaurantId);
      emit(const RestaurantDeleted('Ресторан успешно удален!'));
      // This will be passed from the UI layer
      if (state is SellerLoaded) {
        final currentState = state as SellerLoaded;
        if (currentState.restaurants.isNotEmpty) {
          final userId = currentState.restaurants.first['user_id'] as String;
          add(LoadRestaurants(userId));
        }
      }
    } catch (error) {
      debugPrint('[v0] Error deleting restaurant: $error');
      emit(const SellerOperationFailure(
          'Ошибка удаления ресторана!У вас имеется бронирование.Для безопасности просим обратиться к админстрации.'));

      // 🔧 FIX: Add proper state and null checks before reloading
      if (state is SellerLoaded) {
        final currentState = state as SellerLoaded;
        if (currentState.restaurants.isNotEmpty) {
          final userId = currentState.restaurants.first['user_id'];
          // Check if userId is not null before reloading
          if (userId != null) {
            add(LoadRestaurants(userId as String));
          }
        }
      }
    }
  }

  Future<void> _onRestaurantUpdated(
    RestaurantUpdated event,
    Emitter<SellerState> emit,
  ) async {
    // Уведомления об обновлении ресторана будут отправлены автоматически
    // через Supabase Realtime при изменении записи в таблице restaurants

    if (state is SellerLoaded) {
      final currentState = state as SellerLoaded;
      if (currentState.restaurants.isNotEmpty) {
        final userId = currentState.restaurants.first['user_id'] as String;
        add(LoadRestaurants(userId));
      }
    }
  }
}
