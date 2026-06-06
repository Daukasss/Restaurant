import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:restauran/data/models/booking_hive_model.dart';
import 'package:restauran/data/services/booking_cache_service.dart';
import 'package:restauran/data/services/booking_enrichment_service.dart';
import 'package:restauran/firebase_options.dart';

// Workmanager импортируем только на мобильных платформах
import 'package:workmanager/workmanager.dart'
    if (dart.library.html) 'package:restauran/data/services/workmanager_stub.dart';

const _syncTaskName = 'bookings_background_sync';
const _syncTaskTag = 'bookings_sync';

/// Вызывается Workmanager в фоне (top-level функция — обязательно)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      debugPrint('[BackgroundSync] Задача запущена: $taskName');

      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      await Hive.initFlutter();
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(BookingHiveModelAdapter());
      }

      await BackgroundSyncService._syncAll();

      debugPrint('[BackgroundSync] Синхронизация завершена успешно');
      return true;
    } catch (e, stack) {
      debugPrint('[BackgroundSync] Ошибка: $e\n$stack');
      return false;
    }
  });
}

class BackgroundSyncService {
  /// Инициализировать и зарегистрировать фоновую задачу.
  /// На Web — ничего не делаем (WorkManager не поддерживается).
  static Future<void> initialize() async {
    if (kIsWeb) {
      debugPrint(
          '[BackgroundSyncService] Web — фоновая синхронизация пропущена');
      return;
    }

    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    await Workmanager().registerPeriodicTask(
      _syncTaskName,
      _syncTaskTag,
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 2),
    );

    debugPrint('[BackgroundSyncService] Зарегистрирована фоновая задача '
        '(каждые 15 мин при наличии сети)');
  }

  static Future<void> cancel() async {
    if (kIsWeb) return;
    await Workmanager().cancelByUniqueName(_syncTaskName);
    debugPrint('[BackgroundSyncService] Фоновая задача отменена');
  }

  static Future<void> _syncAll() async {
    final firestore = FirebaseFirestore.instance;
    final cacheService = BookingCacheService();

    final restaurantIds = await _getKnownRestaurantIds();

    if (restaurantIds.isEmpty) {
      debugPrint('[BackgroundSync] Нет ресторанов для синхронизации');
      return;
    }

    for (final restaurantId in restaurantIds) {
      try {
        debugPrint('[BackgroundSync] Синхронизация ресторана: $restaurantId');

        final snapshot = await firestore
            .collection('bookings')
            .where('restaurant_id', isEqualTo: restaurantId)
            .get();

        if (snapshot.docs.isEmpty) continue;

        final rawBookings = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();

        final enriched = await BookingEnrichmentService().enrich(rawBookings);

        await cacheService.saveBookings(restaurantId, enriched);
        await cacheService.saveLastUpdated(restaurantId);

        debugPrint('[BackgroundSync] ✅ Ресторан $restaurantId: '
            '${enriched.length} бронирований обновлено');
      } catch (e) {
        debugPrint('[BackgroundSync] ❌ Ошибка ресторана $restaurantId: $e');
      }
    }
  }

  static Future<List<String>> _getKnownRestaurantIds() async {
    const registryBoxName = 'sync_registry';
    Box<String> registry;

    if (Hive.isBoxOpen(registryBoxName)) {
      registry = Hive.box<String>(registryBoxName);
    } else {
      registry = await Hive.openBox<String>(registryBoxName);
    }

    return registry.values.toSet().toList();
  }

  static Future<void> registerRestaurant(String restaurantId) async {
    const registryBoxName = 'sync_registry';
    Box<String> registry;

    if (Hive.isBoxOpen(registryBoxName)) {
      registry = Hive.box<String>(registryBoxName);
    } else {
      registry = await Hive.openBox<String>(registryBoxName);
    }

    await registry.put(restaurantId, restaurantId);
    debugPrint(
        '[BackgroundSyncService] Зарегистрирован ресторан: $restaurantId');
  }
}
