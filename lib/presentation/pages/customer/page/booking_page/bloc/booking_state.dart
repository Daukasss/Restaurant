import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../../../../data/models/menu_category.dart';
import '../../../../../../data/models/restaurant_category.dart';
import '../../../../../../data/models/restaurant_extra.dart';
import '../../../../../../data/models/booking.dart';
import '../../../../../../data/models/category_closure.dart';

class TimeSlot {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final bool isAvailable;
  final String? reason;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    this.isAvailable = true,
    this.reason,
  });

  String formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  String get displayText => '${formatTime(startTime)} - ${formatTime(endTime)}';
}

class BookingState extends Equatable {
  final String name;
  final String phone;
  final String guests;
  final String notes;
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final List<DateTime> bookedDates;
  final List<MenuCategory> menuCategories;
  final Map<String, String> selectedMenuItems;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final String? bookingId;
  final String? restaurantName;
  final double? pricePerGuest;
  final int? sumPeople;
  final DateTime? errorTimestamp;
  final List<RestaurantCategory> restaurantCategories;
  final String? selectedRestaurantCategoryId;
  final bool isCategoriesLoading;
  final List<RestaurantExtra> restaurantExtras;
  final List<String> selectedExtraIds;
  final bool isExtrasLoading;
  final List<Booking> existingBookings;
  final List<TimeSlot> availableTimeSlots;

  // ── Seller: управление блокировками ────────────────────────────────────────
  final String? selectedManagementCategoryId;
  final List<CategoryClosure> categoryClosures;
  final bool isClosuresLoading;
  final String? closureSuccessMessage;

  // ── НОВЫЕ ПОЛЯ ─────────────────────────────────────────────────────────────

  /// Недоступные даты для выбранной пользователем категории.
  /// Дата в Set = нельзя бронировать: занята бронью с той же секцией ИЛИ заблокирована.
  /// Сбрасывается при смене категории, загружается через LoadUnavailableDatesForCategoryEvent.
  final Set<DateTime> unavailableDatesForCategory;

  /// Все бронирования для выбранной категории управления (Seller).
  /// Загружается через LoadBookingsForCategoryEvent при SelectManagementCategoryEvent.
  final List<Booking> bookingsForCategory;

  /// Флаг загрузки бронирований для категории
  final bool isBookingsForCategoryLoading;

  /// Флаг загрузки недоступных дат (пока true — открывать календарь нельзя)
  final bool isUnavailableDatesLoading;

  const BookingState(
    this.notes,
    this.selectedDate, {
    this.name = '',
    this.phone = '',
    this.guests = '',
    this.startTime = const TimeOfDay(hour: 12, minute: 0),
    this.endTime = const TimeOfDay(hour: 15, minute: 0),
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
    this.existingBookings = const [],
    this.availableTimeSlots = const [],
    this.selectedManagementCategoryId,
    this.categoryClosures = const [],
    this.isClosuresLoading = false,
    this.closureSuccessMessage,
    this.unavailableDatesForCategory = const {},
    this.bookingsForCategory = const [],
    this.isBookingsForCategoryLoading = false,
    this.isUnavailableDatesLoading = false,
  });

  BookingState copyWith({
    String? name,
    String? phone,
    String? guests,
    String? notes,
    DateTime? selectedDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    List<DateTime>? bookedDates,
    List<MenuCategory>? menuCategories,
    Map<String, String>? selectedMenuItems,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    String? bookingId,
    String? restaurantName,
    DateTime? errorTimestamp,
    double? pricePerGuest,
    int? sumPeople,
    List<RestaurantCategory>? restaurantCategories,
    String? selectedRestaurantCategoryId,
    bool? isCategoriesLoading,
    List<RestaurantExtra>? restaurantExtras,
    List<String>? selectedExtraIds,
    bool? isExtrasLoading,
    List<Booking>? existingBookings,
    List<TimeSlot>? availableTimeSlots,
    String? selectedManagementCategoryId,
    List<CategoryClosure>? categoryClosures,
    bool? isClosuresLoading,
    String? closureSuccessMessage,
    Set<DateTime>? unavailableDatesForCategory,
    List<Booking>? bookingsForCategory,
    bool? isBookingsForCategoryLoading,
    bool? isUnavailableDatesLoading,
    bool clearSelectedManagementCategory = false,
    bool clearClosureSuccessMessage = false,
    bool clearErrorMessage = false,
    bool clearUnavailableDates = false,
  }) {
    return BookingState(
      notes ?? this.notes,
      selectedDate ?? this.selectedDate,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      guests: guests ?? this.guests,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      bookedDates: bookedDates ?? this.bookedDates,
      menuCategories: menuCategories ?? this.menuCategories,
      selectedMenuItems: selectedMenuItems ?? this.selectedMenuItems,
      isLoading: isLoading ?? this.isLoading,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
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
      existingBookings: existingBookings ?? this.existingBookings,
      availableTimeSlots: availableTimeSlots ?? this.availableTimeSlots,
      selectedManagementCategoryId: clearSelectedManagementCategory
          ? null
          : (selectedManagementCategoryId ?? this.selectedManagementCategoryId),
      categoryClosures: categoryClosures ?? this.categoryClosures,
      isClosuresLoading: isClosuresLoading ?? this.isClosuresLoading,
      closureSuccessMessage: clearClosureSuccessMessage
          ? null
          : (closureSuccessMessage ?? this.closureSuccessMessage),
      unavailableDatesForCategory: clearUnavailableDates
          ? const {}
          : (unavailableDatesForCategory ?? this.unavailableDatesForCategory),
      bookingsForCategory: bookingsForCategory ?? this.bookingsForCategory,
      isBookingsForCategoryLoading:
          isBookingsForCategoryLoading ?? this.isBookingsForCategoryLoading,
      isUnavailableDatesLoading:
          isUnavailableDatesLoading ?? this.isUnavailableDatesLoading,
    );
  }

