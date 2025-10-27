import 'package:equatable/equatable.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookings extends BookingEvent {
  final int restaurantId;

  const LoadBookings(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

class UpdateBookingStatus extends BookingEvent {
  final int bookingId;
  final String newStatus;

  const UpdateBookingStatus({
    required this.bookingId,
    required this.newStatus,
  });

  @override
  List<Object?> get props => [bookingId, newStatus];
}

class FilterBookings extends BookingEvent {
  final String filter;

  const FilterBookings(this.filter);

  @override
  List<Object?> get props => [filter];
}
