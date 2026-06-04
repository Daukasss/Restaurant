// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/services/connectivity_service.dart';
import 'package:restauran/presentation/pages/seller/page/add_edit_restaurant/view/add_restaurant_page.dart';
import 'package:restauran/presentation/widgets/result_diolog.dart';
import 'package:restauran/theme/app_colors.dart';
import '../../../../customer/page/profile_page/view/profile_page.dart';
import '../bloc/seller_bloc.dart';
import '../bloc/seller_event.dart';
import '../bloc/seller_state.dart';
import '../widgets/restaurant_card.dart';
import 'seller_restaurant_page.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  _SellerDashboardPageState createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isOnline = true;
  int _selectedTab = 0; // 0 = Рестораны, 1 = Профиль
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    final online = await _connectivityService.checkNow();
    if (mounted) setState(() => _isOnline = online);

    _connectivitySub =
        _connectivityService.onConnectivityChanged.listen((online) {
      if (mounted) setState(() => _isOnline = online);
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Ошибка: пользователь не авторизован')),
      );
    }

    return BlocProvider(
      create: (context) => SellerBloc()..add(LoadRestaurants(userId)),
      child: BlocListener<SellerBloc, SellerState>(
        listener: (context, state) {
          if (state is SellerError) {
            showResultDialog(
                context: context,
                isSuccess: false,
                title: 'Ошибка',
                message: state.message);
          } else if (state is RestaurantDeleted) {
            showResultDialog(
                context: context,
                isSuccess: true,
                title: 'Успех',
                message: state.message);
            context.read<SellerBloc>().add(LoadRestaurants(userId));
          } else if (state is SellerOperationFailure) {
            showResultDialog(
                context: context,
                isSuccess: false,
                title: 'Ошибка',
                message: state.message);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.surface,
          body: IndexedStack(
            index: _selectedTab,
            children: [
              // ── Вкладка 0: список ресторанов ────────────────────────────
              _RestaurantsTab(
                userId: userId,
                isOnline: _isOnline,
              ),
              // ── Вкладка 1: профиль ───────────────────────────────────────
              const ProfilePage(),
            ],
          ),
          bottomNavigationBar: _DashboardBottomNav(
            currentIndex: _selectedTab,
            isOnline: _isOnline,
            onTap: (i) {
              if (i == 1 && !_isOnline) {
                _showOfflineToast('Профиль');
                return;
              }
              setState(() => _selectedTab = i);
            },
          ),
        ),
      ),
    );
  }

  void _showOfflineToast(String feature) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.wifi_off, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text('$feature недоступно без интернета',
                style: const TextStyle(fontSize: 13)),
          ),
        ]),
        backgroundColor: Colors.grey[700],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ── Вкладка «Рестораны» ───────────────────────────────────────────────────
class _RestaurantsTab extends StatelessWidget {
  final String userId;
  final bool isOnline;

  const _RestaurantsTab({required this.userId, required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        toolbarHeight: 80,
        title: const Text(
          'Мои рестораны',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.textMain,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: isOnline
                  ? const Icon(Icons.wifi_rounded,
                      key: ValueKey('on'), color: Colors.green, size: 20)
                  : Icon(Icons.wifi_off_rounded,
                      key: const ValueKey('off'),
                      color: Colors.orange[400],
                      size: 20),
            ),
          ),
          Padding(
              padding: const EdgeInsets.only(right: 14),
              child: IconButton(
                  onPressed:
                      isOnline ? () => _navigateToAdd(context, userId) : null,
                  icon: Icon(Icons.add_rounded))),
        ],
      ),
      body: BlocBuilder<SellerBloc, SellerState>(
        builder: (context, state) {
          if (state is SellerLoading) {
            return const Center(child: CircularProgressIndicator.adaptive());
          }
          if (state is SellerLoaded) {
            return RefreshIndicator.adaptive(
              onRefresh: isOnline
                  ? () async =>
                      context.read<SellerBloc>().add(LoadRestaurants(userId))
                  : () async {},
              child: state.restaurants.isEmpty
                  ? _EmptyRestaurantsState(
                      isOnline: isOnline,
                      onAdd: () => _navigateToAdd(context, userId),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      itemCount: state.restaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = state.restaurants[index];
                        return RestaurantCard(
                          restaurant: restaurant,
                          isOffline: !isOnline,
                          onEdit: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddRestaurantPage(
                                restaurantId: restaurant['id'],
                                restaurantName: restaurant['name']!,
                                restaurant: restaurant,
                              ),
                            ),
                          ).then((result) {
                            if (result == true && context.mounted) {
                              context
                                  .read<SellerBloc>()
                                  .add(LoadRestaurants(userId));
                            }
                          }),
                          // Тап по карточке → страница ресторана
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SellerRestaurantPage(
                                restaurant: restaurant,
                              ),
                            ),
                          ),
                          onDelete: () => _showDeleteConfirmation(
                              context, restaurant['id'], userId),
                        );
                      },
                    ),
            );
          }
          if (state is SellerError) {
            return Center(
              child: Text(state.message,
                  style: const TextStyle(color: AppColors.textSub)),
            );
          }
          return const Center(child: CircularProgressIndicator.adaptive());
        },
      ),
    );
  }

  Future<void> _navigateToAdd(BuildContext context, String userId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddRestaurantPage(
          restaurantId: '',
          restaurantName: '',
        ),
      ),
    );
    if (result == true && context.mounted) {
      context.read<SellerBloc>().add(const RestaurantUpdated());
    }
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, String restaurantId, String userId) async {
    final sellerCtx = context;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Удалить ресторан',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text(
            'Вы уверены, что хотите удалить этот ресторан? Это действие нельзя отменить.'),
        actions: [
          TextButton(
            child: Text('Назад', style: TextStyle(color: Colors.grey[600])),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          TextButton(
            child: const Text('Удалить',
                style: TextStyle(
                    color: AppColors.danger, fontWeight: FontWeight.w600)),
            onPressed: () {
              Navigator.of(ctx).pop();
              sellerCtx
                  .read<SellerBloc>()
                  .add(DeleteRestaurant(restaurantId, userId));
            },
          ),
        ],
      ),
    );
  }
}

// ── Нижняя навигация дашборда ─────────────────────────────────────────────
class _DashboardBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isOnline;
  final ValueChanged<int> onTap;

  const _DashboardBottomNav({
    required this.currentIndex,
    required this.isOnline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border:
            const Border(top: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _DashNavItem(
                icon: Icons.storefront_outlined,
                activeIcon: Icons.storefront_rounded,
                label: 'Рестораны',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _DashNavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Профиль',
                isActive: currentIndex == 1,
                isDisabled: !isOnline,
                onTap: () => onTap(1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashNavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onTap;

  const _DashNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isActive
        ? AppColors.primary
        : isDisabled
            ? AppColors.textSub.withOpacity(0.35)
            : AppColors.textSub;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 5),
              child: Icon(
                isActive ? activeIcon : icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Пустое состояние ──────────────────────────────────────────────────────
class _EmptyRestaurantsState extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onAdd;

  const _EmptyRestaurantsState({required this.isOnline, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded,
                        size: 44, color: AppColors.primary),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Нет ресторанов',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Добавьте своё первое заведение,\nчтобы начать принимать брони',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSub,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isOnline ? onAdd : null,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text(
                        'Добавить ресторан',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
