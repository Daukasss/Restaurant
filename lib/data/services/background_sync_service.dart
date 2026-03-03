import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'package:restauran/data/models/booking_hive_model.dart';
import 'package:restauran/data/services/booking_cache_service.dart';
import 'package:restauran/firebase_options.dart';

const _syncTaskName = 'bookings_background_sync';
const _syncTaskTag = 'bookings_sync';

/// Вызывается Workmanager в фоне (top-level функция — обязательно)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      debugPrint('[BackgroundSync] Задача запущена: $taskName');

      // Инициализируем Firebase если не инициализирован
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      // Инициализируем Hive
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

/// Сервис фоновой синхронизации бронирований.
/// Регистрирует периодическую задачу через Workmanager.
class BackgroundSyncService {
  /// Инициализировать и зарегистрировать фоновую задачу.
  /// Вызывать один раз в main() после Hive.initFlutter().
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: kDebugMode,
    );

    await Workmanager().registerPeriodicTask(
      _syncTaskName,
      _syncTaskTag,
      // Минимальный интервал для Workmanager — 15 минут
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        // Синхронизируем только при наличии сети
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 2),
    );

    debugPrint('[BackgroundSyncService] Зарегистрирована фоновая задача '
        '(каждые 15 мин при наличии сети)');
  }

  /// Отменить фоновую задачу (например, при выходе из аккаунта)
  static Future<void> cancel() async {
    await Workmanager().cancelByUniqueName(_syncTaskName);
    debugPrint('[BackgroundSyncService] Фоновая задача отменена');
  }

  /// Немедленная синхронизация всех ресторанов из Hive.
  /// Читает restaurantId из всех открытых box-ов и обновляет данные.
  static Future<void> _syncAll() async {
    final firestore = FirebaseFirestore.instance;
    final cacheService = BookingCacheService();

    // Получаем список restaurantId из метаданных Hive
    final restaurantIds = await _getKnownRestaurantIds();

    if (restaurantIds.isEmpty) {
      debugPrint('[BackgroundSync] Нет ресторанов для синхронизации');
      return;
    }

    for (final restaurantId in restaurantIds) {
      try {
        debugPrint('[BackgroundSync] Синхронизация ресторана: $restaurantId');

        // Загружаем брони из Firestore
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

        // Обогащаем данные
        final enriched = await _enrichBookings(firestore, rawBookings);

        // Сохраняем в кэш
        await cacheService.saveBookings(restaurantId, enriched);
        await cacheService.saveLastUpdated(restaurantId);

        debugPrint('[BackgroundSync] ✅ Ресторан $restaurantId: '
            '${enriched.length} бронирований обновлено');
      } catch (e) {
        debugPrint('[BackgroundSync] ❌ Ошибка ресторана $restaurantId: $e');
      }
    }
  }

  /// Обогащает список бронирований данными из Firestore:
  /// категория зала, extras, блюда — для офлайн-доступа
  static Future<List<Map<String, dynamic>>> _enrichBookings(
    FirebaseFirestore firestore,
    List<Map<String, dynamic>> bookings,
  ) async {
    final enriched = <Map<String, dynamic>>[];

    for (final booking in bookings) {
      final map = Map<String, dynamic>.from(booking);

      // 1. Название категории зала
      final categoryId = map['restaurant_category_id']?.toString();
      if (categoryId != null && categoryId.isNotEmpty) {
        try {
          final doc = await firestore
              .collection('restaurant_categories')
              .doc(categoryId)
              .get();
          map['_category_name'] = doc.data()?['name']?.toString() ?? '';
        } catch (_) {
          map['_category_name'] = '';
        }
      }

      // 2. Названия доп. опций
      final extrasIds = map['selected_extras'];
      if (extrasIds is List && extrasIds.isNotEmpty) {
        final names = <String>[];
        for (final id in extrasIds) {
          try {
            final doc = await firestore
                .collection('restaurant_extras')
                .doc(id.toString())
                .get();
            if (doc.exists) {
              names.add(doc.data()?['name']?.toString() ?? '');
            }
          } catch (_) {}
        }
        map['_extras_names'] = names;
      } else {
        map['_extras_names'] = <String>[];
      }

      // 3. Выбранные блюда (menu_selections: {categoryId: itemId})
      final menuSelections = map['menu_selections'];
      if (menuSelections is Map && menuSelections.isNotEmpty) {
        final menuItems = <Map<String, String>>[];
        for (final entry in menuSelections.entries) {
          try {
            final categoryDoc = await firestore
                .collection('menu_categories')
                .doc(entry.key.toString())
                .get();
            final categoryName =
                categoryDoc.data()?['name']?.toString() ?? '—';

            final itemDoc = await firestore
                .collection('menu_items')
                .doc(entry.value.toString())
                .get();
            final itemName = itemDoc.data()?['name']?.toString() ?? '—';

            menuItems.add({'category': categoryName, 'item': itemName});
          } catch (_) {}
        }
        map['_menu_items'] = menuItems;
      } else {
        map['_menu_items'] = <Map<String, String>>[];
      }

      enriched.add(map);
    }

    return enriched;
  }

  /// Читает список всех известных restaurantId из meta box-ов Hive
  static Future<List<String>> _getKnownRestaurantIds() async {
    // Открываем registry box где храним список ресторанов
    const registryBoxName = 'sync_registry';
    Box<String> registry;

    if (Hive.isBoxOpen(registryBoxName)) {
      registry = Hive.box<String>(registryBoxName);
    } else {
      registry = await Hive.openBox<String>(registryBoxName);
    }

    return registry.values.toSet().toList();
  }

  /// Регистрирует restaurantId в registry (вызывается при первой загрузке)
  static Future<void> registerRestaurant(String restaurantId) async {
    const registryBoxName = 'sync_registry';
    Box<String> registry;

    if (Hive.isBoxOpen(registryBoxName)) {
      registry = Hive.box<String>(registryBoxName);
    } else {
      registry = await Hive.openBox<String>(registryBoxName);
    }

    // Ключ = restaurantId, значение = restaurantId
    await registry.put(restaurantId, restaurantId);
    debugPrint('[BackgroundSyncService] Зарегистрирован ресторан: $restaurantId');
  }
}