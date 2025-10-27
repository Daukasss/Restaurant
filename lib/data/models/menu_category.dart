import 'menu_item.dart';

class MenuCategory {
  final int id;
  final int restaurantId;
  final int? restaurantCategoryId;
  final String name;
  final String description;
  final bool requiresSelection;
  final int displayOrder;
  final List<MenuItem> menuItems;

  MenuCategory({
    required this.id,
    required this.restaurantId,
    this.restaurantCategoryId,
    required this.name,
    required this.description,
    required this.requiresSelection,
    required this.displayOrder,
    required this.menuItems,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    List<MenuItem> items = [];
    if (json['menu_items'] != null) {
      items = List<Map<String, dynamic>>.from(json['menu_items'])
          .map((item) => MenuItem.fromJson(item))
          .toList();
    }

    return MenuCategory(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      restaurantCategoryId: json['restaurant_category_id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      requiresSelection: json['requires_selection'] ?? false,
      displayOrder: json['display_order'] ?? 0,
      menuItems: items,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'restaurant_id': restaurantId,
      'restaurant_category_id': restaurantCategoryId,
      'name': name,
      'description': description,
      'requires_selection': requiresSelection,
      'display_order': displayOrder,
    };
  }

  MenuCategory copyWith({
    int? id,
    int? restaurantId,
    int? restaurantCategoryId,
    String? name,
    String? description,
    bool? requiresSelection,
    int? displayOrder,
    List<MenuItem>? menuItems,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantCategoryId: restaurantCategoryId ?? this.restaurantCategoryId,
      name: name ?? this.name,
      description: description ?? this.description,
      requiresSelection: requiresSelection ?? this.requiresSelection,
      displayOrder: displayOrder ?? this.displayOrder,
      menuItems: menuItems ?? this.menuItems,
    );
  }
}
