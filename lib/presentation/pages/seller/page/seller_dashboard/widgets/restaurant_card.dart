import 'package:flutter/material.dart';
import 'package:restauran/theme/app_colors.dart';

class RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  /// true = нет интернета
  final bool isOffline;

  const RestaurantCard({
    super.key,
    required this.restaurant,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isOffline = false,
  });

  @override
  Widget build(BuildContext context) {
    final String name = (restaurant['name'] ?? 'Нет названия').toString();
    final String location = (restaurant['location'] ?? 'Нет адреса').toString();
    final String? imageUrl = restaurant['image_url']?.toString();
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.divider,
          ),
          boxShadow: AppColors.softShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: hasImage
                    ? Image.network(
                        imageUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const _PlaceholderImage(),
                      )
                    : const _PlaceholderImage(),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppColors.textSub,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _IconAction(
                    icon: Icons.edit_outlined,
                    color: AppColors.primary,
                    onTap: isOffline ? null : onEdit,
                    isOffline: isOffline,
                  ),
                  const SizedBox(height: 10),
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
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.storefront_rounded,
        color: AppColors.primary,
        size: 34,
      ),
    );
  }
}

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
    final effectiveColor = isOffline ? Colors.grey : color;

    Widget child = Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        icon,
        size: 18,
        color: effectiveColor,
      ),
    );

    if (onTap != null) {
      child = GestureDetector(
        onTap: onTap,
        child: child,
      );
    }

    return child;
  }
}