  String calculateBookingPrice() {
    if (guests.isEmpty) return 'Цена не указана';
    final guestCount = int.tryParse(guests) ?? 0;
    if (guestCount <= 0) return 'Цена не указана';

    double total = 0;
    if (selectedRestaurantCategoryId != null) {
      final selectedCategory = restaurantCategories.firstWhere(
        (cat) => cat.id == selectedRestaurantCategoryId,
        orElse: () => restaurantCategories.isNotEmpty
            ? restaurantCategories.first
            : const RestaurantCategory(
                restaurantId: '',
                name: '',
                priceRange: 0,
                globalCategoryId: '',
                section: 1),
      );
      if (selectedCategory.priceRange > 0) {
        total = selectedCategory.priceRange * guestCount;
      }
    } else if (pricePerGuest != null && pricePerGuest! > 0) {
      total = pricePerGuest! * guestCount;
    }

    for (final extraId in selectedExtraIds) {
      final extra = restaurantExtras.firstWhere(
        (e) => e.id == extraId,
        orElse: () =>
            const RestaurantExtra(restaurantId: '', name: '', price: 0),
      );
      total += extra.price;
    }

    if (total <= 0) return 'Цена не указана';
    return total.toStringAsFixed(0);
  }

  bool isTimeRangeValid() {
    final s = startTime.hour * 60 + startTime.minute;
    final e = endTime.hour * 60 + endTime.minute;
    return e > s;
  }

  int? getSelectedCategorySection() {
    if (selectedRestaurantCategoryId == null) return null;
    try {
      return restaurantCategories
          .firstWhere((c) => c.id == selectedRestaurantCategoryId)
          .section;
    } catch (_) {
      return null;
    }
  }

  // ── Seller панель управления ───────────────────────────────────────────────

  Set<DateTime> get datesWithClosures {
    if (selectedManagementCategoryId == null) return {};
    return categoryClosures
        .where((c) => c.categoryId == selectedManagementCategoryId)
        .map((c) => DateTime(c.date.year, c.date.month, c.date.day))
        .toSet();
  }

  Set<DateTime> get datesWithBookings {
    return bookingsForCategory
        .map((b) => DateTime(
            b.bookingDate.year, b.bookingDate.month, b.bookingDate.day))
        .toSet();
  }

  List<CategoryClosure> closuresForDate(DateTime date) {
    return categoryClosures
        .where((c) =>
            c.date.year == date.year &&
            c.date.month == date.month &&
            c.date.day == date.day)
        .toList();
  }

  List<Booking> bookingsForManagementDate(DateTime date) {
    return bookingsForCategory
        .where((b) =>
            b.bookingDate.year == date.year &&
            b.bookingDate.month == date.month &&
            b.bookingDate.day == date.day)
        .toList();
  }

  /// Проверяет: заблокирована ли дата для пользователя (по выбранной категории)
  bool isDateUnavailableForUser(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return unavailableDatesForCategory
        .any((u) => u.year == d.year && u.month == d.month && u.day == d.day);
  }

  @override
  List<Object?> get props => [
        name,
        phone,
        guests,
        notes,
        selectedDate,
        startTime,
        endTime,
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
        existingBookings,
        availableTimeSlots,
        selectedManagementCategoryId,
        categoryClosures,
        isClosuresLoading,
        closureSuccessMessage,
        unavailableDatesForCategory,
        bookingsForCategory,
        isBookingsForCategoryLoading,
        isUnavailableDatesLoading,
      ];
}
