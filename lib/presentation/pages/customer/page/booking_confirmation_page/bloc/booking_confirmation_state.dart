import 'package:equatable/equatable.dart';

abstract class BookingConfirmationState extends Equatable {
  const BookingConfirmationState();

  @override
  List<Object?> get props => [];
}

class BookingConfirmationInitial extends BookingConfirmationState {}

class BookingConfirmationLoading extends BookingConfirmationState {}

class BookingConfirmationLoaded extends BookingConfirmationState {
  final List<Map<String, dynamic>> selectedItems;

  const BookingConfirmationLoaded(this.selectedItems);

  @override
  List<Object?> get props => [selectedItems];
}

class BookingConfirmationError extends BookingConfirmationState {
  final String message;

  const BookingConfirmationError(this.message);

  @override
  List<Object?> get props => [message];
}

class NavigatingToHome extends BookingConfirmationState {}
