import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../../data/models/menu_category.dart';
import '../../../../../../data/services/menu_service.dart';
import 'menu_event.dart';
import 'menu_state.dart';

class MenuBloc extends Bloc<MenuEvent, MenuState> {
  final MenuService _menuService;

  MenuBloc({required MenuService menuService})
      : _menuService = menuService,
        super(MenuInitial()) {
    on<LoadMenuCategories>(_onLoadMenuCategories);
    on<LoadRestaurantCategories>(_onLoadRestaurantCategories);
    on<SelectRestaurantCategory>(_onSelectRestaurantCategory);
    on<AddMenuCategory>(_onAddMenuCategory);
    on<UpdateMenuCategory>(_onUpdateMenuCategory);
    on<DeleteMenuCategory>(_onDeleteMenuCategory);
    on<AddMenuItem>(_onAddMenuItem);
    on<UpdateMenuItem>(_onUpdateMenuItem);
    on<DeleteMenuItem>(_onDeleteMenuItem);
  }

  Future<void> _onLoadMenuCategories(
      LoadMenuCategories event, Emitter<MenuState> emit) async {
    emit(MenuLoading());
    try {
      final restaurantCategories =
          await _menuService.getRestaurantCategories(event.restaurantId);

      String? selectedCategoryId = event.restaurantCategoryId;
      if (selectedCategoryId == null && restaurantCategories.isNotEmpty) {
        selectedCategoryId = restaurantCategories.first['id'];
      }

      List<MenuCategory> categories;

      if (selectedCategoryId != null) {
        categories = await _menuService.getMenuCategoriesByRestaurantCategory(
            event.restaurantId, selectedCategoryId);
      } else {
        categories = await _menuService.getMenuCategories(event.restaurantId);
      }

      emit(MenuLoaded(
        categories,
        restaurantCategories: restaurantCategories,
        selectedRestaurantCategoryId: selectedCategoryId,
      ));
    } catch (error) {
      emit(MenuError('Failed to load menu categories: ${error.toString()}'));
    }
  }

  Future<void> _onLoadRestaurantCategories(
      LoadRestaurantCategories event, Emitter<MenuState> emit) async {
    try {
      final restaurantCategories =
          await _menuService.getRestaurantCategories(event.restaurantId);
      emit(RestaurantCategoriesLoaded(restaurantCategories));
    } catch (error) {
      emit(MenuError(
          'Failed to load restaurant categories: ${error.toString()}'));
    }
  }

  Future<void> _onSelectRestaurantCategory(
      SelectRestaurantCategory event, Emitter<MenuState> emit) async {
    emit(MenuLoading());
    try {
      final categories =
          await _menuService.getMenuCategoriesByRestaurantCategory(
              event.restaurantId, event.restaurantCategoryId);

      final restaurantCategories =
          await _menuService.getRestaurantCategories(event.restaurantId);

      emit(MenuLoaded(
        categories,
        restaurantCategories: restaurantCategories,
        selectedRestaurantCategoryId: event.restaurantCategoryId,
      ));
    } catch (error) {
      emit(MenuError(
          'Failed to load menu for selected category: ${error.toString()}'));
    }
  }

  Future<void> _onAddMenuCategory(
      AddMenuCategory event, Emitter<MenuState> emit) async {
    try {
      await _menuService.addCategory(event.category);
      emit(CategoryAdded());

      // Перезагружаем с первой из привязанных категорий
      final reloadCategoryId = event.category.restaurantCategoryIds.isNotEmpty
          ? event.category.restaurantCategoryIds.first
          : null;

      add(LoadMenuCategories(
        event.category.restaurantId,
        restaurantCategoryId: reloadCategoryId,
      ));
    } catch (error) {
      emit(MenuError('Failed to add category: ${error.toString()}'));
    }
  }

  Future<void> _onUpdateMenuCategory(
      UpdateMenuCategory event, Emitter<MenuState> emit) async {
    try {
      await _menuService.updateCategory(event.categoryId, event.category);
      emit(CategoryUpdated());

      final reloadCategoryId = event.category.restaurantCategoryIds.isNotEmpty
          ? event.category.restaurantCategoryIds.first
          : null;

      add(LoadMenuCategories(
        event.category.restaurantId,
        restaurantCategoryId: reloadCategoryId,
      ));
    } catch (error) {
      emit(MenuError('Failed to update category: ${error.toString()}'));
    }
  }

  Future<void> _onDeleteMenuCategory(
      DeleteMenuCategory event, Emitter<MenuState> emit) async {
    try {
      final currentState = state;
      String? restaurantId;
      String? restaurantCategoryId;

      if (currentState is MenuLoaded && currentState.categories.isNotEmpty) {
        final category = currentState.categories.firstWhere(
          (c) => c.id == event.categoryId,
          orElse: () => currentState.categories.first,
        );
        restaurantId = category.restaurantId;
        restaurantCategoryId = category.restaurantCategoryIds.isNotEmpty
            ? category.restaurantCategoryIds.first
            : null;
      }

      await _menuService.deleteCategory(event.categoryId);
      emit(CategoryDeleted());

      if (restaurantId != null) {
        add(LoadMenuCategories(
          restaurantId,
          restaurantCategoryId: restaurantCategoryId,
        ));
      }
    } catch (error) {
      emit(MenuError('Failed to delete category: ${error.toString()}'));
    }
  }

  Future<void> _onAddMenuItem(
      AddMenuItem event, Emitter<MenuState> emit) async {
    try {
      await _menuService.addMenuItem(event.menuItem);
      emit(MenuItemAdded());
      add(LoadMenuCategories(event.menuItem.restaurantId));
    } catch (error) {
      emit(MenuError('Failed to add menu item: ${error.toString()}'));
    }
  }

  Future<void> _onUpdateMenuItem(
      UpdateMenuItem event, Emitter<MenuState> emit) async {
    try {
      await _menuService.updateMenuItem(event.menuItemId, event.menuItem);
      emit(MenuItemUpdated());
      add(LoadMenuCategories(event.menuItem.restaurantId));
    } catch (error) {
      emit(MenuError('Failed to update menu item: ${error.toString()}'));
    }
  }

  Future<void> _onDeleteMenuItem(
      DeleteMenuItem event, Emitter<MenuState> emit) async {
    try {
      final currentState = state;
      String? restaurantId;

      if (currentState is MenuLoaded && currentState.categories.isNotEmpty) {
        restaurantId = currentState.categories.first.restaurantId;
      }

      await _menuService.deleteMenuItem(event.menuItemId);
      emit(MenuItemDeleted());

      if (restaurantId != null) {
        add(LoadMenuCategories(restaurantId));
      }
    } catch (error) {
      emit(MenuError('Failed to delete menu item: ${error.toString()}'));
    }
  }
}
