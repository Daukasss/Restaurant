import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/models/booking.dart';
import 'package:restauran/data/models/restaurant_category.dart';
import 'package:restauran/data/services/abstract/abstract_category_closure_service.dart';
import 'package:restauran/data/services/abstract/service_export.dart';
import 'package:restauran/data/services/service_locator.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/view/booking_page.dart';
import 'package:url_launcher/url_launcher.dart';

class BookingDetailPage extends StatelessWidget {
  final Map<String, dynamic> booking;
  final double? pricePerGuest;
  final int? sumPeople;
  final Function(String, String)? onUpdateStatus;
  final VoidCallback? onBookingDeleted;

  const BookingDetailPage({
    super.key,
    required this.booking,
    this.pricePerGuest,
    this.sumPeople,
    this.onUpdateStatus,
    this.onBookingDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    DateTime bookingDate = _parseBookingDate(booking['booking_date']);
    final startTime = _formatTime(booking['start_time']);
    final endTime = _formatTime(booking['end_time']);

    final status = booking['status']?.toLowerCase() ?? 'pending';
    final statusText = _getStatusText(status);
    final statusColor = _getStatusColor(status, colorScheme);

    // Офлайн-режим: данные уже есть в Map (обогащены при онлайн-загрузке)
    final String? cachedCategoryName = booking['_category_name']?.toString();
    final List<String> cachedExtrasNames =
        _parseStringList(booking['_extras_names']);
    final List<Map<String, String>> cachedMenuItems =
        _parseMenuItems(booking['_menu_items']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Детали брони'),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'edit') {
                await _navigateToEdit(context);
              } else if (value == 'delete') {
                await _confirmAndDelete(context);
              }
            },
            itemBuilder: (context) {
              final isSellerBooking =
                  booking['is_seller_booking'] as bool? ?? false;
              return [
                if (isSellerBooking)
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 20),
                        SizedBox(width: 12),
                        Text('Редактировать'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline,
                          size: 20, color: Colors.red[700]),
                      const SizedBox(width: 12),
                      Text('Удалить', style: TextStyle(color: Colors.red[700])),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Карточка: основная информация ──────────────
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking['name'] ?? 'Клиент не указан',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              GestureDetector(
                                onTap: () {
                                  final phone = booking['phone']?.toString();
                                  if (phone != null && phone.isNotEmpty) {
                                    launchUrl(Uri.parse('tel:$phone'));
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(Icons.phone,
                                        size: 18, color: colorScheme.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      booking['phone'] ?? '—',
                                      style: TextStyle(
                                        color: colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Chip(
                          label: Text(statusText),
                          backgroundColor: statusColor.withOpacity(0.15),
                          labelStyle: TextStyle(
                              color: statusColor, fontWeight: FontWeight.w600),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    _DetailRow(
                      icon: Icons.group,
                      label: 'Гостей',
                      value: '${booking['guests'] ?? 0}',
                    ),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: 'Дата',
                      value:
                          '${bookingDate.day} ${_monthRu(bookingDate.month)} ${bookingDate.year}',
                    ),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: 'Время',
                      value: '$startTime – $endTime',
                    ),
                    _DetailRow(
                      icon: Icons.attach_money,
                      label: 'Итоговая цена',
                      value: '${booking['totalPrice'] ?? 0} ₸',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Карточка: детали зала ───────────────────────
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Категория зала
                    // Если есть кэшированное имя — показываем сразу без FutureBuilder
                    if (cachedCategoryName != null &&
                        cachedCategoryName.isNotEmpty)
                      _DetailRow(
                        icon: Icons.category,
                        label: 'Категория',
                        value: cachedCategoryName,
                      )
                    else if (booking['restaurant_category_id'] != null)
                      // Фоллбэк: онлайн-запрос если кэш пустой
                      FutureBuilder<RestaurantCategory?>(
                        future: getIt<AbstractRestaurantService>()
                            .getRestaurantCategoryById(
                                booking['restaurant_category_id']),
                        builder: (context, snap) {
                          if (snap.hasData && snap.data != null) {
                            return _DetailRow(
                              icon: Icons.category,
                              label: 'Категория',
                              value: snap.data!.name,
                            );
                          }
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const _DetailRowSkeleton(label: 'Категория');
                          }
                          return const SizedBox.shrink();
                        },
                      ),

                    // Количество столов (вычисляется локально — всегда работает)
                    _DetailRow(
                      icon: Icons.table_bar,
                      label: 'Столов',
                      value: _calculateTables(booking, sumPeople),
                    ),

                    // Доп. опции (extras)
                    if (cachedExtrasNames.isNotEmpty)
                      // ✅ Из кэша — без сети
                      _ExtrasSection(
                        theme: theme,
                        names: cachedExtrasNames,
                      )
                    else if (booking['selected_extras']?.isNotEmpty == true)
                      // Фоллбэк: онлайн-запрос если кэш пустой
                      FutureBuilder<List<String>>(
                        future: _fetchExtrasNames(booking['selected_extras']),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const _DetailRowSkeleton(
                                label: 'Доп. опции');
                          }
                          if (!snap.hasData || snap.data!.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return _ExtrasSection(
                            theme: theme,
                            names: snap.data!,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Карточка: блюда ─────────────────────────────
            if (cachedMenuItems.isNotEmpty)
              // ✅ Из кэша — без сети
              _MenuCard(theme: theme, items: cachedMenuItems)
            else if (booking['menu_selections'] != null)
              // Фоллбэк: онлайн-запрос если кэш пустой
              FutureBuilder<List<Map<String, dynamic>>>(
                future:
                    getIt<AbstractMenuService>().fetchMenuSelections(booking),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (!snap.hasData || snap.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return _MenuCard(
                    theme: theme,
                    items: snap.data!
                        .map((i) => {
                              'category': (i['category'] ?? '—').toString(),
                              'item': (i['item'] ?? '—').toString(),
                            })
                        .toList(),
                  );
                },
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // ── Редактирование и удаление ────────────────────

  Future<void> _navigateToEdit(BuildContext context) async {
    final bookingId = booking['id']?.toString();
    final restaurantId = booking['restaurant_id']?.toString() ?? '';
    final restaurantName = booking['restaurant_name']?.toString() ?? 'Ресторан';

    // Восстанавливаем Booking из Map для передачи в BookingPage
    final existingBooking = _mapToBooking();
    if (existingBooking == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Не удалось открыть редактирование')),
      );
      return;
    }

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
            restaurantId: restaurantId,
            restaurantName: restaurantName,
            bookingId: bookingId,
            existingBooking: existingBooking,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Удалить бронирование?'),
        content: const Text(
            'Это действие нельзя отменить. Бронирование будет удалено навсегда.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final bookingId = booking['id']?.toString();
    if (bookingId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .delete();

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Бронирование удалено')),
      );
      onBookingDeleted?.call();
      Navigator.pop(context);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка при удалении: $e')),
      );
    }
  }

  /// Конвертируем Map обратно в объект Booking для передачи в BookingPage
  Booking? _mapToBooking() {
    try {
      final rawDate = booking['booking_date'];
      DateTime bookingDate;
      if (rawDate is Timestamp) {
        bookingDate = rawDate.toDate();
      } else if (rawDate is String) {
        bookingDate = DateTime.parse(rawDate);
      } else {
        return null;
      }

      TimeOfDay _parseTime(String? t) {
        final parts = (t ?? '00:00').split(':');
        return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }

      final rawExtras = booking['selected_extras'];
      List<String>? extras;
      if (rawExtras is List) {
        extras = rawExtras.map((e) => e.toString()).toList();
      }

      final rawMenu = booking['menu_selections'];
      Map<String, String> menuSelections = {};
      if (rawMenu is Map) {
        rawMenu.forEach((k, v) => menuSelections[k.toString()] = v.toString());
      }

      return Booking(
        booking['restaurant_id']?.toString() ?? '',
        id: booking['id']?.toString(),
        userId: booking['user_id']?.toString(),
        name: booking['name']?.toString() ?? '',
        phone: booking['phone']?.toString() ?? '',
        guests: (booking['guests'] as num?)?.toInt() ?? 0,
        bookingDate: bookingDate,
        startTime: _parseTime(booking['start_time']?.toString()),
        endTime: _parseTime(booking['end_time']?.toString()),
        status: booking['status']?.toString() ?? 'pending',
        menu_selections: menuSelections,
        totalPrice: (booking['totalPrice'] as num?)?.toInt(),
        restaurantCategoryId: booking['restaurant_category_id']?.toString(),
        selectedExtraIds: extras,
        categorySection: (booking['category_section'] as num?)?.toInt(),
        isSellerBooking: booking['is_seller_booking'] as bool? ?? false,
      );
    } catch (_) {
      return null;
    }
  }

  // ── Парсинг кэшированных данных ──────────────────

  List<String> _parseStringList(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return [];
  }

  List<Map<String, String>> _parseMenuItems(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw.map((e) {
        if (e is Map) {
          return {
            'category': (e['category'] ?? '—').toString(),
            'item': (e['item'] ?? '—').toString(),
          };
        }
        return {'category': '—', 'item': '—'};
      }).toList();
    }
    return [];
  }

  // ── Вспомогательные методы ───────────────────────

  DateTime _parseBookingDate(dynamic data) {
    if (data is Timestamp) return data.toDate();
    if (data is String) return DateTime.tryParse(data) ?? DateTime.now();
    return DateTime.now();
  }

  String _formatTime(String? time) => time ?? '—';

  String _monthRu(int month) {
    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек'
    ];
    return months[month - 1];
  }

  Color _getStatusColor(String status, ColorScheme scheme) {
    switch (status) {
      case 'completed':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Прошедшее';
      case 'pending':
        return 'Ожидается';
      case 'cancelled':
        return 'Отменено';
      default:
        return status;
    }
  }

  String _calculateTables(Map<String, dynamic> booking, int? sumPeople) {
    if (sumPeople == null || sumPeople <= 0) return '—';
    final guests = booking['guests'] as int? ?? 0;
    return (guests / sumPeople).ceil().toString();
  }

  Future<List<String>> _fetchExtrasNames(List<dynamic>? ids) async {
    if (ids == null || ids.isEmpty) return [];
    final firestore = FirebaseFirestore.instance;
    final List<String> names = [];
    for (var id in ids) {
      final doc = await firestore
          .collection('restaurant_extras')
          .doc(id.toString())
          .get();
      if (doc.exists) {
        names.add(doc.data()?['name'] ?? '');
      }
    }
    return names;
  }
}

// ── Переиспользуемые виджеты ─────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String value;

  const _DetailRow({
    this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: Colors.grey[700]),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Скелетон-плейсхолдер пока данные грузятся онлайн
class _DetailRowSkeleton extends StatelessWidget {
  final String label;
  const _DetailRowSkeleton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 14)),
        ],
      ),
    );
  }
}

/// Секция доп. опций
class _ExtrasSection extends StatelessWidget {
  final ThemeData theme;
  final List<String> names;

  const _ExtrasSection({required this.theme, required this.names});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text('Доп. опции', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        ...names.map((name) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(name),
                ],
              ),
            )),
      ],
    );
  }
}

/// Карточка выбранных блюд
class _MenuCard extends StatelessWidget {
  final ThemeData theme;
  final List<Map<String, String>> items;

  const _MenuCard({required this.theme, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Выбранные блюда', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            ...items.map((item) => _DetailRow(
                  label: item['category'] ?? '—',
                  value: item['item'] ?? '—',
                )),
          ],
        ),
      ),
    );
  }
}
