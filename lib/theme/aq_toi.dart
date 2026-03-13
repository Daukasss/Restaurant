import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:restauran/data/services/push_notification_service.dart';
import 'package:restauran/presentation/pages/auth/pages/login_page/view/login_page.dart';
import 'package:restauran/theme/app_theme.dart';
import '../presentation/pages/admin/view/admin_panel_page.dart';
import '../presentation/pages/customer/page/home_page/view/home_page.dart';
import '../presentation/pages/seller/page/seller_dashboard/view/seller_dashboard_page.dart';

/// Hive box для сохранения роли пользователя на диске.
/// Переживает убийство процесса и повторный запуск без сети.
const _roleBoxName = 'user_role_cache';
const _roleKey = 'role';
const _uidKey = 'uid';

class AqToi extends StatefulWidget {
  const AqToi({super.key});

  @override
  State<AqToi> createState() => _AqToiState();
}

class _AqToiState extends State<AqToi> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Кэшируем роль в памяти чтобы не перезапрашивать при перестройке дерева
  String? _cachedRole;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Когда пользователь логинится — сохраняем FCM токен
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        PushNotificationService.instance.initialize();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Hive helpers ─────────────────────────────────────

  Future<Box<String>> _openRoleBox() async {
    if (Hive.isBoxOpen(_roleBoxName)) {
      return Hive.box<String>(_roleBoxName);
    }
    return await Hive.openBox<String>(_roleBoxName);
  }

  /// Сохранить роль на диск (Hive)
  Future<void> _saveRoleToHive(String uid, String role) async {
    try {
      final box = await _openRoleBox();
      await box.put(_uidKey, uid);
      await box.put(_roleKey, role);
    } catch (e) {
      debugPrint('[AqToi] Hive save error: $e');
    }
  }

  /// Прочитать роль из Hive.
  /// Возвращает null если uid не совпадает или box пустой.
  Future<String?> _loadRoleFromHive(String uid) async {
    try {
      final box = await _openRoleBox();
      final savedUid = box.get(_uidKey);
      if (savedUid != uid) return null; // другой пользователь — не используем
      return box.get(_roleKey);
    } catch (e) {
      debugPrint('[AqToi] Hive load error: $e');
      return null;
    }
  }

  /// Очистить кэш роли (при логауте)
  Future<void> _clearRoleCache() async {
    try {
      final box = await _openRoleBox();
      await box.clear();
    } catch (e) {
      debugPrint('[AqToi] Hive clear error: $e');
    }
    _cachedRole = null;
  }

  // ── Получение роли с многоуровневым fallback ─────────

  /// Порядок приоритетов:
  ///   1. In-memory кэш (_cachedRole) — самый быстрый
  ///   2. Firestore (онлайн) с таймаутом 5 сек
  ///   3. Firestore кэш (офлайн)
  ///   4. Hive (переживает kill процесса)
  Future<String?> _fetchUserRole() async {
    // 1. In-memory
    if (_cachedRole != null) return _cachedRole;

    final user = _auth.currentUser;
    if (user == null) return null;

    // 2. Firestore (сеть)
    try {
      final doc =
          await _firestore.collection('profiles').doc(user.uid).get().timeout(
                const Duration(seconds: 5),
                onTimeout: () => throw Exception('timeout'),
              );

      final role = doc.data()?['role'] as String?;
      if (role != null) {
        _cachedRole = role;
        await _saveRoleToHive(user.uid, role); // сохраняем на диск
        return role;
      }
    } catch (e) {
      debugPrint('[AqToi] fetchUserRole network error/timeout: $e');
    }

    // 3. Firestore SDK cache (офлайн, работает пока процесс жив)
    try {
      final doc = await _firestore
          .collection('profiles')
          .doc(user.uid)
          .get(const GetOptions(source: Source.cache));

      final role = doc.data()?['role'] as String?;
      if (role != null) {
        _cachedRole = role;
        await _saveRoleToHive(user.uid, role);
        return role;
      }
    } catch (e) {
      debugPrint('[AqToi] Firestore cache fallback error: $e');
    }

    // 4. Hive — работает даже после kill процесса
    final hiveRole = await _loadRoleFromHive(user.uid);
    if (hiveRole != null) {
      debugPrint('[AqToi] Роль загружена из Hive: $hiveRole');
      _cachedRole = hiveRole;
      return hiveRole;
    }

    // Ничего не нашли — направляем на логин
    debugPrint('[AqToi] Роль не найдена нигде → LoginPage');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aq Toi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: StreamBuilder<User?>(
        stream: _auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingScreen();
          }

          final user = snapshot.data;
          if (user == null) {
            // Сбрасываем кэш при логауте
            _clearRoleCache();
            return const LoginPage();
          }

          return FutureBuilder<String?>(
            future: _fetchUserRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingScreen();
              }

              if (roleSnapshot.hasError || roleSnapshot.data == null) {
                return const LoginPage();
              }

              final role = roleSnapshot.data!;
              if (role == 'admin') return const AdminPanelPage();
              if (role == 'seller') return const SellerDashboardPage();
              return const HomePage();
            },
          );
        },
      ),
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
