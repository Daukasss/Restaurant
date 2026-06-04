// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/services/abstract/abstract_booking_service.dart';
import 'package:restauran/data/services/abstract/abstract_category_closure_service.dart';
import 'package:restauran/data/services/abstract/abstract_menu_service.dart';
import 'package:restauran/data/services/abstract/abstract_restaurant_service.dart';
import 'package:restauran/data/services/connectivity_service.dart';
import 'package:restauran/data/services/service_locator.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_event.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/view/booking_page.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/bloc/restaurant_detail_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/bloc/restaurant_detail_event.dart';
import 'package:restauran/presentation/pages/seller/page/booking_managment_page/view/booking_management_page.dart';
import 'package:restauran/presentation/pages/seller/page/menu_management/view/menu_management_page.dart';
import 'package:restauran/theme/app_colors.dart';

class SellerRestaurantPage extends StatefulWidget {
  final Map<String, dynamic> restaurant;

  const SellerRestaurantPage({super.key, required this.restaurant});

  @override
  State<SellerRestaurantPage> createState() => _SellerRestaurantPageState();
}

class _SellerRestaurantPageState extends State<SellerRestaurantPage> {
  int _selectedTab = 0;
  bool _isOnline = true;
  final ConnectivityService _connectivity = ConnectivityService();

  late final String _restaurantId;
  late final String _restaurantName;

  @override
  void initState() {
    super.initState();
    _restaurantId = widget.restaurant['id'] as String;
    _restaurantName = (widget.restaurant['name'] ?? 'Ресторан').toString();

    _connectivity.checkNow().then((v) {
      if (mounted) setState(() => _isOnline = v);
    });
    _connectivity.onConnectivityChanged.listen((v) {
      if (mounted) setState(() => _isOnline = v);
    });
  }

  @override
  void dispose() {
    _connectivity.dispose();
    super.dispose();
  }

  void _onTabTap(int index) {
    if (!_isOnline && index != 0) {
      _showOfflineToast(_tabLabel(index));
      return;
    }
    setState(() => _selectedTab = index);
  }

  String _tabLabel(int index) => [
        'Брони',
        'Меню',
        'Добавить',
        'Витрина',
        'Закрытия',
      ][index];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: IndexedStack(
        index: _selectedTab,
        children: [
          // 0: Брони
          BookingManagementPage(
            restaurantId: _restaurantId,
            restaurantName: _restaurantName,
          ),

          // 1: Меню (управление)
          MenuManagementPage(
            restaurantId: _restaurantId,
            restaurantName: _restaurantName,
          ),

          // 2: Ручная бронь
          BlocProvider(
            create: (_) => BookingBloc(
              bookingService: getIt<AbstractBookingService>(),
              restaurantService: getIt<AbstractRestaurantService>(),
              menuService: getIt<AbstractMenuService>(),
              closureService: getIt<AbstractCategoryClosureService>(),
            ),
            child: BookingPage(
              restaurantId: _restaurantId,
              restaurantName: _restaurantName,
            ),
          ),

          // 3: Закрытия дат
          BlocProvider(
            create: (_) => BookingBloc(
              bookingService: getIt<AbstractBookingService>(),
              restaurantService: getIt<AbstractRestaurantService>(),
              menuService: getIt<AbstractMenuService>(),
              closureService: getIt<AbstractCategoryClosureService>(),
            )..add(LoadRestaurantCategoriesEvent(_restaurantId)),
            child: DateManagementPage(restaurantId: _restaurantId),
          ),
          // 4: Витрина меню
          BlocProvider(
            create: (_) =>
                RestaurantDetailBloc()..add(FetchRestaurantData(_restaurantId)),
            child: MenuTabPage(restaurantId: _restaurantId),
          ),
        ],
      ),
      bottomNavigationBar: _RestaurantBottomNav(
        currentIndex: _selectedTab,
        isOnline: _isOnline,
        onTap: _onTabTap,
      ),
    );
  }
}

class _RestaurantBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isOnline;
  final ValueChanged<int> onTap;

  const _RestaurantBottomNav({
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
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.calendar_today_outlined,
                activeIcon: Icons.calendar_today_rounded,
                label: 'Брони',
                isActive: currentIndex == 0,
                showOfflineBadge: !isOnline,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.restaurant_menu_outlined,
                activeIcon: Icons.restaurant_menu_rounded,
                label: 'Меню',
                isActive: currentIndex == 1,
                isDisabled: !isOnline,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.edit_calendar_outlined,
                activeIcon: Icons.edit_calendar_rounded,
                label: 'Добавить',
                isActive: currentIndex == 2,
                isDisabled: !isOnline,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.event_busy_outlined,
                activeIcon: Icons.event_busy_rounded,
                label: 'Закрытия',
                isActive: currentIndex == 3,
                isDisabled: !isOnline,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.visibility_outlined,
                activeIcon: Icons.visibility_rounded,
                label: 'Витрина',
                isActive: currentIndex == 4,
                isDisabled: !isOnline,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final bool isDisabled;
  final bool showOfflineBadge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isDisabled = false,
    this.showOfflineBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color activeColor = AppColors.primary;
    final Color inactiveColor =
        isDisabled ? AppColors.textSub.withOpacity(0.35) : AppColors.textSub;

    final Color iconColor = isActive ? activeColor : inactiveColor;
    final Color labelColor = isActive ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                if (showOfflineBadge)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.orange[600],
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.cardBg, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: labelColor,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
