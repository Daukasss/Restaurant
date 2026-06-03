// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:restauran/data/models/menu_category.dart';
import 'package:restauran/data/models/menu_item.dart';
import 'package:restauran/data/services/menu_service.dart';
import 'package:restauran/presentation/pages/seller/widgets/menu_category_card.dart';
import 'package:restauran/presentation/pages/seller/widgets/menu_item_dialog.dart';
import 'package:restauran/presentation/widgets/result_diolog.dart';
import 'package:restauran/theme/app_colors.dart';

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Удалить категорию',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text(
              'Вы уверены? Все блюда в этой категории также будут удалены. Это действие нельзя отменить.'),
          actions: [
            TextButton(
              child: Text('Отмена', style: TextStyle(color: Colors.grey[600])),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Удалить',
                  style: TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w600)),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Удалить блюдо',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: const Text(
              'Вы уверены, что хотите удалить это блюдо? Это действие нельзя отменить.'),
          actions: [
            TextButton(
              child: Text('Отмена', style: TextStyle(color: Colors.grey[600])),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Удалить',
                  style: TextStyle(
                      color: AppColors.danger, fontWeight: FontWeight.w600)),
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
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textMain),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Меню',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textMain,
          ),
        ),
        actions: [
          BlocBuilder<MenuBloc, MenuState>(
            builder: (context, state) {
              String? restaurantCategoryId;
              List<Map<String, dynamic>> restaurantCategories = [];
              if (state is MenuLoaded) {
                restaurantCategoryId = state.selectedRestaurantCategoryId;
                restaurantCategories = state.restaurantCategories;
              }
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: () => _addCategory(
                      context, restaurantCategoryId, restaurantCategories),
                  icon: const Icon(Icons.add_rounded,
                      size: 18, color: AppColors.primary),
                  label: const Text(
                    'Категория',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                          color: AppColors.primary.withOpacity(0.25), width: 1),
                    ),
                    backgroundColor: AppColors.primary.withOpacity(0.06),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: BlocConsumer<MenuBloc, MenuState>(
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
              return const Center(child: CircularProgressIndicator.adaptive());
            } else if (state is MenuLoaded) {
              final categories = state.categories;
              final restaurantCategories = state.restaurantCategories;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Фильтр по категориям ресторана ──
                  if (restaurantCategories.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: restaurantCategories.map((cat) {
                            final isSelected =
                                state.selectedRestaurantCategoryId == cat['id'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  if (!isSelected) {
                                    context.read<MenuBloc>().add(
                                          SelectRestaurantCategory(
                                              restaurantId, cat['id']),
                                        );
                                  }
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.divider,
                                    ),
                                  ),
                                  child: Text(
                                    '${cat['name']}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : AppColors.textSub,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                  Expanded(
                    child: Stack(
                      children: [
                        categories.isEmpty
                            ? _EmptyMenuState(
                                onAddCategory: () => _addCategory(
                                  context,
                                  state.selectedRestaurantCategoryId,
                                  restaurantCategories,
                                ),
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 16, 16, 32),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  return CategoryCard(
                                    category: categories[index],
                                    restaurantCategories: restaurantCategories,
                                    onEditCategory: (category) => _editCategory(
                                      context,
                                      category,
                                      restaurantCategories,
                                    ),
                                    onDeleteCategory: (id) =>
                                        _showDeleteCategoryConfirmation(
                                      context,
                                      id ?? '',
                                    ),
                                    onAddMenuItem: (categoryId) => _addMenuItem(
                                      context,
                                      categoryId ?? '',
                                    ),
                                    onEditMenuItem: (menuItem) =>
                                        _editMenuItem(context, menuItem),
                                    onDeleteMenuItem: (id) =>
                                        _showDeleteMenuItemConfirmation(
                                      context,
                                      id ?? '',
                                    ),
                                  );
                                },
                              ),
                        if (state.isCategoryLoading)
                          Positioned.fill(
                            child: Container(
                              color: Colors.white.withValues(alpha: 0.7),
                              child: const Center(
                                child: CircularProgressIndicator.adaptive(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            } else if (state is MenuError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        color: AppColors.danger, size: 52),
                    const SizedBox(height: 16),
                    Text('Ошибка: ${state.message}',
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.textSub),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => context
                          .read<MenuBloc>()
                          .add(LoadMenuCategories(restaurantId)),
                      child: const Text('Повторить'),
                    ),
                  ],
                ),
              );
            }

            return const Center(child: CircularProgressIndicator.adaptive());
          },
        ),
      ),
    );
  }
}

// ── Пустое состояние ──────────────────────────────────────────────────────────
class _EmptyMenuState extends StatelessWidget {
  final VoidCallback onAddCategory;

  const _EmptyMenuState({required this.onAddCategory});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Меню пока пусто',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textMain,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте первую категорию,\nчтобы начать добавлять блюда',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSub,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: onAddCategory,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text(
                  'Создать категорию',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
