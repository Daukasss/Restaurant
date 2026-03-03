import 'package:equatable/equatable.dart';
import 'package:restauran/data/models/profile.dart';
import 'package:restauran/data/models/booking.dart';
import 'package:restauran/data/models/restaurant.dart';

class ProfileState extends Equatable {
  final bool isLoading;
  final bool isUpdating;
  final bool isAuthenticated;

  final bool wasUpdated; // 🔥 главный флаг успеха
  final String? error;

  final Profile? profile;
  final List<Booking> bookings;
  final List<Favorite> favorites;
  final List<Restaurant> restaurants;

  const ProfileState({
    this.isLoading = false,
    this.isUpdating = false,
    this.isAuthenticated = true,
    this.wasUpdated = false,
    this.error,
    this.profile,
    this.bookings = const [],
    this.favorites = const [],
    this.restaurants = const [],
  });

  ProfileState copyWith({
    bool? isLoading,
    bool? isUpdating,
    bool? isAuthenticated,
    bool? wasUpdated,
    String? error,
    Profile? profile,
    List<Booking>? bookings,
    List<Favorite>? favorites,
    List<Restaurant>? restaurants,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      wasUpdated: wasUpdated ?? false,
      error: error,
      profile: profile ?? this.profile,
      bookings: bookings ?? this.bookings,
      favorites: favorites ?? this.favorites,
      restaurants: restaurants ?? this.restaurants,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isUpdating,
        isAuthenticated,
        wasUpdated,
        error,
        profile,
        bookings,
        favorites,
        restaurants,
      ];
}
