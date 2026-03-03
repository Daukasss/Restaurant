import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../../../data/models/booking.dart';
import '../../../../../../data/models/category_closure.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();
  @override
  List<Object?> get props => [];
}

class LoadUserInfoEvent extends BookingEvent {}

class LoadRestaurantDataEvent extends BookingEvent {
  final String restaurantId;
  const LoadRestaurantDataEvent(this.restaurantId);
  @override
  List<Object?> get props => [restaurantId];
}

class LoadRestaurantBookedDatesEvent extends BookingEvent {
  final String restaurantId;
  const LoadRestaurantBookedDatesEvent(this.restaurantId);
  @override
  List<Object?> get props => [restaurantId];
}

class LoadRestaurantCategoriesEvent extends BookingEvent {
  final String restaurantId;
  const LoadRestaurantCategoriesEvent(this.restaurantId);
  @override
  List<Object?> get props => [restaurantId];
}

/// ИЗМЕНЕНО: добавлен restaurantId чтобы сразу загрузить недоступные даты
class SelectRestaurantCategoryEvent extends BookingEvent {
  final String categoryId;
  final String restaurantId;
  const SelectRestaurantCategoryEvent(this.categoryId,
      {required this.restaurantId});
  @override
  List<Object?> get props => [categoryId, restaurantId];
}

class LoadMenuCategoriesEvent extends BookingEvent {
  final String restaurantId;
  final String? restaurantCategoryId;
  const LoadMenuCategoriesEvent(this.restaurantId, {this.restaurantCategoryId});
  @override
  List<Object?> get props => [restaurantId, restaurantCategoryId];
}

class LoadRestaurantExtrasEvent extends BookingEvent {
  final String restaurantId;
  const LoadRestaurantExtrasEvent(this.restaurantId);
  @override
  List<Object?> get props => [restaurantId];
}

class ToggleExtraSelectionEvent extends BookingEvent {
  final String extraId;
  const ToggleExtraSelectionEvent(this.extraId);
  @override
  List<Object?> get props => [extraId];
}

class UpdateDateEvent extends BookingEvent {
  final DateTime date;
  const UpdateDateEvent(this.date);
  @override
  List<Object?> get props => [date];
}

class UpdateStartTimeEvent extends BookingEvent {
  final TimeOfDay startTime;
  const UpdateStartTimeEvent(this.startTime);
  @override
  List<Object?> get props => [startTime];
}

class UpdateEndTimeEvent extends BookingEvent {
  final TimeOfDay endTime;
  const UpdateEndTimeEvent(this.endTime);
  @override
  List<Object?> get props => [endTime];
}

class UpdateTimeEvent extends BookingEvent {
  final TimeOfDay time;
  const UpdateTimeEvent(this.time);
  @override
  List<Object?> get props => [time];
}

class UpdateGuestsEvent extends BookingEvent {
  final String guests;
  const UpdateGuestsEvent(this.guests);
  @override
  List<Object?> get props => [guests];
}

class UpdateMenuSelectionEvent extends BookingEvent {
  final String categoryId;
  final String menuItemId;
  const UpdateMenuSelectionEvent(this.categoryId, this.menuItemId);
  @override
  List<Object?> get props => [categoryId, menuItemId];
}

class UpdateNameEvent extends BookingEvent {
  final String name;
  const UpdateNameEvent(this.name);
  @override
  List<Object?> get props => [name];
}

class UpdatePhoneEvent extends BookingEvent {
  final String phone;
  const UpdatePhoneEvent(this.phone);
  @override
  List<Object?> get props => [phone];
}

class LoadExistingBookingsForDateEvent extends BookingEvent {
  final DateTime date;
  final String restaurantId;
  const LoadExistingBookingsForDateEvent(this.date, this.restaurantId);
  @override
  List<Object?> get props => [date, restaurantId];
}

class SubmitBookingEvent extends BookingEvent {
  final String name;
  final String phone;
  final String guests;
  final String notes;
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String restaurantId;
  final String restaurantName;
  final Map<String, String> selectedMenuItems;
  final String? restaurantCategoryId;
  final List<String> selectedExtraIds;
  final int? totalPrice;

  const SubmitBookingEvent({
    required this.name,
    required this.phone,
    required this.guests,
    required this.notes,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.restaurantId,
    required this.restaurantName,
    required this.selectedMenuItems,
    required this.totalPrice,
    this.restaurantCategoryId,
    this.selectedExtraIds = const [],
  });

