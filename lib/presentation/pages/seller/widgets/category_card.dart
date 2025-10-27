import 'package:flutter/material.dart';
import 'package:restauran/presentation/pages/seller/widgets/menu_item_title.dart';
import '../../../../data/models/menu_category.dart';
import '../../../../data/models/menu_item.dart';

class CategoryCard extends StatelessWidget {
  final MenuCategory category;
  final Function(MenuCategory) onEditCategory;
  final Function(int) onDeleteCategory;
  final Function(int) onAddMenuItem;
  final Function(MenuItem) onEditMenuItem;
  final Function(int) onDeleteMenuItem;

  const CategoryCard({
    super.key,
    required this.category,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onAddMenuItem,
    required this.onEditMenuItem,
    required this.onDeleteMenuItem,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              category.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(category.description),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Icon(
                        category.requiresSelection
                            ? Icons.check_circle
                            : Icons.info,
                        size: 16,
                        color: category.requiresSelection
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        category.requiresSelection
                            ? 'Обязательный выбор'
                            : 'Необязательный выбор',
                        style: TextStyle(
                          color: category.requiresSelection
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => onEditCategory(category),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => onDeleteCategory(category.id),
                ),
              ],
            ),
          ),
          const Divider(),
          if (category.menuItems.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'В этой категории нет блюд',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: category.menuItems.length,
              itemBuilder: (context, itemIndex) {
                return MenuItemTile(
                  menuItem: category.menuItems[itemIndex],
                  onEditMenuItem: onEditMenuItem,
                  onDeleteMenuItem: onDeleteMenuItem,
                );
              },
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () => onAddMenuItem(category.id),
              icon: const Icon(Icons.add),
              label: const Text('Добавить блюдо'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
