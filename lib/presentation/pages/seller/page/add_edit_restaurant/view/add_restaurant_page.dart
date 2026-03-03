// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/presentation/pages/seller/page/add_edit_restaurant/bloc/restaurant_state.dart';
import 'package:restauran/presentation/pages/seller/page/add_edit_restaurant/widget/restaurant_categories_widget.dart';
import 'dart:async';

import '../../../../../widgets/custom_text_field.dart';
import '../../../../../widgets/date_range_picker.dart';
import '../../../../../widgets/photo_gallery.dart';
import '../widget/restaurant_extras_widget.dart';
import '../bloc/restaurant_bloc.dart';
import '../bloc/restaurant_event.dart';

class AddRestaurantPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final Map<String, dynamic>? restaurant;

  const AddRestaurantPage({
    super.key,
    this.restaurant,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends State<AddRestaurantPage> {
  // Контроллеры создаются один раз и живут всё время жизни страницы
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _phonesController = TextEditingController();
  final _sumPeopleController = TextEditingController();

  // Флаг: данные уже были загружены в контроллеры
  bool _controllersInitialized = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _phonesController.dispose();
    _sumPeopleController.dispose();
    super.dispose();
  }

  /// Заполняет контроллеры данными из стейта.
  /// Вызывается только один раз — когда данные реально загрузились.
  void _initControllers(RestaurantState state) {
    _nameController.text = state.name;
    _descriptionController.text = state.description;
    _locationController.text = state.location;
    _phonesController.text = state.phones.join('\n');
    _sumPeopleController.text = state.sumPeople;
    _controllersInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = RestaurantBloc();
        bloc.add(LoadRestaurantData(
          restaurant: widget.restaurant,
          restaurantId: widget.restaurantId,
        ));
        bloc.add(LoadBookedDates(restaurantId: widget.restaurantId));
        return bloc;
      },
      child: BlocConsumer<RestaurantBloc, RestaurantState>(
        listener: (context, state) {
          // Заполняем контроллеры ровно один раз — когда загрузка завершена
          // и данные появились в стейте
          if (!_controllersInitialized &&
              !state.isLoading &&
              state.name.isNotEmpty) {
            _initControllers(state);
          }

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
            // Обновляем контроллеры при pull-to-refresh
            _initControllers(newState);
            completer.complete();
            subscription.cancel();
          }
        });

        bloc.add(LoadRestaurantData(
          restaurant: widget.restaurant,
          restaurantId: widget.restaurantId,
        ));
        bloc.add(LoadBookedDates(restaurantId: widget.restaurantId));

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
            // ==================== ИНФОРМАЦИЯ О РЕСТОРАНЕ ====================
            const Text(
              'Информация',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _nameController,
              onChanged: (value) => bloc.add(UpdateName(value)),
              hintText: 'Название ресторана*',
              prefixIcon: Icons.restaurant,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              onChanged: (value) => bloc.add(UpdateDescription(value)),
              hintText: 'Описание',
              prefixIcon: Icons.description,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _locationController,
              onChanged: (value) => bloc.add(UpdateLocation(value)),
              hintText: 'Местоположение *',
              prefixIcon: Icons.location_on,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phonesController,
              onChanged: (value) => bloc.add(UpdatePhone(value)),
              hintText: 'Номера телефонов',
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
                    controller: _sumPeopleController,
                    onChanged: (value) => bloc.add(UpdateSumPeople(value)),
                    hintText: 'Кол-во мест в одном столе',
                    prefixIcon: Icons.people,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 24),

            // ==================== КАТЕГОРИИ РЕСТОРАНА ====================
            const Text(
              'Категории ресторана',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SellerCategoriesWidget(
              restaurantId: widget.restaurantId,
              availableCategories: state.availableGlobalCategories,
              restaurantCategories: state.restaurantCategories,
              isLoading: state.isCategoriesLoading,
              onActivateCategory: (globalCategoryId, price, description) {
                bloc.add(ActivateRestaurantCategory(
                  globalCategoryId: globalCategoryId,
                  price: price,
                  description: description,
                ));
              },
              onUpdateCategory: (categoryId, price, description, isActive) {
                bloc.add(UpdateRestaurantCategory(
                  categoryId: categoryId,
                  price: price,
                  description: description,
                  isActive: isActive,
                ));
              },
              onDeactivateCategory: (categoryId) {
                bloc.add(DeactivateRestaurantCategory(categoryId));
              },
            ),

            const SizedBox(height: 8),
            const Text(
              'Дополнительные опции',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (!state.isEditing) ...[
              const SizedBox(height: 8),
              const Text(
                'Создайте дополнительные опции после создания ресторана',
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 255, 0, 0),
                ),
              ),
            ],
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

            // ==================== ИЗОБРАЖЕНИЯ ====================
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: state.isLoading
                    ? null
                    : () => bloc.add(SaveRestaurant(context)),
                child: state.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        state.isEditing ? 'Обновить' : 'Добавить',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
