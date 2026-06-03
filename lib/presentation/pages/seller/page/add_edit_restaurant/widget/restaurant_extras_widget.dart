import 'package:flutter/material.dart';
import 'package:restauran/theme/app_colors.dart';
import '../../../../../../data/models/restaurant_extra.dart';

class RestaurantExtrasWidget extends StatelessWidget {
  final List<RestaurantExtra> extras;
  final bool isLoading;
  final Function(String name, double price, String? description) onAddExtra;
  final Function(
          String extraId, String? name, double? price, String? description)
      onUpdateExtra;
  final Function(String extraId) onRemoveExtra;

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
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final extra in extras) _buildExtraRow(context, extra),
        const SizedBox(height: 4),
        _buildAddButton(context),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _showAddExtraDialog(context),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Добавить опцию'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.divider),
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size(double.infinity, 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildExtraRow(BuildContext context, RestaurantExtra extra) {
    final hasDescription =
        extra.description != null && extra.description!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  extra.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMain,
                  ),
                ),
                if (hasDescription) ...[
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () => _showFullDescription(
                        context, extra.name, extra.description!),
                    child: Text(
                      extra.description!.replaceAll('\n', ' ').trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSub,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${extra.price.toStringAsFixed(0)} Тг',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textMain,
            ),
          ),
          PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            icon:
                const Icon(Icons.more_vert, color: AppColors.textSub, size: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'edit',
                child: Text('Редактировать'),
              ),
              PopupMenuItem(
                value: 'delete',
                child:
                    Text('Удалить', style: TextStyle(color: AppColors.danger)),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _showEditExtraDialog(context, extra);
              } else if (value == 'delete') {
                _showDeleteConfirmation(context, extra.id!, extra.name);
              }
            },
          ),
        ],
      ),
    );
  }

  // ==================== ДИАЛОГИ ====================

  void _showFullDescription(
    BuildContext context,
    String title,
    String description,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 30),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: AppColors.textSub,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddExtraDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Добавить опцию',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain)),
            const SizedBox(height: 16),
            _DialogTextField(
                controller: nameController,
                label: 'Название *',
                hint: 'Например: Живая музыка'),
            const SizedBox(height: 12),
            _DialogTextField(
                controller: priceController,
                label: 'Цена *',
                suffix: 'Тг',
                hint: '5000',
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _DialogTextField(
                controller: descriptionController,
                label: 'Описание (необязательно)',
                maxLines: 3),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Отмена',
                      style: TextStyle(color: AppColors.textSub)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final priceText = priceController.text.trim();
                    final description = descriptionController.text.trim();
                    if (name.isEmpty || priceText.isEmpty) {
                      _snack(context, 'Заполните обязательные поля');
                      return;
                    }
                    final price = double.tryParse(priceText);
                    if (price == null || price <= 0) {
                      _snack(context, 'Введите корректную цену');
                      return;
                    }
                    onAddExtra(
                        name, price, description.isEmpty ? null : description);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Добавить'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showEditExtraDialog(BuildContext context, RestaurantExtra extra) {
    final nameController = TextEditingController(text: extra.name);
    final priceController =
        TextEditingController(text: extra.price.toStringAsFixed(0));
    final descriptionController =
        TextEditingController(text: extra.description ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Редактировать опцию',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain)),
            const SizedBox(height: 16),
            _DialogTextField(controller: nameController, label: 'Название *'),
            const SizedBox(height: 12),
            _DialogTextField(
                controller: priceController,
                label: 'Цена *',
                suffix: 'Тг',
                keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            _DialogTextField(
                controller: descriptionController,
                label: 'Описание (необязательно)',
                maxLines: 3),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Отмена',
                      style: TextStyle(color: AppColors.textSub)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final priceText = priceController.text.trim();
                    final description = descriptionController.text.trim();
                    if (name.isEmpty || priceText.isEmpty) {
                      _snack(context, 'Заполните обязательные поля');
                      return;
                    }
                    final price = double.tryParse(priceText);
                    if (price == null || price <= 0) {
                      _snack(context, 'Введите корректную цену');
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
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Сохранить'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context, String extraId, String extraName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Удалить опцию?',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain)),
            const SizedBox(height: 10),
            Text('Вы уверены, что хотите удалить «$extraName»?',
                style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Отмена',
                      style: TextStyle(color: AppColors.textSub)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    onRemoveExtra(extraId);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Удалить'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ==================== ВСПОМОГАТЕЛЬНЫЕ ВИДЖЕТЫ ====================

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final int maxLines;
  final String? hint;
  final TextInputType? keyboardType;

  const _DialogTextField({
    required this.controller,
    required this.label,
    this.suffix,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      cursorColor: AppColors.accent,
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        hintText: hint,
        labelStyle: const TextStyle(color: AppColors.textSub),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
        ),
      ),
    );
  }
}
