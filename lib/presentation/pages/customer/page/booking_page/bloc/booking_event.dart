import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../../../../data/models/booking.dart';

abstract class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserInfoEvent extends BookingEvent {}

class LoadRestaurantDataEvent extends BookingEvent {
  final int restaurantId;

  const LoadRestaurantDataEvent(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

class LoadRestaurantBookedDatesEvent extends BookingEvent {
  final int restaurantId;

  const LoadRestaurantBookedDatesEvent(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

class LoadRestaurantCategoriesEvent extends BookingEvent {
  final int restaurantId;

  const LoadRestaurantCategoriesEvent(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

class SelectRestaurantCategoryEvent extends BookingEvent {
  final int categoryId;

  const SelectRestaurantCategoryEvent(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class LoadMenuCategoriesEvent extends BookingEvent {
  final int restaurantId;
  final int? restaurantCategoryId;

  const LoadMenuCategoriesEvent(this.restaurantId, {this.restaurantCategoryId});

  @override
  List<Object?> get props => [restaurantId, restaurantCategoryId];
}

class LoadRestaurantExtrasEvent extends BookingEvent {
  final int restaurantId;

  const LoadRestaurantExtrasEvent(this.restaurantId);

  @override
  List<Object?> get props => [restaurantId];
}

class ToggleExtraSelectionEvent extends BookingEvent {
  final int extraId;

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
  final int categoryId;
  final int menuItemId;

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

class SubmitBookingEvent extends BookingEvent {
  final String name;
  final String phone;
  final String guests;
  final String notes;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final int restaurantId;
  final String restaurantName;
  final Map<int, int> selectedMenuItems;
  final int? restaurantCategoryId;
  final List<int> selectedExtraIds;

  const SubmitBookingEvent({
    required this.name,
    required this.phone,
    required this.guests,
    required this.notes,
    required this.selectedDate,
    required this.selectedTime,
    required this.restaurantId,
    required this.restaurantName,
    required this.selectedMenuItems,
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
        selectedTime,
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
  final int restaurantId;

  const InitEditBookingEvent(this.booking, this.restaurantId);

  @override
  List<Object?> get props => [booking, restaurantId];
}

class UpdateBookingEvent extends BookingEvent {
  final int bookingId;
  final String name;
  final String phone;
  final String guests;
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final int restaurantId;
  final String restaurantName;
  final Map<int, int> selectedMenuItems;
  final int? restaurantCategoryId;
  final List<int> selectedExtraIds;

  const UpdateBookingEvent({
    required this.bookingId,
    required this.name,
    required this.phone,
    required this.guests,
    required this.selectedDate,
    required this.selectedTime,
    required this.restaurantId,
    required this.restaurantName,
    required this.selectedMenuItems,
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
        selectedTime,
        restaurantId,
        restaurantName,
        selectedMenuItems,
        restaurantCategoryId,
        selectedExtraIds,
      ];
}
