// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../../data/models/restaurant.dart';
import '../../../../../../data/models/restaurant_category.dart';
import '../../../../../../data/models/restaurant_extra.dart';
import '../../../../../../data/services/restaurant_service.dart';
import '../../../../../../data/services/category_service.dart'; // НОВОЕ
import 'restaurant_event.dart';
import 'restaurant_state.dart';

class RestaurantBloc extends Bloc<RestaurantEvent, RestaurantState> {
  final RestaurantService _restaurantService;
  final CategoryService _categoryService = CategoryService(); // НОВОЕ
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  RestaurantBloc({RestaurantService? restaurantService})
      : _restaurantService = restaurantService ?? RestaurantService(),
        super(const RestaurantState()) {
    on<LoadRestaurantData>(_onLoadRestaurantData);
    on<LoadBookedDates>(_onLoadBookedDates);
    on<UpdateName>(_onUpdateName);
    on<UpdateDescription>(_onUpdateDescription);
    on<UpdateLocation>(_onUpdateLocation);
    on<UpdatePhone>(_onUpdatePhone);
    on<UpdateWorkingHours>(_onUpdateWorkingHours);
    on<UpdatePriceRange>(_onUpdatePriceRange);
    on<UpdateSumPeople>(_onUpdateSumPeople);
    on<UpdateCategory>(_onUpdateCategory);
    on<AddPhoto>(_onAddPhoto);
    on<RemovePhoto>(_onRemovePhoto);
    on<UpdateTempBookedDates>(_onUpdateTempBookedDates);
    on<UpdateBookedDates>(_onUpdateBookedDates);
    on<SaveRestaurant>(_onSaveRestaurant);

    // НОВЫЕ обработчики для категорий
    on<LoadAvailableGlobalCategories>(_onLoadAvailableGlobalCategories);
    on<LoadRestaurantCategories>(_onLoadRestaurantCategories);
    on<ActivateRestaurantCategory>(_onActivateRestaurantCategory);
    on<UpdateRestaurantCategory>(_onUpdateRestaurantCategory);
    on<DeactivateRestaurantCategory>(_onDeactivateRestaurantCategory);

    // Extras
    on<LoadRestaurantExtras>(_onLoadRestaurantExtras);
    on<AddRestaurantExtra>(_onAddRestaurantExtra);
    on<UpdateRestaurantExtra>(_onUpdateRestaurantExtra);
    on<RemoveRestaurantExtra>(_onRemoveRestaurantExtra);
  }

