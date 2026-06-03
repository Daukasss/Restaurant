import 'package:flutter/material.dart';
import 'package:restauran/theme/app_colors.dart';

class RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onMenuManagement;
  final VoidCallback onManualBooking;
  final VoidCallback onBookingManagement;

  /// true = нет интернета; блокирует все кнопки кроме «Брони»
  final bool isOffline;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onEdit,
    required this.onDelete,
    required this.onManualBooking,
    required this.onMenuManagement,
    required this.onBookingManagement,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final String name = (restaurant['name'] ?? 'Нет названия').toString();
    final String location = (restaurant['location'] ?? 'Нет адреса').toString();
    final String? imageUrl = restaurant['image_url']?.toString();
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return InkWell(
      onTap: isOffline ? null : onEdit,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: AppColors.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Верхняя часть: фото + инфо + edit/delete ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Фото ──
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: hasImage
                        ? Image.network(
                            imageUrl,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _PlaceholderImage(),
                          )
                        : _PlaceholderImage(),
                  ),
                  const SizedBox(width: 12),

                  // ── Название + адрес ──
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMain,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined,
                                size: 13, color: AppColors.textSub),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                location,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSub),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // ── Иконки edit / delete ──
                  Column(
                    children: [
                      // _IconAction(
                      //   icon: Icons.edit_outlined,
                      //   color: AppColors.primary,
                      //   onTap: isOffline ? null : onEdit,
                      //   isOffline: isOffline,
                      // ),
                      const SizedBox(height: 6),
                      _IconAction(
                        icon: Icons.delete_outline_rounded,
                        color: AppColors.danger,
                        onTap: isOffline ? null : onDelete,
                        isOffline: isOffline,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Разделитель ──
            Divider(height: 1, color: AppColors.divider),

            // ── Кнопки действий ──
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                children: [
                  // Брони — полная ширина, всегда активна
                  _ActionButton(
                    icon: Icons.calendar_today_rounded,
                    label: 'Брони',
                    onTap: onBookingManagement,
                    isPrimary: true,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.restaurant_menu_rounded,
                          label: 'Меню',
                          onTap: isOffline ? null : onMenuManagement,
                          isOffline: isOffline,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _ActionButton(
                          icon: Icons.add_circle_outline_rounded,
                          label: 'Ручная бронь',
                          onTap: isOffline ? null : onManualBooking,
                          isOffline: isOffline,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Фото-заглушка ─────────────────────────────────────────────────────────
class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.storefront_rounded,
          color: AppColors.primary, size: 28),
    );
  }
}

// ── Иконка-кнопка (edit/delete) ───────────────────────────────────────────
class _IconAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool isOffline;

  const _IconAction({
    required this.icon,
    required this.color,
    this.onTap,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isOffline ? Colors.grey[350]! : color;

    final widget = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: effectiveColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: effectiveColor),
      ),
    );

    if (isOffline) {
      return Tooltip(message: 'Недоступно офлайн', child: widget);
    }
    return widget;
  }
}

// ── Кнопка действия ───────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isPrimary;
  final bool isOffline;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isPrimary = false,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final Color bgColor = isPrimary
        ? AppColors.primary
        : disabled
            ? Colors.grey[100]!
            : AppColors.primary.withOpacity(0.06);
    final Color fgColor = isPrimary
        ? Colors.white
        : disabled
            ? Colors.grey[400]!
            : AppColors.primary;
    final Color borderColor = isPrimary
        ? Colors.transparent
        : disabled
            ? Colors.grey[200]!
            : AppColors.primary.withOpacity(0.2);

    final btn = GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: fgColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: fgColor,
              ),
            ),
          ],
        ),
      ),
    );

    if (isOffline && disabled) {
      return Tooltip(message: 'Недоступно без интернета', child: btn);
    }
    return btn;
  }
}
