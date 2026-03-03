// ✅ Обновлённый UI | BookingCard
// Стиль: Светлый классический | Цвет: #1A365D
// Версия 2.0: Поддержка временных интервалов

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
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../data/models/booking.dart';

import '../../../../data/services/restaurant_service.dart';
import '../page/booking_page/view/booking_page.dart';

class BookingCard extends StatefulWidget {
  final Booking booking;
  final Restaurant restaurant;
  final VoidCallback? onBookingUpdated;

  const BookingCard({
    super.key,
    required this.booking,
    required this.restaurant,
    this.onBookingUpdated,
  });

  @override
  State<BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<BookingCard> {
  @override
  void initState() {
    super.initState();
    _loadRestaurantCategory();
    _loadSelectedExtras();
  }

  @override
  void didUpdateWidget(BookingCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.booking.id != widget.booking.id ||
        oldWidget.booking.guests != widget.booking.guests ||
        oldWidget.booking.restaurantCategoryId !=
            widget.booking.restaurantCategoryId ||
        _hasExtrasChanged(oldWidget.booking.selectedExtraIds,
            widget.booking.selectedExtraIds)) {
      _loadRestaurantCategory();
      _loadSelectedExtras();
    }
  }

  bool _hasExtrasChanged(List<String>? oldExtras, List<String>? newExtras) {
    if (oldExtras == null && newExtras == null) return false;
    if (oldExtras == null || newExtras == null) return true;
    if (oldExtras.length != newExtras.length) return true;

    for (int i = 0; i < oldExtras.length; i++) {
      if (oldExtras[i] != newExtras[i]) return true;
    }
    return false;
  }

  Future<void> _loadRestaurantCategory() async {
    if (widget.booking.restaurantCategoryId == null) {
      if (!mounted) return;
      return;
    }

    try {
      final restaurantService = RestaurantService();
      await restaurantService
          .getRestaurantCategoryById(widget.booking.restaurantCategoryId!);

      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
    }
  }

  Future<void> _loadSelectedExtras() async {
    if (widget.booking.selectedExtraIds == null ||
        widget.booking.selectedExtraIds!.isEmpty) {
      return;
    }

    try {
      final restaurantService = RestaurantService();
      final allExtras = await restaurantService.getRestaurantExtras(
        widget.booking.restaurantId,
      );

      allExtras
          .where((extra) => widget.booking.selectedExtraIds!.contains(extra.id))
          .toList();

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;
    }
  }

  bool _canEditBooking() {
    final now = DateTime.now();
    // Используем bookingDate вместо bookingTime
    final difference = widget.booking.bookingDate.difference(now).inDays;
    return difference > 1;
  }

  // String _calculateBookingPrice() {
  //   double total = 0;

  //   if (_restaurantCategory != null && _restaurantCategory!.priceRange > 0) {
  //     total = _restaurantCategory!.priceRange * widget.booking.guests;
  //   }

  //   for (var extra in _selectedExtras) {
  //     total += extra.price;
  //   }

  //   if (total > 0) {
  //     return '${total.toStringAsFixed(0)} ₸';
  //   }
  //   return 'Цена не указана';
  // }

  // НОВЫЙ метод: форматирование времени
  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // НОВЫЙ метод: форматирование даты
  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF1A365D);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Заголовок с именем ресторана
            // Row(
            //   children: [
            //     Expanded(
            //       child: Text(
            //         widget.restaurant.name,
            //         style: const TextStyle(
            //             fontSize: 18,
            //             fontWeight: FontWeight.w600,
            //             color: primaryColor),
            //       ),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 8),

            // --- Дата и время (ОБНОВЛЕНО)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16, color: primaryColor.withOpacity(0.7)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatDate(widget.booking.bookingDate),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time,
                                size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${_formatTime(widget.booking.startTime)} - ${_formatTime(widget.booking.endTime)}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // // --- Категория (если есть)
            // if (_restaurantCategory != null) ...[
            //   Row(
            //     children: [
            //       Icon(Icons.category_outlined,
            //           size: 16, color: primaryColor.withOpacity(0.7)),
            //       const SizedBox(width: 6),
            //       Text(
            //         _restaurantCategory!.name,
            //         style: TextStyle(
            //           fontSize: 13,
            //           color: Colors.grey[700],
            //           fontWeight: FontWeight.w500,
            //         ),
            //       ),
            //     ],
            //   ),
            //   const SizedBox(height: 12),
            // ],

            // --- Количество гостей и кнопка редактирования
            Row(
              children: [
                const Icon(Icons.people_alt_outlined,
                    size: 18, color: primaryColor),
                const SizedBox(width: 6),
                Text('${widget.booking.guests} гостей',
                    style: const TextStyle(fontSize: 14, color: primaryColor)),
                const Spacer(),
                if (_canEditBooking() &&
                    widget.booking.status.toLowerCase() != 'cancelled')
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider(
                            create: (context) => BookingBloc(
                              bookingService: getIt<AbstractBookingService>(),
                              restaurantService:
                                  getIt<AbstractRestaurantService>(),
                              menuService: getIt<AbstractMenuService>(),
                              closureService:
                                  getIt<AbstractCategoryClosureService>(),
                            ),
                            child: BookingPage(
                              restaurantId: widget.booking.restaurantId,
                              restaurantName: widget.restaurant.name,
                              bookingId: widget.booking.id,
                              existingBooking: widget.booking,
                            ),
                          ),
                        ),
                      );
                      widget.onBookingUpdated?.call();
                    },
                    icon: const Icon(Icons.edit, size: 16, color: primaryColor),
                    label: const Text('Изменить',
                        style: TextStyle(color: primaryColor, fontSize: 13)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                    ),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Нельзя изменить',
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // --- Блок с ценой
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Общая стоимость:',
                      style: TextStyle(
                          fontSize: 14,
                          color: primaryColor,
                          fontWeight: FontWeight.w500)),
                  Text(
                      widget.booking.totalPrice != null
                          ? '${widget.booking.totalPrice!.toStringAsFixed(0)} ₸'
                          : 'Цена не указана',
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: primaryColor)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // --- Адрес ресторана
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => launchUrlString(
                      'https://2gis.kz/search/${widget.restaurant.location}'),
                  icon: const Icon(Icons.location_on_outlined,
                      color: primaryColor, size: 18),
                  label: Text(
                    widget.restaurant.location ?? '',
                    style: const TextStyle(
                      color: primaryColor,
                      fontSize: 13,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final id = widget.restaurant.id;
                    if (id != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RestaurantDetailPage(
                            restaurantId: id,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    widget.restaurant.name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: primaryColor),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
