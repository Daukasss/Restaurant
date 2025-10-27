// ignore_for_file: avoid_print, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restauran/data/services/abstract/service_export.dart';
import 'package:restauran/data/services/service_lacator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../widgets/result_diolog.dart';
import 'restaurant_event.dart';
import 'restaurant_state.dart';
import '../../../../../../data/models/restaurant_category.dart';
import '../../../../../../data/models/restaurant_extra.dart';

class RestaurantBloc extends Bloc<RestaurantEvent, RestaurantState> {
  final _restaurantService = getIt<AbstractRestaurantService>();
  final SupabaseClient _supabase = Supabase.instance.client;

  RestaurantBloc() : super(const RestaurantState()) {
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
    on<LoadRestaurantCategories>(_onLoadRestaurantCategories);
    on<AddRestaurantCategory>(_onAddRestaurantCategory);
    on<UpdateRestaurantCategory>(_onUpdateRestaurantCategory);
    on<RemoveRestaurantCategory>(_onRemoveRestaurantCategory);
    on<LoadRestaurantExtras>(_onLoadRestaurantExtras);
    on<AddRestaurantExtra>(_onAddRestaurantExtra);
    on<UpdateRestaurantExtra>(_onUpdateRestaurantExtra);
    on<RemoveRestaurantExtra>(_onRemoveRestaurantExtra);
  }

  // ... existing code ...

  void _onLoadRestaurantData(
      LoadRestaurantData event, Emitter<RestaurantState> emit) {
    final restaurant = event.restaurant;
    final isEditing = restaurant != null;

    if (isEditing) {
      List<String> photoUrls = [];
      if (restaurant['photos'] != null) {
        photoUrls = List<String>.from(restaurant['photos']);
      } else if (restaurant['image_url'] != null) {
        final imageUrl = restaurant['image_url'];
        if (imageUrl is String && imageUrl.isNotEmpty) {
          photoUrls = [imageUrl];
        } else if (imageUrl is List && imageUrl.isNotEmpty) {
          photoUrls = imageUrl.map((url) => url.toString()).toList();
        }
      }

      // <CHANGE> Загрузка телефонов как массива
      List<String> phones = [];
      if (restaurant['phones'] != null) {
        // Новый формат - массив телефонов
        phones = List<String>.from(restaurant['phones']);
      } else if (restaurant['phone'] != null) {
        // Старый формат - один телефон (для обратной совместимости)
        final phoneValue = restaurant['phone'].toString();
        if (phoneValue.isNotEmpty) {
          // Если телефон содержит переносы строк, разделяем
          phones = phoneValue
              .split('\n')
              .map((p) => p.trim())
              .where((p) => p.isNotEmpty)
              .toList();
        }
      }

      emit(state.copyWith(
        name: restaurant['name'] ?? '',
        description: restaurant['description'] ?? '',
        location: restaurant['location'] ?? '',
        phones: phones, // <CHANGE> Используем массив телефонов
        workingHours: restaurant['working_hours'] ?? '',
        priceRange: restaurant['price_range'] ?? '',
        category: restaurant['category'] ?? 'Mid-range',
        sumPeople: restaurant['sum_people']?.toString() ?? '',
        photoUrls: photoUrls,
        restaurantBookedDates: restaurant['booked_dates'] != null
            ? (restaurant['booked_dates'] as List)
                .map((date) => DateTime.parse(date))
                .toList()
            : [],
        isEditing: true,
        rating: restaurant['rating'] ?? 5.0,
        restaurantId: event.restaurantId,
      ));

      add(LoadRestaurantCategories(event.restaurantId));
      add(LoadRestaurantExtras(event.restaurantId));
    } else {
      emit(state.copyWith(
        isEditing: false,
        restaurantId: event.restaurantId,
      ));
    }
  }

  // ... existing code ...

