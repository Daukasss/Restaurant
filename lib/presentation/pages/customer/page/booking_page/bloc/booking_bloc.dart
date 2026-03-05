import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../../../data/models/booking.dart';
import '../../../../../../data/models/category_closure.dart';
import '../../../../../../data/services/abstract/service_export.dart';
import '../../../../../../data/services/abstract/abstract_category_closure_service.dart';
import '../../../../../../data/services/push_notification_service.dart';
import 'booking_event.dart';
import 'booking_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final AbstractBookingService bookingService;
  final AbstractRestaurantService restaurantService;
  final AbstractMenuService menuService;
  final AbstractCategoryClosureService closureService;

  BookingBloc({
    required this.bookingService,
    required this.restaurantService,
    required this.menuService,
    required this.closureService,
  }) : super(BookingState('', DateTime.now())) {
    on<LoadUserInfoEvent>(_onLoadUserInfo);
    on<LoadRestaurantDataEvent>(_onLoadRestaurantData);
    on<LoadRestaurantBookedDatesEvent>(_onLoadRestaurantBookedDates);
    on<LoadRestaurantCategoriesEvent>(_onLoadRestaurantCategories);
    on<SelectRestaurantCategoryEvent>(_onSelectRestaurantCategory);
    on<LoadMenuCategoriesEvent>(_onLoadMenuCategories);
    on<LoadRestaurantExtrasEvent>(_onLoadRestaurantExtras);
    on<ToggleExtraSelectionEvent>(_onToggleExtraSelection);
    on<UpdateDateEvent>(_onUpdateDate);
    on<UpdateStartTimeEvent>(_onUpdateStartTime);
    on<UpdateEndTimeEvent>(_onUpdateEndTime);
    on<UpdateTimeEvent>(_onUpdateTime);
    on<UpdateGuestsEvent>(_onUpdateGuests);
    on<UpdateMenuSelectionEvent>(_onUpdateMenuSelection);
    on<UpdateNameEvent>(_onUpdateName);
    on<UpdatePhoneEvent>(_onUpdatePhone);
    on<SubmitBookingEvent>(_onSubmitBooking);
    on<LoadExistingBookingEvent>(_onLoadExistingBooking);
    on<InitEditBookingEvent>(_onInitEditBooking);
    on<UpdateBookingEvent>(_onUpdateBooking);
    on<LoadExistingBookingsForDateEvent>(_onLoadExistingBookingsForDate);
    on<SelectManagementCategoryEvent>(_onSelectManagementCategory);
    on<LoadCategoryClosuresEvent>(_onLoadCategoryClosures);
    on<CreateCategoryClosureEvent>(_onCreateCategoryClosure);
    on<DeleteCategoryClosureEvent>(_onDeleteCategoryClosure);
    on<LoadBookingsForCategoryEvent>(_onLoadBookingsForCategory);
    on<LoadUnavailableDatesForCategoryEvent>(
        _onLoadUnavailableDatesForCategory);
  }

  // ─── Вспомогательные ─────────────────────────────────────────────────────

  static String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  static String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  TimeOfDay _minutesToTimeOfDay(int minutes) {
    return TimeOfDay(
      hour: (minutes ~/ 60).clamp(0, 23),
      minute: (minutes % 60).clamp(0, 59),
    );
  }

  // ─── Загрузка профиля ────────────────────────────────────────────────────

  Future<void> _onLoadUserInfo(
    LoadUserInfoEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final profileDoc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(currentUser.uid)
          .get();

      if (!profileDoc.exists) return;
      final data = profileDoc.data();
      final role = data?['role'] as String? ?? '';
      if (role != 'user') return;

      String userName = currentUser.displayName ?? '';
      if (userName.isEmpty) userName = data?['name'] as String? ?? '';
      final phone =
          currentUser.phoneNumber ?? (data?['phone'] as String? ?? '');

      emit(state.copyWith(name: userName, phone: phone));
    } catch (e) {
      debugPrint('Ошибка загрузки профиля: $e');
    }
  }

  // ─── Загрузка данных ресторана ───────────────────────────────────────────

  Future<void> _onLoadRestaurantData(
    LoadRestaurantDataEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      final data =
          await restaurantService.getRestaurantData(event.restaurantId);
      emit(state.copyWith(
        isLoading: false,
        restaurantName: data['name'] as String?,
        pricePerGuest: (data['price_per_guest'] as num?)?.toDouble(),
        sumPeople: data['sum_people'] as int?,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка загрузки данных ресторана: $e',
        errorTimestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _onLoadRestaurantBookedDates(
    LoadRestaurantBookedDatesEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      final dates =
          await restaurantService.getRestaurantBookedDates(event.restaurantId);
      emit(state.copyWith(bookedDates: dates));
    } catch (e) {
      debugPrint('Ошибка загрузки занятых дат: $e');
    }
  }

  Future<void> _onLoadRestaurantCategories(
    LoadRestaurantCategoriesEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      final selectedId = state.selectedRestaurantCategoryId;
      final alreadyHasDates = state.unavailableDatesForCategory.isNotEmpty;

      emit(state.copyWith(isCategoriesLoading: true));
      final categories =
          await restaurantService.getRestaurantCategories(event.restaurantId);
      emit(state.copyWith(
        restaurantCategories: categories,
        isCategoriesLoading: false,
      ));

      if (selectedId != null && !alreadyHasDates) {
        try {
          final category = categories.firstWhere((c) => c.id == selectedId);
          add(LoadUnavailableDatesForCategoryEvent(
            restaurantId: event.restaurantId,
            categoryId: selectedId,
            categorySection: category.section,
            excludeBookingId: state.bookingId,
          ));
        } catch (_) {
          try {
            final categoryDoc = await FirebaseFirestore.instance
                .collection('restaurant_categories')
                .doc(selectedId)
                .get();
            if (categoryDoc.exists) {
              final section = (categoryDoc.data()?['section'] as int?) ?? 1;
              add(LoadUnavailableDatesForCategoryEvent(
                restaurantId: event.restaurantId,
                categoryId: selectedId,
                categorySection: section,
                excludeBookingId: state.bookingId,
              ));
            }
          } catch (e2) {
            debugPrint('Ошибка загрузки секции: $e2');
          }
        }
      }
    } catch (e) {
      emit(state.copyWith(
        isCategoriesLoading: false,
        errorMessage: 'Ошибка загрузки категорий: $e',
        errorTimestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _onSelectRestaurantCategory(
    SelectRestaurantCategoryEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(
      selectedRestaurantCategoryId: event.categoryId,
      clearUnavailableDates: true,
    ));

    try {
      final category = state.restaurantCategories
          .firstWhere((c) => c.id == event.categoryId);
      add(LoadUnavailableDatesForCategoryEvent(
        restaurantId: event.restaurantId,
        categoryId: event.categoryId,
        categorySection: category.section,
        excludeBookingId: event.excludeBookingId,
      ));
    } catch (e) {
      try {
        final categoryDoc = await FirebaseFirestore.instance
            .collection('restaurant_categories')
            .doc(event.categoryId)
            .get();
        if (categoryDoc.exists) {
          final section = (categoryDoc.data()?['section'] as int?) ?? 1;
          add(LoadUnavailableDatesForCategoryEvent(
            restaurantId: event.restaurantId,
            categoryId: event.categoryId,
            categorySection: section,
            excludeBookingId: event.excludeBookingId,
          ));
        }
      } catch (e2) {
        debugPrint('Ошибка загрузки секции категории: $e2');
      }
    }
  }

  Future<void> _onLoadMenuCategories(
    LoadMenuCategoriesEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      final menuCategories = await menuService.getMenuCategories(
        event.restaurantId,
        restaurantCategoryId: event.restaurantCategoryId,
      );
      emit(state.copyWith(menuCategories: menuCategories, isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка загрузки меню: $e',
        errorTimestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _onLoadRestaurantExtras(
    LoadRestaurantExtrasEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(state.copyWith(isExtrasLoading: true));
      final extras =
          await restaurantService.getRestaurantExtras(event.restaurantId);
      emit(state.copyWith(restaurantExtras: extras, isExtrasLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isExtrasLoading: false,
        errorMessage: 'Ошибка загрузки дополнительных услуг: $e',
        errorTimestamp: DateTime.now(),
      ));
    }
  }

  // ─── Простые обновления стейта ───────────────────────────────────────────

  void _onToggleExtraSelection(
    ToggleExtraSelectionEvent event,
    Emitter<BookingState> emit,
  ) {
    final extras = List<String>.from(state.selectedExtraIds);
    extras.contains(event.extraId)
        ? extras.remove(event.extraId)
        : extras.add(event.extraId);
    emit(state.copyWith(selectedExtraIds: extras));
  }

  void _onUpdateDate(UpdateDateEvent event, Emitter<BookingState> emit) {
    emit(state.copyWith(selectedDate: event.date));
  }

  void _onUpdateStartTime(
      UpdateStartTimeEvent event, Emitter<BookingState> emit) {
    emit(state.copyWith(startTime: event.startTime));
  }

  void _onUpdateEndTime(UpdateEndTimeEvent event, Emitter<BookingState> emit) {
    emit(state.copyWith(endTime: event.endTime));
  }

  void _onUpdateTime(UpdateTimeEvent event, Emitter<BookingState> emit) {
    emit(state.copyWith(startTime: event.time));
  }

  void _onUpdateGuests(UpdateGuestsEvent event, Emitter<BookingState> emit) {
    emit(state.copyWith(guests: event.guests));
  }

  void _onUpdateMenuSelection(
      UpdateMenuSelectionEvent event, Emitter<BookingState> emit) {
    final updated = Map<String, String>.from(state.selectedMenuItems);
    updated[event.categoryId] = event.menuItemId;
    emit(state.copyWith(selectedMenuItems: updated));
  }

  void _onUpdateName(UpdateNameEvent event, Emitter<BookingState> emit) {
    emit(state.copyWith(name: event.name));
  }

  void _onUpdatePhone(UpdatePhoneEvent event, Emitter<BookingState> emit) {
    emit(state.copyWith(phone: event.phone));
  }

  // ─── Загрузка слотов для даты ────────────────────────────────────────────

  Future<void> _onLoadExistingBookingsForDate(
    LoadExistingBookingsForDateEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      if (event.restaurantId.isEmpty) return;
      final bookings = await bookingService.getBookingsForDate(
        restaurantId: event.restaurantId,
        date: event.date,
      );

      List<CategoryClosure> closures = [];
      if (state.selectedRestaurantCategoryId != null) {
        try {
          final all = await closureService.getClosuresForDate(
            restaurantId: event.restaurantId,
            date: event.date,
          );
          closures = all
              .where((c) => c.categoryId == state.selectedRestaurantCategoryId)
              .toList();
        } catch (_) {}
      }

      final categorySection = state.getSelectedCategorySection();
      final slots = _calculateAvailableSlotsForSection(
        existingBookings: bookings,
        categorySection: categorySection,
        closures: closures,
      );

      emit(state.copyWith(
        existingBookings: bookings,
        availableTimeSlots: slots,
      ));
    } catch (e) {
      debugPrint('Ошибка загрузки бронирований для даты: $e');
    }
  }

  // ─── Создание брони ──────────────────────────────────────────────────────

  Future<void> _onSubmitBooking(
    SubmitBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, clearErrorMessage: true));

      if (event.name.isEmpty || event.phone.isEmpty || event.guests.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Заполните все обязательные поля',
          errorTimestamp: DateTime.now(),
        ));
        return;
      }

      if (event.restaurantCategoryId == null) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Выберите категорию',
          errorTimestamp: DateTime.now(),
        ));
        return;
      }

      final startMin = event.startTime.hour * 60 + event.startTime.minute;
      final endMin = event.endTime.hour * 60 + event.endTime.minute;
      if (endMin <= startMin) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Время окончания должно быть позже времени начала',
          errorTimestamp: DateTime.now(),
        ));
        return;
      }

      final isBlocked = await closureService.isCategoryBlocked(
        restaurantId: event.restaurantId,
        categoryId: event.restaurantCategoryId!,
        date: event.selectedDate,
        startTime: event.startTime,
        endTime: event.endTime,
      );
      if (isBlocked) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage:
              'Выбранное время недоступно для бронирования. Выберите другое время.',
          errorTimestamp: DateTime.now(),
        ));
        return;
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Пользователь не авторизован',
          errorTimestamp: DateTime.now(),
        ));
        return;
      }

      bool isSellerBooking = false;
      try {
        final profileDoc = await FirebaseFirestore.instance
            .collection('profiles')
            .doc(currentUser.uid)
            .get();
        isSellerBooking =
            (profileDoc.data()?['role'] as String? ?? '') == 'seller';
      } catch (e) {
        debugPrint('Ошибка получения роли: $e');
      }

      int? categorySection;
      final category = await restaurantService
          .getRestaurantCategoryById(event.restaurantCategoryId!);
      if (category != null) categorySection = category.section;

      final booking = Booking(
        event.restaurantId,
        userId: currentUser.uid,
        name: event.name,
        phone: event.phone,
        guests: int.parse(event.guests),
        bookingDate: event.selectedDate,
        startTime: event.startTime,
        endTime: event.endTime,
        status: 'pending',
        totalPrice: event.totalPrice,
        menu_selections: event.selectedMenuItems,
        restaurantCategoryId: event.restaurantCategoryId,
        selectedExtraIds: event.selectedExtraIds,
        categorySection: categorySection,
        isSellerBooking: isSellerBooking,
      );

      final result = await bookingService.createBooking(booking);

      emit(state.copyWith(
        isLoading: false,
        isSuccess: true,
        bookingId: result['id'] as String?,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        errorTimestamp: DateTime.now(),
      ));
    }
  }

  // ─── Загрузка / инициализация редактирования ─────────────────────────────

  void _onLoadExistingBooking(
    LoadExistingBookingEvent event,
    Emitter<BookingState> emit,
  ) {
    emit(state.copyWith(
      name: event.booking.name,
      phone: event.booking.phone,
      guests: event.booking.guests.toString(),
      selectedDate: event.booking.bookingDate,
      startTime: event.booking.startTime,
      endTime: event.booking.endTime,
      selectedMenuItems: event.booking.menu_selections,
      selectedRestaurantCategoryId: event.booking.restaurantCategoryId,
      selectedExtraIds: event.booking.selectedExtraIds ?? [],
      bookingId: event.booking.id,
    ));
  }

  Future<void> _onInitEditBooking(
    InitEditBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true));
      add(LoadRestaurantDataEvent(event.restaurantId));
      add(LoadRestaurantCategoriesEvent(event.restaurantId));
      add(LoadRestaurantExtrasEvent(event.restaurantId));
      add(LoadRestaurantBookedDatesEvent(event.restaurantId));
      add(LoadExistingBookingEvent(event.booking));
      if (event.booking.restaurantCategoryId != null) {
        add(LoadMenuCategoriesEvent(
          event.restaurantId,
          restaurantCategoryId: event.booking.restaurantCategoryId,
        ));
        add(SelectRestaurantCategoryEvent(
          event.booking.restaurantCategoryId!,
          restaurantId: event.restaurantId,
          excludeBookingId:
              event.booking.id, // исключаем текущую бронь из проверки дат
        ));
      }
      emit(state.copyWith(isLoading: false));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка инициализации редактирования: $e',
        errorTimestamp: DateTime.now(),
      ));
    }
  }

  // ─── Обновление брони ────────────────────────────────────────────────────

  Future<void> _onUpdateBooking(
    UpdateBookingEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoading: true, clearErrorMessage: true));

      if (event.name.isEmpty || event.phone.isEmpty || event.guests.isEmpty) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Заполните все обязательные поля',
          errorTimestamp: DateTime.now(),
        ));
        return;
      }

      if (event.restaurantCategoryId == null) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Выберите категорию',
          errorTimestamp: DateTime.now(),
        ));
        return;
      }

      final startMin = event.startTime.hour * 60 + event.startTime.minute;
      final endMin = event.endTime.hour * 60 + event.endTime.minute;
      if (endMin <= startMin) {
        emit(state.copyWith(
          isLoading: false,
          errorMessage: 'Время окончания должно быть позже времени начала',
          errorTimestamp: DateTime.now(),
        ));
        return;
      }

      await bookingService.updateBooking(
        bookingId: event.bookingId,
        name: event.name,
        phone: event.phone,
        guests: int.parse(event.guests),
        date: event.selectedDate,
        startTime: event.startTime,
        endTime: event.endTime,
        restaurantId: event.restaurantId,
        menuItems: event.selectedMenuItems,
        restaurantCategoryId: event.restaurantCategoryId!,
        selectedExtraIds: event.selectedExtraIds,
        totalPrice: event.totalPrice,
      );

      // ── Пуш селлеру об изменении (игнорируется если бронь ручная) ─────────

      // ─────────────────────────────────────────────────────────────────────

      emit(state.copyWith(isLoading: false, isSuccess: true));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
        errorTimestamp: DateTime.now(),
      ));
    }
  }

  // ─── Блокировки (Seller) ─────────────────────────────────────────────────

  Future<void> _onSelectManagementCategory(
    SelectManagementCategoryEvent event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(
      selectedManagementCategoryId: event.categoryId,
      categoryClosures: const [],
      bookingsForCategory: const [],
    ));
    add(LoadCategoryClosuresEvent(
      restaurantId: event.restaurantId,
      categoryId: event.categoryId,
    ));
    add(LoadBookingsForCategoryEvent(
      restaurantId: event.restaurantId,
      categoryId: event.categoryId,
    ));
  }

  Future<void> _onLoadCategoryClosures(
    LoadCategoryClosuresEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(state.copyWith(isClosuresLoading: true));
      final closures = await closureService.getClosuresForCategory(
        restaurantId: event.restaurantId,
        categoryId: event.categoryId,
      );
      emit(state.copyWith(
        categoryClosures: closures,
        isClosuresLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isClosuresLoading: false,
        errorMessage: 'Ошибка загрузки блокировок: $e',
        errorTimestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _onCreateCategoryClosure(
    CreateCategoryClosureEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(state.copyWith(isClosuresLoading: true));

      final newClosure = CategoryClosure(
        restaurantId: event.restaurantId,
        categoryId: event.categoryId,
        categoryName: event.categoryName,
        date: DateTime(event.date.year, event.date.month, event.date.day),
        startTime: event.startTime,
        endTime: event.endTime,
        reason: event.reason,
      );

      await closureService.createClosure(newClosure);

      final updated = await closureService.getClosuresForCategory(
        restaurantId: event.restaurantId,
        categoryId: event.categoryId,
      );

      emit(state.copyWith(
        categoryClosures: updated,
        isClosuresLoading: false,
        closureSuccessMessage: 'Блокировка успешно создана',
      ));
    } catch (e) {
      emit(state.copyWith(
        isClosuresLoading: false,
        errorMessage: 'Ошибка создания блокировки: $e',
        errorTimestamp: DateTime.now(),
      ));
    }
  }

  Future<void> _onDeleteCategoryClosure(
    DeleteCategoryClosureEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(state.copyWith(isClosuresLoading: true));
      await closureService.deleteClosure(event.closureId);

      final updated = await closureService.getClosuresForCategory(
        restaurantId: event.restaurantId,
        categoryId: event.categoryId,
      );

      emit(state.copyWith(
        categoryClosures: updated,
        isClosuresLoading: false,
        closureSuccessMessage: 'Блокировка удалена',
      ));
    } catch (e) {
      emit(state.copyWith(
        isClosuresLoading: false,
        errorMessage: 'Ошибка удаления блокировки: $e',
        errorTimestamp: DateTime.now(),
      ));
    }
  }

  // ─── Бронирования для категории (Seller) ─────────────────────────────────

  Future<void> _onLoadBookingsForCategory(
    LoadBookingsForCategoryEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(state.copyWith(isBookingsForCategoryLoading: true));

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('restaurant_id', isEqualTo: event.restaurantId)
          .where('restaurant_category_id', isEqualTo: event.categoryId)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('booking_date', descending: false)
          .get();

      final bookings = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return Booking.fromJson(data);
      }).toList();

      emit(state.copyWith(
        bookingsForCategory: bookings,
        isBookingsForCategoryLoading: false,
      ));
    } catch (e) {
      debugPrint('Ошибка загрузки бронирований для категории: $e');
      emit(state.copyWith(isBookingsForCategoryLoading: false));
    }
  }

  // ─── Недоступные даты для юзера ──────────────────────────────────────────

  Future<void> _onLoadUnavailableDatesForCategory(
    LoadUnavailableDatesForCategoryEvent event,
    Emitter<BookingState> emit,
  ) async {
    try {
      emit(state.copyWith(isUnavailableDatesLoading: true));
      final Set<DateTime> unavailable = {};
      final now = DateTime.now();
      final startOfRange = DateTime(now.year, now.month, now.day);
      final future = startOfRange.add(const Duration(days: 365));

      // Нормализуем excludeBookingId — пустая строка приравнивается к null
      final effectiveExcludeId =
          (event.excludeBookingId != null && event.excludeBookingId!.isNotEmpty)
              ? event.excludeBookingId
              : null;

      // 1. Брони с той же секцией
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('restaurant_id', isEqualTo: event.restaurantId)
          .where('booking_date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfRange))
          .where('booking_date', isLessThan: Timestamp.fromDate(future))
          .where('status', whereIn: ['pending', 'confirmed']).get();

      for (final doc in bookingsSnapshot.docs) {
        // Пропускаем текущую бронь пользователя при редактировании
        if (effectiveExcludeId != null && doc.id == effectiveExcludeId) {
          continue;
        }
        final data = doc.data();
        final section = data['category_section'] as int?;
        if (section == event.categorySection && data['booking_date'] != null) {
          final date = (data['booking_date'] as Timestamp).toDate();
          unavailable.add(DateTime(date.year, date.month, date.day));
        }
      }

      // 2. ID всех категорий той же секции
      final sameSectionIds = <String>{event.categoryId};
      try {
        final catSnapshot = await FirebaseFirestore.instance
            .collection('restaurant_categories')
            .where('restaurant_id', isEqualTo: event.restaurantId)
            .where('section', isEqualTo: event.categorySection)
            .where('is_active', isEqualTo: true)
            .get();
        for (final doc in catSnapshot.docs) {
          sameSectionIds.add(doc.id);
        }
      } catch (e) {
        debugPrint('Ошибка загрузки категорий по секции: $e');
        for (final cat in state.restaurantCategories) {
          if (cat.section == event.categorySection && cat.id != null) {
            sameSectionIds.add(cat.id!);
          }
        }
      }

      // 3. Блокировки той же секции
      final allClosures =
          await closureService.getAllClosures(event.restaurantId);
      for (final closure in allClosures) {
        if (sameSectionIds.contains(closure.categoryId)) {
          final d =
              DateTime(closure.date.year, closure.date.month, closure.date.day);
          if (!d.isBefore(startOfRange) && d.isBefore(future)) {
            unavailable.add(d);
          }
        }
      }

      emit(state.copyWith(
        unavailableDatesForCategory: unavailable,
        isUnavailableDatesLoading: false,
      ));
    } catch (e) {
      debugPrint('Ошибка загрузки недоступных дат: $e');
      emit(state.copyWith(isUnavailableDatesLoading: false));
    }
  }

  // ─── Расчёт доступных временных слотов ──────────────────────────────────

  List<TimeSlot> _calculateAvailableSlotsForSection({
    required List<Booking> existingBookings,
    required int? categorySection,
    required List<dynamic> closures,
  }) {
    final List<({int start, int end, String reason})> busy = [];

    for (final b in existingBookings) {
      final buffStart = (b.startTimeInMinutes - 60).clamp(0, 24 * 60);
      final buffEnd = (b.endTimeInMinutes + 60).clamp(0, 24 * 60);
      busy.add((
        start: buffStart,
        end: buffEnd,
        reason: b.categorySection != null
            ? 'Раздел ${b.categorySection}'
            : 'Занято',
      ));
    }

    for (final c in closures) {
      if (c is CategoryClosure) {
        final buffEnd = (c.endTimeInMinutes + 60).clamp(0, 24 * 60);
        busy.add((
          start: c.startTimeInMinutes,
          end: buffEnd,
          reason: 'Закрыто',
        ));
      }
    }

    if (busy.isEmpty) {
      return [
        const TimeSlot(
          startTime: TimeOfDay(hour: 0, minute: 0),
          endTime: TimeOfDay(hour: 23, minute: 59),
          isAvailable: true,
        ),
      ];
    }

    busy.sort((a, b) => a.start.compareTo(b.start));

    final merged = <({int start, int end, String reason})>[];
    var cur = busy.first;
    for (int i = 1; i < busy.length; i++) {
      final next = busy[i];
      if (next.start <= cur.end) {
        cur = (
          start: cur.start,
          end: next.end > cur.end ? next.end : cur.end,
          reason: cur.reason,
        );
      } else {
        merged.add(cur);
        cur = next;
      }
    }
    merged.add(cur);

    final slots = <TimeSlot>[];
    int cursor = 0;

    for (final interval in merged) {
      if (interval.start > cursor) {
        slots.add(TimeSlot(
          startTime: _minutesToTimeOfDay(cursor),
          endTime: _minutesToTimeOfDay(interval.start),
          isAvailable: true,
        ));
      }
      slots.add(TimeSlot(
        startTime: _minutesToTimeOfDay(interval.start),
        endTime: _minutesToTimeOfDay(interval.end.clamp(0, 24 * 60 - 1)),
        isAvailable: false,
        reason: interval.reason,
      ));
      cursor = interval.end;
    }

    if (cursor < 24 * 60 - 1) {
      slots.add(TimeSlot(
        startTime: _minutesToTimeOfDay(cursor),
        endTime: const TimeOfDay(hour: 23, minute: 59),
        isAvailable: true,
      ));
    }

    return slots;
  }
}
