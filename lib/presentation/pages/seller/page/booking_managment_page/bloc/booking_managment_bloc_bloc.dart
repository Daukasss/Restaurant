import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/services/abstract/service_export.dart';

import '../../../../../../data/services/service_lacator.dart';
import 'booking_managment_bloc_event.dart';
import 'booking_managment_bloc_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final _restaurantService = getIt<AbstractRestaurantService>();
  final _bookingService = getIt<AbstractBookingService>();

  BookingBloc() : super(BookingInitial()) {
    on<LoadBookings>(_onLoadBookings);
    on<UpdateBookingStatus>(_onUpdateBookingStatus);
    on<FilterBookings>(_onFilterBookings);
  }

  Future<void> _onLoadBookings(
    LoadBookings event,
    Emitter<BookingState> emit,
  ) async {
    emit(BookingLoading());
    try {
      final restaurantData =
          await _restaurantService.getRestaurantData(event.restaurantId);
      final bookings = await _bookingService.getBookings(event.restaurantId);

      // Update booking statuses based on time
      final updatedBookings = _updateBookingStatusesByTime(bookings);

      emit(BookingLoaded(
        bookings: updatedBookings,
        filteredBookings: updatedBookings,
        pricePerGuest: restaurantData['pricePerGuest'],
        sumPeople: restaurantData['sumPeople'],
      ));
    } catch (error) {
      debugPrint(error.toString());
      emit(const BookingError('Ошибка загрузки данных!'));
    }
  }

  Future<void> _onUpdateBookingStatus(
    UpdateBookingStatus event,
    Emitter<BookingState> emit,
  ) async {
    try {
      await _bookingService.updateBookingStatus(
        event.bookingId,
        event.newStatus,
      );

      emit(BookingStatusUpdated());

      // Reload bookings after status update
      if (state is BookingLoaded) {
        final restaurantId =
            await _bookingService.getRestaurantIdFromBooking(event.bookingId);
        add(LoadBookings(restaurantId));
      }
    } catch (error) {
      debugPrint(error.toString());
      emit(const BookingError('Ошибка обновления статуса!'));
    }
  }

  void _onFilterBookings(
    FilterBookings event,
    Emitter<BookingState> emit,
  ) {
    if (state is BookingLoaded) {
      final currentState = state as BookingLoaded;
      final String filter = event.filter;

      List<Map<String, dynamic>> filteredBookings;

      if (filter == 'all') {
        filteredBookings = currentState.bookings;
      } else {
        filteredBookings = currentState.bookings
            .where((booking) => booking['status'] == filter)
            .toList();
      }

      emit(currentState.copyWith(
        filteredBookings: filteredBookings,
        activeFilter: filter,
      ));
    }
  }

  List<Map<String, dynamic>> _updateBookingStatusesByTime(
      List<Map<String, dynamic>> bookings) {
    final now = DateTime.now();

    return bookings.map((booking) {
      final bookingTime = DateTime.parse(booking['booking_time']);

      // Create a new map to avoid modifying the original
      final updatedBooking = Map<String, dynamic>.from(booking);

      // Update status based on time
      if (bookingTime.isBefore(now)) {
        updatedBooking['status'] = 'completed';
      } else {
        updatedBooking['status'] = 'pending';
      }

      return updatedBooking;
    }).toList();
  }
}