  Future<void> _onLoadRestaurantData(
    LoadRestaurantData event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));

    try {
      print('╔═══════════════════════════════════════════════');
      print('║  LoadRestaurantData event received');
      print('║  restaurantId: ${event.restaurantId}');
      print('║  event.restaurant type: ${event.restaurant?.runtimeType}');
      print('╚═══════════════════════════════════════════════');

      if (event.restaurant != null) {
        final data = event.restaurant!;

        // Очень подробный лог входящих данных
        print('Входящие данные ресторана (Map):');
        print('Количество ключей: ${data.length}');
        print('Ключи: ${data.keys.toList().join(", ")}');

        // Показываем значения важных полей (если они есть)
        print('name         → ${data['name']}');
        print('description  → ${data['description']}');
        print('location     → ${data['location']}');
        print('phone        → ${data['phone']}');
        print(
            'photos       → ${data['photos']} (type: ${data['photos']?.runtimeType})');
        print('booked_dates → ${data['booked_dates']}');
        print('rating       → ${data['rating']}');
        print('sum_people   → ${data['sum_people']}');
        print('owner_id     → ${data['owner_id']}');
        print('---');

        // Пробуем создать модель
        final restaurant = Restaurant.fromJson(data);

        print('После Restaurant.fromJson:');
        print('name:            ${restaurant.name}');
        print('description:     ${restaurant.description}');
        print('location:        ${restaurant.location}');
        print('phone:           ${restaurant.phone}');
        print(
            'photos:          ${restaurant.photos} (length: ${restaurant.photos?.length ?? 0})');
        print(
            'bookedDates:     ${restaurant.bookedDates} (length: ${restaurant.bookedDates?.length ?? 0})');
        print('rating:          ${restaurant.rating}');
        print('sumPeople:       ${restaurant.sumPeople}');
        print('---');

        // Парсинг телефонов (особое внимание, т.к. это вручную)
        List<String> phones = [];
        final phoneRaw = data['phone']?.toString() ?? '';
        if (phoneRaw.isNotEmpty) {
          phones = phoneRaw
              .split('\n')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();
        }
        print('Спарсенные телефоны: $phones (count: ${phones.length})');

        emit(state.copyWith(
          name: restaurant.name,
          description: restaurant.description ?? '',
          location: restaurant.location ?? '',
          phones: phones,
          workingHours: restaurant.workingHours ?? '',
          sumPeople: restaurant.sumPeople?.toString() ?? '',
          photoUrls: restaurant.photos ?? [],
          restaurantBookedDates: restaurant.bookedDates ?? [],
          rating: restaurant.rating ?? 5.0,
          isEditing: true,
          isLoading: false,
          restaurantId: event.restaurantId,
        ));

        print('Состояние после emit (основные поля):');
        print('name → ${restaurant.name}');
        print('phones → $phones');
        print('photos → ${restaurant.photos?.length ?? 0} шт');
        print('bookedDates → ${restaurant.bookedDates?.length ?? 0} дат');
      } else {
        print('event.restaurant == null → это создание нового ресторана');

        // Генерируем ID заранее, чтобы фото можно было загружать до сохранения ресторана
        final newRestaurantId = event.restaurantId.isNotEmpty
            ? event.restaurantId
            : _restaurantService.generateRestaurantId();

        emit(state.copyWith(
          isLoading: false,
          restaurantId: newRestaurantId,
          isEditing: false,
        ));
      }

      // Загрузка дополнительных данных
      if (event.restaurantId.isNotEmpty) {
        print(
            'Запускаем загрузку категорий и extras для id: ${event.restaurantId}');
        add(LoadAvailableGlobalCategories(event.restaurantId));
        add(LoadRestaurantCategories(event.restaurantId));
        add(LoadRestaurantExtras(event.restaurantId));
      }
    } catch (e, stack) {
      print('!!! ОШИБКА в _onLoadRestaurantData !!!');
      print('Error: $e');
      print('Stack:\n$stack');

      emit(state.copyWith(
        isLoading: false,
        error: 'Не удалось загрузить данные ресторана: $e',
      ));
    }
  }

  // ==================== НОВЫЕ ОБРАБОТЧИКИ ДЛЯ КАТЕГОРИЙ ====================

  Future<void> _onLoadAvailableGlobalCategories(
    LoadAvailableGlobalCategories event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(state.copyWith(isCategoriesLoading: true));

    try {
      final globalCategories =
          await _categoryService.getAvailableGlobalCategories(
        event.restaurantId,
      );

      emit(state.copyWith(
        availableGlobalCategories: globalCategories,
        isCategoriesLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        isCategoriesLoading: false,
        error: 'Ошибка загрузки доступных категорий: $error',
      ));
    }
  }

  Future<void> _onLoadRestaurantCategories(
    LoadRestaurantCategories event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(state.copyWith(isCategoriesLoading: true));

    try {
      final categories =
          await _categoryService.getRestaurantCategories(event.restaurantId);

      emit(state.copyWith(
        restaurantCategories: categories,
        isCategoriesLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        isCategoriesLoading: false,
        error: 'Ошибка загрузки категорий: $error',
      ));
    }
  }

  Future<void> _onActivateRestaurantCategory(
    ActivateRestaurantCategory event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(state.copyWith(isCategoriesLoading: true));

    try {
      await _categoryService.activateCategory(
        state.restaurantId,
        event.globalCategoryId,
        event.price,
        event.description,
      );

      // Перезагружаем список категорий
      final categories = await _categoryService.getRestaurantCategories(
        state.restaurantId,
      );

      emit(state.copyWith(
        restaurantCategories: categories,
        isCategoriesLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        error: 'Ошибка активации категории: $error',
        isCategoriesLoading: false,
      ));
    }
  }

  Future<void> _onUpdateRestaurantCategory(
    UpdateRestaurantCategory event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(state.copyWith(isCategoriesLoading: true));

    try {
      // Находим текущую категорию
      final currentCategory = state.restaurantCategories.firstWhere(
        (c) => c.id == event.categoryId,
      );

      // Создаем обновленную категорию
      final updatedCategory = currentCategory.copyWith(
        priceRange: event.price,
        description: event.description,
        isActive: event.isActive,
      );

      // Обновляем в базе
      await _categoryService.updateRestaurantCategory(updatedCategory);

      // Перезагружаем список категорий
      final categories = await _categoryService.getRestaurantCategories(
        state.restaurantId,
      );

      emit(state.copyWith(
        restaurantCategories: categories,
        isCategoriesLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        error: 'Ошибка обновления категории: $error',
        isCategoriesLoading: false,
      ));
    }
  }

  Future<void> _onDeactivateRestaurantCategory(
    DeactivateRestaurantCategory event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(state.copyWith(isCategoriesLoading: true));

    try {
      await _categoryService.deactivateRestaurantCategory(event.categoryId);

      // Перезагружаем список категорий
      final categories = await _categoryService.getRestaurantCategories(
        state.restaurantId,
      );

      emit(state.copyWith(
        restaurantCategories: categories,
        isCategoriesLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        error: 'Ошибка деактивации категории: $error',
        isCategoriesLoading: false,
      ));
    }
  }

  // ==================== ОБРАБОТЧИКИ ДЛЯ EXTRAS ====================

  Future<void> _onLoadRestaurantExtras(
    LoadRestaurantExtras event,
    Emitter<RestaurantState> emit,
  ) async {
    emit(state.copyWith(isExtrasLoading: true));

    try {
      final extras =
          await _restaurantService.getRestaurantExtras(event.restaurantId);

      emit(state.copyWith(
        restaurantExtras: extras,
        isExtrasLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        isExtrasLoading: false,
        error: 'Ошибка загрузки дополнительных опций',
      ));
    }
  }

  Future<void> _onAddRestaurantExtra(
    AddRestaurantExtra event,
    Emitter<RestaurantState> emit,
  ) async {
    try {
      final extra = RestaurantExtra(
        restaurantId: state.restaurantId,
        name: event.name,
        price: event.price,
        description: event.description,
      );

      await _restaurantService.addRestaurantExtra(extra);
      add(LoadRestaurantExtras(state.restaurantId));
    } catch (error) {
      emit(state.copyWith(error: 'Ошибка добавления дополнительной опции'));
    }
  }

  Future<void> _onUpdateRestaurantExtra(
    UpdateRestaurantExtra event,
    Emitter<RestaurantState> emit,
  ) async {
    try {
      final existingExtra = state.restaurantExtras.firstWhere(
        (e) => e.id == event.extraId,
      );

      final updatedExtra = existingExtra.copyWith(
        name: event.name,
        price: event.price,
        description: event.description,
        isActive: event.isActive,
      );

      await _restaurantService.updateRestaurantExtra(updatedExtra);
      add(LoadRestaurantExtras(state.restaurantId));
    } catch (error) {
      emit(state.copyWith(error: 'Ошибка обновления дополнительной опции'));
    }
  }

  Future<void> _onRemoveRestaurantExtra(
    RemoveRestaurantExtra event,
    Emitter<RestaurantState> emit,
  ) async {
    try {
      await _restaurantService.deleteRestaurantExtra(event.extraId);
      add(LoadRestaurantExtras(state.restaurantId));
    } catch (error) {
      emit(state.copyWith(error: 'Ошибка удаления дополнительной опции'));
    }
  }

  // ==================== ОСТАЛЬНЫЕ ОБРАБОТЧИКИ ====================

  Future<void> _onLoadBookedDates(
    LoadBookedDates event,
    Emitter<RestaurantState> emit,
  ) async {
    try {
      final bookedDates =
          await _restaurantService.getBookedDates(event.restaurantId);

      emit(state.copyWith(
        visibleBookedDates: bookedDates,
        restaurantBookedDates: state.restaurantBookedDates,
      ));
    } catch (error) {
      emit(state.copyWith(error: 'Ошибка загрузки дат'));
    }
  }

  void _onUpdateName(UpdateName event, Emitter<RestaurantState> emit) {
    emit(state.copyWith(name: event.name));
  }

  void _onUpdateDescription(
      UpdateDescription event, Emitter<RestaurantState> emit) {
    emit(state.copyWith(description: event.description));
  }

  void _onUpdateLocation(UpdateLocation event, Emitter<RestaurantState> emit) {
    emit(state.copyWith(location: event.location));
  }

  void _onUpdatePhone(UpdatePhone event, Emitter<RestaurantState> emit) {
    // Разделяем строку на массив телефонов
    final phones = event.phone
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    emit(state.copyWith(phones: phones));
  }

  void _onUpdateWorkingHours(
      UpdateWorkingHours event, Emitter<RestaurantState> emit) {
    emit(state.copyWith(workingHours: event.workingHours));
  }

  void _onUpdatePriceRange(
      UpdatePriceRange event, Emitter<RestaurantState> emit) {
    emit(state.copyWith(priceRange: event.priceRange));
  }

  void _onUpdateSumPeople(
      UpdateSumPeople event, Emitter<RestaurantState> emit) {
    emit(state.copyWith(sumPeople: event.sumPeople));
  }

  void _onUpdateCategory(UpdateCategory event, Emitter<RestaurantState> emit) {
    emit(state.copyWith(category: event.category));
  }

  Future<void> _onAddPhoto(
      AddPhoto event, Emitter<RestaurantState> emit) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image != null) {
        emit(state.copyWith(isLoading: true));

        // Принудительно обновляем токен перед загрузкой
        final currentUser = _auth.currentUser;
        if (currentUser == null) {
          emit(state.copyWith(
            error: 'Пользователь не авторизован',
            isLoading: false,
          ));
          return;
        }
        await currentUser.getIdToken(true);

        // Загружаем в Firebase Storage (путь: restaurants/{id}/{timestamp}.jpg)
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = _storage
            .ref()
            .child('restaurants')
            .child(event.restaurantId)
            .child(fileName);

        await ref.putFile(File(image.path));
        final downloadUrl = await ref.getDownloadURL();

        final updatedPhotos = List<String>.from(state.photoUrls)
          ..add(downloadUrl);

        emit(state.copyWith(
          photoUrls: updatedPhotos,
          isLoading: false,
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        error: 'Ошибка загрузки фото: $error',
        isLoading: false,
      ));
    }
  }

  void _onRemovePhoto(RemovePhoto event, Emitter<RestaurantState> emit) {
    final updatedPhotos = List<String>.from(state.photoUrls)
      ..removeAt(event.index);
    emit(state.copyWith(photoUrls: updatedPhotos));
  }

  void _onUpdateTempBookedDates(
      UpdateTempBookedDates event, Emitter<RestaurantState> emit) {
    emit(state.copyWith(tempBookedDates: event.dates));
  }

  void _onUpdateBookedDates(
      UpdateBookedDates event, Emitter<RestaurantState> emit) {
    emit(state.copyWith(restaurantBookedDates: event.dates));
  }

  Future<void> _onSaveRestaurant(
      SaveRestaurant event, Emitter<RestaurantState> emit) async {
    if (state.name.isEmpty || state.location.isEmpty) {
      emit(state.copyWith(error: 'Заполните обязательные поля'));
      return;
    }

    emit(state.copyWith(isLoading: true));

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }

      // Объединяем массив телефонов в строку
      final phoneString = state.phones.join('\n');

      final restaurant = Restaurant(
        name: state.name,
        description: state.description,
        location: state.location,
        phone: phoneString,
        workingHours: state.workingHours,
        ownerId: currentUser.uid,
        photos: state.photoUrls,
        bookedDates: state.restaurantBookedDates,
        rating: state.rating,
        sumPeople: int.tryParse(state.sumPeople),
      );

      await _restaurantService.saveRestaurant(
        restaurant,
        existingId: state.isEditing ? state.restaurantId : null,
        // При создании передаём заранее сгенерированный ID,
        // чтобы фото, загруженные до сохранения, уже лежали в правильном пути
        newId: state.isEditing ? null : state.restaurantId,
      );

      emit(state.copyWith(isLoading: false, isSuccess: true));

      ScaffoldMessenger.of(event.context).showSnackBar(
        SnackBar(
          content: Text(state.isEditing
              ? 'Ресторан успешно обновлен!'
              : 'Ресторан успешно добавлен!'),
        ),
      );

      Navigator.of(event.context).pop();
    } catch (error) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Ошибка сохранения ресторана: $error',
      ));
    }
  }
}
