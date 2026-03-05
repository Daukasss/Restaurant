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

  // flutter_local_notifications — для показа пуша когда приложение активно
  static final _localNotifications = FlutterLocalNotificationsPlugin();
  static const _androidChannel = AndroidNotificationChannel(
    'bookings', // должен совпадать с channelId в index.ts
    'Бронирования',
    description: 'Уведомления о бронированиях',
    importance: Importance.max,
    playSound: true,
  );

  // ─── Инициализация ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // 1. Разрешение FCM
    try {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('[Push] requestPermission error: $e');
    }

    // 2. Настройка flutter_local_notifications (только мобильные)
    if (!kIsWeb) {
      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/icon_toi'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      // Создаём канал на Android
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_androidChannel);
    }

    // 3. Сохранить токен
    await _saveCurrentToken();
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // 4. Пуш когда приложение было убито
    try {
      final initial = await _fcm.getInitialMessage();
      if (initial != null) _handleMessage(initial);
    } catch (e) {
      debugPrint('[Push] getInitialMessage error: $e');
    }

    // 5. Пуш когда приложение в фоне и пользователь тапнул
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // 6. Пуш когда приложение АКТИВНО — показываем через local notifications
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('[Push] foreground: ${msg.notification?.title}');
      _showLocalNotification(msg);
    });

    debugPrint('[Push] initialized');
  }

  /// Показать уведомление через flutter_local_notifications (foreground)
  void _showLocalNotification(RemoteMessage message) {
    if (kIsWeb) return;
    final n = message.notification;
    if (n == null) return;

    _localNotifications.show(
      // id — хэш messageId чтобы не дублировать
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
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  void _handleMessage(RemoteMessage message) {
    debugPrint('[Push] opened: ${message.data}');
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
          'fcm_tokens': FieldValue.arrayUnion([token])
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
