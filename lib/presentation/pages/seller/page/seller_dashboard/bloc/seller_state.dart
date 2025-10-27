import 'package:equatable/equatable.dart';

abstract class SellerState extends Equatable {
  const SellerState();

  @override
  List<Object?> get props => [];
}

class SellerInitial extends SellerState {}

class SellerLoading extends SellerState {}

class SellerLoaded extends SellerState {
  final List<Map<String, dynamic>> restaurants;

  const SellerLoaded(this.restaurants);

  @override
  List<Object?> get props => [restaurants];
}

class SellerError extends SellerState {
  final String message;

  const SellerError(this.message);

  @override
  List<Object?> get props => [message];
}

class RestaurantDeleted extends SellerState {
  final String message;

  const RestaurantDeleted(this.message);

  @override
  List<Object?> get props => [message];
}

class SellerOperationFailure extends SellerState {
  final String message;

  const SellerOperationFailure(this.message);

  @override
  List<Object?> get props => [message];
}
