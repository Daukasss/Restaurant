import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/models/restaurant.dart';
import 'package:restauran/data/services/favorite_service.dart';
import 'package:restauran/data/services/profile_service.dart';
import '../../../../../../data/services/booking_service.dart';
import '../../../../../../data/services/restaurant_service.dart';
import 'profil_event.dart';
import 'profil_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileService _profileService;
  final BookingService _bookingService;
  final FavoriteService _favoriteService;
  final RestaurantService _restaurantService;

  ProfileBloc({
    required ProfileService profileService,
    required BookingService bookingService,
    required FavoriteService favoriteService,
    required RestaurantService restaurantService,
  })  : _profileService = profileService,
        _bookingService = bookingService,
        _favoriteService = favoriteService,
        _restaurantService = restaurantService,
        super(const ProfileState()) {
    on<LoadUserData>(_onLoadUserData);
    on<UpdateProfile>(_onUpdateProfile);
    on<SignOut>(_onSignOut);
    on<ResetUpdateStatus>(_onResetUpdateStatus);
  }

  Future<void> _onLoadUserData(
    LoadUserData event,
    Emitter<ProfileState> emit,
  ) async {
    if (!_profileService.isAuthenticated()) {
      emit(state.copyWith(isAuthenticated: false));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));

    try {
      debugPrint('=== Загрузка профиля ===');
      final profile = await _profileService.getProfile();
      debugPrint('Профиль загружен: ${profile.toJson()}');

      debugPrint('=== Загрузка бронирований ===');
      final bookings = await _bookingService.getBookingsByUser();
      debugPrint('Бронирований получено: ${bookings.length}');

      debugPrint('=== Загрузка избранного ===');
      final favorites = await _favoriteService.getFavorites();
      debugPrint('Избранных ресторанов: ${favorites.length}');

      debugPrint('=== Загрузка ресторанов ===');
      final restaurantMaps = await _restaurantService.getRestaurants();
      debugPrint('Ресторанов загружено: ${restaurantMaps.length}');

      final restaurants = restaurantMaps.map<Restaurant>((map) {
        try {
          return Restaurant.fromJson(map);
        } catch (e) {
          debugPrint('Ошибка парсинга ресторана: $map\nОшибка: $e');
          rethrow;
        }
      }).toList();

      emit(state.copyWith(
        profile: profile,
        bookings: bookings,
        favorites: favorites,
        isLoading: false,
        restaurants: restaurants,
      ));

      debugPrint('=== Данные успешно загружены ===');
    } catch (error, stack) {
      debugPrint('!!! Ошибка загрузки данных: $error');
      debugPrint('Стек ошибки:\n$stack');
      emit(state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки данных!',
      ));
    }
  }

  Future<void> _onUpdateProfile(
    UpdateProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(state.copyWith(isUpdating: true, error: null, wasUpdated: false));

    try {
      // Проверяем, изменились ли данные
      final currentProfile = state.profile;
      if (currentProfile != null &&
          currentProfile.name == event.name &&
          currentProfile.phone == event.phone) {
        // Данные не изменились, просто завершаем без обновления
        emit(state.copyWith(
          isUpdating: false,
          wasUpdated: false,
        ));
        return;
      }

      // Данные изменились, обновляем профиль
      await _profileService.updateProfile(
        event.name,
        event.phone,
      );

      final updatedProfile = await _profileService.getProfile();
      emit(state.copyWith(
        profile: updatedProfile,
        isUpdating: false,
        wasUpdated: true, // Устанавливаем флаг, что данные были обновлены
      ));
    } catch (error) {
      emit(state.copyWith(
        isUpdating: false,
        error: 'Ошибка обновления профиля!',
        wasUpdated: false,
      ));
    }
  }

  Future<void> _onSignOut(
    SignOut event,
    Emitter<ProfileState> emit,
  ) async {
    await _profileService.signOut();
    emit(state.copyWith(isAuthenticated: false));
  }

  void _onResetUpdateStatus(
    ResetUpdateStatus event,
    Emitter<ProfileState> emit,
  ) {
    emit(state.copyWith(wasUpdated: false));
  }
}
