// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:restauran/presentation/pages/seller/page/add_edit_restaurant/view/add_restaurant_page.dart';
import 'package:restauran/presentation/pages/seller/page/booking_managment_page/view/booking_management_page.dart';
import 'package:restauran/presentation/widgets/result_diolog.dart';
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
  final supabase = Supabase.instance.client;

  @override
  Widget build(BuildContext context) {
    final userId = supabase.auth.currentUser?.id;

    debugPrint('[v0] Current user ID: $userId');

    if (userId == null) {
      debugPrint('[v0] ERROR: User is not authenticated');
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
            final userId = supabase.auth.currentUser?.id;
            if (userId != null) {
              context.read<SellerBloc>().add(LoadRestaurants(userId));
            }
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
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfilePage(),
                    ),
                  );
                },
              ),
            ],
          ),
          body: BlocBuilder<SellerBloc, SellerState>(
            builder: (context, state) {
              if (state is SellerLoading) {
                return const Center(child: CircularProgressIndicator());
              } else if (state is SellerLoaded) {
                // ✅ Обернули и пустой экран, и список в RefreshIndicator
                return RefreshIndicator(
                  onRefresh: () async {
                    final userId = supabase.auth.currentUser?.id;
                    if (userId != null) {
                      context.read<SellerBloc>().add(LoadRestaurants(userId));
                    }
                  },
                  child: state.restaurants.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.7,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'У вас пока нет ресторанов',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _navigateToAddRestaurant(context),
                                      icon: const Icon(Icons.add),
                                      label: const Text('Добавить ресторан'),
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
                              onEdit: () => _navigateToEditRestaurant(
                                  context, restaurant),
                              onDelete: () => _showDeleteConfirmation(
                                  context, restaurant['id'], userId),
                              onMenuManagement: () => _navigateToMenuManagement(
                                context,
                                restaurant['id'],
                                restaurant['name'],
                              ),
                              onBookingManagement: () =>
                                  _navigateToBookingManagement(
                                context,
                                restaurant['id'],
                                restaurant['name'],
                              ),
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
          floatingActionButton: FloatingActionButton(
            onPressed: () => _navigateToAddRestaurant(context),
            child: const Icon(Icons.add),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToAddRestaurant(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddRestaurantPage(
          restaurantId: 0,
          restaurantName: '',
        ),
      ),
    );

    if (result == true) {
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

    if (result == true) {
      context.read<SellerBloc>().add(const RestaurantUpdated());
    }
  }

  Future<void> _navigateToBookingManagement(
      BuildContext context, int restaurantId, String restaurantName) async {
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
      BuildContext context, int restaurantId, String restaurantName) async {
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
      BuildContext context, int restaurantId, String userId) async {
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
              onPressed: () {
                Navigator.of(context).pop();
              },
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
