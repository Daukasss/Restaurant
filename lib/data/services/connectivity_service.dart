import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Сервис для отслеживания состояния сети.
/// Предоставляет Stream<bool> и синхронный геттер isOnline.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // Внутренний контроллер
  final StreamController<bool> _controller = StreamController<bool>.broadcast();

  bool _isOnline = true;
  StreamSubscription? _subscription;

  bool get isOnline => _isOnline;

  Stream<bool> get onConnectivityChanged => _controller.stream;

  ConnectivityService() {
    _init();
  }

  Future<void> _init() async {
    // Проверяем текущее состояние сразу
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    _controller.add(_isOnline);

    // Подписываемся на изменения
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final online = _isConnected(result);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(_isOnline);
        debugPrint(
            '[ConnectivityService] Статус сети: ${online ? "ONLINE" : "OFFLINE"}');
      }
    });
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) =>
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet);
  }

  Future<bool> checkNow() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);
    return _isOnline;
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}
