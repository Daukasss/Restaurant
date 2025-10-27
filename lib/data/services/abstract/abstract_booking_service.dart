import '../../models/booking.dart';

abstract class AbstractBookingService {
  Future<List<Booking>> getBookingsByUser();
  Future<Map<String, dynamic>> createBooking(Booking booking);
  Future<List<Booking>> getBookingsByUserId(String userId);
  Future<void> updateBookingStatus(int bookingId, String newStatus);
  Future<int> getRestaurantIdFromBooking(int bookingId);
  Future<List<Map<String, dynamic>>> getBookings(int restaurantId);
}
