// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/presentation/pages/seller/page/add_edit_restaurant/bloc/restaurant_state.dart';
import 'dart:async';

import '../../../../../widgets/custom_text_field.dart';
import '../../../../../widgets/date_range_picker.dart';
import '../../../../../widgets/photo_gallery.dart';
import '../widget/restaurant_categories_widget.dart';
import '../widget/restaurant_extras_widget.dart';
import '../bloc/restaurant_bloc.dart';
import '../bloc/restaurant_event.dart';

class AddRestaurantPage extends StatelessWidget {
  final int restaurantId;
  final String restaurantName;
  final Map<String, dynamic>? restaurant;

  const AddRestaurantPage({
    super.key,
    this.restaurant,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = RestaurantBloc();
        bloc.add(LoadRestaurantData(
          restaurant: restaurant,
          restaurantId: restaurantId,
        ));
        bloc.add(LoadBookedDates(restaurantId: restaurantId));
        return bloc;
      },
      child: BlocConsumer<RestaurantBloc, RestaurantState>(
        listener: (context, state) {
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.error!)),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              title: Text(state.isEditing ? 'Обновить' : 'Добавить'),
            ),
            body: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildForm(context, state),
          );
        },
      ),
    );
  }

  Widget _buildForm(BuildContext context, RestaurantState state) {
    final bloc = context.read<RestaurantBloc>();

    return RefreshIndicator(
      onRefresh: () async {
        final completer = Completer<void>();

        late StreamSubscription subscription;
        subscription = bloc.stream.listen((newState) {
          if (!newState.isLoading && !completer.isCompleted) {
            completer.complete();
            subscription.cancel();
          }
        });

        bloc.add(LoadRestaurantData(
          restaurant: restaurant,
          restaurantId: restaurantId,
        ));
        bloc.add(LoadBookedDates(restaurantId: restaurantId));

        await completer.future.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            subscription.cancel();
          },
        );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Информация',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: state.name,
              onChanged: (value) {
                bloc.add(UpdateName(value));
                return;
              },
              hintText: 'Hазвание ресторана*',
              prefixIcon: Icons.restaurant,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: state.description,
              onChanged: (value) {
                bloc.add(
                  UpdateDescription(value),
                );
                return;
              },
              hintText: 'Описание',
              prefixIcon: Icons.description,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              initialValue: state.location,
              onChanged: (value) {
                bloc.add(UpdateLocation(value));
                return;
              },
              hintText: 'Местоположение *',
              prefixIcon: Icons.location_on,
            ),
            const SizedBox(height: 16),
            // <CHANGE> Обновлено поле для телефонов - объединяем массив в строку
            CustomTextField(
              initialValue: state.phones.join('\n'),
              onChanged: (value) {
                bloc.add(
                  UpdatePhone(value),
                );
                return;
              },
              hintText: 'Номера телефонов (каждый с новой строки)',
              prefixIcon: Icons.phone,
              isMultiplePhones: true,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text(
                'Введите каждый номер с новой строки',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    initialValue: state.sumPeople,
                    onChanged: (value) {
                      bloc.add(UpdateSumPeople(value));
                      return;
                    },
                    hintText: 'Количество мест в одном столе',
                    prefixIcon: Icons.people,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomTextField(
                    initialValue: state.workingHours,
                    onChanged: (value) {
                      bloc.add(UpdateWorkingHours(value));
                      return;
                    },
                    hintText: 'График',
                    prefixIcon: Icons.access_time,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            const Text(
              'Категории ресторана',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Создайте категории после созданий ресторана',
              style: TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 255, 0, 0),
              ),
            ),
            const SizedBox(height: 16),
            RestaurantCategoriesWidget(
              categories: state.restaurantCategories,
              isLoading: state.isCategoriesLoading,
              onAddCategory: (name, price, description) {
                bloc.add(AddRestaurantCategory(
                  name: name,
                  priceRange: price,
                  description: description,
                ));
              },
              onUpdateCategory: (categoryId, name, price, description) {
                bloc.add(UpdateRestaurantCategory(
                  categoryId: categoryId,
                  name: name,
                  priceRange: price,
                  description: description,
                ));
              },
              onRemoveCategory: (categoryId) {
                bloc.add(RemoveRestaurantCategory(categoryId));
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Дополнительные опции',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Создайте дополнительные опции после создания ресторана',
              style: TextStyle(
                fontSize: 14,
                color: Color.fromARGB(255, 255, 0, 0),
              ),
            ),
            const SizedBox(height: 16),
            RestaurantExtrasWidget(
              extras: state.restaurantExtras,
              isLoading: state.isExtrasLoading,
              onAddExtra: (name, price, description) {
                bloc.add(AddRestaurantExtra(
                  name: name,
                  price: price,
                  description: description,
                ));
              },
              onUpdateExtra: (extraId, name, price, description) {
                bloc.add(UpdateRestaurantExtra(
                  extraId: extraId,
                  name: name,
                  price: price,
                  description: description,
                ));
              },
              onRemoveExtra: (extraId) {
                bloc.add(RemoveRestaurantExtra(extraId));
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Изображение',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            PhotoGallery(
              photoUrls: state.photoUrls,
              onAddPhoto: () =>
                  bloc.add(AddPhoto(restaurantId: state.restaurantId)),
              onRemovePhoto: (index) => bloc.add(RemovePhoto(index)),
            ),
            const SizedBox(height: 24),
            const Text(
              'Забронированные даты',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Выберите даты, когда ресторан будет забронирован',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            DateRangePicker(
              selectedDates: state.restaurantBookedDates,
              bookedDates: state.visibleBookedDates,
              onDatesChanged: (dates) => bloc.add(UpdateBookedDates(dates)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => bloc.add(SaveRestaurant(context)),
              child: Text(state.isEditing ? 'Обновить' : 'Добавить'),
            ),
          ],
        ),
      ),
    );
  }
}
