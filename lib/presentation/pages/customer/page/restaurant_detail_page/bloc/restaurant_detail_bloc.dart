import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../../../../data/models/restaurant_category.dart';
import 'restaurant_detail_event.dart';
import 'restaurant_detail_state.dart';

class RestaurantDetailBloc
    extends Bloc<RestaurantDetailEvent, RestaurantDetailState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  RestaurantDetailBloc() : super(const RestaurantDetailState()) {
    on<FetchRestaurantData>(_onFetchRestaurantData);
    on<ToggleFavorite>(_onToggleFavorite);
  }

  Future<void> _onFetchRestaurantData(
    FetchRestaurantData event,
    Emitter<RestaurantDetailState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      // Получаем ресторан
      final restaurantDoc = await _firestore
          .collection('restaurants')
          .doc(event.restaurantId.toString())
          .get();

      if (!restaurantDoc.exists) {
        throw Exception('Ресторан не найден');
      }

      final restaurant = restaurantDoc.data()!;
      restaurant['id'] = (restaurantDoc.id);

      // Получаем категории ресторана
      final restaurantCategoriesSnapshot = await _firestore
          .collection('restaurant_categories')
          .where('restaurant_id', isEqualTo: event.restaurantId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at')
          .get();

      final restaurantCategories = restaurantCategoriesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RestaurantCategory.fromJson(data);
      }).toList();

      final menuByRestaurantCategory = <String, Map<String, dynamic>>{};

      for (final restCategory in restaurantCategories) {
        // Загружаем категории меню для этой категории ресторана
        // Используем array-contains т.к. поле restaurant_category_ids — список
        final menuCategoriesSnapshot = await _firestore
            .collection('menu_categories')
            .where('restaurant_id', isEqualTo: event.restaurantId)
            .where('restaurant_category_ids', arrayContains: restCategory.id)
            .get();

        final menuCategoriesList = menuCategoriesSnapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        final menuItemsByMenuCategory = <String, List<Map<String, dynamic>>>{};

        for (final menuCategory in menuCategoriesList) {
          final menuItemsSnapshot = await _firestore
              .collection('menu_items')
              .where('category_id', isEqualTo: menuCategory['id'])
              .get();

          menuItemsByMenuCategory[menuCategory['id']] =
              menuItemsSnapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        }

        menuByRestaurantCategory[restCategory.id!] = {
          'menuCategories': menuCategoriesList,
          'menuItems': menuItemsByMenuCategory,
        };
      }

      // Получаем все категории меню
      final categoriesSnapshot = await _firestore
          .collection('menu_categories')
          .where('restaurant_id', isEqualTo: event.restaurantId)
          .get();

      final categoriesList = categoriesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Получаем все блюда
      final menuItemsSnapshot = await _firestore
          .collection('menu_items')
          .where('restaurant_id', isEqualTo: event.restaurantId)
          .get();

      final menuItemsList = menuItemsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Проверяем, в избранном ли ресторан
      bool isFavorite = false;
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final favsSnapshot = await _firestore
            .collection('favorites')
            .where('user_id', isEqualTo: currentUser.uid)
            .where('restaurant_id', isEqualTo: event.restaurantId)
            .get();

        isFavorite = favsSnapshot.docs.isNotEmpty;
      }

      final photoUrls = _parsePhotos(restaurant);

      // Группируем блюда по категориям
      final menuItemsByCategory = _groupMenuItemsByCategory(menuItemsList);

      emit(state.copyWith(
        restaurant: restaurant,
        menuItems: menuItemsList,
        photoUrls: photoUrls,
        isLoading: false,
        isFavorite: isFavorite,
        categories: categoriesList,
        menuItemsByCategory: menuItemsByCategory,
        restaurantCategories: restaurantCategories,
        menuByRestaurantCategory: menuByRestaurantCategory,
      ));
    } catch (e) {
      developer.log('Ошибка загрузки данных: $e');
      emit(state.copyWith(
        isLoading: false,
        error: 'Ошибка загрузки данных!',
      ));
    }
  }

  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<RestaurantDetailState> emit,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      emit(state.copyWith(
        error: 'Пожалуйста, войдите в систему, чтобы добавить в избранное.',
      ));
      return;
    }

    try {
      if (state.isFavorite) {
        // Удаляем из избранного
        final favsSnapshot = await _firestore
            .collection('favorites')
            .where('user_id', isEqualTo: currentUser.uid)
            .where('restaurant_id', isEqualTo: event.restaurantId)
            .get();

        for (var doc in favsSnapshot.docs) {
          await doc.reference.delete();
        }
      } else {
        // Добавляем в избранное
        await _firestore.collection('favorites').add({
          'user_id': currentUser.uid,
          'restaurant_id': event.restaurantId,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      emit(state.copyWith(isFavorite: !state.isFavorite));
    } catch (e) {
      developer.log('Ошибка избранного: $e');
      emit(state.copyWith(
        error: 'Ошибка при обновлении избранного.',
      ));
    }
  }

  List<String> _parsePhotos(Map<String, dynamic> data) {
    final rawPhotos = data['photos'];
    List<String> photos = [];

    if (rawPhotos != null) {
      if (rawPhotos is List) {
        photos = List<String>.from(
            rawPhotos.where((p) => p != null && p.toString().isNotEmpty));
      } else if (rawPhotos is String) {
        try {
          final parsed = jsonDecode(rawPhotos);
          if (parsed is List) {
            photos = List<String>.from(
                parsed.where((p) => p != null && p.toString().isNotEmpty));
          } else {
            photos.add(parsed.toString());
          }
        } catch (_) {
          photos.add(rawPhotos);
        }
      }
    }

    if (photos.isEmpty && data['image_url'] != null) {
      photos.add(data['image_url']);
    }

    return photos;
  }

  // Метод для группировки блюд по категориям
  Map<String, List<Map<String, dynamic>>> _groupMenuItemsByCategory(
      List<Map<String, dynamic>> menuItems) {
    final result = <String, List<Map<String, dynamic>>>{};

    for (final item in menuItems) {
      final categoryId = item['category_id'] as String;
      if (!result.containsKey(categoryId)) {
        result[categoryId] = [];
      }
      result[categoryId]!.add(item);
    }

    return result;
  }
}
