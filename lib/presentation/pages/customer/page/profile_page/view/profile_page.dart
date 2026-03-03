import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/models/profile.dart';
import 'package:restauran/presentation/widgets/result_diolog.dart';
import 'package:restauran/data/services/favorite_service.dart';
import 'package:restauran/data/services/profile_service.dart';
import '../../../../../../data/models/restaurant.dart';
import '../../../../../../data/services/booking_service.dart';
import '../../../../../../data/services/restaurant_service.dart';
import '../../../widgets/booking_card.dart';
import '../../../widgets/favorite_card.dart';
import '../../../widgets/profile_dialog.dart';
import '../../../widgets/profile_header.dart';
import '../../../../auth/pages/login_page/view/login_page.dart';
import '../../../../seller/page/seller_dashboard/view/seller_dashboard_page.dart';
import '../bloc/profil_bloc.dart';
import '../bloc/profil_event.dart';
import '../bloc/profil_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(
        restaurantService: RestaurantService(),
        profileService: ProfileService(),
        bookingService: BookingService(),
        favoriteService: FavoriteService(),
      )..add(LoadUserData()),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView>
    with SingleTickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _phoneController.text = '+7 '; // начальное значение
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        // Если пользователь вышел → переходим на логин
        if (!state.isAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
          return;
        }

        // Синхронизируем поля с актуальными данными из состояния
        if (state.profile != null) {
          // Обновляем только если значение реально отличается → избегание "мигания" курсора
          if (_nameController.text != state.profile!.name) {
            _nameController.text = state.profile!.name;
          }
          if (_phoneController.text != state.profile!.phone) {
            _phoneController.text = state.profile!.phone;
          }
        }

        // Показываем успех после обновления профиля
        if (state.wasUpdated) {
          showResultDialog(
            context: context,
            isSuccess: true,
            title: 'Успешно',
            message: 'Данные профиля обновлены',
          );
          // Сразу сбрасываем флаг, чтобы не показывало повторно
          context.read<ProfileBloc>().add(ResetUpdateStatus());
        }

        // Показ ошибок
        if (state.error != null) {
          showResultDialog(
            context: context,
            isSuccess: false,
            title: 'Ошибка',
            message: state.error!,
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading || state.profile == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Профиль')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final profile = state.profile!;

        return Scaffold(
          appBar: AppBar(title: const Text('Профиль')),
          body: Column(
            children: [
              ProfileHeader(
                profile: profile,
                onEditProfile: _showEditProfileDialog,
                onNavigateToSellerDashboard:
                    profile.isSeller ? _navigateToSellerDashboard : null,
              ),
              if (profile.isUser) ...[
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Мои бронирования'),
                    Tab(text: 'Избранное'),
                  ],
                ),
              ],
              if (profile.isUser)
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Мои бронирования
                      state.bookings.isEmpty
                          ? const Center(child: Text('Пока нет бронирований'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: state.bookings.length,
                              itemBuilder: (context, index) {
                                final booking = state.bookings[index];

                                final restaurant = state.restaurants.firstWhere(
                                  (r) => r.id == booking.restaurantId,
                                  orElse: () => Restaurant(
                                    id: booking.restaurantId,
                                    name: 'Неизвестный ресторан',
                                    sumPeople: null,
                                    description: '',
                                    location: '',
                                    phone: '',
                                    workingHours: '',
                                    ownerId: '',
                                    photos: const [],
                                    bookedDates: const [],
                                    rating: 5.0,
                                  ),
                                );

                                return BookingCard(
                                  key: ValueKey(booking.id),
                                  booking: booking,
                                  restaurant: restaurant,
                                  onBookingUpdated: () {
                                    context
                                        .read<ProfileBloc>()
                                        .add(LoadUserData());
                                  },
                                );
                              },
                            ),

                      // Избранное
                      state.favorites.isEmpty
                          ? const Center(
                              child: Text('Пока нет избранных ресторанов'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: state.favorites.length,
                              itemBuilder: (context, index) {
                                return FavoriteCard(
                                  favorite: state.favorites[index],
                                );
                              },
                            ),
                    ],
                  ),
                ),
            ],
          ),
          bottomNavigationBar: BottomAppBar(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: OutlinedButton(
                onPressed: () {
                  context.read<ProfileBloc>().add(SignOut());
                },
                child: const Text('Выйти из аккаунта'),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return EditProfileDialog(
          nameController: _nameController,
          phoneController: _phoneController,
          onSave: () {
            final name = _nameController.text.trim();
            final phone = _phoneController.text.trim();

            // Можно добавить здесь базовую валидацию, если нужно
            if (name.isEmpty || phone.length < 10) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Проверьте введённые данные')),
              );
              return;
            }

            context.read<ProfileBloc>().add(
                  UpdateProfile(name: name, phone: phone),
                );

            Navigator.pop(dialogContext);
          },
        );
      },
    );
  }

  void _navigateToSellerDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SellerDashboardPage(),
      ),
    );
  }
}
