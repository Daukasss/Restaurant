import 'package:equatable/equatable.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadBookings extends BookingEvent {
  final String restaurantId;

  const LoadBookings(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

class UpdateBookingStatus extends BookingEvent {
  final String bookingId;
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

class FilterBookingsByDate extends BookingEvent {
  final DateTime? date;

  const FilterBookingsByDate(this.date);

  @override
  List<Object?> get props => [date];
}

/// Событие изменения состояния сети (вызывается из ConnectivityService)
class ConnectivityChanged extends BookingEvent {
  final bool isOnline;

  const ConnectivityChanged(this.isOnline);

  @override
  List<Object?> get props => [isOnline];
}
