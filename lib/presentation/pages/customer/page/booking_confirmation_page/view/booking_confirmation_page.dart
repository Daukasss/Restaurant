import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/presentation/widgets/result_diolog.dart';
import '../../home_page/view/home_page.dart';
import '../bloc/booking_confirmation_bloc.dart';
import '../bloc/booking_confirmation_event.dart';
import '../bloc/booking_confirmation_state.dart';

class BookingConfirmationPage extends StatelessWidget {
  final String? bookingId;
  final String restaurantName;
  final DateTime bookingTime;
  final int guests;
  final Map<int, int>? menuSelections;

  const BookingConfirmationPage({
    super.key,
    required this.bookingId,
    required this.restaurantName,
    required this.bookingTime,
    required this.guests,
    this.menuSelections,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = BookingConfirmationBloc();

        if (menuSelections != null && menuSelections!.isNotEmpty) {
          bloc.add(LoadMenuSelections(menuSelections!));
        }

        return bloc;
      },
      child: BlocConsumer<BookingConfirmationBloc, BookingConfirmationState>(
        listener: (context, state) {
          if (state is BookingConfirmationError) {
            showResultDialog(
              context: context,
              isSuccess: false,
              title: 'Ошибка',
              message: state.message,
            );
          } else if (state is NavigatingToHome) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 100,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Бронирование подтверждено!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ваше бронирование успешно подтверждено.',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _buildInfoRow(
                            context,
                            'Бронирование ID',
                            '#$bookingId',
                            Icons.confirmation_number_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            context,
                            'Ресторан',
                            restaurantName,
                            Icons.restaurant_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            context,
                            'Дата и время',
                            '${bookingTime.day}/${bookingTime.month}/${bookingTime.year} at ${bookingTime.hour}:${bookingTime.minute.toString().padLeft(2, '0')}',
                            Icons.calendar_today_outlined,
                          ),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            context,
                            'Гости',
                            '$guests гостей',
                            Icons.people_outline,
                          ),
                        ],
                      ),
                    ),
                    if (state is BookingConfirmationLoaded &&
                        state.selectedItems.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'Выбранные блюда',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          itemCount: state.selectedItems.length,
                          itemBuilder: (context, index) {
                            final item = state.selectedItems[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: item['image_url'] != null &&
                                        item['image_url'].isNotEmpty
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.network(
                                          item['image_url'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Icon(Icons.restaurant,
                                            color: Colors.grey),
                                      ),
                                title: Text(item['name']),
                                subtitle: Text(item['menu_categories']['name']),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else if (state is BookingConfirmationLoading) ...[
                      const SizedBox(height: 24),
                      const Center(child: CircularProgressIndicator()),
                    ] else if (menuSelections == null ||
                        menuSelections!.isEmpty) ...[
                      const SizedBox(height: 24),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<BookingConfirmationBloc>()
                            .add(NavigateToHome());
                      },
                      child: const Text('Вернуться на главную'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
      BuildContext context, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