  // <CHANGE> Обновлен метод для обработки множественных телефонов
  void _onUpdatePhone(UpdatePhone event, Emitter<RestaurantState> emit) {
    // Разделяем строку по переносам строки и убираем пустые значения
    final phoneList = event.phone
        .split('\n')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    emit(state.copyWith(phones: phoneList));
  }

  // ... existing code ...

  Future<void> _onSaveRestaurant(
      SaveRestaurant event, Emitter<RestaurantState> emit) async {
    // <CHANGE> Проверка на наличие хотя бы одного телефона
    if (state.name.isEmpty ||
        state.location.isEmpty ||
        state.sumPeople.isEmpty ||
        state.photoUrls.isEmpty ||
        state.phones.isEmpty) {
      showResultDialog(
        context: event.context,
        isSuccess: false,
        title: 'Ошибка',
        message:
            'Заполните все обязательные поля, включая хотя бы один номер телефона!',
      );
      return;
    }

    emit(state.copyWith(isLoading: true));

    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      print('[v0] Current user ID: $currentUserId');

      if (currentUserId == null) {
        emit(state.copyWith(
          isLoading: false,
          error: 'Ошибка: пользователь не авторизован',
        ));
        showResultDialog(
          context: event.context,
          isSuccess: false,
          title: 'Ошибка',
          message: 'Пользователь не авторизован',
        );
        return;
      }

      // <CHANGE> Сохраняем телефоны как массив
      final restaurantData = {
        'name': state.name,
        'description': state.description,
        'location': state.location,
        'phones': state.phones, // <CHANGE> Массив телефонов
        'sum_people': state.sumPeople,
        'working_hours': state.workingHours,
        'price_range': state.priceRange,
        'photos': state.photoUrls,
        'image_url': state.photoUrls.isNotEmpty ? state.photoUrls.first : null,
        'booked_dates': state.tempBookedDates
            .map((date) => date.toIso8601String())
            .toList(),
      };

      if (state.isEditing) {
        print('[v0] Updating restaurant ID: ${state.restaurantId}');
        await _supabase
            .from('restaurants')
            .update(restaurantData)
            .eq('id', state.restaurantId);

        await _deleteBookingsForRemovedDates(state.restaurantId,
            state.restaurantBookedDates, state.tempBookedDates);
      } else {
        restaurantData['owner_id'] = currentUserId;
        print('[v0] Creating new restaurant with owner_id: $currentUserId');
        print('[v0] Restaurant data: $restaurantData');

        await _supabase.from('restaurants').insert(restaurantData);
        print('[v0] Restaurant created successfully');
      }

      emit(state.copyWith(
        isLoading: false,
        restaurantBookedDates: state.tempBookedDates,
        tempBookedDates: state.tempBookedDates,
      ));

      Navigator.of(event.context).pop();
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Ошибка при сохранении: $e',
      ));
      print('[v0] ❌ Ошибка при сохранении ресторана: $e');
    }
  }

  // ... existing code ...

  Future<void> _onLoadRestaurantExtras(
      LoadRestaurantExtras event, Emitter<RestaurantState> emit) async {
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
        error: 'Ошибка загрузки дополнительных опций: $error',
        isExtrasLoading: false,
      ));
      debugPrint('❌ Ошибка загрузки extras: $error');
    }
  }

  Future<void> _onAddRestaurantExtra(
      AddRestaurantExtra event, Emitter<RestaurantState> emit) async {
    emit(state.copyWith(isExtrasLoading: true));

    try {
      final newExtra = RestaurantExtra(
        restaurantId: state.restaurantId,
        name: event.name,
        price: event.price,
        description: event.description,
      );

      final savedExtra = await _restaurantService.addRestaurantExtra(newExtra);
      final updatedExtras = [...state.restaurantExtras, savedExtra];

      emit(state.copyWith(
        restaurantExtras: updatedExtras,
        isExtrasLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        error: 'Ошибка добавления опции: $error',
        restaurantExtras: state.restaurantExtras,
        isExtrasLoading: false,
      ));
      debugPrint('❌ Ошибка добавления extra: $error');
    }
  }

  Future<void> _onUpdateRestaurantExtra(
      UpdateRestaurantExtra event, Emitter<RestaurantState> emit) async {
    emit(state.copyWith(isExtrasLoading: true));

    try {
      final extraIndex = state.restaurantExtras
          .indexWhere((extra) => extra.id == event.extraId);

      if (extraIndex != -1) {
        final currentExtra = state.restaurantExtras[extraIndex];
        final updatedExtra = currentExtra.copyWith(
          name: event.name ?? currentExtra.name,
          price: event.price ?? currentExtra.price,
          description: event.description ?? currentExtra.description,
          isActive: event.isActive ?? currentExtra.isActive,
        );

        final savedExtra =
            await _restaurantService.updateRestaurantExtra(updatedExtra);
        final updatedExtras = [...state.restaurantExtras];
        updatedExtras[extraIndex] = savedExtra;

        emit(state.copyWith(
          restaurantExtras: updatedExtras,
          isExtrasLoading: false,
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        error: 'Ошибка обновления опции: $error',
        isExtrasLoading: false,
      ));
    }
  }

  Future<void> _onRemoveRestaurantExtra(
      RemoveRestaurantExtra event, Emitter<RestaurantState> emit) async {
    emit(state.copyWith(isExtrasLoading: true));

    try {
      await _restaurantService.deleteRestaurantExtra(event.extraId);
      final updatedExtras = state.restaurantExtras
          .where((extra) => extra.id != event.extraId)
          .toList();

      emit(state.copyWith(
        restaurantExtras: updatedExtras,
        isExtrasLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        error: 'Ошибка удаления опции: $error',
        isExtrasLoading: false,
      ));
    }
  }

  Future<void> _onLoadRestaurantCategories(
      LoadRestaurantCategories event, Emitter<RestaurantState> emit) async {
    emit(state.copyWith(isCategoriesLoading: true));

    try {
      final categories =
          await _restaurantService.getRestaurantCategories(event.restaurantId);
      emit(state.copyWith(
        restaurantCategories: categories,
        isCategoriesLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        error: 'Ошибка загрузки категорий: $error',
        isCategoriesLoading: false,
      ));
      debugPrint('❌ Ошибка загрузки категорий: $error');
    }
  }

  Future<void> _onAddRestaurantCategory(
      AddRestaurantCategory event, Emitter<RestaurantState> emit) async {
    emit(state.copyWith(isCategoriesLoading: true));

    try {
      final newCategory = RestaurantCategory(
        restaurantId: state.restaurantId,
        name: event.name,
        priceRange: event.priceRange,
        description: event.description,
      );

      final savedCategory =
          await _restaurantService.addRestaurantCategory(newCategory);
      final updatedCategories = [...state.restaurantCategories, savedCategory];

      emit(state.copyWith(
        restaurantCategories: updatedCategories,
        isCategoriesLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        error: 'Ошибка добавления категории: $error',
        restaurantCategories: state.restaurantCategories,
        isCategoriesLoading: false,
      ));
      debugPrint('❌ Ошибка добавления категории: $error');
    }
  }

  Future<void> _onUpdateRestaurantCategory(
      UpdateRestaurantCategory event, Emitter<RestaurantState> emit) async {
    emit(state.copyWith(isCategoriesLoading: true));

    try {
      final categoryIndex = state.restaurantCategories
          .indexWhere((cat) => cat.id == event.categoryId);

      if (categoryIndex != -1) {
        final currentCategory = state.restaurantCategories[categoryIndex];
        final updatedCategory = currentCategory.copyWith(
          name: event.name ?? currentCategory.name,
          priceRange: event.priceRange ?? currentCategory.priceRange,
          description: event.description ?? currentCategory.description,
          isActive: event.isActive ?? currentCategory.isActive,
        );

        final savedCategory =
            await _restaurantService.updateRestaurantCategory(updatedCategory);
        final updatedCategories = [...state.restaurantCategories];
        updatedCategories[categoryIndex] = savedCategory;

        emit(state.copyWith(
          restaurantCategories: updatedCategories,
          isCategoriesLoading: false,
        ));
      }
    } catch (error) {
      emit(state.copyWith(
        error: 'Ошибка обновления категории: $error',
        isCategoriesLoading: false,
      ));
    }
  }

  Future<void> _onRemoveRestaurantCategory(
      RemoveRestaurantCategory event, Emitter<RestaurantState> emit) async {
    emit(state.copyWith(isCategoriesLoading: true));

    try {
      await _restaurantService.deleteRestaurantCategory(event.categoryId);
      final updatedCategories = state.restaurantCategories
          .where((cat) => cat.id != event.categoryId)
          .toList();

      emit(state.copyWith(
        restaurantCategories: updatedCategories,
        isCategoriesLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        error: 'Ошибка удаления категории: $error',
        isCategoriesLoading: false,
      ));
    }
  }

  Future<void> _onLoadBookedDates(
      LoadBookedDates event, Emitter<RestaurantState> emit) async {
    emit(state.copyWith(isLoading: true));

    try {
      final restaurantBookedDates =
          await _restaurantService.getRestaurantBookedDates(event.restaurantId);
      final visibleBookedDates =
          await _restaurantService.getBookedDates(event.restaurantId);

      emit(state.copyWith(
        restaurantBookedDates: restaurantBookedDates,
        visibleBookedDates: visibleBookedDates,
        isLoading: false,
      ));
    } catch (error) {
      emit(state.copyWith(
        error: 'Ошибка загрузки данных!',
        isLoading: false,
      ));
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

  void _onUpdateTempBookedDates(
      UpdateTempBookedDates event, Emitter<RestaurantState> emit) {
    emit(state.copyWith(tempBookedDates: event.dates));
  }

  void _onUpdateBookedDates(
      UpdateBookedDates event, Emitter<RestaurantState> emit) {
    emit(state.copyWith(tempBookedDates: event.dates));
  }

  String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  Future<String?> _pickImage(XFile pickedFile, String restaurantId) async {
    try {
      final bytes = await pickedFile.readAsBytes();

      final ext = pickedFile.name.split('.').last.toLowerCase();
      final validExt =
          ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext) ? ext : 'jpg';

      final uniqueFileName =
          'restaurant_${restaurantId}_${DateTime.now().millisecondsSinceEpoch}.$validExt';
      final pathInBucket = 'image_url/$uniqueFileName';

      final uploadResponse =
          await _supabase.storage.from('restaurants').uploadBinary(
                pathInBucket,
                bytes,
                fileOptions: FileOptions(
                  contentType: _getMimeType(validExt),
                  upsert: true,
                ),
              );

      if (uploadResponse == "") {
        final publicUrl =
            _supabase.storage.from('restaurants').getPublicUrl(pathInBucket);
        print('✅ Изображение загружено: $publicUrl');
        return publicUrl;
      } else {
        print(
            '⚠️ uploadBinary вернул путь (возможно уже существует): $uploadResponse');
        final fallbackUrl =
            _supabase.storage.from('restaurants').getPublicUrl(pathInBucket);
        return fallbackUrl;
      }
    } catch (e, stack) {
      print('❌ Ошибка в _pickImage: $e\n$stack');
      return null;
    }
  }

  Future<void> _updateRestaurantPhotos(
      String restaurantId, List<String> photoUrls) async {
    try {
      await _supabase.from('restaurants').update({
        'photos': photoUrls,
        'image_url': photoUrls.isNotEmpty ? photoUrls.first : null,
      }).eq('id', restaurantId);
      print('✅ Фотографии обновлены в таблице restaurants');
    } catch (e) {
      print('❌ Ошибка обновления фотографий: $e');
    }
  }

  Future<void> _onAddPhoto(
      AddPhoto event, Emitter<RestaurantState> emit) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      emit(state.copyWith(isLoading: true));

      final imageUrl =
          await _pickImage(pickedFile, event.restaurantId.toString());

      if (imageUrl != null) {
        final updatedPhotoUrls = List<String>.from(state.photoUrls)
          ..add(imageUrl);
        emit(state.copyWith(
          photoUrls: updatedPhotoUrls,
          isLoading: false,
        ));

        if (state.isEditing) {
          await _updateRestaurantPhotos(
              event.restaurantId.toString(), updatedPhotoUrls);
        }
      } else {
        emit(state.copyWith(
          error: 'Ошибка при загрузке изображения',
          isLoading: false,
        ));
      }
    } catch (e, stack) {
      print('❌ Ошибка при загрузке фото: $e\n$stack');
      emit(state.copyWith(
        error: 'Ошибка загрузки: ${e.toString()}',
        isLoading: false,
      ));
    }
  }

  String? _extractFilePathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;

      final restaurantsIndex = pathSegments.indexOf('restaurants');
      if (restaurantsIndex != -1 &&
          restaurantsIndex < pathSegments.length - 1) {
        final filePath = pathSegments.sublist(restaurantsIndex + 1).join('/');
        return filePath;
      }
      return null;
    } catch (e) {
      print('❌ Ошибка извлечения пути из URL: $e');
      return null;
    }
  }

  Future<bool> _deleteImageFromStorage(String imageUrl) async {
    try {
      final filePath = _extractFilePathFromUrl(imageUrl);
      if (filePath == null) {
        print('❌ Не удалось извлечь путь файла из URL: $imageUrl');
        return false;
      }

      await _supabase.storage.from('restaurants').remove([filePath]);
      print('✅ Файл удален из Storage: $filePath');
      return true;
    } catch (e) {
      print('❌ Ошибка удаления файла из Storage: $e');
      return false;
    }
  }

  Future<void> _onRemovePhoto(
      RemovePhoto event, Emitter<RestaurantState> emit) async {
    final updatedPhotoUrls = List<String>.from(state.photoUrls);
    if (event.index >= 0 && event.index < updatedPhotoUrls.length) {
      final imageUrlToDelete = updatedPhotoUrls[event.index];

      emit(state.copyWith(isLoading: true));
      final deletedFromStorage =
          await _deleteImageFromStorage(imageUrlToDelete);

      if (deletedFromStorage) {
        updatedPhotoUrls.removeAt(event.index);
        emit(state.copyWith(
          photoUrls: updatedPhotoUrls,
          isLoading: false,
        ));

        if (state.isEditing) {
          await _updateRestaurantPhotos(
              state.restaurantId.toString(), updatedPhotoUrls);
        }
      } else {
        emit(state.copyWith(
          error: 'Ошибка при удалении изображения из хранилища',
          isLoading: false,
        ));
      }
    }
  }

  Future<void> _deleteBookingsForRemovedDates(
    int restaurantId,
    List<DateTime> oldDates,
    List<DateTime> newDates,
  ) async {
    final removedDates =
        oldDates.where((date) => !newDates.contains(date)).toList();

    if (removedDates.isEmpty) return;

    print('[v0] Удаляем записи для дат: $removedDates');

    for (final date in removedDates) {
      try {
        final response = await _supabase
            .from('bookings')
            .select('id')
            .eq('restaurant_id', restaurantId)
            .gte('booking_time', date.toIso8601String().split('T')[0])
            .lt(
                'booking_time',
                DateTime(date.year, date.month, date.day + 1)
                    .toIso8601String()
                    .split('T')[0]);

        final bookings = response as List<dynamic>;

        for (final booking in bookings) {
          await _supabase.from('bookings').delete().eq('id', booking['id']);
        }

        print('[v0] Удалено ${bookings.length} записей для даты $date');
      } catch (e) {
        print('[v0] Ошибка при удалении записей для даты $date: $e');
      }
    }
  }
}
