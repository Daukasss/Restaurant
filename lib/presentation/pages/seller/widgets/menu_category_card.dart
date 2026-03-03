import 'package:flutter/material.dart';
import 'package:restauran/presentation/pages/seller/widgets/menu_item_title.dart';
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

  /// Парсим menuItems из List<dynamic> в List<MenuItem>
  List<MenuItem> get _parsedMenuItems {
    return category.menuItems.map((item) {
      if (item is MenuItem) return item;
      if (item is Map<String, dynamic>) return MenuItem.fromJson(item);
      // LinkedMap из Firestore
      return MenuItem.fromJson(Map<String, dynamic>.from(item as Map));
    }).toList();
  }

  /// Находим названия категорий ресторана по ID
  List<Map<String, dynamic>> get _linkedCategories {
    if (restaurantCategories.isEmpty ||
        category.restaurantCategoryIds.isEmpty) {
      return [];
    }
    return restaurantCategories
        .where((rc) =>
            category.restaurantCategoryIds.contains(rc['id']?.toString()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final linked = _linkedCategories;
    final parsedItems = _parsedMenuItems;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Заголовок карточки ──
          Padding(
            padding:
                const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                      if (category.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          category.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey[500]),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEditCategory(category);
                    } else if (value == 'delete') {
                      onDeleteCategory(category.id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Редактировать'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_rounded,
                              color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Text('Удалить', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Теги привязанных категорий ресторана ──
          // if (linked.isNotEmpty)
          //   Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          //     child: Wrap(
          //       spacing: 6,
          //       runSpacing: 6,
          //       children: linked.map((rc) {
          //         final name = rc['name']?.toString() ?? '';
          //         final price = rc['price_range']?.toString();
          //         return Container(
          //           padding:
          //               const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          //           decoration: BoxDecoration(
          //             color: primaryColor.withOpacity(0.08),
          //             borderRadius: BorderRadius.circular(20),
          //             border: Border.all(
          //                 color: primaryColor.withOpacity(0.25), width: 1),
          //           ),
          //           child: Row(
          //             mainAxisSize: MainAxisSize.min,
          //             children: [
          //               Icon(Icons.link_rounded, size: 12, color: primaryColor),
          //               const SizedBox(width: 4),
          //               Text(
          //                 price != null && price.isNotEmpty
          //                     ? '$name · \$$price'
          //                     : name,
          //                 style: TextStyle(
          //                   fontSize: 12,
          //                   color: primaryColor,
          //                   fontWeight: FontWeight.w500,
          //                 ),
          //               ),
          //             ],
          //           ),
          //         );
          //       }).toList(),
          //     ),
          //   )
          // else if (restaurantCategories.isNotEmpty)
          //   Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          //     child: Row(
          //       children: [
          //         Icon(Icons.link_off_rounded,
          //             size: 13, color: Colors.grey[400]),
          //         const SizedBox(width: 4),
          //         Text(
          //           'Не привязана ни к одной категории',
          //           style: TextStyle(
          //             fontSize: 12,
          //             color: Colors.grey[400],
          //             fontStyle: FontStyle.italic,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),

          // ── Индикатор обязательного выбора ──
          // if (category.requiresSelection)
          //   Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          //     child: Row(
          //       children: [
          //         Icon(Icons.touch_app_rounded,
          //             size: 13, color: Colors.orange[700]),
          //         const SizedBox(width: 4),
          //         Text(
          //           'Обязательный выбор',
          //           style: TextStyle(
          //             fontSize: 12,
          //             color: Colors.orange[700],
          //             fontWeight: FontWeight.w500,
          //           ),
          //         ),
          //       ],
          //     ),
          //   ),

          // Divider(height: 20, color: Colors.grey[100]),

          // ── Блюда ──
          if (parsedItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.no_food_rounded,
                        size: 32, color: Colors.grey[300]),
                    const SizedBox(height: 6),
                    Text(
                      'В этой категории нет блюд',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: parsedItems.length,
              itemBuilder: (context, itemIndex) {
                // ✅ Используем уже распарсенный List<MenuItem>
                return MenuItemTile(
                  menuItem: parsedItems[itemIndex],
                  onEditMenuItem: onEditMenuItem,
                  onDeleteMenuItem: onDeleteMenuItem,
                );
              },
            ),

          // ── Кнопка добавления блюда ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => onAddMenuItem(category.id),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Добавить блюдо'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: BorderSide(color: primaryColor.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
