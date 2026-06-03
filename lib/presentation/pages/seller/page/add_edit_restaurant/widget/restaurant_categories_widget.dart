import 'package:flutter/material.dart';
import 'package:restauran/data/models/global_category.dart';
import 'package:restauran/data/models/restaurant_category.dart';
import 'package:restauran/theme/app_colors.dart';

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
  // Заменяем _showActivateCategoryDialog:
  void _showActivateCategoryDialog(GlobalCategory globalCategory) {
    final priceController =
        TextEditingController(text: globalCategory.defaultPrice.toString());
    final descriptionController =
        TextEditingController(text: globalCategory.description ?? '');

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
            Text('Активировать «${globalCategory.name}»',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain)),
            const SizedBox(height: 16),
            _DialogTextField(
                controller: priceController,
                label: 'Цена за гостя',
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
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Активировать'),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  // ================= РЕДАКТИРОВАНИЕ =================
  void _showEditCategoryDialog(RestaurantCategory category) {
    final priceController =
        TextEditingController(text: category.priceRange.toString());
    final descriptionController =
        TextEditingController(text: category.description ?? '');

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
            Text('Редактировать «${category.name}»',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMain)),
            const SizedBox(height: 16),
            _DialogTextField(
                controller: priceController,
                label: 'Цена',
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

  @override
  Widget build(BuildContext context) {
    // Собираем активированные id
    final activatedIds =
        widget.restaurantCategories.map((e) => e.globalCategoryId).toSet();
    final availableToActivate = widget.availableCategories
        .where((c) => !activatedIds.contains(c.id))
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.isLoading)
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: LinearProgressIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.divider,
            ),
          ),
        // Активированные — плоский список без секций
        ...widget.restaurantCategories.map(_buildActivatedRow),
        // Неактивные — чипы
        if (availableToActivate.isNotEmpty) ...[
          if (widget.restaurantCategories.isNotEmpty) const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                availableToActivate.map((c) => _buildAvailableChip(c)).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildActivatedRow(RestaurantCategory category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.success, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textMain,
              ),
            ),
          ),
          Text(
            '${category.priceRange.toStringAsFixed(0)} Тг',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSub,
            ),
          ),
          PopupMenuButton<String>(
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
                child: Text('Деактивировать',
                    style: TextStyle(color: AppColors.danger)),
              ),
            ],
            onSelected: (value) {
              if (value == 'edit') {
                _showEditCategoryDialog(category);
              } else if (value == 'delete') {
                widget.onDeactivateCategory(category.id!);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableChip(GlobalCategory category) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap:
          widget.isLoading ? null : () => _showActivateCategoryDialog(category),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, size: 16, color: AppColors.textSub),
            const SizedBox(width: 6),
            Text(
              category.name,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== ОБЩИЕ СТИЛИЗОВАННЫЕ ВИДЖЕТЫ ДИАЛОГОВ ====================

class _StyledDialog extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final String confirmText;
  final VoidCallback onConfirm;

  const _StyledDialog({
    required this.title,
    required this.fields,
    required this.confirmText,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textMain,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: fields),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:
              const Text('Отмена', style: TextStyle(color: AppColors.textSub)),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(confirmText),
        ),
      ],
    );
  }
}

class _DialogTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? suffix;
  final int maxLines;
  final TextInputType? keyboardType;

  const _DialogTextField({
    required this.controller,
    required this.label,
    this.suffix,
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
