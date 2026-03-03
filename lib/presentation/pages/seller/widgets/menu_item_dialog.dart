// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class MenuItemBottomSheet extends StatefulWidget {
  final String? initialName;
  final String? initialDescription;
  final String? initialImageUrl;
  final String restaurantId;

  const MenuItemBottomSheet({
    super.key,
    this.initialName,
    this.initialDescription,
    this.initialImageUrl,
    required this.restaurantId,
  });

  /// Удобный статический метод для показа
  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required String restaurantId,
    String? initialName,
    String? initialDescription,
    String? initialImageUrl,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MenuItemBottomSheet(
        restaurantId: restaurantId,
        initialName: initialName,
        initialDescription: initialDescription,
        initialImageUrl: initialImageUrl,
      ),
    );
  }

  @override
  State<MenuItemBottomSheet> createState() => _MenuItemBottomSheetState();
}

class _MenuItemBottomSheetState extends State<MenuItemBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  File? _pickedImage;
  String? _currentImageUrl;
  bool _isUploading = false;

  bool get _isEditing => widget.initialName != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    _currentImageUrl = widget.initialImageUrl;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (pickedFile != null) {
      setState(() => _pickedImage = File(pickedFile.path));
    }
  }

  Future<String?> _uploadImage() async {
    if (_pickedImage == null) return _currentImageUrl;
    setState(() => _isUploading = true);
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(_pickedImage!.path)}';
      final ref = FirebaseStorage.instance
          .ref()
          .child('menu_items')
          .child(widget.restaurantId)
          .child(fileName);
      final snapshot = await ref.putFile(_pickedImage!);
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка загрузки фото: $e')),
      );
      return _currentImageUrl;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      _shakeName();
      return;
    }
    final imageUrl = await _uploadImage();
    if (!mounted) return;
    Navigator.of(context).pop({
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'image_url': imageUrl ?? '',
    });
  }

  void _shakeName() {
    // Подсветить поле
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Введите название блюда'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  bool get _hasImage =>
      _pickedImage != null ||
      (_currentImageUrl != null && _currentImageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnim,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            _buildHandle(),

            // Фото секция
            _buildPhotoSection(theme),

            // Форма
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel('Название блюда'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hint: 'Например: Борщ украинский',
                    icon: Icons.restaurant_menu_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildLabel('Описание'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _descriptionController,
                    hint: 'Состав, особенности подачи...',
                    icon: Icons.notes_rounded,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _buildSaveButton(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  _isEditing ? 'Редактировать блюдо' : 'Новое блюдо',
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
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    return GestureDetector(
      onTap: _isUploading ? null : _pickImage,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[100],
          border: Border.all(
            color: _hasImage ? Colors.transparent : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Фото
            if (_pickedImage != null)
              Image.file(_pickedImage!, fit: BoxFit.cover)
            else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty)
              Image.network(
                _currentImageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(),
              )
            else
              _buildPhotoPlaceholder(),

            // Оверлей при наведении / смене
            if (_hasImage)
              Positioned(
                bottom: 10,
                right: 10,
                child: _buildPhotoChip(
                  icon: Icons.edit_rounded,
                  label: 'Изменить',
                  onTap: _pickImage,
                ),
              ),
            if (_hasImage)
              Positioned(
                bottom: 10,
                left: 10,
                child: _buildPhotoChip(
                  icon: Icons.delete_outline_rounded,
                  label: 'Удалить',
                  color: Colors.red[400]!,
                  onTap: () => setState(() {
                    _pickedImage = null;
                    _currentImageUrl = null;
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.add_photo_alternate_rounded,
            size: 28,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Добавить фото блюда',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Нажмите, чтобы выбрать из галереи',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildPhotoChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? Colors.black87;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color != null ? color : Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color != null ? color : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
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
          padding: EdgeInsets.only(
            top: maxLines > 1 ? 12 : 0,
            left: 4,
          ),
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

  Widget _buildSaveButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isUploading ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isUploading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                _isEditing ? 'Сохранить изменения' : 'Добавить блюдо',
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
