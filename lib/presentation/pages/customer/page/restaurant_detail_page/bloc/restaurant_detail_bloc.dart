import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:developer' as developer;
import '../../../../../../data/models/restaurant_category.dart';
import '../../../../../../theme/aq_toi.dart';
import 'restaurant_detail_event.dart';
import 'restaurant_detail_state.dart';

class RestaurantDetailBloc
    extends Bloc<RestaurantDetailEvent, RestaurantDetailState> {
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
      final restaurant = await supabase
          .from('restaurants')
          .select()
          .eq('id', event.restaurantId)
          .single();

      final restaurantCategoriesData = await supabase
          .from('restaurant_categories')
          .select()
          .eq('restaurant_id', event.restaurantId)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      final restaurantCategories =
          List<Map<String, dynamic>>.from(restaurantCategoriesData)
              .map((json) => RestaurantCategory.fromJson(json))
              .toList();

      final menuByRestaurantCategory = <int, Map<String, dynamic>>{};

      for (final restCategory in restaurantCategories) {
        // Load menu categories for this restaurant category
        final menuCategories = await supabase
            .from('menu_categories')
            .select()
            .eq('restaurant_id', event.restaurantId)
            .eq('restaurant_category_id', restCategory.id as Object);

        final menuCategoriesList =
            List<Map<String, dynamic>>.from(menuCategories);

        final menuItemsByMenuCategory =
            Map<int, List<Map<String, dynamic>>>.fromEntries(
                menuCategoriesList.map((category) =>
                    MapEntry(category['id'] as int, <Map<String, dynamic>>[])));

        for (final menuCategory in menuCategoriesList) {
          final menuItems = await supabase
              .from('menu_items')
              .select()
              .eq('category_id', menuCategory['id']);

          menuItemsByMenuCategory[menuCategory['id'] as int] =
              List<Map<String, dynamic>>.from(menuItems);
        }

        menuByRestaurantCategory[restCategory.id!] = {
          'menuCategories': menuCategoriesList,
          'menuItems': menuItemsByMenuCategory,
        };
      }

      // Получаем категории меню
      final categories = await supabase
          .from('menu_categories')
          .select()
          .eq('restaurant_id', event.restaurantId);

      // Получаем все блюда
      final menuItems = await supabase
          .from('menu_items')
          .select()
          .eq('restaurant_id', event.restaurantId);

      bool isFavorite = false;
      final currentUser = supabase.auth.currentUser;
      if (currentUser != null) {
        final favs = await supabase
            .from('favorites')
            .select()
            .eq('user_id', currentUser.id)
            .eq('restaurant_id', event.restaurantId);

        isFavorite = favs.isNotEmpty;
      }

      final photoUrls = _parsePhotos(restaurant);
      final menuItemsList = List<Map<String, dynamic>>.from(menuItems);
      final categoriesList = List<Map<String, dynamic>>.from(categories);

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
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      emit(state.copyWith(
        error: 'Пожалуйста, войдите в систему, чтобы добавить в избранное.',
      ));
      return;
    }

    try {
      if (state.isFavorite) {
        await supabase
            .from('favorites')
            .delete()
            .eq('user_id', currentUser.id)
            .eq('restaurant_id', event.restaurantId);
      } else {
        await supabase.from('favorites').insert({
          'user_id': currentUser.id,
          'restaurant_id': event.restaurantId,
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
  Map<int, List<Map<String, dynamic>>> _groupMenuItemsByCategory(
      List<Map<String, dynamic>> menuItems) {
    final result = <int, List<Map<String, dynamic>>>{};

    for (final item in menuItems) {
      final categoryId = item['category_id'] as int;
      if (!result.containsKey(categoryId)) {
        result[categoryId] = [];
      }
      result[categoryId]!.add(item);
    }

    return result;
  }
}
