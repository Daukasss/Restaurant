class MenuItem {
  final String? id;
  final String categoryId;
  final String restaurantId;
  final String name;
  final String description;
  final String imageUrl;

  MenuItem({
    this.id,
    required this.categoryId,
    required this.restaurantId,
    required this.name,
    required this.description,
    this.imageUrl = '',
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id']?.toString(),
      categoryId: json['category_id']?.toString() ?? '',
      restaurantId: json['restaurant_id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'category_id': categoryId,
      'restaurant_id': restaurantId,
      'name': name,
      'description': description,
      'image_url': imageUrl, // теперь сохраняем URL фото
    };
  }
}
