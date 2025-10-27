// ignore_for_file: prefer_collection_literals

import 'package:flutter/foundation.dart';
import 'package:restauran/data/services/abstract/service_export.dart';
import '../../theme/aq_toi.dart';
import '../models/restaurant.dart';
import '../models/restaurant_category.dart';
import '../models/restaurant_extra.dart';

class RestaurantService implements AbstractRestaurantService {
  @override
  Future<List<RestaurantExtra>> getRestaurantExtras(int restaurantId) async {
    try {
      final response = await supabase
          .from('restaurant_extras')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => RestaurantExtra.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to load restaurant extras: $error');
    }
  }

  @override
  Future<RestaurantExtra> addRestaurantExtra(RestaurantExtra extra) async {
    try {
      final response = await supabase
          .from('restaurant_extras')
          .insert(extra.toJson())
          .select()
          .single();

      return RestaurantExtra.fromJson(response);
    } catch (error) {
      throw Exception('Failed to add restaurant extra: $error');
    }
  }

  @override
  Future<RestaurantExtra> updateRestaurantExtra(RestaurantExtra extra) async {
    try {
      final response = await supabase
          .from('restaurant_extras')
          .update(extra.toJson())
          .eq('id', extra.id!)
          .select()
          .single();

      return RestaurantExtra.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update restaurant extra: $error');
    }
  }

  @override
  Future<void> deleteRestaurantExtra(int extraId) async {
    try {
      await supabase
          .from('restaurant_extras')
          .update({'is_active': false}).eq('id', extraId);
    } catch (error) {
      throw Exception('Failed to delete restaurant extra: $error');
    }
  }

