import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restauran/data/services/push_notification_service.dart';
import 'package:restauran/presentation/pages/auth/pages/login_page/view/login_page.dart';
import 'package:restauran/theme/app_theme.dart';
import '../presentation/pages/admin/view/admin_panel_page.dart';
import '../presentation/pages/customer/page/home_page/view/home_page.dart';
import '../presentation/pages/seller/page/seller_dashboard/view/seller_dashboard_page.dart';

class AqToi extends StatefulWidget {
  const AqToi({super.key});

  @override
  State<AqToi> createState() => _AqToiState();
}

class _AqToiState extends State<AqToi> with WidgetsBindingObserver {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Кэшируем роль чтобы не перезапрашивать при перестройке дерева
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

  /// Получить роль с таймаутом 5 секунд.
  /// При офлайне или ошибке — возвращает null → показываем LoginPage.
  Future<String?> _fetchUserRole() async {
    // Если уже загрузили — возвращаем кэш
    if (_cachedRole != null) return _cachedRole;

    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc =
          await _firestore.collection('profiles').doc(user.uid).get().timeout(
                const Duration(seconds: 5),
                onTimeout: () => throw Exception('timeout'),
              );

      _cachedRole = doc.data()?['role'] as String?;
      return _cachedRole;
    } catch (e) {
      debugPrint('[AqToi] fetchUserRole error/timeout: $e');

      // Пробуем получить из кэша Firestore (работает офлайн)
      try {
        final doc = await _firestore
            .collection('profiles')
            .doc(user.uid)
            .get(const GetOptions(source: Source.cache));

        _cachedRole = doc.data()?['role'] as String?;
        return _cachedRole;
      } catch (cacheError) {
        debugPrint('[AqToi] cache fallback error: $cacheError');
        // Нет ни сети, ни кэша — направляем на логин
        return null;
      }
    }
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
            _cachedRole = null; // сбрасываем кэш при логауте
            return const LoginPage();
          }

          return FutureBuilder<String?>(
            future: _fetchUserRole(),
            builder: (context, roleSnapshot) {
              // Ждём — но не дольше чем таймаут в _fetchUserRole (5 сек)
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingScreen();
              }

              // Ошибка или null → логин
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
