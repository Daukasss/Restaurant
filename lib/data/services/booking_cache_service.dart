import 'package:hive_flutter/hive_flutter.dart';
import 'package:restauran/data/models/booking_hive_model.dart';

/// Сервис кэширования бронирований через Hive.
/// Ключ box-а = restaurantId, чтобы каждый ресторан хранил свои брони отдельно.
class BookingCacheService {
  static const String _boxPrefix = 'bookings_';

  // ── Внутренний хелпер для meta box ──────────────────
  Future<Box<String>> _getMetaBox(String restaurantId) async {
    final metaBoxName = 'meta_${_boxPrefix}$restaurantId';
    if (Hive.isBoxOpen(metaBoxName)) {
      return Hive.box<String>(metaBoxName);
    }
    return await Hive.openBox<String>(metaBoxName);
  }

  /// Открыть/получить box для конкретного ресторана
  Future<Box<BookingHiveModel>> _getBox(String restaurantId) async {
    final boxName = '$_boxPrefix$restaurantId';
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<BookingHiveModel>(boxName);
    }
    return await Hive.openBox<BookingHiveModel>(boxName);
  }

  /// Сохранить список бронирований в кэш (полная перезапись)
  Future<void> saveBookings(
    String restaurantId,
    List<Map<String, dynamic>> bookings,
  ) async {
    final box = await _getBox(restaurantId);
    await box.clear();

    final models = bookings.map((b) => BookingHiveModel.fromMap(b)).toList();

    final Map<String, BookingHiveModel> entries = {
      for (var m in models)
        m.bookingId.isNotEmpty ? m.bookingId : DateTime.now().toIso8601String():
            m,
    };

    await box.putAll(entries);
  }

  /// Загрузить бронирования из кэша
  Future<List<Map<String, dynamic>>> loadBookings(String restaurantId) async {
    final box = await _getBox(restaurantId);
    return box.values.map((m) => m.toMap()).toList();
  }

  /// Проверить, есть ли кэш для ресторана
  Future<bool> hasCache(String restaurantId) async {
    final box = await _getBox(restaurantId);
    return box.isNotEmpty;
  }

  /// Очистить кэш конкретного ресторана
  Future<void> clearCache(String restaurantId) async {
    final box = await _getBox(restaurantId);
    await box.clear();
  }

  // ── Метка времени ────────────────────────────────────

  /// Дата последнего обновления кэша
  Future<DateTime?> lastUpdated(String restaurantId) async {
    final metaBox = await _getMetaBox(restaurantId);
    final ts = metaBox.get('last_updated');
    if (ts == null) return null;
    return DateTime.tryParse(ts);
  }

  /// Сохранить метку времени последнего обновления
  Future<void> saveLastUpdated(String restaurantId) async {
    final metaBox = await _getMetaBox(restaurantId);
    await metaBox.put('last_updated', DateTime.now().toIso8601String());
  }

  // ── Мета-данные ресторана (sumPeople, pricePerGuest) ─
  // Нужны офлайн для расчёта кол-ва столов в BookingDetailPage

  /// Сохранить мета-данные ресторана
  Future<void> saveRestaurantMeta(
    String restaurantId, {
    double? pricePerGuest,
    int? sumPeople,
  }) async {
    final metaBox = await _getMetaBox(restaurantId);
    if (pricePerGuest != null) {
      await metaBox.put('price_per_guest', pricePerGuest.toString());
    }
    if (sumPeople != null) {
      await metaBox.put('sum_people', sumPeople.toString());
    }
  }

  /// Загрузить мета-данные ресторана
  Future<({double? pricePerGuest, int? sumPeople})> loadRestaurantMeta(
    String restaurantId,
  ) async {
    final metaBox = await _getMetaBox(restaurantId);
    final price = double.tryParse(metaBox.get('price_per_guest') ?? '');
    final people = int.tryParse(metaBox.get('sum_people') ?? '');
    return (pricePerGuest: price, sumPeople: people);
  }
}
