import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:restauran/data/services/abstract/service_export.dart';
import 'package:restauran/data/services/background_sync_service.dart';
import 'package:restauran/data/services/booking_cache_service.dart';
import 'package:restauran/data/services/connectivity_service.dart';
import 'package:restauran/data/services/service_locator.dart';

import 'booking_managment_bloc_event.dart';
import 'booking_managment_bloc_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final _restaurantService = getIt<AbstractRestaurantService>();
  final _bookingService = getIt<AbstractBookingService>();
  final _menuService = getIt<AbstractMenuService>();
  final _cacheService = BookingCacheService();
  final _connectivityService = ConnectivityService();

  StreamSubscription<bool>? _connectivitySub;
  String? _currentRestaurantId;

  BookingBloc() : super(BookingInitial()) {
    on<LoadBookings>(_onLoadBookings);
    on<UpdateBookingStatus>(_onUpdateBookingStatus);
    on<FilterBookings>(_onFilterBookings);
    on<FilterBookingsByDate>(_onFilterBookingsByDate);
    on<ConnectivityChanged>(_onConnectivityChanged);

    _connectivitySub =
        _connectivityService.onConnectivityChanged.listen((isOnline) {
      add(ConnectivityChanged(isOnline));
    });
  }

  // ────────────────────────────────────────────────
  //              Загрузка бронирований
  // ────────────────────────────────────────────────
  Future<void> _onLoadBookings(
    LoadBookings event,
    Emitter<BookingState> emit,
  ) async {
    _currentRestaurantId = event.restaurantId;
    emit(BookingLoading());

    await BackgroundSyncService.registerRestaurant(event.restaurantId);

    final isOnline = await _connectivityService.checkNow();
    if (isOnline) {
      await _loadFromNetwork(event.restaurantId, emit);
    } else {
      await _loadFromCache(event.restaurantId, emit);
    }
  }

  Future<void> _loadFromNetwork(
    String restaurantId,
    Emitter<BookingState> emit,
  ) async {
    try {
      final restaurantData =
          await _restaurantService.getRestaurantData(restaurantId);

      final pricePerGuest = restaurantData['pricePerGuest'] as double?;
      final sumPeople = restaurantData['sumPeople'] as int?;

      // ✅ Сохраняем sumPeople и pricePerGuest в Hive — нужны офлайн
      await _cacheService.saveRestaurantMeta(
        restaurantId,
        pricePerGuest: pricePerGuest,
        sumPeople: sumPeople,
      );

      var bookings = await _bookingService.getBookings(restaurantId);
      bookings = _updateBookingStatusesByTime(bookings);
      bookings.sort(_compareBookingsByDateAndTime);
      bookings = await _enrichBookings(bookings);

      await _cacheService.saveBookings(restaurantId, bookings);
      await _cacheService.saveLastUpdated(restaurantId);

      emit(BookingLoaded(
        bookings: bookings,
        filteredBookings: bookings,
        pricePerGuest: pricePerGuest,
        sumPeople: sumPeople,
        activeFilter: 'all',
        isOffline: false,
        cacheTime: DateTime.now(),
      ));
    } catch (error, stack) {
      debugPrint('Ошибка загрузки из сети: $error\n$stack');
      final hasCached = await _cacheService.hasCache(restaurantId);
      if (hasCached) {
        await _loadFromCache(restaurantId, emit);
      } else {
        emit(const BookingError('Не удалось загрузить бронирования'));
      }
    }
  }

  Future<void> _loadFromCache(
    String restaurantId,
    Emitter<BookingState> emit,
  ) async {
    final hasCached = await _cacheService.hasCache(restaurantId);
    if (!hasCached) {
      emit(BookingOfflineEmpty());
      return;
    }

    final cached = await _cacheService.loadBookings(restaurantId);
    final cacheTime = await _cacheService.lastUpdated(restaurantId);

    // ✅ Читаем сохранённые мета-данные ресторана из Hive
    final meta = await _cacheService.loadRestaurantMeta(restaurantId);

    var bookings = _updateBookingStatusesByTime(cached);
    bookings.sort(_compareBookingsByDateAndTime);

    debugPrint('[BookingBloc] Кэш: ${bookings.length} бронирований, '
        'sumPeople=${meta.sumPeople}, pricePerGuest=${meta.pricePerGuest}');

    emit(BookingLoaded(
      bookings: bookings,
      filteredBookings: bookings,
      pricePerGuest: meta.pricePerGuest, // ✅ теперь не null
      sumPeople: meta.sumPeople, // ✅ теперь не null
      activeFilter: 'all',
      isOffline: true,
      cacheTime: cacheTime,
    ));
  }

  // ── Обогащение данных ─────────────────────────────────

  Future<List<Map<String, dynamic>>> _enrichBookings(
    List<Map<String, dynamic>> bookings,
  ) async {
    final enriched = <Map<String, dynamic>>[];

    for (final booking in bookings) {
      final map = Map<String, dynamic>.from(booking);

      // 1. Название категории зала
      final categoryId = map['restaurant_category_id']?.toString();
      if (categoryId != null && categoryId.isNotEmpty) {
        try {
          final category =
              await _restaurantService.getRestaurantCategoryById(categoryId);
          map['_category_name'] = category?.name ?? '';
        } catch (_) {
          map['_category_name'] = '';
        }
      } else {
        map['_category_name'] = '';
      }

      // 2. Названия доп. опций
      final extrasIds = map['selected_extras'];
      if (extrasIds is List && extrasIds.isNotEmpty) {
        try {
          map['_extras_names'] = await _fetchExtrasNames(extrasIds);
        } catch (_) {
          map['_extras_names'] = <String>[];
        }
      } else {
        map['_extras_names'] = <String>[];
      }

      // 3. Выбранные блюда
      if (map['menu_selections'] != null) {
        try {
          final items = await _menuService.fetchMenuSelections(map);
          map['_menu_items'] = items
              .map((i) => {
                    'category': (i['category'] ?? '—').toString(),
                    'item': (i['item'] ?? '—').toString(),
                  })
              .toList();
        } catch (_) {
          map['_menu_items'] = <Map<String, String>>[];
        }
      } else {
        map['_menu_items'] = <Map<String, String>>[];
      }

      enriched.add(map);
    }

    return enriched;
  }

  Future<List<String>> _fetchExtrasNames(List<dynamic> ids) async {
    final firestore = FirebaseFirestore.instance;
    final names = <String>[];
    for (final id in ids) {
      try {
        final doc = await firestore
            .collection('restaurant_extras')
            .doc(id.toString())
            .get();
        if (doc.exists) names.add(doc.data()?['name']?.toString() ?? '');
      } catch (_) {}
    }
    return names;
  }

  // ── Обновление статуса ────────────────────────────────

  Future<void> _onUpdateBookingStatus(
    UpdateBookingStatus event,
    Emitter<BookingState> emit,
  ) async {
    final isOnline = await _connectivityService.checkNow();
    if (!isOnline) {
      emit(const BookingError(
        'Нет интернета. Изменение статуса недоступно офлайн.',
        isNetworkError: true,
      ));
      if (_currentRestaurantId != null) {
        await _loadFromCache(_currentRestaurantId!, emit);
      }
      return;
    }

    try {
      await _bookingService.updateBookingStatus(
          event.bookingId, event.newStatus);
      emit(BookingStatusUpdated());
      final restaurantId =
          await _bookingService.getRestaurantIdFromBooking(event.bookingId);
      add(LoadBookings(restaurantId.toString()));
    } catch (error, stack) {
      debugPrint('Ошибка обновления статуса: $error\n$stack');
      emit(const BookingError('Не удалось обновить статус брони'));
    }
  }

  // ── Фильтрация ────────────────────────────────────────

  void _onFilterBookings(FilterBookings event, Emitter<BookingState> emit) {
    if (state is! BookingLoaded) return;
    final current = state as BookingLoaded;
    emit(current.copyWith(
      filteredBookings: _applyFilters(
        bookings: current.bookings,
        statusFilter: event.filter,
        dateFilter: current.selectedDate,
      ),
      activeFilter: event.filter,
    ));
  }

  void _onFilterBookingsByDate(
      FilterBookingsByDate event, Emitter<BookingState> emit) {
    if (state is! BookingLoaded) return;
    final current = state as BookingLoaded;
    emit(current.copyWith(
      filteredBookings: _applyFilters(
        bookings: current.bookings,
        statusFilter: current.activeFilter ?? 'all',
        dateFilter: event.date,
      ),
      selectedDate: event.date,
      clearDate: event.date == null,
    ));
  }

  // ── Реакция на сеть ───────────────────────────────────

  Future<void> _onConnectivityChanged(
      ConnectivityChanged event, Emitter<BookingState> emit) async {
    if (_currentRestaurantId == null) return;
    if (event.isOnline) {
      debugPrint('[BookingBloc] ONLINE → обновляем из сети');
      await _loadFromNetwork(_currentRestaurantId!, emit);
    } else {
      debugPrint('[BookingBloc] OFFLINE → кэш');
      if (state is BookingLoaded) {
        emit((state as BookingLoaded).copyWith(isOffline: true));
      } else {
        await _loadFromCache(_currentRestaurantId!, emit);
      }
    }
  }

  // ── Вспомогательные ──────────────────────────────────

  List<Map<String, dynamic>> _applyFilters({
    required List<Map<String, dynamic>> bookings,
    required String statusFilter,
    DateTime? dateFilter,
  }) {
    var result = List.of(bookings);
    if (statusFilter != 'all') {
      result = result
          .where((b) =>
              (b['status'] as String?)?.toLowerCase() ==
              statusFilter.toLowerCase())
          .toList();
    }
    if (dateFilter != null) {
      result = result.where((b) {
        final d = _parseBookingDateTime(b);
        return d.year == dateFilter.year &&
            d.month == dateFilter.month &&
            d.day == dateFilter.day;
      }).toList();
    }
    return result;
  }

  int _compareBookingsByDateAndTime(
      Map<String, dynamic> a, Map<String, dynamic> b) {
    final now = DateTime.now();
    final dA = _parseBookingDateTime(a);
    final dB = _parseBookingDateTime(b);
    final aF = dA.isAfter(now);
    final bF = dB.isAfter(now);
    if (aF && bF) return dA.compareTo(dB);
    if (!aF && !bF) return dB.compareTo(dA);
    return aF ? -1 : 1;
  }

  DateTime _parseBookingDateTime(Map<String, dynamic> booking) {
    try {
      DateTime date;
      final rawDate = booking['booking_date'];
      if (rawDate is Timestamp) {
        date = rawDate.toDate();
      } else if (rawDate is String) {
        date = DateTime.parse(rawDate);
      } else if (rawDate is DateTime) {
        date = rawDate;
      } else {
        return DateTime(2100);
      }
      final parts = (booking['start_time'] as String? ?? '00:00').split(':');
      return DateTime(date.year, date.month, date.day,
          int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
    } catch (_) {
      return DateTime(2100);
    }
  }

  List<Map<String, dynamic>> _updateBookingStatusesByTime(
      List<Map<String, dynamic>> bookings) {
    final now = DateTime.now();
    return bookings.map((b) {
      final u = Map<String, dynamic>.from(b);
      if ((u['status'] as String?)?.toLowerCase() == 'cancelled') return u;
      u['status'] =
          _parseBookingDateTime(b).isBefore(now) ? 'completed' : 'pending';
      return u;
    }).toList();
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    _connectivityService.dispose();
    return super.close();
  }
}
