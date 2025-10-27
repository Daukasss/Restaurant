// ignore_for_file: avoid_print

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SupabaseNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final SupabaseClient supabase = Supabase.instance.client;
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static RealtimeChannel? _notificationsChannel;
  static RealtimeChannel? _bookingsChannel;
  static RealtimeChannel? _restaurantsChannel;

  // Улучшенная система дедупликации
  static final Map<String, DateTime> _processedNotifications = {};
  static const Duration _deduplicationWindow = Duration(minutes: 5);

  // Централизованная очередь уведомлений
  static final List<NotificationRequest> _notificationQueue = [];
  static bool _isProcessingQueue = false;

  // Таймер для очистки
  static Timer? _cleanupTimer;

  /// Создает уникальный ключ для дедупликации
  static String _createDeduplicationKey({
    required String type,
    required String userId,
    String? bookingId,
    String? restaurantId,
    String? title,
    String? body,
  }) {
    final content = '$type:$userId:$bookingId:$restaurantId:$title:$body';
    final bytes = utf8.encode(content);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Проверяет, было ли уведомление уже обработано
  static bool _isDuplicate(String key) {
    final now = DateTime.now();

    // Очищаем старые записи
    _processedNotifications.removeWhere(
        (k, timestamp) => now.difference(timestamp) > _deduplicationWindow);

    if (_processedNotifications.containsKey(key)) {
      return true;
    }

    _processedNotifications[key] = now;
    return false;
  }

  /// Централизованная отправка уведомлений с дедупликацией
  static Future<void> sendNotificationSafely({
    required String type,
    required String userId,
    required String title,
    required String body,
    String? bookingId,
    String? restaurantId,
    Map<String, dynamic>? data,
    bool useDatabase = true,
    bool useFCM = true,
    bool useLocal = true,
  }) async {
    final deduplicationKey = _createDeduplicationKey(
      type: type,
      userId: userId,
      bookingId: bookingId,
      restaurantId: restaurantId,
      title: title,
      body: body,
    );

    if (_isDuplicate(deduplicationKey)) {
      return;
    }

    final request = NotificationRequest(
      type: type,
      userId: userId,
      title: title,
      body: body,
      bookingId: bookingId,
      restaurantId: restaurantId,
      data: data,
      useDatabase: useDatabase,
      useFCM: useFCM,
      useLocal: useLocal,
      deduplicationKey: deduplicationKey,
    );

    _notificationQueue.add(request);
    _processNotificationQueue();
  }

  /// Обрабатывает очередь уведомлений
  static Future<void> _processNotificationQueue() async {
    if (_isProcessingQueue || _notificationQueue.isEmpty) return;

    _isProcessingQueue = true;

    try {
      while (_notificationQueue.isNotEmpty) {
        final request = _notificationQueue.removeAt(0);
        await _processNotificationRequest(request);

        // Небольшая задержка между уведомлениями
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// Обрабатывает отдельный запрос уведомления
  static Future<void> _processNotificationRequest(
      NotificationRequest request) async {
    try {
      // 1. Сохраняем в базу данных (если нужно)
      if (request.useDatabase) {
        await _createDatabaseNotification(request);
      }

      // 2. Отправляем через FCM (если нужно)
      if (request.useFCM) {
        await _sendFCMNotification(request);
      }

      // 3. Показываем локальное уведомление (если нужно и пользователь текущий)
      if (request.useLocal && _isCurrentUser(request.userId)) {
        await _showLocalNotificationSafe(request);
      }
    } catch (e) {
      print('Error processing notification: $e');
    }
  }

  /// Проверяет, является ли пользователь текущим
  static bool _isCurrentUser(String userId) {
    return supabase.auth.currentUser?.id == userId;
  }

  /// Создает запись в базе данных
  static Future<void> _createDatabaseNotification(
      NotificationRequest request) async {
    try {
      final notificationData = <String, dynamic>{
        'user_id': request.userId,
        'title': request.title,
        'body': request.body,
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
        'data': request.data,
        'deduplication_key': request.deduplicationKey,
      };

      if (request.restaurantId != null) {
        notificationData['restaurant_id'] = int.tryParse(request.restaurantId!);
      }

      if (request.bookingId != null) {
        notificationData['booking_id'] = int.tryParse(request.bookingId!);
      }

      await supabase.from('notifications').insert(notificationData);
    } catch (e) {
      print('Error creating database notification: $e');
    }
  }

  /// Отправляет FCM уведомление
  static Future<void> _sendFCMNotification(NotificationRequest request) async {
    try {
      final tokenResponse = await supabase
          .from('profiles')
          .select('fcm_token')
          .eq('id', request.userId)
          .single();

      final fcmToken = tokenResponse['fcm_token'];
      if (fcmToken == null) return;

      await supabase.functions.invoke(
        'send-fcm-v1-notification',
        body: {
          'fcm_token': fcmToken,
          'title': request.title,
          'body': request.body,
          'data': {
            'deduplication_key': request.deduplicationKey,
            if (request.restaurantId != null)
              'restaurant_id': request.restaurantId,
            if (request.bookingId != null) 'booking_id': request.bookingId,
            ...?request.data,
          },
        },
      );
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }

  /// Показывает локальное уведомление с проверкой дедупликации
  static Future<void> _showLocalNotificationSafe(
      NotificationRequest request) async {
    try {
      final channelId = _getChannelId(request.type);

      AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        channelId,
        _getChannelName(channelId),
        channelDescription: _getChannelDescription(channelId),
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/icon_toi',
        color: _getChannelColor(channelId),
        playSound: true,
        enableVibration: true,
        tag: request.deduplicationKey,
      );

      const DarwinNotificationDetails iOSDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      );

      final NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
        iOS: iOSDetails,
      );

      final notificationId = request.deduplicationKey.hashCode.abs() % 100000;

      await _localNotifications.show(
        notificationId,
        request.title,
        request.body,
        platformChannelSpecifics,
        payload: jsonEncode({
          'type': request.type,
          'booking_id': request.bookingId,
          'restaurant_id': request.restaurantId,
          'deduplication_key': request.deduplicationKey,
          ...?request.data,
        }),
      );
    } catch (e) {
      print('Error showing local notification: $e');
    }
  }

  // Вспомогательные методы для каналов
  static String _getChannelId(String type) {
    switch (type) {
      case 'new_booking':
        return 'new_booking';
      case 'booking_updated':
        return 'booking_updated';
      default:
        return 'restaurant_notifications';
    }
  }

  static String _getChannelName(String channelId) {
    switch (channelId) {
      case 'new_booking':
        return 'Новые бронирования';
      case 'booking_updated':
        return 'Изменения бронирований';
      default:
        return 'Уведомления ресторана';
    }
  }

  static String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'new_booking':
        return 'Уведомления о новых бронированиях';
      case 'booking_updated':
        return 'Уведомления об изменениях в бронированиях';
      default:
        return 'Уведомления о бронированиях и изменениях в ресторане';
    }
  }

  static Color _getChannelColor(String channelId) {
    switch (channelId) {
      case 'new_booking':
        return const Color(0xFF4CAF50);
      case 'booking_updated':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF2196F3);
    }
  }

  /// Обработчик фоновых сообщений с дедупликацией
  static Future<void> handleBackgroundMessage(RemoteMessage message) async {
    try {
      final deduplicationKey = message.data['deduplication_key'];
      if (deduplicationKey != null && _isDuplicate(deduplicationKey)) {
        print('Duplicate background message blocked: $deduplicationKey');
        return;
      }

      final title = message.notification?.title ?? message.data['title'];
      final body = message.notification?.body ?? message.data['body'];

      if (title == null || body == null) return;

      await _showBackgroundNotification(title, body, message.data);
    } catch (e) {
      print('Error handling background message: $e');
    }
  }

  static Future<void> _showBackgroundNotification(
      String title, String body, Map<String, dynamic> data) async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/icon_toi');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      final FlutterLocalNotificationsPlugin localNotifications =
          FlutterLocalNotificationsPlugin();

      await localNotifications.initialize(initializationSettings);

      final androidImplementation =
          localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'fcm_v1_background',
            'FCM V1 фоновые уведомления',
            description: 'Уведомления через FCM V1 API',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Color(0xFF4CAF50),
            showBadge: true,
          ),
        );
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'fcm_v1_background',
        'FCM V1 фоновые уведомления',
        channelDescription: 'Уведомления через FCM V1 API',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/icon_toi',
        color: Color(0xFF4CAF50),
        playSound: true,
        enableVibration: true,
        enableLights: true,
        ledColor: Color(0xFF4CAF50),
        ledOnMs: 1000,
        ledOffMs: 500,
        showWhen: true,
        channelShowBadge: true,
        visibility: NotificationVisibility.public,
        autoCancel: true,
        ongoing: false,
        fullScreenIntent: false,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
      );

      final notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await localNotifications.show(
        notificationId,
        title,
        body,
        notificationDetails,
        payload: jsonEncode(data),
      );
    } catch (e) {
      print('Error showing background notification: $e');
    }
  }

  /// Публичные методы для отправки уведомлений
  static Future<void> sendBookingNotification({
    required String userId,
    required String customerName,
    required String restaurantName,
    required String guests,
    required String bookingId,
    required String restaurantId,
    bool isUpdate = false,
  }) async {
    final type = isUpdate ? 'booking_updated' : 'new_booking';
    final title =
        isUpdate ? 'Бронирование изменено 📝' : 'Новое бронирование! 🎉';
    final body = isUpdate
        ? '$customerName изменил данные броня'
        : '$customerName забронировал столик на $guests гостей в ресторане "$restaurantName"';

    await sendNotificationSafely(
      type: type,
      userId: userId,
      title: title,
      body: body,
      bookingId: bookingId,
      restaurantId: restaurantId,
      data: {
        'type': type,
        'customer_name': customerName,
        'guests': guests,
        'restaurant_name': restaurantName,
      },
    );
  }

  static Future<void> sendNotificationToAdmins({
    required String title,
    required String body,
    String? restaurantId,
    String? bookingId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response =
          await supabase.from('profiles').select('id').eq('role', 'admin');

      for (final admin in response) {
        final adminId = admin['id'];
        await sendNotificationSafely(
          type: 'admin_notification',
          userId: adminId,
          title: title,
          body: body,
          restaurantId: restaurantId,
          bookingId: bookingId,
          data: data,
        );
      }
    } catch (e) {
      print('Error sending admin notifications: $e');
    }
  }

  /// Очистка старых записей дедупликации
  static void cleanupOldNotifications() {
    final now = DateTime.now();
    _processedNotifications.removeWhere(
        (key, timestamp) => now.difference(timestamp) > _deduplicationWindow);
  }

  /// Инициализация
  static Future<void> initialize() async {
    try {
      await _setupFCMToken();
      await _setupLocalNotifications();
      await _requestPermissions();
      await _setupRealtimeListeners();
      await _setupForegroundMessageHandler();

      // Периодическая очистка старых записей
      _cleanupTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
        cleanupOldNotifications();
      });
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  static Future<void> _setupFCMToken() async {
    try {
      NotificationSettings settings =
          await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: false,
        announcement: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }

      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await _saveFCMTokenToSupabase(token);
      }

      _firebaseMessaging.onTokenRefresh.listen((newToken) {
        _saveFCMTokenToSupabase(newToken);
      });
    } catch (e) {
      print('Error setting up FCM token: $e');
    }
  }

  static Future<void> _saveFCMTokenToSupabase(String token) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      await supabase.from('profiles').update({
        'fcm_token': token,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  static Future<void> _setupForegroundMessageHandler() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final messageId = message.messageId ?? 'unknown';
      print('FCM foreground message received: $messageId');

      // Проверяем дедупликацию для foreground сообщений
      final deduplicationKey = message.data['deduplication_key'];
      if (deduplicationKey != null && _isDuplicate(deduplicationKey)) {
        print('Duplicate foreground message blocked: $deduplicationKey');
        return;
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(jsonEncode(message.data));
    });

    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(jsonEncode(initialMessage.data));
    }
  }

  static Future<void> _setupLocalNotifications() async {
    (NotificationResponse response) async {
      final String? payload = response.payload;
      _handleNotificationTap(payload);
    };

    if (Platform.isAndroid) {
      final androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'new_booking',
            'Новые бронирования',
            description: 'Уведомления о новых бронированиях',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Color(0xFF4CAF50),
            showBadge: true,
          ),
        );

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'booking_updated',
            'Изменения бронирований',
            description: 'Уведомления об изменениях в бронированиях',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Color(0xFFFF9800),
            showBadge: true,
          ),
        );

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'fcm_v1_background',
            'FCM V1 фоновые уведомления',
            description: 'Уведомления через FCM V1 API в фоне',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: Color(0xFF2196F3),
            showBadge: true,
          ),
        );

        await androidImplementation.createNotificationChannel(
          const AndroidNotificationChannel(
            'restaurant_notifications',
            'Уведомления ресторана',
            description: 'Уведомления о бронированиях и изменениях в ресторане',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            showBadge: true,
          ),
        );
      }
    }
  }

  static Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.notification.isDenied) {
        await Permission.notification.request();
      }
    } else if (Platform.isIOS) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    }
  }

  static Future<void> _setupRealtimeListeners() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final userRole = await _getUserRole(userId);
    if (userRole == null) return;

    if (userRole == 'seller') {
      await _setupSellerListeners(userId);
    } else if (userRole == 'admin') {
      await _setupAdminListeners();
    }
  }

  static Future<String?> _getUserRole(String userId) async {
    try {
      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      return response['role'];
    } catch (e) {
      return null;
    }
  }

  static Future<void> _setupSellerListeners(String sellerId) async {
    final restaurants = await _getSellerRestaurants(sellerId);
    if (restaurants.isEmpty) return;

    final channelName = 'seller_bookings_$sellerId';

    if (_bookingsChannel != null) {
      await _bookingsChannel!.unsubscribe();
    }

    _bookingsChannel = supabase.channel(channelName);

    // Слушатель для новых бронирований с дедупликацией
    _bookingsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'bookings',
      callback: (payload) async {
        try {
          final booking = payload.newRecord;
          final restaurantId = booking['restaurant_id'];
          final customerName = booking['name'];
          final guests = booking['guests'];

          final deduplicationKey = _createDeduplicationKey(
            type: 'realtime_booking_insert',
            userId: sellerId,
            bookingId: booking['id'].toString(),
            restaurantId: restaurantId.toString(),
            title: 'Новое бронирование! 🎉',
            body: '$customerName забронировал столик на $guests гостей',
          );

          if (_isDuplicate(deduplicationKey)) {
            return;
          }

          final isSellerRestaurant =
              await _checkIfSellerRestaurant(sellerId, restaurantId);

          if (isSellerRestaurant) {
            final restaurantName = await _getRestaurantName(restaurantId);

            await _showLocalNotificationSafe(NotificationRequest(
              type: 'new_booking',
              userId: sellerId,
              title: 'Новое бронирование! 🎉',
              body:
                  '$customerName забронировал столик на $guests гостей в ресторане "$restaurantName"',
              bookingId: booking['id'].toString(),
              restaurantId: restaurantId.toString(),
              deduplicationKey: deduplicationKey,
              useDatabase: false,
              useFCM: false,
              useLocal: true,
            ));
          }
        } catch (e) {
          print('Error handling realtime booking insert: $e');
        }
      },
    );

    // Слушатель для обновлений бронирований с дедупликацией
    _bookingsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'bookings',
      callback: (payload) async {
        try {
          final booking = payload.newRecord;
          final oldBooking = payload.oldRecord;
          final restaurantId = booking['restaurant_id'];
          final customerName = booking['name'];

          final deduplicationKey = _createDeduplicationKey(
            type: 'realtime_booking_update',
            userId: sellerId,
            bookingId: booking['id'].toString(),
            restaurantId: restaurantId.toString(),
            title: 'Бронирование изменено 📝',
            body: '$customerName изменил данные броня',
          );

          if (_isDuplicate(deduplicationKey)) {
            return;
          }

          final isSellerRestaurant =
              await _checkIfSellerRestaurant(sellerId, restaurantId);

          if (isSellerRestaurant) {
            String changeDetails =
                _getBookingChangeDetails(oldBooking, booking);

            await _showLocalNotificationSafe(NotificationRequest(
              type: 'booking_updated',
              userId: sellerId,
              title: 'Бронирование изменено 📝',
              body: '$customerName изменил данные броня: $changeDetails',
              bookingId: booking['id'].toString(),
              restaurantId: restaurantId.toString(),
              deduplicationKey: deduplicationKey,
              useDatabase: false,
              useFCM: false,
              useLocal: true,
            ));
          }
        } catch (e) {
          print('Error handling realtime booking update: $e');
        }
      },
    );

    try {
      _bookingsChannel!.subscribe();
    } catch (e) {
      print('Error subscribing to bookings channel: $e');
    }
  }

  static Future<void> _setupAdminListeners() async {
    _bookingsChannel = supabase.channel('admin_bookings');

    _bookingsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'bookings',
      callback: (payload) async {
        final booking = payload.newRecord;
        final adminId = supabase.auth.currentUser?.id;
        if (adminId == null) return;

        final deduplicationKey = _createDeduplicationKey(
          type: 'admin_booking_insert',
          userId: adminId,
          bookingId: booking['id'].toString(),
          restaurantId: booking['restaurant_id'].toString(),
          title: 'Новое бронирование в системе 🏪',
          body: '${booking['name']} забронировал столик',
        );

        if (_isDuplicate(deduplicationKey)) {
          return;
        }

        final restaurantName =
            await _getRestaurantName(booking['restaurant_id']);

        await _showLocalNotificationSafe(NotificationRequest(
          type: 'new_booking',
          userId: adminId,
          title: 'Новое бронирование в системе 🏪',
          body:
              '${booking['name']} забронировал столик в ресторане "$restaurantName" на ${booking['guests']} гостей',
          bookingId: booking['id'].toString(),
          restaurantId: booking['restaurant_id'].toString(),
          deduplicationKey: deduplicationKey,
          useDatabase: false,
          useFCM: false,
          useLocal: true,
        ));
      },
    );

    _restaurantsChannel = supabase.channel('admin_restaurants');

    _restaurantsChannel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'restaurants',
      callback: (payload) async {
        final restaurant = payload.newRecord;
        final adminId = supabase.auth.currentUser?.id;
        if (adminId == null) return;

        final deduplicationKey = _createDeduplicationKey(
          type: 'restaurant_update',
          userId: adminId,
          restaurantId: restaurant['id'].toString(),
          title: 'Ресторан обновлен 🍽️',
          body: 'Продавец внес изменения в ресторан "${restaurant['name']}"',
        );

        if (_isDuplicate(deduplicationKey)) {
          return;
        }

        await _showLocalNotificationSafe(NotificationRequest(
          type: 'restaurant_notifications',
          userId: adminId,
          title: 'Ресторан обновлен 🍽️',
          body: 'Продавец внес изменения в ресторан "${restaurant['name']}"',
          restaurantId: restaurant['id'].toString(),
          deduplicationKey: deduplicationKey,
          useDatabase: false,
          useFCM: false,
          useLocal: true,
        ));
      },
    );

    _bookingsChannel?.subscribe();
    _restaurantsChannel?.subscribe();
  }

  static String _getBookingChangeDetails(
      Map<String, dynamic> oldBooking, Map<String, dynamic> newBooking) {
    List<String> changes = [];

    if (oldBooking['guests'] != newBooking['guests']) {
      changes.add(
          'количество гостей: ${oldBooking['guests']} → ${newBooking['guests']}');
    }

    if (oldBooking['booking_time'] != newBooking['booking_time']) {
      final oldDate = DateTime.parse(oldBooking['booking_time']).toLocal();
      final newDate = DateTime.parse(newBooking['booking_time']).toLocal();
      changes.add(
          'время: ${_formatDateTime(oldDate)} → ${_formatDateTime(newDate)}');
    }

    if (oldBooking['notes'] != newBooking['notes']) {
      changes.add('примечания');
    }

    if (oldBooking['phone'] != newBooking['phone']) {
      changes.add('телефон');
    }

    return changes.isNotEmpty ? changes.join(', ') : 'детали бронирования';
  }

  static String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}.${dateTime.month}.${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  static Future<List<Map<String, dynamic>>> _getSellerRestaurants(
      String sellerId) async {
    try {
      final response = await supabase
          .from('restaurants')
          .select('id, name, owner_id')
          .eq('owner_id', sellerId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  static Future<bool> _checkIfSellerRestaurant(
      String sellerId, int restaurantId) async {
    try {
      final response = await supabase
          .from('restaurants')
          .select('owner_id')
          .eq('id', restaurantId)
          .single();
      return response['owner_id'] == sellerId;
    } catch (e) {
      return false;
    }
  }

  static Future<String> _getRestaurantName(int restaurantId) async {
    try {
      final response = await supabase
          .from('restaurants')
          .select('name')
          .eq('id', restaurantId)
          .single();
      return response['name'] ?? 'Неизвестный ресторан';
    } catch (e) {
      return 'Неизвестный ресторан';
    }
  }

  static void _handleNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      if (payload.startsWith('booking_')) {
        // Навигация к бронированиям
      } else if (payload.startsWith('restaurant_')) {
        // Навигация к ресторану
      } else if (payload.startsWith('notification_')) {
        // Навигация к уведомлениям
      } else {
        final data = jsonDecode(payload);
        if (data is Map<String, dynamic>) {
          final type = data['type'];
          if (type == 'new_booking') {
            // Навигация к бронированию
          } else if (type == 'booking_updated') {
            // Навигация к бронированию
          }
        }
      }
    } catch (e) {
      print('Error handling notification tap: $e');
    }
  }

  static void dispose() {
    _notificationsChannel?.unsubscribe();
    _bookingsChannel?.unsubscribe();
    _restaurantsChannel?.unsubscribe();
    _cleanupTimer?.cancel();
    _processedNotifications.clear();
  }

  static Future<void> reconnect() async {
    dispose();
    await Future.delayed(const Duration(seconds: 1));
    await _setupRealtimeListeners();
  }
}

/// Класс для запроса уведомления
class NotificationRequest {
  final String type;
  final String userId;
  final String title;
  final String body;
  final String? bookingId;
  final String? restaurantId;
  final Map<String, dynamic>? data;
  final bool useDatabase;
  final bool useFCM;
  final bool useLocal;
  final String deduplicationKey;

  NotificationRequest({
    required this.type,
    required this.userId,
    required this.title,
    required this.body,
    this.bookingId,
    this.restaurantId,
    this.data,
    this.useDatabase = true,
    this.useFCM = true,
    this.useLocal = true,
    required this.deduplicationKey,
  });
}
