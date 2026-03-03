import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:restauran/presentation/widgets/result_diolog.dart';
import 'package:restauran/theme/offline_banner.dart';

import '../bloc/booking_managment_bloc_bloc.dart';
import '../bloc/booking_managment_bloc_event.dart';
import '../bloc/booking_managment_bloc_state.dart';
import '../widgets/booking_detail_bottom_sheet.dart';
import '../widgets/booking_list_item.dart';

class BookingManagementPage extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;

  const BookingManagementPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BookingBloc()..add(LoadBookings(restaurantId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Бронирования - $restaurantName'),
        ),
        body: BlocConsumer<BookingBloc, BookingState>(
          listener: (context, state) {
            if (state is BookingError) {
              // Сетевая ошибка — менее «страшный» снэкбар
              if (state.isNetworkError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.wifi_off, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(child: Text(state.message)),
                      ],
                    ),
                    backgroundColor: Colors.orange[800],
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else {
                showResultDialog(
                  context: context,
                  isSuccess: false,
                  title: 'Ошибка',
                  message: state.message,
                );
              }
            } else if (state is BookingStatusUpdated) {
              showResultDialog(
                context: context,
                isSuccess: true,
                title: 'Успешно',
                message: 'Статус обновлен!',
              );
            }
          },
          builder: (context, state) {
            if (state is BookingLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is BookingOfflineEmpty) {
              return _buildOfflineEmptyState(context);
            }

            if (state is BookingLoaded) {
              return _buildLoadedBody(context, state);
            }

            if (state is BookingError) {
              return Center(child: Text(state.message));
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildLoadedBody(BuildContext context, BookingLoaded state) {
    return Column(
      children: [
        OfflineBanner(
          isOffline: state.isOffline,
          lastUpdatedText: state.cacheTime != null
              ? _formatCacheTime(state.cacheTime!)
              : null,
        ),
        _buildStatusFilter(context, state),
        _buildDateFilter(context, state),
        const SizedBox(height: 4),
        // ✅ Expanded — прямой child Column
        Expanded(
          child: state.filteredBookings.isEmpty
              ? _buildEmptyBookingsMessage()
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<BookingBloc>().add(LoadBookings(restaurantId));
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: state.filteredBookings.length,
                    itemBuilder: (context, index) {
                      final booking = state.filteredBookings[index];
                      return BookingListItem(
                        booking: booking,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingDetailPage(
                              booking: booking,
                              pricePerGuest: state.pricePerGuest,
                              sumPeople: state.sumPeople,
                              onUpdateStatus: state.isOffline
                                  ? null
                                  : (id, status) {
                                      context.read<BookingBloc>().add(
                                            UpdateBookingStatus(
                                              bookingId: id,
                                              newStatus: status,
                                            ),
                                          );
                                    },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  /// Состояние: нет сети + нет кэша
  Widget _buildOfflineEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 72, color: Colors.orange[300]),
            const SizedBox(height: 24),
            const Text(
              'Нет подключения к интернету',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Кэшированных данных нет.\nПодключитесь к интернету для загрузки бронирований.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 15),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () {
                context.read<BookingBloc>().add(LoadBookings(restaurantId));
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Попробовать снова'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusFilter(BuildContext context, BookingLoaded state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(context, 'Все', 'all', state.activeFilter ?? 'all'),
            const SizedBox(width: 8),
            _filterChip(
                context, 'Ожидается', 'pending', state.activeFilter ?? 'all'),
            const SizedBox(width: 8),
            _filterChip(
                context, 'Прошедшие', 'completed', state.activeFilter ?? 'all'),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context, BookingLoaded state) {
    final selectedDate = state.selectedDate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null && context.mounted) {
                  context.read<BookingBloc>().add(FilterBookingsByDate(picked));
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selectedDate != null
                      ? Theme.of(context).primaryColor.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selectedDate != null
                        ? Theme.of(context).primaryColor.withOpacity(0.5)
                        : Colors.grey[300]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_month_rounded,
                      size: 18,
                      color: selectedDate != null
                          ? Theme.of(context).primaryColor
                          : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      selectedDate != null
                          ? _formatDate(selectedDate)
                          : 'Фильтр по дате',
                      style: TextStyle(
                        color: selectedDate != null
                            ? Theme.of(context).primaryColor
                            : Colors.grey[600],
                        fontSize: 14,
                        fontWeight: selectedDate != null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (selectedDate != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                context
                    .read<BookingBloc>()
                    .add(const FilterBookingsByDate(null));
              },
              icon: const Icon(Icons.close_rounded),
              color: Colors.grey[600],
              tooltip: 'Сбросить дату',
              style: IconButton.styleFrom(
                backgroundColor: Colors.grey[100],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }

  String _formatCacheTime(DateTime dt) {
    final fmt = DateFormat('dd.MM HH:mm', 'ru');
    return fmt.format(dt);
  }

  Widget _filterChip(
    BuildContext context,
    String label,
    String filter,
    String activeFilter,
  ) {
    final isActive = filter == activeFilter;

    return FilterChip(
      label: Text(label),
      selected: isActive,
      onSelected: (selected) {
        if (selected) {
          context.read<BookingBloc>().add(FilterBookings(filter));
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
      checkmarkColor: Theme.of(context).primaryColor,
    );
  }

  Widget _buildEmptyBookingsMessage() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Нет бронирований по выбранному фильтру',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
