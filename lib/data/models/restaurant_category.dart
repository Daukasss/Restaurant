import 'package:equatable/equatable.dart';

class RestaurantCategory extends Equatable {
  final int? id;
  final int restaurantId;
  final String name;
  final double priceRange;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;

  const RestaurantCategory({
    this.id,
    required this.restaurantId,
    required this.name,
    required this.priceRange,
    this.description,
    this.isActive = true,
    this.createdAt,
  });

  factory RestaurantCategory.fromJson(Map<String, dynamic> json) {
    return RestaurantCategory(
      id: json['id'],
      restaurantId: json['restaurant_id'],
      name: json['name'] ?? '',
      priceRange: (json['price_range'] ?? 0.0).toDouble(),
      description: json['description'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'price_range': priceRange,
      'description': description,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  RestaurantCategory copyWith({
    int? id,
    int? restaurantId,
    String? name,
    double? priceRange,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RestaurantCategory(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      priceRange: priceRange ?? this.priceRange,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        name,
        priceRange,
        description,
        isActive,
        createdAt,
      ];
}
