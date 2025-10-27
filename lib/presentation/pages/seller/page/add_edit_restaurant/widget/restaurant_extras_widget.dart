import 'package:flutter/material.dart';
import '../../../../../../data/models/restaurant_extra.dart';

class RestaurantExtrasWidget extends StatelessWidget {
  final List<RestaurantExtra> extras;
  final bool isLoading;
  final Function(String name, double price, String? description) onAddExtra;
  final Function(int extraId, String? name, double? price, String? description)
      onUpdateExtra;
  final Function(int extraId) onRemoveExtra;

  const RestaurantExtrasWidget({
    super.key,
    required this.extras,
    required this.isLoading,
    required this.onAddExtra,
    required this.onUpdateExtra,
    required this.onRemoveExtra,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: extras.length,
            itemBuilder: (context, index) {
              final extra = extras[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    extra.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${extra.price.toStringAsFixed(0)} Тг'),
                      if (extra.description != null &&
                          extra.description!.isNotEmpty)
                        Text(
                          extra.description!,
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                        ),
                        onPressed: () => _showEditExtraDialog(context, extra),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmation(
                          context,
                          extra.id!,
                          extra.name,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _showAddExtraDialog(context),
          icon: const Icon(Icons.add),
          label: const Text('Добавить дополнительную опцию'),
        ),
      ],
    );
  }

  void _showAddExtraDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Добавить дополнительную опцию'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Название *',
                  hintText: 'Например: Живая музыка',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Цена (Тг) *',
                  hintText: '5000',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                  hintText: 'Дополнительная информация',
                ),
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
              final name = nameController.text.trim();
              final priceText = priceController.text.trim();
              final description = descriptionController.text.trim();

              if (name.isEmpty || priceText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Заполните обязательные поля'),
                  ),
                );
                return;
              }

              final price = double.tryParse(priceText);
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Введите корректную цену'),
                  ),
                );
                return;
              }

              onAddExtra(
                name,
                price,
                description.isEmpty ? null : description,
              );
              Navigator.pop(context);
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  void _showEditExtraDialog(BuildContext context, RestaurantExtra extra) {
    final nameController = TextEditingController(text: extra.name);
    final priceController =
        TextEditingController(text: extra.price.toStringAsFixed(0));
    final descriptionController =
        TextEditingController(text: extra.description ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать опцию'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Название *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Цена (Тг) *'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Описание (необязательно)',
                ),
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
              final name = nameController.text.trim();
              final priceText = priceController.text.trim();
              final description = descriptionController.text.trim();

              if (name.isEmpty || priceText.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Заполните обязательные поля'),
                  ),
                );
                return;
              }

              final price = double.tryParse(priceText);
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Введите корректную цену'),
                  ),
                );
                return;
              }

              onUpdateExtra(
                extra.id!,
                name,
                price,
                description.isEmpty ? null : description,
              );
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, int extraId, String extraName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить опцию?'),
        content: Text('Вы уверены, что хотите удалить "$extraName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () {
              onRemoveExtra(extraId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
