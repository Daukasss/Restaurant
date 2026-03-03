class MenuCategory {
  final String? id;
  final String restaurantId;

  /// Список ID категорий ресторана, к которым привязана эта категория меню.
  /// Заменяет старый restaurantCategoryId: String?
  final List<String> restaurantCategoryIds;

  final String name;
  final String description;
  final bool requiresSelection;
  final int displayOrder;
  final List<dynamic> menuItems;

  MenuCategory({
    this.id,
    required this.restaurantId,
    List<String>? restaurantCategoryIds,

    // Обратная совместимость: если передан старый одиночный ID
    String? restaurantCategoryId,
    required this.name,
    required this.description,
    required this.requiresSelection,
    required this.displayOrder,
    required this.menuItems,
  }) : restaurantCategoryIds = restaurantCategoryIds ??
            (restaurantCategoryId != null ? [restaurantCategoryId] : []);

  /// Удобный геттер для обратной совместимости со старым кодом
  String? get restaurantCategoryId =>
      restaurantCategoryIds.isNotEmpty ? restaurantCategoryIds.first : null;

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    // Поддержка обоих форматов: старый (строка) и новый (массив)
    List<String> categoryIds = [];

    final rawIds = json['restaurant_category_ids'];
    final rawId = json['restaurant_category_id'];

    if (rawIds != null && rawIds is List) {
      categoryIds = rawIds.map((e) => e.toString()).toList();
    } else if (rawId != null) {
      // Миграция старых данных
      categoryIds = [rawId.toString()];
    }

    return MenuCategory(
      id: json['id']?.toString(),
      restaurantId: json['restaurant_id']?.toString() ?? '',
      restaurantCategoryIds: categoryIds,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      requiresSelection: json['requires_selection'] ?? false,
      displayOrder: json['display_order'] ?? 0,
      menuItems: json['menu_items'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'restaurant_id': restaurantId,
      'restaurant_category_ids': restaurantCategoryIds,
      'name': name,
      'description': description,
      'requires_selection': requiresSelection,
      'display_order': displayOrder,
    };
  }

  MenuCategory copyWith({
    String? id,
    String? restaurantId,
    List<String>? restaurantCategoryIds,
    String? name,
    String? description,
    bool? requiresSelection,
    int? displayOrder,
    List<dynamic>? menuItems,
  }) {
    return MenuCategory(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      restaurantCategoryIds:
          restaurantCategoryIds ?? this.restaurantCategoryIds,
      name: name ?? this.name,
      description: description ?? this.description,
      requiresSelection: requiresSelection ?? this.requiresSelection,
      displayOrder: displayOrder ?? this.displayOrder,
      menuItems: menuItems ?? this.menuItems,
    );
  }
}
