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
      // Сначала загружаем категории ресторана
      final restaurantCategories =
          await _menuService.getRestaurantCategories(event.restaurantId);

      int? selectedCategoryId = event.restaurantCategoryId;
      if (selectedCategoryId == null && restaurantCategories.isNotEmpty) {
        selectedCategoryId = restaurantCategories.first['id'] as int;
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

      // Reload categories after adding
      add(LoadMenuCategories(
        event.category.restaurantId,
        restaurantCategoryId: event.category.restaurantCategoryId,
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

      // Reload categories after updating
      add(LoadMenuCategories(
        event.category.restaurantId,
        restaurantCategoryId: event.category.restaurantCategoryId,
      ));
    } catch (error) {
      emit(MenuError('Failed to update category: ${error.toString()}'));
    }
  }

  Future<void> _onDeleteMenuCategory(
      DeleteMenuCategory event, Emitter<MenuState> emit) async {
    try {
      // Store the current state to get restaurantId after deletion
      final currentState = state;
      int? restaurantId;
      int? restaurantCategoryId;

      if (currentState is MenuLoaded && currentState.categories.isNotEmpty) {
        // Find the category to get its restaurantId
        final category = currentState.categories.firstWhere(
          (c) => c.id == event.categoryId,
          orElse: () => currentState.categories.first,
        );
        restaurantId = category.restaurantId;
        restaurantCategoryId = category.restaurantCategoryId;
      }

      await _menuService.deleteCategory(event.categoryId);
      emit(CategoryDeleted());

      // Reload categories after deletion
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

      // Reload categories after adding item
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

      // Reload categories after updating item
      add(LoadMenuCategories(event.menuItem.restaurantId));
    } catch (error) {
      emit(MenuError('Failed to update menu item: ${error.toString()}'));
    }
  }

  Future<void> _onDeleteMenuItem(
      DeleteMenuItem event, Emitter<MenuState> emit) async {
    try {
      // Store the current state to get restaurantId after deletion
      final currentState = state;
      int? restaurantId;

      if (currentState is MenuLoaded) {
        // Find the restaurantId from any category
        if (currentState.categories.isNotEmpty) {
          restaurantId = currentState.categories.first.restaurantId;
        }
      }

      await _menuService.deleteMenuItem(event.menuItemId);
      emit(MenuItemDeleted());

      // Reload categories after deletion
      if (restaurantId != null) {
        add(LoadMenuCategories(restaurantId));
      }
    } catch (error) {
      emit(MenuError('Failed to delete menu item: ${error.toString()}'));
    }
  }
}
