import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _fcm = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ─── Инициализация ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    // Запрос разрешения (iOS + Android 13+)
    await _fcm.requestPermission(alert: true, badge: true, sound: true);

    // Сохранить токен текущего устройства
    await _saveCurrentToken();

    // Обновлять токен при его ротации
    _fcm.onTokenRefresh.listen(_saveTokenToFirestore);

    // Пуш открыт когда приложение было убито
    final initial = await _fcm.getInitialMessage();
    if (initial != null) _handleMessage(initial);

    // Пуш открыт когда приложение в фоне
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // Пуш на переднем плане — просто логируем (показывать не нужно по ТЗ)
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('[Push] foreground: ${msg.notification?.title}');
    });

    debugPrint('[Push] initialized');
  }

  void _handleMessage(RemoteMessage message) {
    // При необходимости — навигация по data payload
    debugPrint('[Push] opened: ${message.data}');
  }

  // ─── Токены ───────────────────────────────────────────────────────────────

  Future<void> _saveCurrentToken() async {
    try {
      final token = await _fcm.getToken();
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

  /// Вызывать при логауте
  Future<void> removeCurrentToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final token = await _fcm.getToken();
      if (token == null) return;
      await _db.collection('users').doc(uid).update({
        'fcm_tokens': FieldValue.arrayRemove([token]),
      });
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('[Push] removeCurrentToken error: $e');
    }
  }

  // ─── Публичные методы (вызываются из BookingBloc) ─────────────────────────

  /// Новая бронь от юзера → уведомить селлера.
  /// Если [isSellerBooking] == true — ничего не делаем.
  Future<void> notifySellerNewBooking({
    required String bookingId,
    required String restaurantId,
    required String restaurantName,
    required String guestName,
    required int guests,
    required String dateStr, // "dd.MM.yyyy"
    required String startTime, // "HH:mm"
    required String endTime,
    required bool isSellerBooking,
  }) async {
    if (isSellerBooking) return;

    final sellerId = await _getOwnerId(restaurantId);
    if (sellerId == null) return;

    await _notifyUser(
      uid: sellerId,
      title: '🆕 Новое бронирование — $restaurantName',
      body: '$guestName · $guests гостей · $dateStr · $startTime–$endTime',
      data: {
        'type': 'new_booking',
        'booking_id': bookingId,
        'restaurant_id': restaurantId
      },
    );
  }

  /// Изменение брони юзером → уведомить селлера.
  /// Если [isSellerBooking] == true — ничего не делаем.
  Future<void> notifySellerBookingUpdated({
    required String bookingId,
    required String restaurantId,
    required String restaurantName,
    required String guestName,
    required String dateStr,
    required String startTime,
    required String endTime,
    required bool isSellerBooking,
    List<String> changedFields = const [],
  }) async {
    if (isSellerBooking) return;

    final sellerId = await _getOwnerId(restaurantId);
    if (sellerId == null) return;

    final changedText = changedFields.isNotEmpty
        ? 'Изменено: ${changedFields.join(", ")}'
        : 'Бронирование обновлено';

    await _notifyUser(
      uid: sellerId,
      title: '✏️ Изменение брони — $restaurantName',
      body: '$guestName · $dateStr · $startTime–$endTime\n$changedText',
      data: {
        'type': 'booking_updated',
        'booking_id': bookingId,
        'restaurant_id': restaurantId
      },
    );
  }

  // ─── Внутренние ───────────────────────────────────────────────────────────

  /// Сохраняем данные для уведомления в служебную коллекцию.
  /// Cloud Function (onWrite на mail_queue / notification_queue) забирает и отправляет.
  ///
  /// Альтернатива: если хотите отправлять прямо из клиента через FCM Data Message —
  /// замените тело этого метода на вызов Cloud Function через http.post.
  Future<void> _notifyUser({
    required String uid,
    required String title,
    required String body,
    Map<String, String> data = const {},
  }) async {
    try {
      await _db.collection('notification_queue').add({
        'uid': uid,
        'title': title,
        'body': body,
        'data': data,
        'created_at': FieldValue.serverTimestamp(),
        'sent': false,
      });
      debugPrint('[Push] queued notification for $uid: $title');
    } catch (e) {
      debugPrint('[Push] _notifyUser error: $e');
    }
  }

  Future<String?> _getOwnerId(String restaurantId) async {
    try {
      final doc = await _db.collection('restaurants').doc(restaurantId).get();
      return doc.data()?['owner_id']?.toString();
    } catch (e) {
      debugPrint('[Push] _getOwnerId error: $e');
      return null;
    }
  }

  static String formatDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';

  static String formatTime(TimeOfDayCompat t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

/// Простой класс-обёртка чтобы не импортировать flutter/material в сервис
class TimeOfDayCompat {
  final int hour;
  final int minute;
  const TimeOfDayCompat(this.hour, this.minute);
}
