import 'package:flutter/material.dart';
import '../../../widgets/custom_text_field.dart';

class EditProfileDialog extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final VoidCallback onSave;

  const EditProfileDialog({
    super.key,
    required this.nameController,
    required this.phoneController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Редактировать профиль'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomTextField(
              controller: nameController,
              hintText: 'Полное имя',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: phoneController,
              hintText: 'Телефон',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Назад'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSave();
          },
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
