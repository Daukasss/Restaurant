import 'package:flutter/material.dart';
import '../../../../data/models/menu_item.dart';

class MenuItemTile extends StatelessWidget {
  final MenuItem menuItem;
  final Function(MenuItem) onEditMenuItem;
  final Function(String?) onDeleteMenuItem;

  const MenuItemTile({
    super.key,
    required this.menuItem,
    required this.onEditMenuItem,
    required this.onDeleteMenuItem,
  });

  void _showFullDescription(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              menuItem.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Text(
              menuItem.description.isEmpty
                  ? 'Описание отсутствует'
                  : menuItem.description,
              style: const TextStyle(fontSize: 15, height: 1.35),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Закрыть'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading() {
    final hasImage = menuItem.imageUrl.isNotEmpty;

    if (hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          menuItem.imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return SizedBox(
              width: 56,
              height: 56,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.restaurant, color: Colors.grey[400], size: 28),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desc = menuItem.description.trim();
    final hasDesc = desc.isNotEmpty;

    return ListTile(
      leading: _buildLeading(),
      title: Text(menuItem.name),
      subtitle: hasDesc
          ? Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _showFullDescription(context),
                    child: Text(
                      desc,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  icon: const Icon(Icons.more_horiz, size: 18),
                  onPressed: () => _showFullDescription(context),
                ),
              ],
            )
          : const Text(
              'Описание отсутствует',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (value) {
          if (value == 'edit') {
            onEditMenuItem(menuItem);
          } else if (value == 'delete') {
            onDeleteMenuItem(menuItem.id);
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('Редактировать'),
              ],
            ),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Удалить', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
