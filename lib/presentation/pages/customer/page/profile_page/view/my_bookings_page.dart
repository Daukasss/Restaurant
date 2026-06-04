import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/models/restaurant.dart';
import 'package:restauran/theme/app_colors.dart';
import '../../../widgets/booking_card.dart';
import '../bloc/profil_bloc.dart';
import '../bloc/profil_event.dart';
import '../bloc/profil_state.dart';

class MyBookingsPage extends StatelessWidget {
  const MyBookingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textMain),
        title: const Text(
          'Мои бронирования',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          if (state.bookings.isEmpty) {
            return const _EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Пока нет бронирований',
              message: 'Забронируйте столик — он появится здесь.',
            );
          }

          return RefreshIndicator.adaptive(
            color: AppColors.primary,
            onRefresh: () async {
              context.read<ProfileBloc>().add(LoadUserData());
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
                    context.read<ProfileBloc>().add(LoadUserData());
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.08),
              ),
              child: Icon(icon, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.textSub),
            ),
          ],
        ),
      ),
    );
  }
}
