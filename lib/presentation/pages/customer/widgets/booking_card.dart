// Минималистичный редизайн карточки бронирования.
// Палитра: AppColors. Логика (изменение/удаление/переходы) сохранена.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/models/restaurant.dart';
import 'package:restauran/data/services/abstract/abstract_booking_service.dart';
import 'package:restauran/data/services/abstract/abstract_category_closure_service.dart';
import 'package:restauran/data/services/abstract/abstract_menu_service.dart';
import 'package:restauran/data/services/abstract/abstract_restaurant_service.dart';
import 'package:restauran/data/services/service_locator.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/view/restaurant_detail_page.dart';
import 'package:restauran/theme/app_colors.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../data/models/booking.dart';
import '../page/booking_page/view/booking_page.dart';

class BookingCard extends StatelessWidget {
  final Booking booking;
  final Restaurant restaurant;
  final VoidCallback? onBookingUpdated;

  const BookingCard({
    super.key,
    required this.booking,
    required this.restaurant,
    this.onBookingUpdated,
  });

  bool get _canEdit {
    final diff = booking.bookingDate.difference(DateTime.now()).inDays;
    final cancelled = booking.status.toLowerCase() == 'cancelled';
    return diff > 1 && !cancelled;
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _formatDate(DateTime d) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Удалить бронирование?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
            fontSize: 17,
          ),
        ),
        content: const Text(
          'Это действие нельзя отменить.',
          style: TextStyle(fontSize: 14, color: AppColors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await getIt<AbstractBookingService>().deleteBooking(booking.id!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Бронирование удалено'),
          backgroundColor: AppColors.success,
        ),
      );
      onBookingUpdated?.call();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Ошибка удаления: $e'),
            backgroundColor: AppColors.danger),
      );
    }
  }

  Future<void> _edit(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (context) => BookingBloc(
            bookingService: getIt<AbstractBookingService>(),
            restaurantService: getIt<AbstractRestaurantService>(),
            menuService: getIt<AbstractMenuService>(),
            closureService: getIt<AbstractCategoryClosureService>(),
          ),
          child: BookingPage(
            restaurantId: booking.restaurantId,
            restaurantName: restaurant.name,
            bookingId: booking.id,
            existingBooking: booking,
          ),
        ),
      ),
    );
    onBookingUpdated?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Заголовок: ресторан + статус
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      final id = restaurant.id;
                      if (id != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                RestaurantDetailPage(restaurantId: id),
                          ),
                        );
                      }
                    },
                    child: Text(
                      restaurant.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMain,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(canEdit: _canEdit),
              ],
            ),
            const SizedBox(height: 14),

            // --- Дата / время / гости
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Дата',
                    value: _formatDate(booking.bookingDate),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InfoTile(
                    icon: Icons.access_time_rounded,
                    label: 'Время',
                    value:
                        '${_formatTime(booking.startTime)}–${_formatTime(booking.endTime)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoTile(
              icon: Icons.people_alt_outlined,
              label: 'Гостей',
              value: '${booking.guests}',
              fullWidth: true,
            ),

            const SizedBox(height: 14),

            // --- Стоимость
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Стоимость',
                      style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSub,
                          fontWeight: FontWeight.w500)),
                  Text(
                    booking.totalPrice != null
                        ? '${booking.totalPrice!.toStringAsFixed(0)} ₸'
                        : '—',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- Адрес
            InkWell(
              onTap: () => launchUrlString(
                  'https://2gis.kz/search/${restaurant.location}'),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        size: 18, color: AppColors.accent),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        restaurant.location ?? 'Адрес не указан',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.accent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // --- Действия
            if (_canEdit) ...[
              const Divider(height: 24, color: AppColors.divider),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _edit(context),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Изменить'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _delete(context),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Удалить'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.danger,
                        side: BorderSide(
                            color: AppColors.danger.withOpacity(0.4)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool canEdit;
  const _StatusChip({required this.canEdit});

  @override
  Widget build(BuildContext context) {
    final color = canEdit ? AppColors.success : AppColors.textSub;
    final text = canEdit ? 'Активно' : 'Скоро';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool fullWidth;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSub)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain)),
            ],
          ),
        ],
      ),
    );
  }
}
