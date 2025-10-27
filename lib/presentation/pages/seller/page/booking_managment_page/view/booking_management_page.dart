import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:restauran/presentation/widgets/result_diolog.dart';

import '../bloc/booking_managment_bloc_bloc.dart';
import '../bloc/booking_managment_bloc_event.dart';
import '../bloc/booking_managment_bloc_state.dart';
import '../widgets/booking_detail_bottom_sheet.dart';
import '../widgets/booking_list_item.dart';

class BookingManagementPage extends StatelessWidget {
  final int restaurantId;
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
              showResultDialog(
                context: context,
                isSuccess: false,
                title: 'Ошибка',
                message: state.message,
              );
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
            } else if (state is BookingLoaded) {
              return RefreshIndicator(
                onRefresh: () async {
                  context.read<BookingBloc>().add(LoadBookings(restaurantId));
                },
                child: Column(
                  children: [
                    _buildStatusFilter(context, state),
                    const SizedBox(height: 8),
                    Expanded(
                      child: state.filteredBookings.isEmpty
                          ? _buildEmptyBookingsMessage()
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16),
                              itemCount: state.filteredBookings.length,
                              itemBuilder: (context, index) {
                                final booking = state.filteredBookings[index];
                                return BookingListItem(
                                  booking: booking,
                                  onTap: () => _showBookingDetails(
                                    context,
                                    booking,
                                    state.pricePerGuest,
                                    state.sumPeople,
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            } else if (state is BookingError) {
              return Center(child: Text(state.message));
            }

            return const Center(child: CircularProgressIndicator());
          },
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

  void _showBookingDetails(
    BuildContext context,
    Map<String, dynamic> booking,
    double? pricePerGuest,
    int? sumPeople,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return BookingDetailBottomSheet(
          booking: booking,
          pricePerGuest: pricePerGuest,
          sumPeople: sumPeople,
          onUpdateStatus: (bookingId, newStatus) {
            Navigator.pop(context);
            context.read<BookingBloc>().add(
                  UpdateBookingStatus(
                    bookingId: bookingId,
                    newStatus: newStatus,
                  ),
                );
          },
        );
      },
    );
  }
}
