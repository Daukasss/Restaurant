// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../data/models/booking.dart';
import '../../../../../../data/services/booking_service.dart';
import '../../../../../../data/services/menu_service.dart';
import '../../../../../../data/services/profile_service.dart';
import '../../../../../../data/services/restaurant_service.dart';
import '../../../../../../theme/aq_toi.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final BookingService _bookingService;
  final RestaurantService _restaurantService;
  final ProfileService _profileService;
  final MenuService _menuService;

  BookingBloc({
    BookingService? bookingService,
    RestaurantService? restaurantService,
    ProfileService? profileService,
    MenuService? menuService,
  })  : _bookingService = bookingService ?? BookingService(),
        _restaurantService = restaurantService ?? RestaurantService(),
        _profileService = profileService ?? ProfileService(),
        _menuService = menuService ?? MenuService(),
        super(BookingState(
          '', // notes
          DateTime.now().add(const Duration(days: 1)), // selectedDate
        )) {
    on<LoadUserInfoEvent>(_onLoadUserInfo);
    on<LoadRestaurantBookedDatesEvent>(_onLoadRestaurantBookedDates);
    on<LoadMenuCategoriesEvent>(_onLoadMenuCategories);
    on<LoadRestaurantDataEvent>(_onLoadRestaurantData);
    on<LoadRestaurantCategoriesEvent>(_onLoadRestaurantCategories);
    on<SelectRestaurantCategoryEvent>(_onSelectRestaurantCategory);
    on<UpdateDateEvent>(_onUpdateDate);
    on<UpdateTimeEvent>(_onUpdateTime);
    on<UpdateGuestsEvent>(_onUpdateGuests);
    on<UpdateMenuSelectionEvent>(_onUpdateMenuSelection);
    on<SubmitBookingEvent>(_onSubmitBooking);
    on<UpdateNameEvent>(_onUpdateName);
    on<UpdatePhoneEvent>(_onUpdatePhone);
    on<LoadRestaurantExtrasEvent>(_onLoadRestaurantExtras);
    on<ToggleExtraSelectionEvent>(_onToggleExtraSelection);

    on<InitEditBookingEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true, errorTimestamp: DateTime.now()));

      try {
        final nameController = TextEditingController();
        final phoneController = TextEditingController();

        await _profileService.loadUserInfo(
          nameController,
          phoneController,
        );

        final bookedDates =
            await _restaurantService.getBookedDates(event.restaurantId);

        final restaurantCategories = await _restaurantService
            .getRestaurantCategories(event.restaurantId);

        final categories =
            await _menuService.getMenuCategories(event.restaurantId);

        final extras =
            await _restaurantService.getRestaurantExtras(event.restaurantId);

        final booking = event.booking;

        emit(state.copyWith(
            isLoading: false,
            name: booking.name,
            phone: booking.phone,
            guests: booking.guests.toString(),
            selectedDate: booking.bookingTime,
            selectedTime: TimeOfDay.fromDateTime(booking.bookingTime),
            bookedDates: bookedDates,
            menuCategories: categories,
            selectedMenuItems: Map<int, int>.from(booking.menu_selections),
            restaurantCategories: restaurantCategories,
            // FIXED: No need to parse - already an int?
            selectedRestaurantCategoryId: booking.restaurantCategoryId,
            restaurantExtras: extras,
            selectedExtraIds: booking.selectedExtraIds ?? [],
            errorTimestamp: DateTime.now()));

        nameController.dispose();
        phoneController.dispose();
      } catch (error) {
        emit(state.copyWith(
            isLoading: false,
            errorMessage: 'Ошибка загрузки данных!',
            errorTimestamp: DateTime.now()));
      }
    });

    on<LoadExistingBookingEvent>((event, emit) {
      final booking = event.booking;

      emit(state.copyWith(
          name: booking.name,
          phone: booking.phone,
          guests: booking.guests.toString(),
          selectedDate: booking.bookingTime,
          selectedTime: TimeOfDay.fromDateTime(booking.bookingTime),
          selectedMenuItems: Map<int, int>.from(booking.menu_selections),
          // FIXED: No need to parse - already an int?
          selectedRestaurantCategoryId: booking.restaurantCategoryId,
          selectedExtraIds: booking.selectedExtraIds ?? [],
          errorTimestamp: DateTime.now()));
    });

    on<UpdateBookingEvent>((event, emit) async {
      emit(state.copyWith(
          isLoading: true, errorMessage: null, errorTimestamp: DateTime.now()));

      try {
        await _bookingService.updateBooking(
          bookingId: event.bookingId,
          name: event.name,
          phone: event.phone,
          guests: int.parse(event.guests),
          date: DateTime(
            event.selectedDate.year,
            event.selectedDate.month,
            event.selectedDate.day,
            event.selectedTime.hour,
            event.selectedTime.minute,
          ),
          restaurantId: event.restaurantId,
          restaurantCategoryId: event.restaurantCategoryId!,
          menuItems: event.selectedMenuItems,
          selectedExtraIds: event.selectedExtraIds,
        );

        emit(state.copyWith(
            isLoading: false,
            isSuccess: true,
            bookingId: event.bookingId,
            errorTimestamp: DateTime.now()));
      } catch (e) {
        emit(state.copyWith(
            isLoading: false,
            errorMessage: 'Ошибка при обновлении брони: ${e.toString()}',
            errorTimestamp: DateTime.now()));
      }
    });
  }

  Future<void> _onLoadRestaurantExtras(
    LoadRestaurantExtrasEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(isExtrasLoading: true, errorTimestamp: DateTime.now()));

    try {
      final extras =
          await _restaurantService.getRestaurantExtras(event.restaurantId);

      emit(state.copyWith(
        restaurantExtras: extras,
        isExtrasLoading: false,
        errorTimestamp: DateTime.now(),
      ));
    } catch (error) {
      emit(state.copyWith(
        isExtrasLoading: false,
        errorMessage: 'Ошибка загрузки дополнительных опций',
        errorTimestamp: DateTime.now(),
      ));
    }
  }

  void _onToggleExtraSelection(
    ToggleExtraSelectionEvent event,
    Emitter<BookingState> emit,
  ) {
    final List<int> updatedExtras = List.from(state.selectedExtraIds);

    if (updatedExtras.contains(event.extraId)) {
      updatedExtras.remove(event.extraId);
    } else {
      updatedExtras.add(event.extraId);
    }

    emit(state.copyWith(
      selectedExtraIds: updatedExtras,
      errorMessage: null,
      errorTimestamp: DateTime.now(),
    ));
  }

  Future<void> _onLoadRestaurantCategories(
    LoadRestaurantCategoriesEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(
        isCategoriesLoading: true, errorTimestamp: DateTime.now()));

    try {
      final categories =
          await _restaurantService.getRestaurantCategories(event.restaurantId);

      final selectedCategoryId = state.selectedRestaurantCategoryId ??
          (categories.isNotEmpty ? categories.first.id : null);

      emit(state.copyWith(
        restaurantCategories: categories,
        isCategoriesLoading: false,
        selectedRestaurantCategoryId: selectedCategoryId,
        errorTimestamp: DateTime.now(),
      ));

      if (selectedCategoryId != null) {
        add(LoadMenuCategoriesEvent(
          event.restaurantId,
          restaurantCategoryId: selectedCategoryId,
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        isCategoriesLoading: false,
        errorMessage: 'Ошибка загрузки категорий ресторана',
        errorTimestamp: DateTime.now(),
      ));
    }
  }

  void _onSelectRestaurantCategory(
    SelectRestaurantCategoryEvent event,
    Emitter<BookingState> emit,
  ) {
    emit(state.copyWith(
      selectedRestaurantCategoryId: event.categoryId,
      errorMessage: null,
      errorTimestamp: DateTime.now(),
    ));

    add(LoadMenuCategoriesEvent(
      state.restaurantCategories.first.restaurantId,
      restaurantCategoryId: event.categoryId,
    ));
  }

  Future<void> _onLoadUserInfo(
    LoadUserInfoEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      final nameController = TextEditingController();
      final phoneController = TextEditingController();

      await _profileService.loadUserInfo(
        nameController,
        phoneController,
      );

      emit(state.copyWith(
          name: nameController.text,
          phone: phoneController.text,
          errorTimestamp: DateTime.now()));

      nameController.dispose();
      phoneController.dispose();
    } catch (error) {
      emit(state.copyWith(
          errorMessage: 'Ошибка загрузки данных пользователя',
          errorTimestamp: DateTime.now()));
    }
  }

  Future<void> _onLoadRestaurantBookedDates(
    LoadRestaurantBookedDatesEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorTimestamp: DateTime.now()));
    try {
      final bookedDates =
          await _restaurantService.getBookedDates(event.restaurantId);

      emit(state.copyWith(
          bookedDates: bookedDates,
          isLoading: false,
          errorTimestamp: DateTime.now()));
    } catch (error) {
      emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Ошибка загрузки данных!',
          errorTimestamp: DateTime.now()));
    }
  }

  Future<void> _onLoadMenuCategories(
    LoadMenuCategoriesEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      final categories = event.restaurantCategoryId != null
          ? await _menuService.getMenuCategoriesByRestaurantCategory(
              event.restaurantId,
              event.restaurantCategoryId!,
            )
          : await _menuService.getMenuCategories(event.restaurantId);

      final currentSelections = Map<int, int>.from(state.selectedMenuItems);

      final Map<int, int> initialSelections = {};
      for (var category in categories) {
        if (currentSelections.containsKey(category.id)) {
          initialSelections[category.id] = currentSelections[category.id]!;
        } else if (category.menuItems.length == 1) {
          initialSelections[category.id] = category.menuItems[0].id!;
        }
      }

      emit(state.copyWith(
          menuCategories: categories,
          selectedMenuItems: initialSelections,
          errorTimestamp: DateTime.now()));
    } catch (error) {
      emit(state.copyWith(
          errorMessage: 'Ошибка загрузки данных!',
          errorTimestamp: DateTime.now()));
    }
  }

  Future<void> _onLoadRestaurantData(
    LoadRestaurantDataEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      final restaurantData =
          await _restaurantService.getRestaurantData(event.restaurantId);

      emit(state.copyWith(
        pricePerGuest: restaurantData['pricePerGuest'],
        sumPeople: restaurantData['sumPeople'],
        errorTimestamp: DateTime.now(),
      ));
    } catch (error) {
      emit(state.copyWith(
        errorMessage: 'Ошибка загрузки данных ресторана',
        errorTimestamp: DateTime.now(),
      ));
    }
  }

  void _onUpdateDate(UpdateDateEvent event, Emitter<BookingState> emit) {
    emit(state.copyWith(
        selectedDate: event.date,
        errorMessage: null,
        errorTimestamp: DateTime.now()));
  }

  void _onUpdateTime(UpdateTimeEvent event, Emitter<BookingState> emit) {
    emit(state.copyWith(
        selectedTime: event.time,
        errorMessage: null,
        errorTimestamp: DateTime.now()));
  }

  void _onUpdateGuests(UpdateGuestsEvent event, Emitter<BookingState> emit) {
    emit(state.copyWith(
        guests: event.guests,
        errorMessage: null,
        errorTimestamp: DateTime.now()));
  }

  void _onUpdateName(UpdateNameEvent event, Emitter<BookingState> emit) {
    emit(state.copyWith(
        name: event.name, errorMessage: null, errorTimestamp: DateTime.now()));
  }

  void _onUpdatePhone(UpdatePhoneEvent event, Emitter<BookingState> emit) {
    emit(state.copyWith(
        phone: event.phone,
        errorMessage: null,
        errorTimestamp: DateTime.now()));
  }

  void _onUpdateMenuSelection(
    UpdateMenuSelectionEvent event,
    Emitter<BookingState> emit,
  ) {
    final categoryId = event.categoryId;
    final menuItemId = event.menuItemId;
    final category = state.menuCategories.firstWhere((c) => c.id == categoryId);
    final Map<int, int> updatedSelections = Map.from(state.selectedMenuItems);

    final isSelected = state.selectedMenuItems[categoryId] == menuItemId;

    if (isSelected) {
      if (!category.requiresSelection) {
        updatedSelections.remove(categoryId);
      }
    } else {
      updatedSelections[categoryId] = menuItemId;
    }

    emit(state.copyWith(
        selectedMenuItems: updatedSelections,
        errorMessage: null,
        errorTimestamp: DateTime.now()));
  }

  bool _isDateBooked(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return state.bookedDates.any((bookedDate) =>
        bookedDate.year == dateOnly.year &&
        bookedDate.month == dateOnly.month &&
        bookedDate.day == dateOnly.day);
  }

  bool _validateMenuSelections() {
    for (var category in state.menuCategories) {
      if (category.requiresSelection) {
        if (!state.selectedMenuItems.containsKey(category.id)) {
          return false;
        }
      }
    }
    return true;
  }

  Future<void> _onSubmitBooking(
    SubmitBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(errorMessage: null, errorTimestamp: DateTime.now()));

    print(
        '[v0] Submitting booking with restaurantCategoryId: ${event.restaurantCategoryId}');
    print(
        '[v0] State selectedRestaurantCategoryId: ${state.selectedRestaurantCategoryId}');
    print('[v0] Selected extras: ${event.selectedExtraIds}');

    if (event.name.isEmpty || event.phone.isEmpty || event.guests.isEmpty) {
      emit(state.copyWith(
        errorMessage: 'Пожалуйста, заполните все обязательные поля!',
        errorTimestamp: DateTime.now(),
      ));
      return;
    }

    if (event.restaurantCategoryId == null) {
      emit(state.copyWith(
        errorMessage: 'Пожалуйста, выберите категорию ресторана!',
        errorTimestamp: DateTime.now(),
      ));
      return;
    }

    if (_isDateBooked(event.selectedDate)) {
      emit(state.copyWith(
        errorMessage:
            'Выбранная дата уже занята. Пожалуйста, выберите другую дату.',
        errorTimestamp: DateTime.now(),
      ));
      return;
    }

    if (!_validateMenuSelections()) {
      final missingCategory = state.menuCategories.firstWhere(
        (category) =>
            category.requiresSelection &&
            !state.selectedMenuItems.containsKey(category.id),
      );

      emit(state.copyWith(
        errorMessage:
            'Пожалуйста, выберите хотя бы одно блюдо из категории ${missingCategory.name}.',
        errorTimestamp: DateTime.now(),
      ));
      return;
    }

    emit(state.copyWith(isLoading: true, errorTimestamp: DateTime.now()));

    try {
      final bookingDateTime = DateTime(
        event.selectedDate.year,
        event.selectedDate.month,
        event.selectedDate.day,
        event.selectedTime.hour,
        event.selectedTime.minute,
      );

      final booking = Booking(
        event.restaurantId,
        userId: supabase.auth.currentUser?.id,
        name: event.name,
        phone: event.phone,
        guests: int.parse(event.guests),
        bookingTime: bookingDateTime,
        status: '',
        menu_selections: event.selectedMenuItems,
        // FIXED: Keep as int, don't convert to string
        restaurantCategoryId: event.restaurantCategoryId,
        selectedExtraIds: event.selectedExtraIds,
      );

      print('[v0] Creating booking with data: ${booking.toJson()}');
      print('[v0] Selected extras being saved: ${booking.selectedExtraIds}');

      final response = await _bookingService.createBooking(booking);

      print('[v0] Booking created successfully with ID: ${response['id']}');

      await _restaurantService.updateRestaurantBookedDates(
        event.restaurantId,
        event.selectedDate,
      );

      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        bookingId: response['id'],
        restaurantName: event.restaurantName,
        errorTimestamp: DateTime.now(),
      ));
    } catch (error) {
      print('[v0] Error creating booking: $error');
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка создания бронирования!',
        errorTimestamp: DateTime.now(),
      ));
    }
  }
}
