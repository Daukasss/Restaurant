import 'package:flutter/material.dart';
import 'package:restauran/data/models/global_category.dart';
import 'package:restauran/data/models/restaurant_category.dart';

class SellerCategoriesWidget extends StatefulWidget {
  final String restaurantId;
  final List<GlobalCategory> availableCategories;
  final List<RestaurantCategory> restaurantCategories;
  final bool isLoading;

  final Function(String globalCategoryId, double price, String? description)
      onActivateCategory;

  final Function(
          String categoryId, double? price, String? description, bool? isActive)
      onUpdateCategory;

  final Function(String categoryId) onDeactivateCategory;

  const SellerCategoriesWidget({
    super.key,
    required this.restaurantId,
    required this.availableCategories,
    required this.restaurantCategories,
    required this.isLoading,
    required this.onActivateCategory,
    required this.onUpdateCategory,
    required this.onDeactivateCategory,
  });

  @override
  State<SellerCategoriesWidget> createState() => _SellerCategoriesWidgetState();
}

class _SellerCategoriesWidgetState extends State<SellerCategoriesWidget> {
  // ================= АКТИВАЦИЯ =================
  void _showActivateCategoryDialog(GlobalCategory globalCategory) {
    final priceController =
        TextEditingController(text: globalCategory.defaultPrice.toString());
    final descriptionController =
        TextEditingController(text: globalCategory.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Активировать "${globalCategory.name}"'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Цена за гость',
                  suffixText: 'Тг',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Описание (необязательно)'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              if (price == null) return;

              widget.onActivateCategory(
                globalCategory.id!,
                price,
                descriptionController.text.isEmpty
                    ? null
                    : descriptionController.text,
              );

              Navigator.pop(context);
            },
            child: const Text('Активировать'),
          ),
        ],
      ),
    );
  }

  // ================= РЕДАКТ =================
  void _showEditCategoryDialog(RestaurantCategory category) {
    final priceController =
        TextEditingController(text: category.priceRange.toString());
    final descriptionController =
        TextEditingController(text: category.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Редактировать "${category.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Цена',
                suffixText: 'Тг',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration:
                  const InputDecoration(labelText: 'Описание (необязательно)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = double.tryParse(priceController.text);
              if (price == null) return;

              widget.onUpdateCategory(
                category.id!,
                price,
                descriptionController.text.isEmpty
                    ? null
                    : descriptionController.text,
                null,
              );

              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<int, List<GlobalCategory>> availableBySection = {};
    final Map<int, List<RestaurantCategory>> restaurantBySection = {};

    for (var c in widget.availableCategories) {
      availableBySection.putIfAbsent(c.section, () => []).add(c);
    }
    for (var c in widget.restaurantCategories) {
      restaurantBySection.putIfAbsent(c.section, () => []).add(c);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (availableBySection.containsKey(1) ||
            restaurantBySection.containsKey(1))
          _buildSection(
            available: availableBySection[1] ?? [],
            restaurant: restaurantBySection[1] ?? [],
          ),
        const SizedBox(height: 24),
        if (availableBySection.containsKey(2) ||
            restaurantBySection.containsKey(2))
          _buildSection(
            available: availableBySection[2] ?? [],
            restaurant: restaurantBySection[2] ?? [],
          ),
      ],
    );
  }

  Widget _buildSection({
    required List<GlobalCategory> available,
    required List<RestaurantCategory> restaurant,
  }) {
    final activatedIds = restaurant.map((e) => e.globalCategoryId).toSet();
    final availableToActivate =
        available.where((c) => !activatedIds.contains(c.id)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (restaurant.isNotEmpty) ...[
          ...restaurant.map((category) => Card(
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(category.name),
                  subtitle: Text(
                      "Цена: ${category.priceRange.toStringAsFixed(0)} Тг"),
                  trailing: SizedBox(
                    width: 130,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PopupMenuButton(
                            itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('Редактировать'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete,
                                            color: Colors.red, size: 18),
                                        SizedBox(width: 8),
                                        Text('Деактивировать',
                                            style:
                                                TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditCategoryDialog(category);
                              } else if (value == 'delete') {
                                widget.onDeactivateCategory(category.id!);
                              }
                            }),
                      ],
                    ),
                  ),
                ),
              )),
          const SizedBox(height: 16),
        ],
        if (availableToActivate.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...availableToActivate.map((category) => Card(
                child: ListTile(
                  leading:
                      const Icon(Icons.add_circle_outline, color: Colors.grey),
                  title: Text(category.name),
                  subtitle: Text(
                      "Цена: ${category.defaultPrice.toStringAsFixed(0)} Тг"),
                  trailing: SizedBox(
                    width: 120,
                    child: ElevatedButton(
                      onPressed: widget.isLoading
                          ? null
                          : () => _showActivateCategoryDialog(category),
                      child: const Icon(Icons.add, size: 18),
                    ),
                  ),
                ),
              )),
        ],
      ],
    );
  }
}
