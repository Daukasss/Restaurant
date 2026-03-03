import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Категория ресторана - привязана к глобальной категории
/// Seller может активировать/деактивировать и устанавливать свою цену и описание
class RestaurantCategory extends Equatable {
  final String? id;
  final String restaurantId;
  final String globalCategoryId; // ID глобальной категории
  final String name; // Название берется из глобальной категории
  final int section; // 1 или 2 - берется из глобальной категории
  final double priceRange; // Цена, установленная seller'ом
  final String?
      description; // Описание, установленное seller'ом (может переопределить)
  final bool isActive; // Активирована ли категория для этого ресторана
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const RestaurantCategory({
    this.id,
    required this.restaurantId,
    required this.globalCategoryId,
    required this.name,
    required this.section,
    required this.priceRange,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory RestaurantCategory.fromJson(Map<String, dynamic> json) {
    return RestaurantCategory(
      id: json['id']?.toString(),
      restaurantId: json['restaurant_id']?.toString() ?? '',
      globalCategoryId: json['global_category_id']?.toString() ?? '',
      name: json['name'] ?? '',
      section: json['section'] ?? 1,
      priceRange: (json['price_range'] ?? 0.0).toDouble(),
      description: json['description'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? (json['created_at'] as Timestamp).toDate()
          : null,
      updatedAt: json['updated_at'] != null
          ? (json['updated_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'restaurant_id': restaurantId,
      'global_category_id': globalCategoryId,
      'name': name,
      'section': section,
      'price_range': priceRange,
      'description': description,
      'is_active': isActive,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
    };
  }

  RestaurantCategory copyWith({
    String? id,
    String? restaurantId,
    String? globalCategoryId,
    String? name,
    int? section,
    double? priceRange,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RestaurantCategory(
      id: id ?? this.id,
      restaurantId: restaurantId ?? this.restaurantId,
      globalCategoryId: globalCategoryId ?? this.globalCategoryId,
      name: name ?? this.name,
      section: section ?? this.section,
      priceRange: priceRange ?? this.priceRange,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        restaurantId,
        globalCategoryId,
        name,
        section,
        priceRange,
        description,
        isActive,
        createdAt,
        updatedAt,
      ];
}
