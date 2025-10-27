import 'package:equatable/equatable.dart';

abstract class RestaurantDetailEvent extends Equatable {
  const RestaurantDetailEvent();

  @override
  List<Object?> get props => [];
}

class FetchRestaurantData extends RestaurantDetailEvent {
  final int restaurantId;

  const FetchRestaurantData(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

class ToggleFavorite extends RestaurantDetailEvent {
  final int restaurantId;

  const ToggleFavorite(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}
