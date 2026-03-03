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
import 'package:restauran/theme/offline_banner.dart';
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
    // Начальное состояние
    final online = await _connectivityService.checkNow();
    if (mounted) {
      setState(() => _isOnline = online);
    }

    // Подписка на изменения
    _connectivitySub =
        _connectivityService.onConnectivityChanged.listen((online) {
      if (mounted) {
        setState(() => _isOnline = online);

        // Показываем SnackBar при потере/восстановлении соединения
        if (!online) {
          _showOfflineSnackBar();
        } else {
          _showOnlineSnackBar();
        }
      }
    });
  }

  void _showOfflineSnackBar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Нет подключения к интернету. Доступны только «Брони» (из кэша).',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[800],
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showOnlineSnackBar() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.wifi, color: Colors.white),
            SizedBox(width: 10),
            Text('Подключение восстановлено'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
        body: Center(
          child: Text('Ошибка: пользователь не авторизован'),
        ),
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
              message: state.message,
            );
          } else if (state is RestaurantDeleted) {
            showResultDialog(
              context: context,
              isSuccess: true,
              title: 'Успех',
              message: state.message,
            );
            context.read<SellerBloc>().add(LoadRestaurants(userId));
          } else if (state is SellerOperationFailure) {
            showResultDialog(
              context: context,
              isSuccess: false,
              title: 'Ошибка',
              message: state.message,
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Мои рестораны'),
            actions: [
              // Иконка состояния сети
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  _isOnline ? Icons.wifi : Icons.wifi_off,
                  color: _isOnline ? Colors.green[300] : Colors.orange[300],
                  size: 20,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_outline),
                // Профиль недоступен офлайн
                onPressed: _isOnline
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        )
                    : () => _showOfflineFeatureToast(context, 'Профиль'),
              ),
            ],
          ),
          body: Column(
            children: [
              // Глобальный офлайн-баннер для дашборда
              OfflineBanner(isOffline: !_isOnline),

              Expanded(
                child: BlocBuilder<SellerBloc, SellerState>(
                  builder: (context, state) {
                    if (state is SellerLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (state is SellerLoaded) {
                      return RefreshIndicator(
                        // RefreshIndicator недоступен офлайн
                        onRefresh: _isOnline
                            ? () async {
                                context
                                    .read<SellerBloc>()
                                    .add(LoadRestaurants(userId));
                              }
                            : () async {},
                        child: state.restaurants.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.7,
                                    child: Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Text(
                                            'У вас пока нет ресторанов',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton.icon(
                                            onPressed: _isOnline
                                                ? () =>
                                                    _navigateToAddRestaurant(
                                                        context)
                                                : null,
                                            icon: const Icon(Icons.add),
                                            label:
                                                const Text('Добавить ресторан'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.restaurants.length,
                                itemBuilder: (context, index) {
                                  final restaurant = state.restaurants[index];
                                  return RestaurantCard(
                                    restaurant: restaurant,
                                    isOffline: !_isOnline, // ← передаём флаг
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
                                    // ✅ Брони — всегда доступны (откроет кэш)
                                    onBookingManagement: () =>
                                        _navigateToBookingManagement(
                                      context,
                                      restaurant['id'],
                                      restaurant['name'],
                                    ),
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
                      return Center(child: Text(state.message));
                    }

                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            // FAB недоступен офлайн
            onPressed: _isOnline
                ? () => _navigateToAddRestaurant(context)
                : () =>
                    _showOfflineFeatureToast(context, 'Добавление ресторана'),
            tooltip: _isOnline ? 'Добавить ресторан' : 'Недоступно офлайн',
            backgroundColor: _isOnline ? null : Colors.grey[400],
            child: const Icon(Icons.add),
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
              child: Text(
                '$feature недоступно без интернета',
                style: const TextStyle(fontSize: 13),
              ),
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
          title: const Text('Удалить ресторан'),
          content: const SingleChildScrollView(
            child: Text(
                'Вы уверены, что хотите удалить этот ресторан? Это действие нельзя отменить.'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Назад'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
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
