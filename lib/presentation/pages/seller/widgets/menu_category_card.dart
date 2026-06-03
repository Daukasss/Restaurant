import 'package:flutter/material.dart';
import 'package:restauran/presentation/pages/seller/widgets/menu_item_title.dart';
import 'package:restauran/theme/app_colors.dart';
import '../../../../data/models/menu_category.dart';
import '../../../../data/models/menu_item.dart';

class CategoryCard extends StatelessWidget {
  final MenuCategory category;
  final List<Map<String, dynamic>> restaurantCategories;
  final Function(MenuCategory) onEditCategory;
  final Function(String?) onDeleteCategory;
  final Function(String?) onAddMenuItem;
  final Function(MenuItem) onEditMenuItem;
  final Function(String?) onDeleteMenuItem;

  const CategoryCard({
    super.key,
    required this.category,
    this.restaurantCategories = const [],
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onAddMenuItem,
    required this.onEditMenuItem,
    required this.onDeleteMenuItem,
  });

  List<MenuItem> get _parsedMenuItems {
    return category.menuItems.map((item) {
      if (item is MenuItem) return item;
      if (item is Map<String, dynamic>) return MenuItem.fromJson(item);
      return MenuItem.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final parsedItems = _parsedMenuItems;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Заголовок ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppColors.textMain,
                        ),
                      ),
                      if (category.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          category.description,
                          style: const TextStyle(
                            color: AppColors.textSub,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // ── Кнопка "Изменить" ──
                GestureDetector(
                  onTap: () => onEditCategory(category),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.2), width: 1),
                    ),
                    child: const Text(
                      'Изменить',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Разделитель ──
          Divider(height: 1, color: AppColors.divider),

          // ── Блюда ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: parsedItems.isEmpty
                ? _EmptyCategoryItems(
                    onAddMenuItem: () => onAddMenuItem(category.id),
                  )
                : Column(
                    children: [
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: parsedItems.length,
                        itemBuilder: (context, itemIndex) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: MenuItemTile(
                              item: parsedItems[itemIndex].toJson(),
                              onEditMenuItem: (json) =>
                                  onEditMenuItem(MenuItem.fromJson(json)),
                              onDeleteMenuItem: onDeleteMenuItem,
                            ),
                          );
                        },
                      ),
                      // ── Кнопка добавления ──
                      _AddItemButton(onTap: () => onAddMenuItem(category.id)),
                    ],
                  ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Пустое состояние категории ────────────────────────────────────────────────
class _EmptyCategoryItems extends StatelessWidget {
  final VoidCallback onAddMenuItem;

  const _EmptyCategoryItems({required this.onAddMenuItem});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.no_food_rounded, size: 20, color: Colors.grey[350]),
              const SizedBox(width: 8),
              Text(
                'В категории пока нет блюд',
                style: TextStyle(
                  color: AppColors.textSub,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AddItemButton(onTap: onAddMenuItem),
        ],
      ),
    );
  }
}

// ── Кнопка добавления блюда ───────────────────────────────────────────────────
class _AddItemButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddItemButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.18),
            width: 1,
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
            SizedBox(width: 6),
            Text(
              'Добавить блюдо',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
