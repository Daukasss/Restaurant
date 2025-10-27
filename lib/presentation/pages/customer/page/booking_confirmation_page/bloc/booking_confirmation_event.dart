import 'package:equatable/equatable.dart';

abstract class BookingConfirmationEvent extends Equatable {
  const BookingConfirmationEvent();

  @override
  List<Object?> get props => [];
}

class LoadMenuSelections extends BookingConfirmationEvent {
  final Map<int, int> menuSelections;

  const LoadMenuSelections(this.menuSelections);

  @override
  List<Object?> get props => [menuSelections];
}

class NavigateToHome extends BookingConfirmationEvent {}
