// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/services/abstract/abstract_booking_service.dart';
import 'package:restauran/data/services/abstract/abstract_category_closure_service.dart';
import 'package:restauran/data/services/abstract/abstract_menu_service.dart';
import 'package:restauran/data/services/abstract/abstract_restaurant_service.dart';
import 'package:restauran/data/services/connectivity_service.dart';
import 'package:restauran/data/services/service_locator.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/view/booking_page.dart';
import 'package:restauran/presentation/pages/seller/page/add_edit_restaurant/view/add_restaurant_page.dart';
import 'package:restauran/presentation/pages/seller/page/booking_managment_page/view/booking_management_page.dart';
import 'package:restauran/presentation/widgets/result_diolog.dart';
import 'package:restauran/theme/app_colors.dart';
// import 'package:restauran/theme/offline_banner.dart';
import '../../../../customer/page/profile_page/view/profile_page.dart';
import '../../menu_management/view/menu_management_page.dart';
import '../bloc/seller_bloc.dart';
import '../bloc/seller_event.dart';
import '../bloc/seller_state.dart';
import '../widgets/restaurant_card.dart';

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({super.key});

  @override
  _SellerDashboardPageState createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ConnectivityService _connectivityService = ConnectivityService();

  bool _isOnline = true;
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
      if (mounted) {
        setState(() => _isOnline = online);
        if (!online) {
          // _showOfflineSnackBar();
        } else {
          // _showOnlineSnackBar();
        }
      }
    });
  }

  // void _showOfflineSnackBar() {
  //   ScaffoldMessenger.of(context).clearSnackBars();
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: const Row(
  //         children: [
  //           Icon(Icons.wifi_off, color: Colors.white),
  //           SizedBox(width: 10),
  //           Expanded(
  //             child: Text(
  //                 'Нет подключения к интернету. Доступны только «Брони» (из кэша).'),
  //           ),
  //         ],
  //       ),
  //       backgroundColor: Colors.orange[800],
  //       duration: const Duration(seconds: 5),
  //       behavior: SnackBarBehavior.floating,
  //     ),
  //   );
  // }

  // void _showOnlineSnackBar() {
  //   ScaffoldMessenger.of(context).clearSnackBars();
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(
  //       content: Row(
  //         children: [
  //           Icon(Icons.wifi, color: Colors.white),
  //           SizedBox(width: 10),
  //           Text('Подключение восстановлено'),
  //         ],
  //       ),
  //       backgroundColor: Colors.green,
  //       duration: Duration(seconds: 2),
  //       behavior: SnackBarBehavior.floating,
  //     ),
  //   );
  // }

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
          appBar: AppBar(
            title: const Text(
              'Мои рестораны',
              style: TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.textMain),
            ),
            centerTitle: false,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _isOnline ? Colors.green[400] : Colors.orange[400],
                  size: 20,
                ),
              ),
              IconButton(
                icon:
                    const Icon(Icons.person_outline, color: AppColors.textMain),
                onPressed: _isOnline
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ProfilePage()),
                        )
                    : () => _showOfflineFeatureToast(context, 'Профиль'),
              ),
            ],
          ),
          backgroundColor: AppColors.surface,
          body: Column(
            children: [
              // OfflineBanner(isOffline: !_isOnline),
              Expanded(
                child: BlocBuilder<SellerBloc, SellerState>(
                  builder: (context, state) {
                    if (state is SellerLoading) {
                      return const Center(
                          child: CircularProgressIndicator.adaptive());
                    } else if (state is SellerLoaded) {
                      return RefreshIndicator(
                        onRefresh: _isOnline
                            ? () async => context
                                .read<SellerBloc>()
                                .add(LoadRestaurants(userId))
                            : () async {},
                        child: state.restaurants.isEmpty
                            ? _EmptyRestaurantsState(
                                isOnline: _isOnline,
                                onAdd: () => _navigateToAddRestaurant(context),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 32),
                                itemCount: state.restaurants.length + 1,
                                itemBuilder: (context, index) {
                                  // ── Первый элемент — кнопка добавления ──
                                  if (index == 0) {
                                    return _AddRestaurantBanner(
                                      isOnline: _isOnline,
                                      onTap: _isOnline
                                          ? () =>
                                              _navigateToAddRestaurant(context)
                                          : () => _showOfflineFeatureToast(
                                              context, 'Добавление ресторана'),
                                    );
                                  }

                                  final restaurant =
                                      state.restaurants[index - 1];
                                  return RestaurantCard(
                                    restaurant: restaurant,
                                    isOffline: !_isOnline,
                                    onEdit: _isOnline
                                        ? () => _navigateToEditRestaurant(
                                            context, restaurant)
                                        : () => _showOfflineFeatureToast(
                                            context, 'Редактирование'),
                                    onDelete: _isOnline
                                        ? () => _showDeleteConfirmation(
                                            context, restaurant['id'], userId)
                                        : () => _showOfflineFeatureToast(
                                            context, 'Удаление'),
                                    onMenuManagement: _isOnline
                                        ? () => _navigateToMenuManagement(
                                              context,
                                              restaurant['id'],
                                              restaurant['name'],
                                            )
                                        : () => _showOfflineFeatureToast(
                                            context, 'Управление меню'),
                                    onBookingManagement: () =>
                                        _navigateToBookingManagement(
                                            context,
                                            restaurant['id'],
                                            restaurant['name']),
                                    onManualBooking: _isOnline
                                        ? () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => BlocProvider(
                                                  create: (context) =>
                                                      BookingBloc(
                                                    bookingService: getIt<
                                                        AbstractBookingService>(),
                                                    restaurantService: getIt<
                                                        AbstractRestaurantService>(),
                                                    menuService: getIt<
                                                        AbstractMenuService>(),
                                                    closureService: getIt<
                                                        AbstractCategoryClosureService>(),
                                                  ),
                                                  child: BookingPage(
                                                    restaurantId:
                                                        restaurant['id'],
                                                    restaurantName:
                                                        restaurant['name'],
                                                  ),
                                                ),
                                              ),
                                            )
                                        : () => _showOfflineFeatureToast(
                                            context, 'Ручная бронь'),
                                  );
                                },
                              ),
                      );
                    } else if (state is SellerError) {
                      return Center(
                        child: Text(state.message,
                            style: const TextStyle(color: AppColors.textSub)),
                      );
                    }

                    return const Center(
                        child: CircularProgressIndicator.adaptive());
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOfflineFeatureToast(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.wifi_off, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('$feature недоступно без интернета',
                  style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: Colors.grey[700],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _navigateToAddRestaurant(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddRestaurantPage(
          restaurantId: '',
          restaurantName: '',
        ),
      ),
    );
    if (result == true && context.mounted) {
      context.read<SellerBloc>().add(const RestaurantUpdated());
    }
  }

  Future<void> _navigateToEditRestaurant(
      BuildContext context, Map<String, dynamic> restaurant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddRestaurantPage(
          restaurant: restaurant,
          restaurantId: restaurant['id'],
          restaurantName: restaurant['name'],
        ),
      ),
    );
    if (result == true && context.mounted) {
      context.read<SellerBloc>().add(const RestaurantUpdated());
    }
  }

  Future<void> _navigateToBookingManagement(
      BuildContext context, String restaurantId, String restaurantName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingManagementPage(
          restaurantId: restaurantId,
          restaurantName: restaurantName,
        ),
      ),
    );
  }

  Future<void> _navigateToMenuManagement(
      BuildContext context, String restaurantId, String restaurantName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuManagementPage(
          restaurantId: restaurantId,
          restaurantName: restaurantName,
        ),
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, String restaurantId, String userId) async {
    final sellerContext = context;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Удалить ресторан',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text(
              'Вы уверены, что хотите удалить этот ресторан? Это действие нельзя отменить.'),
          actions: [
            TextButton(
              child: Text('Назад', style: TextStyle(color: Colors.grey[600])),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Удалить',
                  style: TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w600)),
              onPressed: () {
                Navigator.of(context).pop();
                sellerContext
                    .read<SellerBloc>()
                    .add(DeleteRestaurant(restaurantId, userId));
              },
            ),
          ],
        );
      },
    );
  }
}

// ── Баннер добавления ресторана (вверху списка) ────────────────────────────
class _AddRestaurantBanner extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onTap;

  const _AddRestaurantBanner({required this.isOnline, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: isOnline ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Добавить ресторан',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      'Зарегистрируйте новое заведение',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSub,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSub, size: 20),
            ],
          ),
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
          height: MediaQuery.of(context).size.height * 0.72,
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
