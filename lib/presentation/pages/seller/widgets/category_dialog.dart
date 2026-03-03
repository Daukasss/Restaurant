// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

class CategoryDialog extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final bool initialRequiresSelection;

  /// Все доступные категории ресторана для привязки
  final List<Map<String, dynamic>> restaurantCategories;

  /// Уже выбранные ID категорий ресторана
  final List<String> initialSelectedCategoryIds;

  const CategoryDialog({
    super.key,
    this.initialName,
    this.initialDescription,
    this.initialRequiresSelection = false,
    this.restaurantCategories = const [],
    this.initialSelectedCategoryIds = const [],
  });

  /// Статический метод для удобного показа как BottomSheet
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    String? initialName,
    String? initialDescription,
    bool initialRequiresSelection = false,
    List<Map<String, dynamic>> restaurantCategories = const [],
    List<String> initialSelectedCategoryIds = const [],
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CategoryDialog(
        initialName: initialName,
        initialDescription: initialDescription,
        initialRequiresSelection: initialRequiresSelection,
        restaurantCategories: restaurantCategories,
        initialSelectedCategoryIds: initialSelectedCategoryIds,
      ),
    );
  }

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late bool _requiresSelection;
  late Set<String> _selectedCategoryIds;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  bool get _isEditing => widget.initialName != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    _requiresSelection = widget.initialRequiresSelection;
    _selectedCategoryIds = Set.from(widget.initialSelectedCategoryIds);

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_selectedCategoryIds.contains(id)) {
        _selectedCategoryIds.remove(id);
      } else {
        _selectedCategoryIds.add(id);
      }
    });
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите название категории'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'requires_selection': _requiresSelection,
      'restaurant_category_ids': _selectedCategoryIds.toList(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Название категории'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Например: Горячие блюда',
                      icon: Icons.category_rounded,
                    ),
                    const SizedBox(height: 32),
                    // Привязка к категориям ресторана
                    if (widget.restaurantCategories.isNotEmpty) ...[
                      _buildSectionTitle(
                        icon: Icons.link_rounded,
                        title: 'Категории ресторана',
                        subtitle: 'Выберите одну или несколько',
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryChips(),
                      const SizedBox(height: 20),
                    ],

                    // Переключатель обязательного выбора
                    // _buildRequiresSelectionToggle(),
                    // const SizedBox(height: 24),
                    _buildSaveButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  _isEditing ? 'Редактировать категорию' : 'Новая категория',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: Colors.grey[500]),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _buildSectionTitle({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              size: 18, color: Theme.of(context).colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        if (_selectedCategoryIds.isNotEmpty) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_selectedCategoryIds.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.restaurantCategories.map((category) {
        final id = category['id']?.toString() ?? '';
        final name = category['name']?.toString() ?? '';
        final priceRange = category['price_range']?.toString();
        final isSelected = _selectedCategoryIds.contains(id);
        final primaryColor = Theme.of(context).colorScheme.primary;

        return GestureDetector(
          onTap: () => _toggleCategory(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? primaryColor : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? primaryColor : Colors.grey[300]!,
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: isSelected
                      ? Icon(Icons.check_rounded,
                          key: const ValueKey('check'),
                          size: 16,
                          color: Colors.white)
                      : Icon(Icons.add_rounded,
                          key: const ValueKey('add'),
                          size: 16,
                          color: Colors.grey[500]),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (priceRange != null && priceRange.isNotEmpty)
                      Text(
                        '\$$priceRange',
                        style: TextStyle(
                          fontSize: 11,
                          color: isSelected
                              ? Colors.white.withOpacity(0.8)
                              : Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // Widget _buildRequiresSelectionToggle() {
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  //     decoration: BoxDecoration(
  //       color: Colors.grey[50],
  //       borderRadius: BorderRadius.circular(14),
  //       border: Border.all(color: Colors.grey[200]!),
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           padding: const EdgeInsets.all(8),
  //           decoration: BoxDecoration(
  //             color: _requiresSelection
  //                 ? Colors.orange.withOpacity(0.15)
  //                 : Colors.grey[200],
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //           child: Icon(
  //             Icons.touch_app_rounded,
  //             size: 18,
  //             color: _requiresSelection ? Colors.orange[700] : Colors.grey[500],
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               const Text(
  //                 'Обязательный выбор',
  //                 style: TextStyle(
  //                   fontWeight: FontWeight.w600,
  //                   fontSize: 14,
  //                 ),
  //               ),
  //               Text(
  //                 'Гость обязан выбрать блюдо из этой категории',
  //                 style: TextStyle(
  //                   fontSize: 12,
  //                   color: Colors.grey[500],
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         Switch(
  //           value: _requiresSelection,
  //           onChanged: (val) => setState(() => _requiresSelection = val),
  //           activeColor: Colors.orange[700],
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: maxLines > 1 ? TextInputType.multiline : TextInputType.text,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
        prefixIcon: Padding(
          padding: EdgeInsets.only(top: maxLines > 1 ? 12 : 0, left: 4),
          child: Icon(icon, size: 20, color: Colors.grey[500]),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          _isEditing ? 'Сохранить изменения' : 'Создать категорию',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}
