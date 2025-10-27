import 'package:flutter/material.dart';
import '../../../widgets/custom_text_field.dart';

class MenuItemDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final double? initialPrice;
  final String? initialImageUrl;

  const MenuItemDialog({
    super.key,
    this.initialName,
    this.initialDescription,
    this.initialPrice,
    this.initialImageUrl,
  });

  @override
  State<MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends State<MenuItemDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null
          ? 'Добавить блюдо'
          : 'Редактировать блюдо'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _nameController,
              hintText: 'Название блюда',
              prefixIcon: Icons.restaurant_menu,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              hintText: 'Описание (необязательно)',
              prefixIcon: Icons.description,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Пожалуйста, введите название блюда')),
              );
              return;
            }
            Navigator.of(context).pop({
              'name': _nameController.text,
              'description': _descriptionController.text,
            });
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
