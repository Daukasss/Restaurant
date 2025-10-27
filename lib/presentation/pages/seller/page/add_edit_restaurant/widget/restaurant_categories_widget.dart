import 'package:flutter/material.dart';
import '../../../../../../data/models/restaurant_category.dart';

class RestaurantCategoriesWidget extends StatefulWidget {
  final List<RestaurantCategory> categories;
  final bool isLoading;
  final Function(String name, double price, String? description) onAddCategory;
  final Function(
          int categoryId, String? name, double? price, String? description)
      onUpdateCategory;
  final Function(int categoryId) onRemoveCategory;

  const RestaurantCategoriesWidget({
    super.key,
    required this.categories,
    required this.isLoading,
    required this.onAddCategory,
    required this.onUpdateCategory,
    required this.onRemoveCategory,
  });

  @override
  State<RestaurantCategoriesWidget> createState() =>
      _RestaurantCategoriesWidgetState();
}

class _RestaurantCategoriesWidgetState
    extends State<RestaurantCategoriesWidget> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  void _showAddCategoryDialog() {
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить категорию'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название категории',
                  hintText: 'Например: Люкс, VIP, Бюджетный',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Цена за гостя',
                  hintText: '20000',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  hintText: 'Описание категории',
                ),
                maxLines: 2,
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
              if (_nameController.text.isNotEmpty &&
                  _priceController.text.isNotEmpty) {
                final price = double.tryParse(_priceController.text);
                if (price != null) {
                  widget.onAddCategory(
                    _nameController.text,
                    price,
                    _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                  );
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(RestaurantCategory category) {
    _nameController.text = category.name;
    _priceController.text = category.priceRange.toString();
    _descriptionController.text = category.description ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать категорию'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Название категории',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Цена за гостя',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                ),
                maxLines: 2,
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
              if (_nameController.text.isNotEmpty &&
                  _priceController.text.isNotEmpty) {
                final price = double.tryParse(_priceController.text);
                if (price != null) {
                  widget.onUpdateCategory(
                    category.id!,
                    _nameController.text,
                    price,
                    _descriptionController.text.isEmpty
                        ? null
                        : _descriptionController.text,
                  );
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Список существующих категорий
        if (widget.categories.isNotEmpty)
          ...widget.categories.map((category) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  title: Text(category.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${category.priceRange.toStringAsFixed(0)} Тг за гостя'),
                      if (category.description != null)
                        Text(category.description!,
                            style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showEditCategoryDialog(category),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => widget.onRemoveCategory(category.id!),
                      ),
                    ],
                  ),
                ),
              )),

        // Кнопка добавления новой категории
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: widget.isLoading ? null : _showAddCategoryDialog,
            icon: widget.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add),
            label:
                Text(widget.isLoading ? 'Загрузка...' : 'Добавить категорию'),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
