import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:restauran/data/services/abstract/service_export.dart';
import 'package:restauran/data/services/background_sync_service.dart';
import 'package:restauran/data/services/booking_cache_service.dart';
import 'package:restauran/data/services/booking_enrichment_service.dart';
import 'package:restauran/data/services/connectivity_service.dart';
import 'package:restauran/data/services/service_locator.dart';

import 'booking_managment_bloc_event.dart';
import 'booking_managment_bloc_state.dart';

class BookingBloc extends Bloc<BookingEvent, BookingState> {
  final _restaurantService = getIt<AbstractRestaurantService>();
  final _bookingService = getIt<AbstractBookingService>();
  final _cacheService = BookingCacheService();
  final _connectivityService = ConnectivityService();
  final _enrichmentService = BookingEnrichmentService();

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
      final results = await Future.wait([
        _restaurantService.getRestaurantData(restaurantId),
        _bookingService.getBookings(restaurantId),
      ]);

      final restaurantData = results[0] as Map<String, dynamic>;
      var bookings = results[1] as List<Map<String, dynamic>>;

      final pricePerGuest = restaurantData['pricePerGuest'] as double?;
      final sumPeople = restaurantData['sumPeople'] as int?;

      await _cacheService.saveRestaurantMeta(
        restaurantId,
        pricePerGuest: pricePerGuest,
        sumPeople: sumPeople,
      );

      bookings = _updateBookingStatusesByTime(bookings);
      bookings.sort(_compareBookingsByDateAndTime);

      // ✅ Обогащаем ДО сохранения в кэш
      bookings = await _enrichmentService.enrich(bookings);

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
      debugPrint('[BookingBloc] Ошибка загрузки из сети: $error\n$stack');
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

    // ✅ Загружаем все данные из кэша параллельно
    final cacheResults = await Future.wait([
      _cacheService.loadBookings(restaurantId),
      _cacheService.lastUpdated(restaurantId),
      _cacheService.loadRestaurantMeta(restaurantId),
    ]);

    final cached = cacheResults[0] as List<Map<String, dynamic>>;
    final cacheTime = cacheResults[1] as DateTime?;
    final meta = cacheResults[2] as dynamic;

    var bookings = _updateBookingStatusesByTime(cached);
    bookings.sort(_compareBookingsByDateAndTime);

    debugPrint('[BookingBloc] Кэш: ${bookings.length} бронирований, '
        'sumPeople=${meta.sumPeople}, pricePerGuest=${meta.pricePerGuest}');

    emit(BookingLoaded(
      bookings: bookings,
      filteredBookings: bookings,
      pricePerGuest: meta.pricePerGuest,
      sumPeople: meta.sumPeople,
      activeFilter: 'all',
      isOffline: true,
      cacheTime: cacheTime,
    ));
  }

  // ── Обновление статуса ────────────────────────────────────────────────

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
      debugPrint('[BookingBloc] Ошибка обновления статуса: $error\n$stack');
      emit(const BookingError('Не удалось обновить статус брони'));
    }
  }

  // ── Фильтрация ────────────────────────────────────────────────────────

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

  // ── Реакция на изменение сети ─────────────────────────────────────────

  Future<void> _onConnectivityChanged(
      ConnectivityChanged event, Emitter<BookingState> emit) async {
    if (_currentRestaurantId == null) return;
    if (event.isOnline) {
      debugPrint('[BookingBloc] ONLINE → обновляем из сети');
      await _loadFromNetwork(_currentRestaurantId!, emit);
    } else {
      debugPrint('[BookingBloc] OFFLINE → переключаемся на кэш');
      if (state is BookingLoaded) {
        emit((state as BookingLoaded).copyWith(isOffline: true));
      } else {
        await _loadFromCache(_currentRestaurantId!, emit);
      }
    }
  }

  // ── Вспомогательные ──────────────────────────────────────────────────

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
    final aFuture = dA.isAfter(now);
    final bFuture = dB.isAfter(now);
    if (aFuture && bFuture) return dA.compareTo(dB);
    if (!aFuture && !bFuture) return dB.compareTo(dA);
    return aFuture ? -1 : 1;
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
      return DateTime(
        date.year,
        date.month,
        date.day,
        int.tryParse(parts[0]) ?? 0,
        int.tryParse(parts[1]) ?? 0,
      );
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
