// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:restauran/data/models/menu_category.dart';
import 'package:restauran/data/models/menu_item.dart';
import 'package:restauran/data/services/menu_service.dart';
import 'package:restauran/presentation/pages/seller/widgets/menu_category_card.dart';
import 'package:restauran/presentation/pages/seller/widgets/menu_item_dialog.dart';
import 'package:restauran/presentation/widgets/result_diolog.dart';

import '../../../widgets/category_dialog.dart';
import '../bloc/menu_bloc.dart';
import '../bloc/menu_event.dart';
import '../bloc/menu_state.dart';

class MenuManagementPage extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;

  const MenuManagementPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => MenuBloc(
        menuService: MenuService(),
      )..add(LoadMenuCategories(restaurantId)),
      child: _MenuManagementView(
        restaurantId: restaurantId,
        restaurantName: restaurantName,
      ),
    );
  }
}

class _MenuManagementView extends StatelessWidget {
  final String restaurantId;
  final String restaurantName;

  const _MenuManagementView({
    required this.restaurantId,
    required this.restaurantName,
  });

  void _addCategory(
    BuildContext context,
    String? selectedRestaurantCategoryId,
    List<Map<String, dynamic>> restaurantCategories,
  ) async {
    final preselected = selectedRestaurantCategoryId != null
        ? [selectedRestaurantCategoryId]
        : <String>[];

    final result = await CategoryDialog.show(
      context,
      restaurantCategories: restaurantCategories,
      initialSelectedCategoryIds: preselected,
    );

    if (result != null) {
      final ids = List<String>.from(result['restaurant_category_ids'] ?? []);
      final newCategory = MenuCategory(
        id: '',
        restaurantId: restaurantId,
        restaurantCategoryIds: ids,
        name: result['name'],
        description: result['description'],
        requiresSelection: result['requires_selection'],
        displayOrder: 0,
        menuItems: [],
      );
      context.read<MenuBloc>().add(AddMenuCategory(newCategory));
    }
  }

  void _editCategory(
    BuildContext context,
    MenuCategory category,
    List<Map<String, dynamic>> restaurantCategories,
  ) async {
    final result = await CategoryDialog.show(
      context,
      initialName: category.name,
      initialDescription: category.description,
      initialRequiresSelection: category.requiresSelection,
      restaurantCategories: restaurantCategories,
      initialSelectedCategoryIds: category.restaurantCategoryIds,
    );

    if (result != null) {
      final ids = List<String>.from(result['restaurant_category_ids'] ?? []);
      final updatedCategory = MenuCategory(
        id: category.id,
        restaurantId: category.restaurantId,
        restaurantCategoryIds: ids,
        name: result['name'],
        description: result['description'],
        requiresSelection: result['requires_selection'],
        displayOrder: category.displayOrder,
        menuItems: category.menuItems,
      );
      context.read<MenuBloc>().add(
            UpdateMenuCategory(category.id ?? '', updatedCategory),
          );
    }
  }

