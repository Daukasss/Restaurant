import 'package:equatable/equatable.dart';

class RestaurantExtra extends Equatable {
  final int? id;
  final int restaurantId;
  final String name;
  final double price;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;

  const RestaurantExtra({
    this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    this.description,
    this.isActive = true,
    this.createdAt,
  });

  factory RestaurantExtra.fromJson(Map<String, dynamic> json) {
    return RestaurantExtra(
      id: json['id'] as int?,
      restaurantId: json['restaurant_id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'restaurant_id': restaurantId,
      'name': name,
      'price': price,
      if (description != null) 'description': description,
      'is_active': isActive,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    };
  }

  RestaurantExtra copyWith({
    int? id,
    int? restaurantId,
    String? name,
    double? price,
    String? description,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return RestaurantExtra(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, restaurantId, name, price, description, isActive, createdAt];
}
