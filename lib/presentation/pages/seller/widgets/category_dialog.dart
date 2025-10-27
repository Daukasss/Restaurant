import 'package:flutter/material.dart';
import '../../../widgets/custom_text_field.dart';

class CategoryDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final bool? initialRequiresSelection;

  const CategoryDialog({
    super.key,
    this.initialName,
    this.initialDescription,
    this.initialRequiresSelection,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _requiresSelection;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    _requiresSelection = widget.initialRequiresSelection ?? true;
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
          ? 'Добавить категорию'
          : 'Редактировать категорию'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: _nameController,
              hintText: 'Название категории',
              prefixIcon: Icons.category,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              hintText: 'Описание (необязательно)',
              prefixIcon: Icons.description,
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Обязательный выбор'),
              subtitle: const Text(
                  'Пользователи должны выбрать один элемент из этой категории'),
              value: _requiresSelection,
              onChanged: (value) {
                setState(() {
                  _requiresSelection = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
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
                    content: Text('Пожалуйста, введите название категории')),
              );
              return;
            }

            Navigator.of(context).pop({
              'name': _nameController.text,
              'description': _descriptionController.text,
              'requires_selection': _requiresSelection,
            });
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
