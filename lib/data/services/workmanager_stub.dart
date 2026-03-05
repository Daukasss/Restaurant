// Заглушка WorkManager для Web.
// Dart условный импорт подключает этот файл вместо реального workmanager на Web.

class Workmanager {
  static final Workmanager _instance = Workmanager._();
  Workmanager._();
  factory Workmanager() => _instance;

  Future<void> initialize(Function dispatcher,
      {bool isInDebugMode = false}) async {}
  Future<void> registerPeriodicTask(
    String uniqueName,
    String taskName, {
    Duration? frequency,
    dynamic constraints,
    dynamic existingWorkPolicy,
    dynamic backoffPolicy,
    Duration? backoffPolicyDelay,
  }) async {}
  Future<void> cancelByUniqueName(String uniqueName) async {}
  Future<void> executeTask(Function task) async {}
}

class Constraints {
  final dynamic networkType;
  const Constraints({this.networkType});
}

class NetworkType {
  static const connected = 'connected';
}

class ExistingPeriodicWorkPolicy {
  static const replace = 'replace';
}

class BackoffPolicy {
  static const exponential = 'exponential';
}
