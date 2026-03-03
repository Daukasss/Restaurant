import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Глобальная категория, создаваемая администратором
class GlobalCategory extends Equatable {
  final String? id;
  final String name;
  final int section; // 1 или 2 - раздел категории
  final double defaultPrice; // Цена по умолчанию
  final String? description;
  final bool isGlobal; // true - для всех, false - для конкретных ресторанов
  final List<String> restaurantIds; // Пустой если isGlobal = true
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GlobalCategory({
    this.id,
    required this.name,
    required this.section,
    required this.defaultPrice,
    this.description,
    this.isGlobal = true,
    this.restaurantIds = const [],
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory GlobalCategory.fromJson(Map<String, dynamic> json) {
    return GlobalCategory(
      id: json['id']?.toString(),
      name: json['name'] ?? '',
      section: json['section'] ?? 1,
      defaultPrice: (json['default_price'] ?? 0.0).toDouble(),
      description: json['description'],
      isGlobal: json['is_global'] ?? true,
      restaurantIds: json['restaurant_ids'] != null
          ? List<String>.from(json['restaurant_ids'])
          : [],
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
      'name': name,
      'section': section,
      'default_price': defaultPrice,
      'description': description,
      'is_global': isGlobal,
      'restaurant_ids': restaurantIds,
      'is_active': isActive,
      if (createdAt != null) 'created_at': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updated_at': Timestamp.fromDate(updatedAt!),
    };
  }

  GlobalCategory copyWith({
    String? id,
    String? name,
    int? section,
    double? defaultPrice,
    String? description,
    bool? isGlobal,
    List<String>? restaurantIds,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GlobalCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      section: section ?? this.section,
      defaultPrice: defaultPrice ?? this.defaultPrice,
      description: description ?? this.description,
      isGlobal: isGlobal ?? this.isGlobal,
      restaurantIds: restaurantIds ?? this.restaurantIds,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        section,
        defaultPrice,
        description,
        isGlobal,
        restaurantIds,
        isActive,
        createdAt,
        updatedAt,
      ];
}
