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
      // ✅ Запускаем независимые запросы параллельно
      final results = await Future.wait([
        _firestore
            .collection('restaurants')
            .doc(event.restaurantId.toString())
            .get(),
        _firestore
            .collection('restaurant_categories')
            .where('restaurant_id', isEqualTo: event.restaurantId)
            .where('is_active', isEqualTo: true)
            .orderBy('created_at')
            .get(),
        _firestore
            .collection('menu_categories')
            .where('restaurant_id', isEqualTo: event.restaurantId)
            .get(),
        _firestore
            .collection('menu_items')
            .where('restaurant_id', isEqualTo: event.restaurantId)
            .get(),
        _fetchIsFavorite(event.restaurantId),
      ]);

      // ── Разбираем результаты ──────────────────────────────────────────

      final restaurantDoc =
          results[0] as DocumentSnapshot<Map<String, dynamic>>;
      if (!restaurantDoc.exists) throw Exception('Ресторан не найден');
      final restaurant = restaurantDoc.data()!;
      restaurant['id'] = restaurantDoc.id;

      final restaurantCategoriesSnapshot =
          results[1] as QuerySnapshot<Map<String, dynamic>>;
      final restaurantCategories = restaurantCategoriesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RestaurantCategory.fromJson(data);
      }).toList();

      final categoriesSnapshot =
          results[2] as QuerySnapshot<Map<String, dynamic>>;
      final categoriesList = categoriesSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      final menuItemsSnapshot =
          results[3] as QuerySnapshot<Map<String, dynamic>>;
      final menuItemsList = menuItemsSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      final isFavorite = results[4] as bool;

      // ── Строим menuByRestaurantCategory без доп. запросов ─────────────
      // Все данные уже загружены — только группируем в памяти

      // Индексируем меню-категории по id для быстрого поиска
      final menuCategoriesById = <String, Map<String, dynamic>>{
        for (final c in categoriesList) c['id'] as String: c,
      };

      // Группируем блюда по category_id
      final menuItemsByCategoryId = <String, List<Map<String, dynamic>>>{};
      for (final item in menuItemsList) {
        final catId = item['category_id'] as String? ?? '';
        menuItemsByCategoryId.putIfAbsent(catId, () => []).add(item);
      }

      // Строим menuByRestaurantCategory — только группировка, без сети
      final menuByRestaurantCategory = <String, Map<String, dynamic>>{};

      for (final restCategory in restaurantCategories) {
        // Меню-категории этой зоны ресторана
        final menuCategoriesForZone = categoriesList.where((c) {
          final ids = c['restaurant_category_ids'];
          return ids is List && ids.contains(restCategory.id);
        }).toList();

        final menuItemsByMenuCategory = <String, List<Map<String, dynamic>>>{};
        for (final menuCategory in menuCategoriesForZone) {
          final id = menuCategory['id'] as String;
          menuItemsByMenuCategory[id] = menuItemsByCategoryId[id] ?? [];
        }

        menuByRestaurantCategory[restCategory.id!] = {
          'menuCategories': menuCategoriesForZone,
          'menuItems': menuItemsByMenuCategory,
        };
      }

      final photoUrls = _parsePhotos(restaurant);
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

  /// Проверка избранного вынесена в отдельный метод для чистоты Future.wait
  Future<bool> _fetchIsFavorite(String restaurantId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;
    try {
      final snapshot = await _firestore
          .collection('favorites')
          .where('user_id', isEqualTo: currentUser.uid)
          .where('restaurant_id', isEqualTo: restaurantId)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (_) {
      return false;
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
        final favsSnapshot = await _firestore
            .collection('favorites')
            .where('user_id', isEqualTo: currentUser.uid)
            .where('restaurant_id', isEqualTo: event.restaurantId)
            .get();

        // ✅ Удаляем все документы параллельно
        await Future.wait(
          favsSnapshot.docs.map((doc) => doc.reference.delete()),
        );
      } else {
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

  Map<String, List<Map<String, dynamic>>> _groupMenuItemsByCategory(
      List<Map<String, dynamic>> menuItems) {
    final result = <String, List<Map<String, dynamic>>>{};
    for (final item in menuItems) {
      final categoryId = item['category_id'] as String;
      result.putIfAbsent(categoryId, () => []).add(item);
    }
    return result;
  }
}