  void _showDeleteCategoryConfirmation(
      BuildContext context, String categoryId) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удалить категорию'),
          content: const SingleChildScrollView(
            child: Text(
                'Вы уверены, что хотите удалить эту категорию? Все блюда в этой категории также будут удалены. Это действие нельзя отменить.'),
          ),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (result == true) {
      context.read<MenuBloc>().add(DeleteMenuCategory(categoryId));
    }
  }

  void _addMenuItem(BuildContext context, String categoryId) async {
    final result = await MenuItemBottomSheet.show(
      context,
      restaurantId: restaurantId,
    );
    if (result != null) {
      context.read<MenuBloc>().add(AddMenuItem(MenuItem(
            categoryId: categoryId,
            restaurantId: restaurantId,
            name: result['name'],
            description: result['description'],
            imageUrl: result['image_url'] ?? '',
          )));
    }
  }

  void _editMenuItem(BuildContext context, MenuItem menuItem) async {
    final result = await MenuItemBottomSheet.show(
      context,
      restaurantId: restaurantId,
      initialName: menuItem.name,
      initialDescription: menuItem.description,
      initialImageUrl: menuItem.imageUrl,
    );
    if (result != null) {
      context.read<MenuBloc>().add(UpdateMenuItem(
            menuItem.id!,
            MenuItem(
              id: menuItem.id,
              categoryId: menuItem.categoryId,
              restaurantId: menuItem.restaurantId,
              name: result['name'],
              description: result['description'],
              imageUrl: result['image_url'] ?? menuItem.imageUrl,
            ),
          ));
    }
  }

  void _showDeleteMenuItemConfirmation(
      BuildContext context, String menuItemId) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удалить блюдо'),
          content: const SingleChildScrollView(
            child: Text(
                'Вы уверены, что хотите удалить это блюдо? Это действие нельзя отменить.'),
          ),
          actions: [
            TextButton(
              child: const Text('Отмена'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Удалить', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );
    if (result == true) {
      context.read<MenuBloc>().add(DeleteMenuItem(menuItemId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Меню - $restaurantName')),
      body: BlocConsumer<MenuBloc, MenuState>(
        listener: (context, state) {
          if (state is MenuError) {
            showResultDialog(
                context: context,
                isSuccess: false,
                title: 'Ошибка',
                message: state.message);
          } else if (state is CategoryAdded) {
            showResultDialog(
                context: context,
                isSuccess: true,
                title: 'Успешно',
                message: 'Категория успешно добавлена');
          } else if (state is CategoryUpdated) {
            showResultDialog(
                context: context,
                isSuccess: true,
                title: 'Успешно',
                message: 'Категория успешно обновлена');
          } else if (state is CategoryDeleted) {
            showResultDialog(
                context: context,
                isSuccess: true,
                title: 'Успешно',
                message: 'Категория успешно удалена');
          } else if (state is MenuItemAdded) {
            showResultDialog(
                context: context,
                isSuccess: true,
                title: 'Успешно',
                message: 'Блюдо успешно добавлено');
          } else if (state is MenuItemUpdated) {
            showResultDialog(
                context: context,
                isSuccess: true,
                title: 'Успешно',
                message: 'Блюдо успешно обновлено');
          } else if (state is MenuItemDeleted) {
            showResultDialog(
                context: context,
                isSuccess: true,
                title: 'Успешно',
                message: 'Блюдо успешно удалено');
          }
        },
        builder: (context, state) {
          if (state is MenuLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is MenuLoaded) {
            final categories = state.categories;
            final restaurantCategories = state.restaurantCategories;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (restaurantCategories.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Выберите категорию ресторана:',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: restaurantCategories.map((cat) {
                              final isSelected =
                                  state.selectedRestaurantCategoryId ==
                                      cat['id'];
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(
                                      '${cat['name']} - \$${cat['price_range']}'),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    if (selected) {
                                      context.read<MenuBloc>().add(
                                            SelectRestaurantCategory(
                                                restaurantId, cat['id']),
                                          );
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(),
                Expanded(
                  child: categories.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Категории меню отсутствуют',
                                  style: TextStyle(fontSize: 16)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () => _addCategory(
                                    context,
                                    state.selectedRestaurantCategoryId,
                                    restaurantCategories),
                                icon: const Icon(Icons.add),
                                label: const Text('Добавить категорию'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            return CategoryCard(
                              category: categories[index],
                              restaurantCategories: restaurantCategories,
                              onEditCategory: (category) => _editCategory(
                                  context, category, restaurantCategories),
                              onDeleteCategory: (id) =>
                                  _showDeleteCategoryConfirmation(
                                      context, id ?? ''),
                              onAddMenuItem: (categoryId) =>
                                  _addMenuItem(context, categoryId ?? ''),
                              onEditMenuItem: (menuItem) =>
                                  _editMenuItem(context, menuItem),
                              onDeleteMenuItem: (id) =>
                                  _showDeleteMenuItemConfirmation(
                                      context, id ?? ''),
                            );
                          },
                        ),
                ),
              ],
            );
          } else if (state is MenuError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  Text('Ошибка: ${state.message}',
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context
                        .read<MenuBloc>()
                        .add(LoadMenuCategories(restaurantId)),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: BlocBuilder<MenuBloc, MenuState>(
        builder: (context, state) {
          String? restaurantCategoryId;
          List<Map<String, dynamic>> restaurantCategories = [];
          if (state is MenuLoaded) {
            restaurantCategoryId = state.selectedRestaurantCategoryId;
            restaurantCategories = state.restaurantCategories;
          }
          return FloatingActionButton(
            onPressed: () => _addCategory(
                context, restaurantCategoryId, restaurantCategories),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
