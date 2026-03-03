import 'package:equatable/equatable.dart';

abstract class BookingState extends Equatable {
  const BookingState();

  @override
  List<Object?> get props => [];
}

class BookingInitial extends BookingState {}

class BookingLoading extends BookingState {}

/// Данные загружены (онлайн или из кэша)
class BookingLoaded extends BookingState {
  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> filteredBookings;
  final double? pricePerGuest;
  final int? sumPeople;
  final String? activeFilter;
  final DateTime? selectedDate;

  /// true = данные из кэша Hive, сеть недоступна
  final bool isOffline;

  /// Когда был последний успешный онлайн-кэш
  final DateTime? cacheTime;

  const BookingLoaded({
    required this.bookings,
    required this.filteredBookings,
    this.pricePerGuest,
    this.sumPeople,
    this.activeFilter,
    this.selectedDate,
    this.isOffline = false,
    this.cacheTime,
  });

  @override
  List<Object?> get props => [
        bookings,
        filteredBookings,
        pricePerGuest,
        sumPeople,
        activeFilter,
        selectedDate,
        isOffline,
        cacheTime,
      ];

  BookingLoaded copyWith({
    List<Map<String, dynamic>>? bookings,
    List<Map<String, dynamic>>? filteredBookings,
    double? pricePerGuest,
    int? sumPeople,
    String? activeFilter,
    DateTime? selectedDate,
    bool clearDate = false,
    bool? isOffline,
    DateTime? cacheTime,
  }) {
    return BookingLoaded(
      bookings: bookings ?? this.bookings,
      filteredBookings: filteredBookings ?? this.filteredBookings,
      pricePerGuest: pricePerGuest ?? this.pricePerGuest,
      sumPeople: sumPeople ?? this.sumPeople,
      activeFilter: activeFilter ?? this.activeFilter,
      selectedDate: clearDate ? null : (selectedDate ?? this.selectedDate),
      isOffline: isOffline ?? this.isOffline,
      cacheTime: cacheTime ?? this.cacheTime,
    );
  }
}

class BookingError extends BookingState {
  final String message;

  /// true = ошибка из-за отсутствия сети (и нет кэша)
  final bool isNetworkError;

  const BookingError(this.message, {this.isNetworkError = false});

  @override
  List<Object?> get props => [message, isNetworkError];
}

class BookingStatusUpdated extends BookingState {}

/// Состояние когда нет сети И нет кэша
class BookingOfflineEmpty extends BookingState {}
