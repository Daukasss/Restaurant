import 'package:equatable/equatable.dart';

import '../../../../../../data/models/booking.dart';
import '../../../../../../data/models/profile.dart';
import '../../../../../../data/models/restaurant.dart';

class ProfileState extends Equatable {
  final Profile? profile;
  final List<Booking> bookings;
  final List<Favorite> favorites;
  final bool isLoading;
  final List<Restaurant> restaurants;
  final String? error;
  final bool isUpdating;
  final bool isAuthenticated;
  final bool wasUpdated;

  const ProfileState({
    this.profile,
    this.bookings = const [],
    this.favorites = const [],
    this.isLoading = false,
    this.error,
    this.restaurants = const [],
    this.isUpdating = false,
    this.isAuthenticated = true,
    this.wasUpdated = false,
  });

  ProfileState copyWith({
    Profile? profile,
    List<Booking>? bookings,
    List<Favorite>? favorites,
    List<Restaurant>? restaurants,
    bool? isLoading,
    String? error,
    bool? isUpdating,
    bool? isAuthenticated,
    bool? wasUpdated,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      bookings: bookings ?? this.bookings,
      favorites: favorites ?? this.favorites,
      restaurants: restaurants ?? this.restaurants,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isUpdating: isUpdating ?? this.isUpdating,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      wasUpdated: wasUpdated ?? this.wasUpdated,
    );
  }

  @override
  List<Object?> get props => [
        profile,
        bookings,
        favorites,
        isLoading,
        restaurants,
        error,
        isUpdating,
        isAuthenticated,
        wasUpdated,
      ];
}