  @override
  Future<RestaurantCategory?> getRestaurantCategoryById(int categoryId) async {
    try {
      final response = await supabase
          .from('restaurant_categories')
          .select()
          .eq('id', categoryId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return null;
      return RestaurantCategory.fromJson(response);
    } catch (error) {
      throw Exception('Failed to load restaurant category: $error');
    }
  }

  @override
  Future<List<RestaurantCategory>> getRestaurantCategories(
      int restaurantId) async {
    try {
      final response = await supabase
          .from('restaurant_categories')
          .select()
          .eq('restaurant_id', restaurantId)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response)
          .map((json) => RestaurantCategory.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to load restaurant categories: $error');
    }
  }

  @override
  Future<RestaurantCategory> addRestaurantCategory(
      RestaurantCategory category) async {
    try {
      final response = await supabase
          .from('restaurant_categories')
          .insert(category.toJson())
          .select()
          .single();

      return RestaurantCategory.fromJson(response);
    } catch (error) {
      throw Exception('Failed to add restaurant category: $error');
    }
  }

  @override
  Future<RestaurantCategory> updateRestaurantCategory(
      RestaurantCategory category) async {
    try {
      final response = await supabase
          .from('restaurant_categories')
          .update(category.toJson())
          .eq('id', category.id!)
          .select()
          .single();

      return RestaurantCategory.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update restaurant category: $error');
    }
  }

  @override
  Future<void> deleteRestaurantCategory(int categoryId) async {
    try {
      await supabase
          .from('restaurant_categories')
          .update({'is_active': false}).eq('id', categoryId);
    } catch (error) {
      throw Exception('Failed to delete restaurant category: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> getRestaurantData(int restaurantId) async {
    try {
      final restaurantResponse = await supabase
          .from('restaurants')
          .select()
          .eq('id', restaurantId)
          .single();

      final categories = await getRestaurantCategories(restaurantId);

      final sumPeople = restaurantResponse['sum_people'] ?? 0;
      final pricePerGuest =
          double.tryParse(restaurantResponse['price_range'].toString()) ?? 0.0;

      return {
        'sumPeople': sumPeople,
        'pricePerGuest': pricePerGuest,
        'categories': categories,
      };
    } catch (error) {
      throw Exception('Failed to load restaurant data');
    }
  }

  @override
  Future<void> saveRestaurant(Restaurant restaurant, {int? existingId}) async {
    if (existingId != null) {
      await supabase
          .from('restaurants')
          .update(restaurant.toJson())
          .eq('id', existingId);
    } else {
      await supabase.from('restaurants').insert(restaurant.toJson());
    }
  }

  @override
  Future<List<DateTime>> getRestaurantBookedDates(int restaurantId) async {
    final response = await supabase
        .from('restaurants')
        .select('booked_dates')
        .eq('id', restaurantId)
        .single();
    if (response['booked_dates'] != null) {
      return List<String>.from(response['booked_dates'])
          .map((e) => DateTime.parse(e))
          .toList();
    }
    return [];
  }

  @override
  Future<List<DateTime>> getBookedDates(int restaurantId) async {
    final restaurantDates = await getRestaurantBookedDates(restaurantId);

    final bookings = await supabase
        .from('bookings')
        .select('booking_time')
        .eq('restaurant_id', restaurantId)
        .or('status.eq.pending,status.eq.confirmed');

    final bookingDates = bookings.map<DateTime>((b) {
      final date = DateTime.parse(b['booking_time']);
      return DateTime(date.year, date.month, date.day);
    }).toList();

    return [...restaurantDates, ...bookingDates].toSet().toList();
  }

  @override
  Future<void> updateRestaurantBookedDates(
      int restaurantId, DateTime newDate) async {
    final existingDates = await getRestaurantBookedDates(restaurantId);
    final dateOnly = DateTime(newDate.year, newDate.month, newDate.day);

    final dateExists = existingDates.any((date) =>
        date.year == dateOnly.year &&
        date.month == dateOnly.month &&
        date.day == dateOnly.day);

    if (!dateExists) {
      final updatedDates = [...existingDates, dateOnly];
      updatedDates.sort();

      await supabase.from('restaurants').update({
        'booked_dates': updatedDates.map((d) => d.toIso8601String()).toList(),
      }).eq('id', restaurantId);
    }
  }

  Future<void> removeBookedDate(int restaurantId, DateTime dateToRemove) async {
    final existingDates = await getRestaurantBookedDates(restaurantId);
    final dateOnly =
        DateTime(dateToRemove.year, dateToRemove.month, dateToRemove.day);

    final updatedDates = existingDates
        .where((date) => !(date.year == dateOnly.year &&
            date.month == dateOnly.month &&
            date.day == dateOnly.day))
        .toList();

    await supabase.from('restaurants').update({
      'booked_dates': updatedDates.map((d) => d.toIso8601String()).toList(),
    }).eq('id', restaurantId);
  }

  @override
  Future<List<Map<String, dynamic>>> getRestaurants() async {
    try {
      final response = await supabase
          .from('restaurants')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to load restaurants');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRestaurantsByUserId(
      String userId) async {
    try {
      debugPrint('[v0] Fetching restaurants for userId: $userId');

      final response = await supabase
          .from('restaurants')
          .select()
          .eq('owner_id', userId)
          .order('created_at', ascending: false);

      debugPrint(
          '[v0] Restaurants fetched successfully: ${response.length} restaurants found');

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('[v0] Error fetching restaurants: $error');
      debugPrint('[v0] Error type: ${error.runtimeType}');
      throw Exception('Failed to load restaurants for user: $error');
    }
  }

  @override
  Future<void> deleteRestaurant(int restaurantId) async {
    try {
      debugPrint('[v0] Starting cascade delete for restaurant $restaurantId');

      await supabase
          .from('restaurant_extras')
          .delete()
          .eq('restaurant_id', restaurantId);
      debugPrint('[v0] Deleted restaurant extras');

      await supabase
          .from('notifications')
          .delete()
          .eq('restaurant_id', restaurantId);
      debugPrint('[v0] Deleted notifications');

      await supabase
          .from('bookings')
          .delete()
          .eq('restaurant_id', restaurantId);
      debugPrint('[v0] Deleted bookings');

      final categories = await supabase
          .from('restaurant_categories')
          .select('id')
          .eq('restaurant_id', restaurantId);

      if (categories.isNotEmpty) {
        final categoryIds = categories.map((c) => c['id'] as int).toList();

        debugPrint('[v0] Deleting menu items for categories: $categoryIds');

        for (final categoryId in categoryIds) {
          await supabase
              .from('menu_items')
              .delete()
              .eq('category_id', categoryId);
        }
        debugPrint('[v0] Deleted menu items');
      }

      await supabase
          .from('restaurant_categories')
          .delete()
          .eq('restaurant_id', restaurantId);
      debugPrint('[v0] Deleted categories');

      await supabase.from('restaurants').delete().eq('id', restaurantId);

      debugPrint(
          '[v0] Restaurant $restaurantId deleted successfully with all related data');
    } catch (error) {
      debugPrint('[v0] Error deleting restaurant: $error');
      throw Exception('Failed to delete restaurant: $error');
    }
  }
}
