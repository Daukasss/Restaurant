import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../../../data/models/menu_category.dart';
import '../../../../../../data/models/restaurant_category.dart';
import '../../../../../../data/models/restaurant_extra.dart';

class BookingState extends Equatable {
  final String name;
  final String phone;
  final String guests;
  final String notes;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final List<DateTime> bookedDates;
  final List<MenuCategory> menuCategories;
  final Map<int, int> selectedMenuItems;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final int? bookingId;
  final String? restaurantName;
  final double? pricePerGuest;
  final int? sumPeople;
  final DateTime? errorTimestamp;
  final List<RestaurantCategory> restaurantCategories;
  final int? selectedRestaurantCategoryId;
  final bool isCategoriesLoading;
  final List<RestaurantExtra> restaurantExtras;
  final List<int> selectedExtraIds;
  final bool isExtrasLoading;

  const BookingState(
    this.notes,
    this.selectedDate, {
    this.name = '',
    this.phone = '',
    this.guests = '',
    this.selectedTime = const TimeOfDay(hour: 12, minute: 0),
    this.bookedDates = const [],
    this.menuCategories = const [],
    this.selectedMenuItems = const {},
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.bookingId,
    this.restaurantName,
    this.errorTimestamp,
    this.pricePerGuest,
    this.sumPeople,
    this.restaurantCategories = const [],
    this.selectedRestaurantCategoryId,
    this.isCategoriesLoading = false,
    this.restaurantExtras = const [],
    this.selectedExtraIds = const [],
    this.isExtrasLoading = false,
  });

  BookingState copyWith({
    String? name,
    String? phone,
    String? guests,
    String? notes,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    List<DateTime>? bookedDates,
    List<MenuCategory>? menuCategories,
    Map<int, int>? selectedMenuItems,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    int? bookingId,
    String? restaurantName,
    DateTime? errorTimestamp,
    double? pricePerGuest,
    int? sumPeople,
    List<RestaurantCategory>? restaurantCategories,
    int? selectedRestaurantCategoryId,
    bool? isCategoriesLoading,
    List<RestaurantExtra>? restaurantExtras,
    List<int>? selectedExtraIds,
    bool? isExtrasLoading,
  }) {
    return BookingState(
      notes ?? this.notes,
      selectedDate ?? this.selectedDate,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      guests: guests ?? this.guests,
      selectedTime: selectedTime ?? this.selectedTime,
      bookedDates: bookedDates ?? this.bookedDates,
      menuCategories: menuCategories ?? this.menuCategories,
      selectedMenuItems: selectedMenuItems ?? this.selectedMenuItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      bookingId: bookingId ?? this.bookingId,
      restaurantName: restaurantName ?? this.restaurantName,
      errorTimestamp: errorTimestamp ?? this.errorTimestamp,
      pricePerGuest: pricePerGuest ?? this.pricePerGuest,
      sumPeople: sumPeople ?? this.sumPeople,
      restaurantCategories: restaurantCategories ?? this.restaurantCategories,
      selectedRestaurantCategoryId:
          selectedRestaurantCategoryId ?? this.selectedRestaurantCategoryId,
      isCategoriesLoading: isCategoriesLoading ?? this.isCategoriesLoading,
      restaurantExtras: restaurantExtras ?? this.restaurantExtras,
      selectedExtraIds: selectedExtraIds ?? this.selectedExtraIds,
      isExtrasLoading: isExtrasLoading ?? this.isExtrasLoading,
    );
  }

  String calculateBookingPrice() {
    if (guests.isEmpty) return 'Цена не указана';

    final guestCount = int.tryParse(guests) ?? 0;
    if (guestCount <= 0) return 'Цена не указана';

    double total = 0;

    // Base price from selected category
    if (selectedRestaurantCategoryId != null) {
      final selectedCategory = restaurantCategories.firstWhere(
        (cat) => cat.id == selectedRestaurantCategoryId,
        orElse: () => restaurantCategories.isNotEmpty
            ? restaurantCategories.first
            : const RestaurantCategory(
                restaurantId: 0, name: '', priceRange: 0),
      );

      if (selectedCategory.priceRange > 0) {
        total = selectedCategory.priceRange * guestCount;
      }
    } else if (pricePerGuest != null && pricePerGuest! > 0) {
      total = pricePerGuest! * guestCount;
    }

    if (selectedExtraIds.isNotEmpty) {
      for (final extraId in selectedExtraIds) {
        final extra = restaurantExtras.firstWhere(
          (e) => e.id == extraId,
          orElse: () => const RestaurantExtra(
            restaurantId: 0,
            name: '',
            price: 0,
          ),
        );
        total += extra.price;
      }
    }

    if (total <= 0) return 'Цена не указана';

    return '${total.toStringAsFixed(0)} Тг';
  }

  @override
  List<Object?> get props => [
        name,
        phone,
        guests,
        notes,
        selectedDate,
        selectedTime,
        bookedDates,
        menuCategories,
        selectedMenuItems,
        isLoading,
        errorMessage,
        isSuccess,
        bookingId,
        restaurantName,
        errorTimestamp,
        pricePerGuest,
        sumPeople,
        restaurantCategories,
        selectedRestaurantCategoryId,
        isCategoriesLoading,
        restaurantExtras,
        selectedExtraIds,
        isExtrasLoading,
      ];
}
