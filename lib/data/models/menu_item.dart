class MenuItem {
  final int? id;
  final int categoryId;
  final int restaurantId;
  final String name;
  final String description;
  // final String imageUrl;

  MenuItem({
    this.id,
    required this.categoryId,
    required this.restaurantId,
    required this.name,
    required this.description,
    // required this.imageUrl,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'],
      categoryId: json['category_id'],
      restaurantId: json['restaurant_id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      // imageUrl: json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'restaurant_id': restaurantId,
      'name': name,
      'description': description,
      // 'image_url': imageUrl,
    };
  }
}
