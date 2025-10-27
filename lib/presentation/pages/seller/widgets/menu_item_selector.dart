import 'package:flutter/material.dart';
import '../../../../data/models/menu_category.dart';

class MenuItemSelector extends StatelessWidget {
  final List<MenuCategory> menuCategories;
  final Map<int, int> selectedMenuItems;
  final Function(int, int) onSelectMenuItem;

  const MenuItemSelector({
    super.key,
    required this.menuCategories,
    required this.selectedMenuItems,
    required this.onSelectMenuItem,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: menuCategories.map((category) {
        if (category.menuItems.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                if (category.requiresSelection)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Обезательный выбор',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            if (category.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  category.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            ...category.menuItems.map((menuItem) {
              final isSelected = selectedMenuItems[category.id] == menuItem.id;
              return InkWell(
                onTap: () => onSelectMenuItem(category.id, menuItem.id!),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      // ClipRRect(
                      //   borderRadius: BorderRadius.circular(4),
                      //   child: Image.network(
                      //     menuItem.imageUrl,
                      //     width: 60,
                      //     height: 60,
                      //     fit: BoxFit.cover,
                      //   ),
                      // ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              menuItem.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (menuItem.description.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  menuItem.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          const SizedBox(height: 4),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          else
                            Icon(
                              Icons.circle_outlined,
                              color: Colors.grey[400],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
        );
      }).toList(),
    );
  }
}
