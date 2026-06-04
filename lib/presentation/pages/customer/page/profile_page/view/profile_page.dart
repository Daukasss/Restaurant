import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/models/profile.dart';
import 'package:restauran/data/services/abstract/abstract_auth_services.dart';
import 'package:restauran/data/services/service_locator.dart';
import 'package:restauran/data/services/favorite_service.dart';
import 'package:restauran/data/services/profile_service.dart';
import 'package:restauran/presentation/pages/customer/page/profile_page/view/about_page.dart';
import 'package:restauran/presentation/pages/customer/page/profile_page/view/help_page.dart';
import 'package:restauran/theme/app_colors.dart';
import '../../../../../../data/services/booking_service.dart';
import '../../../../../../data/services/restaurant_service.dart';
import '../../../../auth/pages/login_page/view/login_page.dart';
import '../../../../seller/page/seller_dashboard/view/seller_dashboard_page.dart';
import '../../../widgets/profile_menu_tile.dart';
import '../bloc/profil_bloc.dart';
import '../bloc/profil_event.dart';
import '../bloc/profil_state.dart';
// import 'about_page.dart';
import 'edit_profile_page.dart';
import 'favorites_page.dart';
// import 'help_page.dart';
import 'my_bookings_page.dart';
import 'settings_page.dart';

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
        authService: getIt<AbstractAuthServices>(),
      )..add(LoadUserData()),
      child: const ProfileView(),
    );
  }
}

class ProfileView extends StatelessWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (!state.isAuthenticated) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading || state.profile == null) {
          return const Scaffold(
            backgroundColor: AppColors.surface,
            body: Center(
              child: CircularProgressIndicator.adaptive(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
            ),
          );
        }

        final profile = state.profile!;
        final bloc = context.read<ProfileBloc>();

        return Scaffold(
          backgroundColor: AppColors.surface,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                // --- Заголовок страницы
                const Text(
                  'Профиль',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textMain,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // --- Карточка пользователя
                _ProfileSummaryCard(profile: profile),
                const SizedBox(height: 24),

                // --- Аккаунт
                ProfileMenuGroup(
                  label: 'Аккаунт',
                  children: [
                    ProfileMenuTile(
                      icon: Icons.edit_outlined,
                      title: 'Редактировать профиль',
                      // subtitle: 'Фото, имя, телефон, пароль',
                      onTap: () => _open(
                        context,
                        bloc,
                        const EditProfilePage(),
                      ),
                    ),
                    // if (profile.isSeller)
                    //   ProfileMenuTile(
                    //     icon: Icons.storefront_outlined,
                    //     title: 'Кабинет заведения',
                    //     // subtitle: 'Управление рестораном',
                    //     onTap: () => Navigator.push(
                    //       context,
                    //       MaterialPageRoute(
                    //         builder: (_) => const SellerDashboardPage(),
                    //       ),
                    //     ),
                    //   ),
                  ],
                ),

                // --- Активность (только для пользователя)
                if (profile.isUser) ...[
                  const SizedBox(height: 20),
                  ProfileMenuGroup(
                    label: 'Активность',
                    children: [
                      ProfileMenuTile(
                        icon: Icons.event_available_outlined,
                        title: 'Мои бронирования',
                        subtitle: '${state.bookings.length}',
                        onTap: () => _open(
                          context,
                          bloc,
                          const MyBookingsPage(),
                        ),
                      ),
                      ProfileMenuTile(
                        icon: Icons.favorite_border_rounded,
                        title: 'Избранное',
                        subtitle: '${state.favorites.length}',
                        onTap: () => _open(
                          context,
                          bloc,
                          const FavoritesPage(),
                        ),
                      ),
                    ],
                  ),
                ],

                // --- Прочее
                const SizedBox(height: 20),
                ProfileMenuGroup(
                  label: 'Прочее',
                  children: [
                    ProfileMenuTile(
                      icon: Icons.settings_outlined,
                      title: 'Настройки',
                      onTap: () => _open(
                        context,
                        bloc,
                        const SettingsPage(),
                      ),
                    ),
                    ProfileMenuTile(
                      icon: Icons.info_outline_rounded,
                      title: 'О приложении',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutPage()),
                      ),
                    ),
                    ProfileMenuTile(
                      icon: Icons.support_agent_outlined,
                      title: 'Помощь',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpPage()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Открывает страницу, прокидывая существующий ProfileBloc.
  void _open(BuildContext context, ProfileBloc bloc, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: bloc, child: page),
      ),
    );
  }
}

class _ProfileSummaryCard extends StatelessWidget {
  final Profile profile;

  const _ProfileSummaryCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.10),
            ),
            alignment: Alignment.center,
            child: Text(
              _initials(profile.name),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.name.isEmpty ? 'Без имени' : profile.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  profile.phone.isEmpty ? 'Телефон не указан' : profile.phone,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSub,
                  ),
                ),
                // const SizedBox(height: 6),
                // Container(
                //   padding:
                //       const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                //   decoration: BoxDecoration(
                //     color: AppColors.accent.withOpacity(0.12),
                //     borderRadius: BorderRadius.circular(20),
                //   ),
                //   child: Text(
                //     profile.isSeller ? 'Владелец' : 'Гость',
                //     style: const TextStyle(
                //       fontSize: 11.5,
                //       fontWeight: FontWeight.w600,
                //       color: AppColors.accent,
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }
}
