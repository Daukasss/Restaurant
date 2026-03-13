import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  static const _vapidKey = 'YOUR_VAPID_KEY';

  static final _localNotifications = FlutterLocalNotificationsPlugin();

  // ВАЖНО: id канала должен совпадать с:
  //   - AndroidManifest.xml → default_notification_channel_id
  //   - index.ts → channelId
  static const _androidChannel = AndroidNotificationChannel(
    'bookings',
    'Бронирования',
    description: 'Уведомления о бронированиях',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  // ─── Инициализация ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // 1. Запрос разрешения FCM
    try {
      await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e) {
      debugPrint('[Push] requestPermission error: $e');
    }

    // 2. ИСПРАВЛЕНО: показывать уведомления когда приложение активно (foreground)
    //    Без этого iOS полностью игнорирует пуши в foreground
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Настройка flutter_local_notifications (только мобильные)
    if (!kIsWeb) {
      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/icon_toi'),
          iOS: DarwinInitializationSettings(
            // ИСПРАВЛЕНО: явно разрешаем показ в foreground на iOS
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            defaultPresentAlert: true,
            defaultPresentBadge: true,
            defaultPresentSound: true,
          ),
        ),
      );

      // Создаём канал на Android
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);

      // ИСПРАВЛЕНО: Android 13+ требует явного запроса разрешения POST_NOTIFICATIONS
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    // 4. Сохранить токен
    await _saveCurrentToken();
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // 5. Приложение было убито — пользователь тапнул на пуш
    try {
      final initial = await _fcm.getInitialMessage();
      if (initial != null) _handleMessage(initial);
    } catch (e) {
      debugPrint('[Push] getInitialMessage error: $e');
    }

    // 6. Приложение в фоне — пользователь тапнул на пуш
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // 7. Приложение АКТИВНО (foreground) — показываем через local notifications
    //    FCM в foreground НЕ показывает системный баннер сам по себе на Android,
    //    поэтому мы делаем это через flutter_local_notifications
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('[Push] foreground message: ${msg.notification?.title}');
      _showLocalNotification(msg);
    });

    debugPrint('[Push] initialized ✅');
  }

  // ─── Показ уведомления через flutter_local_notifications (foreground) ────

  void _showLocalNotification(RemoteMessage message) {
    if (kIsWeb) return;

    final n = message.notification;
    if (n == null) {
      debugPrint('[Push] foreground: notification payload is null, skipping');
      return;
    }

    _localNotifications.show(
      message.messageId?.hashCode ?? DateTime.now().millisecondsSinceEpoch,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          // ИСПРАВЛЕНО: используем тот же значок что и в FCM
          icon: '@mipmap/icon_toi',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );

    debugPrint('[Push] local notification shown: ${n.title}');
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint('[Push] opened: type=${message.data['type']}, '
        'booking_id=${message.data['booking_id']}');
    // Здесь можно добавить навигацию по data['type'] и data['booking_id']
  }

  // ─── Токены ───────────────────────────────────────────────────────────────

  Future<void> _saveCurrentToken() async {
    try {
      final token = kIsWeb
          ? await _fcm.getToken(vapidKey: _vapidKey)
          : await _fcm.getToken();
      if (token != null) await _saveTokenToFirestore(token);
    } catch (e) {
      debugPrint('[Push] _saveCurrentToken error: $e');
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _db.collection('users').doc(uid).set(
        {
          'fcm_tokens': FieldValue.arrayUnion([token]),
        },
        SetOptions(merge: true),
      );
      debugPrint('[Push] token saved for $uid');
    } catch (e) {
      debugPrint('[Push] _saveTokenToFirestore error: $e');
    }
  }

  /// Вызывать при логауте — удаляет токен из Firestore
  Future<void> removeCurrentToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final token = kIsWeb
          ? await _fcm.getToken(vapidKey: _vapidKey)
          : await _fcm.getToken();
      if (token == null) return;
      await _db.collection('users').doc(uid).update({
        'fcm_tokens': FieldValue.arrayRemove([token]),
      });
      await _fcm.deleteToken();
      debugPrint('[Push] token removed for $uid');
    } catch (e) {
      debugPrint('[Push] removeCurrentToken error: $e');
    }
  }

  // ─── Хелперы форматирования (используются в BookingBloc) ─────────────────

  static String formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.'
      '${dt.month.toString().padLeft(2, '0')}.'
      '${dt.year}';

  static String formatTimeOfDay(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:'
      '${t.minute.toString().padLeft(2, '0')}';
}
