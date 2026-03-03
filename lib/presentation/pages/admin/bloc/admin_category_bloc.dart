import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/models/global_category.dart';
import 'package:restauran/data/models/restaurant.dart';
import 'admin_category_event.dart';
import 'admin_category_state.dart';

class AdminCategoryBloc extends Bloc<AdminCategoryEvent, AdminCategoryState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminCategoryBloc() : super(AdminCategoryInitial()) {
    on<LoadGlobalCategoriesEvent>(_onLoadCategories);
    on<LoadAvailableRestaurantsEvent>(_onLoadRestaurants);
    on<AddGlobalCategoryEvent>(_onAddCategory);
    on<UpdateGlobalCategoryEvent>(_onUpdateCategory);
    on<DeleteGlobalCategoryEvent>(_onDeleteCategory);
    on<SearchGlobalCategoriesEvent>(_onSearchCategories);
    on<FilterCategoriesBySectionEvent>(_onFilterBySection);
  }

  Future<void> _onLoadCategories(
    LoadGlobalCategoriesEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    emit(AdminCategoryLoading());

    try {
      final querySnapshot = await _firestore
          .collection('global_categories')
          .where('is_active', isEqualTo: true)
          .orderBy('section')
          .orderBy('created_at', descending: true)
          .get();

      final categories = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return GlobalCategory.fromJson(data);
      }).toList();

      // Сохраняем текущий список ресторанов при обновлении категорий
      final currentRestaurants = state is AdminCategoryLoaded
          ? (state as AdminCategoryLoaded).availableRestaurants
          : <Restaurant>[];

      emit(AdminCategoryLoaded(
        categories: categories,
        filteredCategories: categories,
        availableRestaurants: currentRestaurants,
      ));
    } catch (error) {
      emit(AdminCategoryError('Не удалось загрузить категории: $error'));
    }
  }

  Future<void> _onLoadRestaurants(
    LoadAvailableRestaurantsEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    try {
      final snapshot =
          await _firestore.collection('restaurants').orderBy('name').get();
      final restaurants = snapshot.docs
          .map((doc) {
            try {
              final data = doc.data();
              data['id'] = doc.id;
              return Restaurant.fromJson(data);
            } catch (e) {
              return null;
            }
          })
          .whereType<Restaurant>()
          .toList();

      if (state is AdminCategoryLoaded) {
        final currentState = state as AdminCategoryLoaded;
        emit(currentState.copyWith(availableRestaurants: restaurants));
      } else {}
    } catch (error) {
      return null;
    }
  }

  Future<void> _onAddCategory(
    AddGlobalCategoryEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    print("🔥 ADD CATEGORY START");

    try {
      final category = GlobalCategory(
        name: event.name,
        section: event.section,
        defaultPrice: event.defaultPrice,
        description: event.description,
        isGlobal: event.isGlobal,
        restaurantIds: event.isGlobal ? [] : event.restaurantIds,
      );

      final data = category.toJson();
      data['created_at'] = FieldValue.serverTimestamp();
      data['is_active'] = true;

      print("🔥 DATA: $data");

      await _firestore.collection('global_categories').add(data);

      print("🔥 ADDED TO FIREBASE");

      emit(const AdminCategorySuccess('Категория успешно добавлена'));
      add(LoadGlobalCategoriesEvent());
    } catch (error) {
      print("🔥 FIREBASE ERROR: $error");
      emit(AdminCategoryError('Не удалось добавить категорию: $error'));
    }
  }

  Future<void> _onUpdateCategory(
    UpdateGlobalCategoryEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    try {
      final Map<String, dynamic> updates = {
        'updated_at': FieldValue.serverTimestamp(),
      };

      if (event.name != null) updates['name'] = event.name;
      if (event.section != null) updates['section'] = event.section;
      if (event.defaultPrice != null) {
        updates['default_price'] = event.defaultPrice;
      }
      if (event.description != null) updates['description'] = event.description;
      if (event.isGlobal != null) updates['is_global'] = event.isGlobal;

      // Обновляем restaurantIds только если категория не глобальная
      if (event.restaurantIds != null) {
        updates['restaurant_ids'] =
            event.isGlobal == true ? [] : event.restaurantIds;
      }
      if (event.isActive != null) updates['is_active'] = event.isActive;

      await _firestore
          .collection('global_categories')
          .doc(event.categoryId)
          .update(updates);

      emit(const AdminCategorySuccess('Категория успешно обновлена'));
      add(LoadGlobalCategoriesEvent());
    } catch (error) {
      emit(AdminCategoryError('Не удалось обновить категорию: $error'));
    }
  }

  Future<void> _onDeleteCategory(
    DeleteGlobalCategoryEvent event,
    Emitter<AdminCategoryState> emit,
  ) async {
    try {
      await _firestore
          .collection('global_categories')
          .doc(event.categoryId)
          .update({
        'is_active': false,
        'updated_at': FieldValue.serverTimestamp(),
      });

      emit(const AdminCategorySuccess('Категория успешно удалена'));
      add(LoadGlobalCategoriesEvent());
    } catch (error) {
      emit(AdminCategoryError('Не удалось удалить категорию: $error'));
    }
  }

  void _onSearchCategories(
    SearchGlobalCategoriesEvent event,
    Emitter<AdminCategoryState> emit,
  ) {
    if (state is AdminCategoryLoaded) {
      final currentState = state as AdminCategoryLoaded;
      final query = event.query.toLowerCase();

      var filtered = currentState.categories.where((category) {
        final name = category.name.toLowerCase();
        final description = category.description?.toLowerCase() ?? '';
        return name.contains(query) || description.contains(query);
      }).toList();

      if (currentState.selectedSection != null) {
        filtered = filtered
            .where((c) => c.section == currentState.selectedSection)
            .toList();
      }

      emit(currentState.copyWith(
        filteredCategories: filtered,
        searchQuery: query,
      ));
    }
  }

  void _onFilterBySection(
    FilterCategoriesBySectionEvent event,
    Emitter<AdminCategoryState> emit,
  ) {
    if (state is AdminCategoryLoaded) {
      final currentState = state as AdminCategoryLoaded;

      var filtered = currentState.categories;

      if (event.section != null) {
        filtered = filtered.where((c) => c.section == event.section).toList();
      }

      if (currentState.searchQuery.isNotEmpty) {
        final query = currentState.searchQuery.toLowerCase();
        filtered = filtered.where((category) {
          final name = category.name.toLowerCase();
          final description = category.description?.toLowerCase() ?? '';
          return name.contains(query) || description.contains(query);
        }).toList();
      }

      emit(currentState.copyWith(
        filteredCategories: filtered,
        selectedSection: event.section,
        clearSection: event.section == null,
      ));
    }
  }
}
