import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
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
  // Используем уже существующие экземпляры
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setupAuthListener();
    _getToken();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setupAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        _setupNotifications();
      }
    });
  }

  void _setupNotifications() {
    // Настраиваем уведомления, но НЕ инициализируем Firebase заново
    _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<String?> fetchUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('profiles').doc(user.uid).get();
      return doc.data()?['role'] as String?;
    } catch (e) {
      debugPrint('Ошибка получения роли: $e');
      return null;
    }
  }

  void _getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM Token: $token');
    } catch (e) {
      debugPrint('Ошибка получения FCM токена: $e');
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
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final user = snapshot.data;
          if (user == null) {
            return const LoginPage();
          }

          return FutureBuilder<String?>(
            future: fetchUserRole(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final role = roleSnapshot.data;
              if (role == 'admin') {
                return const AdminPanelPage();
              } else if (role == 'seller') {
                return const SellerDashboardPage();
              } else {
                return const HomePage();
              }
            },
          );
        },
      ),
    );
  }
}
