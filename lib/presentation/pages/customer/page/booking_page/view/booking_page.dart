import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_bloc.dart';
import '../../../../../../data/models/booking.dart';
import '../../../../../../data/services/booking_service.dart';
import '../../../../../../data/services/menu_service.dart';
import '../../../../../../data/services/profile_service.dart';
import '../../../../../../data/services/restaurant_service.dart';
import '../../../../../widgets/custom_text_field.dart';
import '../../../../../widgets/result_diolog.dart';
import '../../../../seller/widgets/data_time_selector.dart';
import '../../../../seller/widgets/menu_item_selector.dart';
import '../../booking_confirmation_page/view/booking_confirmation_page.dart';
import '../bloc/booking_event.dart';
import '../bloc/booking_state.dart';

class BookingPage extends StatelessWidget {
  final int restaurantId;
  final Booking? existingBooking;
  final String restaurantName;

  const BookingPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    this.existingBooking,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = BookingBloc(
          bookingService: BookingService(),
          restaurantService: RestaurantService(),
          profileService: ProfileService(),
          menuService: MenuService(),
        );

        if (existingBooking != null) {
          bloc.add(LoadExistingBookingEvent(existingBooking!));
        }

        bloc.add(LoadUserInfoEvent());
        bloc.add(LoadRestaurantBookedDatesEvent(restaurantId));
        bloc.add(LoadRestaurantDataEvent(restaurantId));
        bloc.add(LoadRestaurantCategoriesEvent(restaurantId));
        bloc.add(LoadRestaurantExtrasEvent(restaurantId));

