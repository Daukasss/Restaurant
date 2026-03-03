import 'package:flutter/material.dart';
import '../../models/booking.dart';
import '../booking_service.dart';

abstract class AbstractBookingService {
  Future<List<Booking>> getBookingsByUser();
  Future<Map<String, dynamic>> createBooking(Booking booking);
  Future<List<Booking>> getBookingsByUserId(String userId);
  Future<void> updateBookingStatus(String bookingId, String newStatus);
  Future<int> getRestaurantIdFromBooking(String bookingId);
  Future<List<Map<String, dynamic>>> getBookings(String restaurantId);

  Future<ValidationResult> validateBooking({
    required String restaurantId,
    required String restaurantCategoryId,
    required DateTime bookingDate,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    String? excludeBookingId,
  });

  Future<List<Booking>> getBookingsForDate({
    required String restaurantId,
    required DateTime date,
  });

  Future<void> updateBooking({
    required String? bookingId,
    required String name,
    required String phone,
    required int guests,
    required DateTime date,
    required TimeOfDay startTime,
    required TimeOfDay endTime,
    required String restaurantId,
    required Map<String, String> menuItems,
    required String restaurantCategoryId,
    required List<String> selectedExtraIds,
    required int? totalPrice,
  });
}
