import 'package:flutter/material.dart';

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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (restaurant['image_url'] != null &&
              restaurant['image_url'].isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                restaurant['image_url'],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        restaurant['name'] ?? 'Нет названия',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Попап меню заблокирован офлайн
                    if (!isOffline)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (value) {
                          if (value == 'edit') onEdit();
                          if (value == 'delete') onDelete();
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit),
                                SizedBox(width: 8),
                                Text('Редактировать'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Удалить',
                                    style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Tooltip(
                        message: 'Недоступно офлайн',
                        child: Icon(Icons.more_vert, color: Colors.grey[400]),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        restaurant['location'] ?? 'Нет адреса',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _OfflineAwareButton(
                            isOffline: isOffline,
                            onPressed: onEdit,
                            icon: Icons.edit,
                            label: 'Edit',
                            outlined: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _OfflineAwareButton(
                            isOffline: isOffline,
                            onPressed: onMenuManagement,
                            icon: Icons.restaurant_menu,
                            label: 'Меню',
                            outlined: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // ✅ Брони — единственная кнопка, активная офлайн
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: onBookingManagement,
                        icon: const Icon(Icons.calendar_today),
                        label: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Брони', style: TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: _OfflineAwareButton(
                        isOffline: isOffline,
                        onPressed: onManualBooking,
                        icon: Icons.add,
                        label: 'Ручная бронь',
                        outlined: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Кнопка, которая показывает тултип «Недоступно офлайн» когда isOffline=true
class _OfflineAwareButton extends StatelessWidget {
  final bool isOffline;
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool outlined;

  const _OfflineAwareButton({
    required this.isOffline,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final Widget button = outlined
        ? OutlinedButton.icon(
            onPressed: isOffline ? null : onPressed,
            icon: Icon(icon),
            label: Text(label, style: const TextStyle(fontSize: 13)),
          )
        : ElevatedButton.icon(
            onPressed: isOffline ? null : onPressed,
            icon: Icon(icon),
            label: Text(label, style: const TextStyle(fontSize: 13)),
          );

    if (isOffline) {
      return Tooltip(
        message: 'Недоступно без интернета',
        child: button,
      );
    }

    return button;
  }
}
