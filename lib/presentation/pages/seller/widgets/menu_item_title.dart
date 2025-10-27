import 'package:flutter/material.dart';
import '../../../../data/models/menu_item.dart';

class MenuItemTile extends StatelessWidget {
  final MenuItem menuItem;
  final Function(MenuItem) onEditMenuItem;
  final Function(int) onDeleteMenuItem;

  const MenuItemTile({
    super.key,
    required this.menuItem,
    required this.onEditMenuItem,
    required this.onDeleteMenuItem,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // leading: menuItem.imageUrl.isNotEmpty
      //     ? ClipRRect(
      //         borderRadius: BorderRadius.circular(4),
      //         child: Image.network(
      //           menuItem.imageUrl,
      //           width: 50,
      //           height: 50,
      //           fit: BoxFit.cover,
      //         ),
      //       )
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(Icons.restaurant, color: Colors.grey),
      ),
      title: Text(menuItem.name),
      subtitle: Text(menuItem.description),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => onEditMenuItem(menuItem),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => onDeleteMenuItem(menuItem.id!),
          ),
        ],
      ),
    );
  }
}
