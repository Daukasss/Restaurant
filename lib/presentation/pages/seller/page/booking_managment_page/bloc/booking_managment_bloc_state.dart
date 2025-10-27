import 'package:equatable/equatable.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

class BookingLoaded extends BookingState {
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> filteredBookings;
  final double? pricePerGuest;
  final int? sumPeople;
  final String? activeFilter;

  const BookingLoaded({
    required this.bookings,
    required this.filteredBookings,
    this.pricePerGuest,
    this.sumPeople,
    this.activeFilter,
  });

  @override
  List<Object?> get props =>
      [bookings, filteredBookings, pricePerGuest, sumPeople, activeFilter];

  BookingLoaded copyWith({
    List<Map<String, dynamic>>? bookings,
    List<Map<String, dynamic>>? filteredBookings,
    double? pricePerGuest,
    int? sumPeople,
    String? activeFilter,
  }) {
    return BookingLoaded(
      bookings: bookings ?? this.bookings,
      filteredBookings: filteredBookings ?? this.filteredBookings,
      pricePerGuest: pricePerGuest ?? this.pricePerGuest,
      sumPeople: sumPeople ?? this.sumPeople,
      activeFilter: activeFilter ?? this.activeFilter,
    );
  }
}

class BookingError extends BookingState {
  final String message;

  const BookingError(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingStatusUpdated extends BookingState {}
