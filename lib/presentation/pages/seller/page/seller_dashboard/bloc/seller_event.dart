import 'package:equatable/equatable.dart';

abstract class SellerEvent extends Equatable {
  const SellerEvent();

  @override
  List<Object?> get props => [];
}

class LoadRestaurants extends SellerEvent {
  final String userId;

  const LoadRestaurants(this.userId);

  @override
  List<Object?> get props => [userId];
}

class DeleteRestaurant extends SellerEvent {
  final String restaurantId;
  final String userId;
  const DeleteRestaurant(this.restaurantId, this.userId);

  @override
  List<Object?> get props => [restaurantId, userId];
}

class RestaurantUpdated extends SellerEvent {
  const RestaurantUpdated();
}