        return bloc;
      },
      child: BlocConsumer<BookingBloc, BookingState>(
        listenWhen: (previous, current) {
          return (previous.errorMessage != current.errorMessage &&
                  current.errorMessage != null) ||
              (previous.isSuccess != current.isSuccess && current.isSuccess);
        },
        listener: (context, state) {
          if (state.errorMessage != null) {
            showResultDialog(
              context: context,
              isSuccess: false,
              title: 'Ошибка',
              message: state.errorMessage!,
            );
          }

          if (state.isSuccess && state.bookingId != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => BookingConfirmationPage(
                  bookingId: state.bookingId!,
                  restaurantName: restaurantName,
                  bookingTime: DateTime(
                    state.selectedDate.year,
                    state.selectedDate.month,
                    state.selectedDate.day,
                    state.selectedTime.hour,
                    state.selectedTime.minute,
                  ),
                  guests: int.parse(state.guests.isEmpty ? '0' : state.guests),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final bloc = context.read<BookingBloc>();

          return Scaffold(
            appBar: AppBar(
              title: Text(existingBooking != null
                  ? 'Ввести изменения'
                  : 'Забронировать'),
            ),
            body: state.isLoading && state.bookedDates.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Бронирование в $restaurantName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Контактная информация',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          hintText: 'Полное имя',
                          prefixIcon: Icons.person_outline,
                          initialValue: state.name,
                          onChanged: (value) {
                            bloc.add(UpdateNameEvent(value));
                            return;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          hintText: 'Номер телефона',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          initialValue: state.phone,
                          onChanged: (value) {
                            bloc.add(UpdatePhoneEvent(value));
                            return;
                          },
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Детали бронирования',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (state.restaurantCategories.isNotEmpty) ...[
                          const Text(
                            'Выберите категорию',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildRestaurantCategorySelector(
                              context, state, bloc),
                          const SizedBox(height: 16),
                        ],
                        DateTimeSelector(
                          selectedDate: state.selectedDate,
                          selectedTime: state.selectedTime,
                          bookedDates: state.bookedDates,
                          onSelectDate: () async {
                            final picked = await showDatePickerDialog(
                                context, state.selectedDate, state.bookedDates);
                            if (picked != null) {
                              bloc.add(UpdateDateEvent(picked));
                            }
                          },
                          onSelectTime: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: state.selectedTime,
                            );
                            if (picked != null) {
                              bloc.add(UpdateTimeEvent(picked));
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          hintText: 'Количество гостей',
                          prefixIcon: Icons.people_outline,
                          keyboardType: TextInputType.phone,
                          initialValue: state.guests,
                          onChanged: (value) {
                            bloc.add(UpdateGuestsEvent(value));
                            return;
                          },
                        ),
                        if (state.selectedRestaurantCategoryId != null &&
                            state.guests.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        Theme.of(context).colorScheme.primary),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Общая стоимость:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    state.calculateBookingPrice(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        if (state.restaurantExtras.isNotEmpty) ...[
                          const Text(
                            'Дополнительные опции',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildExtrasSelector(context, state, bloc),
                          const SizedBox(height: 16),
                        ],
                        if (state.menuCategories.isNotEmpty)
                          MenuItemSelector(
                            menuCategories: state.menuCategories,
                            selectedMenuItems: state.selectedMenuItems,
                            onSelectMenuItem: (categoryId, menuItemId) {
                              bloc.add(UpdateMenuSelectionEvent(
                                  categoryId, menuItemId));
                            },
                          ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: state.isLoading ||
                                  _isDateBooked(
                                      state.selectedDate, state.bookedDates)
                              ? null
                              : () {
                                  if (existingBooking != null) {
                                    bloc.add(UpdateBookingEvent(
                                      bookingId: existingBooking!.id!,
                                      name: state.name,
                                      phone: state.phone,
                                      guests: state.guests,
                                      selectedDate: state.selectedDate,
                                      selectedTime: state.selectedTime,
                                      restaurantId: restaurantId,
                                      restaurantName: restaurantName,
                                      selectedMenuItems:
                                          state.selectedMenuItems,
                                      restaurantCategoryId:
                                          state.selectedRestaurantCategoryId,
                                      selectedExtraIds: state.selectedExtraIds,
                                    ));
                                  } else {
                                    bloc.add(SubmitBookingEvent(
                                      name: state.name,
                                      phone: state.phone,
                                      guests: state.guests,
                                      notes: state.notes,
                                      selectedDate: state.selectedDate,
                                      selectedTime: state.selectedTime,
                                      restaurantId: restaurantId,
                                      restaurantName: restaurantName,
                                      selectedMenuItems:
                                          state.selectedMenuItems,
                                      restaurantCategoryId:
                                          state.selectedRestaurantCategoryId,
                                      selectedExtraIds: state.selectedExtraIds,
                                    ));
                                  }
                                },
                          child: state.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : Text(existingBooking != null
                                  ? 'Сохранить изменения'
                                  : 'Подтвердить бронирование'),
                        ),
                        if (_isDateBooked(
                            state.selectedDate, state.bookedDates))
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              'Выбранная дата уже занята. Пожалуйста, выберите другую дату.',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildRestaurantCategorySelector(
    BuildContext context,
    BookingState state,
    BookingBloc bloc,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: state.restaurantCategories.map((category) {
        final isSelected = state.selectedRestaurantCategoryId == category.id;

        return GestureDetector(
          onTap: () {
            bloc.add(SelectRestaurantCategoryEvent(category.id!));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[80],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${category.priceRange.toStringAsFixed(0)} Тг/гость',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildExtrasSelector(
    BuildContext context,
    BookingState state,
    BookingBloc bloc,
  ) {
    return Column(
      children: state.restaurantExtras.map((extra) {
        final isSelected = state.selectedExtraIds.contains(extra.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              bloc.add(ToggleExtraSelectionEvent(extra.id!));
            },
            title: Text(
              extra.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '+${extra.price.toStringAsFixed(0)} Тг',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (extra.description != null && extra.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      extra.description!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
              ],
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        );
      }).toList(),
    );
  }

  bool _isDateBooked(DateTime date, List<DateTime> bookedDates) {
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (existingBooking != null) {
      final existingDateOnly = DateTime(existingBooking!.bookingTime.year,
          existingBooking!.bookingTime.month, existingBooking!.bookingTime.day);

      if (dateOnly.isAtSameMomentAs(existingDateOnly)) {
        return false;
      }
    }

    return bookedDates.any((bookedDate) =>
        bookedDate.year == dateOnly.year &&
        bookedDate.month == dateOnly.month &&
        bookedDate.day == dateOnly.day);
  }
}
