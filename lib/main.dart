import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:restauran/data/models/booking_hive_model.dart';

import 'package:restauran/data/services/abstract/abstract_auth_services.dart';
import 'package:restauran/data/services/background_sync_service.dart';
import 'package:restauran/data/services/booking_service.dart';
import 'package:restauran/data/services/favorite_service.dart';
import 'package:restauran/data/services/profile_service.dart';
import 'package:restauran/data/services/push_notification_service.dart';
import 'package:restauran/data/services/service_locator.dart';
import 'package:restauran/firebase_options.dart';
import 'package:restauran/presentation/pages/auth/pages/register_page/cubit/register_cubit.dart';
import 'package:restauran/presentation/pages/customer/page/profile_page/bloc/profil_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/profile_page/bloc/profil_event.dart';
import 'package:restauran/presentation/pages/seller/page/seller_dashboard/bloc/seller_bloc.dart';
import 'data/services/restaurant_service.dart';
import 'theme/aq_toi.dart';
import 'package:intl/date_symbol_data_local.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Фоновое сообщение: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Hive ──────────────────────────────────────────────────────────────────
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(BookingHiveModelAdapter());
  }

  // ─── Firebase ─────────────────────────────────────────────────────────────
  // Обёрнуто в try/catch — Firebase.initializeApp может упасть офлайн
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Firebase init timeout'),
      );
    } else {
      Firebase.app();
    }
  } catch (e) {
    debugPrint('⚠️ Firebase init error (продолжаем офлайн): $e');
    // Пробуем получить уже существующий инстанс
    try {
      Firebase.app();
    } catch (_) {}
  }

  // Фоновый обработчик — ОБЯЗАТЕЛЬНО до runApp
  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ FirebaseMessaging setup error: $e');
  }

  // ─── DI ───────────────────────────────────────────────────────────────────
  await setupLocator();

  await initializeDateFormatting('ru');

  // ─── Запускаем приложение сразу ───────────────────────────────────────────
  // Push-уведомления и фоновая синхронизация запускаются ПОСЛЕ runApp
  // асинхронно, чтобы не блокировать старт при отсутствии сети.
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => RegisterCubit(
            getIt<AbstractAuthServices>(),
          ),
        ),
        BlocProvider(
          create: (context) => ProfileBloc(
            restaurantService: RestaurantService(),
            profileService: ProfileService(),
            bookingService: BookingService(),
            favoriteService: FavoriteService(),
          )..add(LoadUserData()),
        ),
        BlocProvider(
          create: (context) => SellerBloc(),
        ),
      ],
      child: const AqToi(),
    ),
  );

  // ─── Push-уведомления (не блокируют UI) ───────────────────────────────────
  // Запрос разрешений может зависнуть без сети — изолируем с таймаутом
  _initPushNotifications();

  // ─── Фоновая синхронизация (не блокирует UI) ──────────────────────────────
  _initBackgroundSync();
}

/// Инициализация push-уведомлений с защитой от зависания.
void _initPushNotifications() {
  Future(() async {
    try {
      await PushNotificationService.instance.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⚠️ PushNotificationService timeout — пропускаем');
        },
      );
    } catch (e) {
      debugPrint('⚠️ PushNotificationService error: $e');
    }
  });
}

/// Регистрация фоновой задачи Workmanager с защитой от зависания.
void _initBackgroundSync() {
  Future(() async {
    try {
      await BackgroundSyncService.initialize().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('⚠️ BackgroundSyncService timeout — пропускаем');
        },
      );
    } catch (e) {
      debugPrint('⚠️ BackgroundSyncService error: $e');
    }
  });
}