  @override
  List<Object?> get props => [
        name,
        phone,
        guests,
        notes,
        selectedDate,
        startTime,
        endTime,
        restaurantId,
        restaurantName,
        selectedMenuItems,
        restaurantCategoryId,
        selectedExtraIds,
      ];
}

class LoadExistingBookingEvent extends BookingEvent {
  final Booking booking;
  const LoadExistingBookingEvent(this.booking);
}

class InitEditBookingEvent extends BookingEvent {
  final Booking booking;
  final String restaurantId;
  const InitEditBookingEvent(this.booking, this.restaurantId);
  @override
  List<Object?> get props => [booking, restaurantId];
}

class UpdateBookingEvent extends BookingEvent {
  final String? bookingId;
  final String name;
  final String phone;
  final String guests;
  final DateTime selectedDate;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String restaurantId;
  final String restaurantName;
  final Map<String, String> selectedMenuItems;
  final String? restaurantCategoryId;
  final List<String> selectedExtraIds;
  final int? totalPrice;

  const UpdateBookingEvent({
    required this.bookingId,
    required this.name,
    required this.phone,
    required this.guests,
    required this.selectedDate,
    required this.startTime,
    required this.endTime,
    required this.restaurantId,
    required this.restaurantName,
    required this.selectedMenuItems,
    required this.totalPrice,
    this.restaurantCategoryId,
    this.selectedExtraIds = const [],
  });

  @override
  List<Object?> get props => [
        bookingId,
        name,
        phone,
        guests,
        selectedDate,
        startTime,
        endTime,
        restaurantId,
        restaurantName,
        selectedMenuItems,
        restaurantCategoryId,
        selectedExtraIds,
      ];
}

// ─── СОБЫТИЯ ДЛЯ БЛОКИРОВОК (Seller) ─────────────────────────────────────────

class LoadCategoryClosuresEvent extends BookingEvent {
  final String restaurantId;
  final String categoryId;
  const LoadCategoryClosuresEvent({
    required this.restaurantId,
    required this.categoryId,
  });
  @override
  List<Object?> get props => [restaurantId, categoryId];
}

class CreateCategoryClosureEvent extends BookingEvent {
  final String restaurantId;
  final String categoryId;
  final String categoryName;
  final DateTime date;
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final String? reason;

  const CreateCategoryClosureEvent({
    required this.restaurantId,
    required this.categoryId,
    required this.categoryName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.reason,
  });

  @override
  List<Object?> get props => [
        restaurantId,
        categoryId,
        categoryName,
        date,
        startTime,
        endTime,
        reason,
      ];
}

class DeleteCategoryClosureEvent extends BookingEvent {
  final String closureId;
  final String restaurantId;
  final String categoryId;

  const DeleteCategoryClosureEvent({
    required this.closureId,
    required this.restaurantId,
    required this.categoryId,
  });

  @override
  List<Object?> get props => [closureId, restaurantId, categoryId];
}

/// ИЗМЕНЕНО: добавлен restaurantId для загрузки броней
class SelectManagementCategoryEvent extends BookingEvent {
  final String categoryId;
  final String restaurantId;
  const SelectManagementCategoryEvent(this.categoryId,
      {required this.restaurantId});
  @override
  List<Object?> get props => [categoryId, restaurantId];
}

/// НОВОЕ: Загрузить бронирования для категории (Seller видит их в календаре)
class LoadBookingsForCategoryEvent extends BookingEvent {
  final String restaurantId;
  final String categoryId;
  const LoadBookingsForCategoryEvent({
    required this.restaurantId,
    required this.categoryId,
  });
  @override
  List<Object?> get props => [restaurantId, categoryId];
}

/// НОВОЕ: Вычислить недоступные даты для пользователя по выбранной категории.
/// Дата недоступна если: есть бронь с той же секцией ИЛИ есть блокировка.
class LoadUnavailableDatesForCategoryEvent extends BookingEvent {
  final String restaurantId;
  final String categoryId;
  final int categorySection;

  const LoadUnavailableDatesForCategoryEvent({
    required this.restaurantId,
    required this.categoryId,
    required this.categorySection,
  });

  @override
  List<Object?> get props => [restaurantId, categoryId, categorySection];
}
