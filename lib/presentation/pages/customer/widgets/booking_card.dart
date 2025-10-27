// ✅ Обновлённый UI | BookingCard
// Стиль: Светлый классический | Цвет: #1A365D

import 'package:flutter/material.dart';
import 'package:restauran/data/models/restaurant.dart';
import 'package:url_launcher/url_launcher_string.dart';
import '../../../../data/models/booking.dart';
import '../../../../data/models/restaurant_category.dart';
import '../../../../data/models/restaurant_extra.dart';
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
  RestaurantCategory? _restaurantCategory;
  List<RestaurantExtra> _selectedExtras = [];
  // ignore: unused_field
  bool _isLoadingCategory = true;

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

  bool _hasExtrasChanged(List<int>? oldExtras, List<int>? newExtras) {
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
      setState(() => _isLoadingCategory = false);
      return;
    }

    try {
      final restaurantService = RestaurantService();
      final category = await restaurantService
          .getRestaurantCategoryById(widget.booking.restaurantCategoryId!);

      if (!mounted) return;
      setState(() {
        _restaurantCategory = category;
        _isLoadingCategory = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCategory = false);
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

      final selected = allExtras
          .where((extra) => widget.booking.selectedExtraIds!.contains(extra.id))
          .toList();

      if (!mounted) return;
      setState(() => _selectedExtras = selected);
    } catch (e) {
      if (!mounted) return;
      setState(() => _selectedExtras = []);
    }
  }

  bool _canEditBooking() {
    final now = DateTime.now();
    final difference = widget.booking.bookingTime.difference(now).inDays;
    return difference > 1;
  }

  String _calculateBookingPrice() {
    double total = 0;

    if (_restaurantCategory != null && _restaurantCategory!.priceRange > 0) {
      total = _restaurantCategory!.priceRange * widget.booking.guests;
    }

    for (var extra in _selectedExtras) {
      total += extra.price;
    }

    if (total > 0) {
      return '${total.toStringAsFixed(0)} ₸';
    }
    return 'Цена не указана';
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
            // --- Заголовок
            Text(
              widget.restaurant.name,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.booking.bookingTime.day}.${widget.booking.bookingTime.month}.${widget.booking.bookingTime.year}  '
              'в ${widget.booking.bookingTime.hour}:${widget.booking.bookingTime.minute.toString().padLeft(2, '0')}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 12),

            // --- Guests
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
                          builder: (_) => BookingPage(
                            restaurantId: widget.booking.restaurantId,
                            restaurantName: widget.restaurant.name,
                            existingBooking: widget.booking,
                          ),
                        ),
                      );
                      widget.onBookingUpdated?.call();
                    },
                    icon: const Icon(Icons.edit, size: 16, color: primaryColor),
                    label: const Text('Изменить',
                        style: TextStyle(color: primaryColor)),
                  )
                else
                  const Text('Изменение недоступно',
                      style: TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 12),

            // --- Price box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.05),
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
                  Text(_calculateBookingPrice(),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: () => launchUrlString(
                    'https://2gis.kz/search/${widget.restaurant.location}'),
                icon:
                    const Icon(Icons.location_on_outlined, color: primaryColor),
                label: Text(widget.restaurant.location ?? '',
                    style: const TextStyle(color: primaryColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
