import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:restauran/presentation/pages/auth/pages/login_page/view/login_page.dart';
import 'package:restauran/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/services/supabase_notification_service.dart';
import '../presentation/pages/admin/view/admin_panel_page.dart';
import '../presentation/pages/customer/page/home_page/view/home_page.dart';
import '../presentation/pages/seller/page/seller_dashboard/view/seller_dashboard_page.dart';

final supabase = Supabase.instance.client;

class AqToi extends StatefulWidget {
  const AqToi({super.key});

  @override
  State<AqToi> createState() => _AqToiState();
}

class _AqToiState extends State<AqToi> with WidgetsBindingObserver {
  bool _notificationsInitialized = false;

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
    SupabaseNotificationService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed && _notificationsInitialized) {
      _reconnectNotifications();
    }
  }

  void _setupAuthListener() {
    supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;

      if (session != null) {
        await _initializeNotifications();
      } else {
        _cleanupNotifications();
      }
    });
  }

  Future<void> _initializeNotifications() async {
    if (_notificationsInitialized) {
      await _reconnectNotifications();
      return;
    }

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      await SupabaseNotificationService.initialize();
      _notificationsInitialized = true;
    } catch (_) {
      _notificationsInitialized = false;
    }
  }

  Future<void> _reconnectNotifications() async {
    try {
      await SupabaseNotificationService.reconnect();
    } catch (_) {}
  }

  void _cleanupNotifications() {
    SupabaseNotificationService.dispose();
    _notificationsInitialized = false;
  }

  Future<String?> fetchUserRole() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      return response['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  final FirebaseMessaging messaging = FirebaseMessaging.instance;

  void _getToken() async {
    await messaging.getToken();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Aq Tой',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: StreamBuilder<AuthState>(
          stream: supabase.auth.onAuthStateChange,
          builder: (context, snapshot) {
            final session = supabase.auth.currentSession;

            if (session == null) {
              return const LoginPage();
            }

            return FutureBuilder<String?>(
              future: fetchUserRole(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                }

                final role = snapshot.data;

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
        ));
  }
}
