import 'package:flutter/material.dart';
import 'package:restauran/data/services/abstract/service_export.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../data/models/restaurant_category.dart';
import '../../../../../../data/models/restaurant_extra.dart';
import '../../../../../../data/services/service_lacator.dart';
import '../../../../../../theme/aq_toi.dart';

class BookingDetailBottomSheet extends StatelessWidget {
  final Map<String, dynamic> booking;
  final double? pricePerGuest;
  final int? sumPeople;
  final Function(int, String) onUpdateStatus;

  const BookingDetailBottomSheet({
    super.key,
    required this.booking,
    required this.pricePerGuest,
    required this.sumPeople,
    required this.onUpdateStatus,
  });

  Future<List<String>> _fetchExtrasNames(List<dynamic>? extraIds) async {
    if (extraIds == null || extraIds.isEmpty) {
      return [];
    }

    try {
      ;
      final response = await supabase
          .from('restaurant_extras')
          .select('name')
          .inFilter('id', extraIds);

      return response.map((item) => item['name'] as String).toList();
    } catch (e) {
      print('Error fetching extras names: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingTime = booking['booking_time'] != null
        ? DateTime.tryParse(booking['booking_time']) ?? DateTime.now()
        : DateTime.now();
    final menuServise = getIt<AbstractMenuService>();
    final restaurantService = getIt<AbstractRestaurantService>();

    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Детали бронирования',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
                'ID Бронирование', Text('#${booking['id'] ?? 'N/A'}')),
            _buildDetailRow('Заказчик', Text(booking['name'] ?? 'Не указан')),
            _buildDetailRow(
              'Телефон',
              GestureDetector(
                child: Text(
                  booking['phone'] ?? 'Не указан',
                  style: const TextStyle(color: Colors.blue),
                ),
                onTap: () {
                  final phone = booking['phone'];
                  if (phone != null) {
                    launchUrl(Uri.parse('tel:$phone'));
                  }
                },
              ),
            ),
            _buildDetailRow('Кол. Гостей', Text('${booking['guests'] ?? 0}')),
            _buildDetailRow(
              'Время',
              Text(
                '${bookingTime.day}/${bookingTime.month}/${bookingTime.year} в ${bookingTime.hour}:${bookingTime.minute.toString().padLeft(2, '0')}',
              ),
            ),
            if (booking['restaurant_category_id'] != null)
              FutureBuilder<RestaurantCategory?>(
                future: restaurantService.getRestaurantCategoryById(
                  int.parse(booking['restaurant_category_id'].toString()),
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return _buildDetailRow(
                      'Категория',
                      Text(
                        snapshot.data!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    );
                  }

                  return const SizedBox();
                },
              ),
            _buildDetailRow(
              'Статус',
              Text(
                _getStatusText(booking['status'] ?? 'pending'),
                style: TextStyle(
                  color: _getStatusColor(booking['status'] ?? 'pending'),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FutureBuilder(
              future: Future.wait([
                booking['restaurant_category_id'] != null
                    ? restaurantService.getRestaurantCategoryById(
                        int.parse(booking['restaurant_category_id'].toString()),
                      )
                    : Future.value(null),
                booking['selected_extras'] != null
                    ? restaurantService
                        .getRestaurantExtras(booking['restaurant_id'])
                    : Future.value([]),
              ]),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return _buildDetailRow('Цена', const Text('Загрузка...'));
                }

                final category = snapshot.data![0] as RestaurantCategory?;
                final allExtras = snapshot.data![1] as List<RestaurantExtra>;

                double total = 0;
                final guests = booking['guests'] ?? 0;

                // Цена категории
                if (category != null && category.priceRange > 0) {
                  total += category.priceRange * guests;
                }

                // Сумма доп. опций
                if (booking['selected_extras'] != null) {
                  final selectedExtras = allExtras.where((extra) =>
                      (booking['selected_extras'] as List).contains(extra.id));
                  for (var extra in selectedExtras) {
                    total += extra.price;
                  }
                }

                return _buildDetailRow(
                  'Цена',
                  Text(total > 0
                      ? '${total.toStringAsFixed(0)} Тг'
                      : 'Цена не указана'),
                );
              },
            ),
            _buildDetailRow('Кол. столов', Text(_calculateStule(booking))),
            _buildDetailRow(
              'Доп Опций',
              FutureBuilder<List<String>>(
                future: _fetchExtrasNames(
                    booking['selected_extras'] as List<dynamic>?),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Text('Ошибка загрузки');
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('Нет');
                  }

                  return Text(snapshot.data!.join(', '));
                },
              ),
            ),
            const SizedBox(height: 16),
            if (booking['menu_selections'] != null)
              FutureBuilder<List<Map<String, dynamic>>>(
                future: menuServise.fetchMenuSelections(booking),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox();
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Выбранные блюда:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...snapshot.data!.map((item) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['category'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '• ${item['item'] ?? ''}',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, Widget valueWidget) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(child: valueWidget),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Прошедший';
      case 'pending':
        return 'Ожидается';
      case 'canceled':
        return 'Отменен';
      default:
        return status;
    }
  }

  String _calculateStule(Map<String, dynamic> booking) {
    if (sumPeople == null || sumPeople == 0) return 'N/A';
    final guests = booking['guests'] ?? 0;
    final total = (guests / sumPeople!).ceil();
    return '$total';
  }
}
