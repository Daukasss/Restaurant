import 'package:hive/hive.dart';

part 'booking_hive_model.g.dart';

@HiveType(typeId: 0)
class BookingHiveModel extends HiveObject {
  @HiveField(0)
  late String bookingId;

  @HiveField(1)
  late String restaurantId;

  @HiveField(2)
  late String name;

  @HiveField(3)
  late String phone;

  @HiveField(4)
  late int guests;

  @HiveField(5)
  late String status;

  @HiveField(6)
  late String bookingDate;

  @HiveField(7)
  late String startTime;

  @HiveField(8)
  late String endTime;

  @HiveField(9)
  late double totalPrice;

  @HiveField(10)
  late String? restaurantCategoryId;

  @HiveField(11)
  late List<String>? selectedExtras;

  @HiveField(12)
  late Map<String, String>? menuSelections;

  @HiveField(13)
  late String? restaurantName;

  // ── Обогащённые поля (резолвятся онлайн, хранятся для офлайн) ──

  @HiveField(14)
  late String? categoryName; // Название зала/категории

  @HiveField(15)
  late List<String>? extrasNames; // Названия доп. опций

  @HiveField(16)
  late List<String>? menuItemCategories; // Категории блюд (параллельный список)

  @HiveField(17)
  late List<String>? menuItemNames; // Названия блюд (параллельный список)

  BookingHiveModel();

  factory BookingHiveModel.fromMap(Map<String, dynamic> map) {
    final model = BookingHiveModel();

    model.bookingId = map['id']?.toString() ?? '';
    model.restaurantId = map['restaurant_id']?.toString() ?? '';
    model.name = map['name']?.toString() ?? '';
    model.phone = map['phone']?.toString() ?? '';
    model.guests = (map['guests'] as int?) ?? 0;
    model.status = map['status']?.toString() ?? 'pending';
    model.startTime = map['start_time']?.toString() ?? '00:00';
    model.endTime = map['end_time']?.toString() ?? '00:00';
    model.totalPrice = (map['totalPrice'] as num?)?.toDouble() ?? 0.0;
    model.restaurantCategoryId = map['restaurant_category_id']?.toString();
    model.restaurantName = map['restaurant_name']?.toString();

    // Парсим дату
    final rawDate = map['booking_date'];
    if (rawDate != null) {
      try {
        if (rawDate.runtimeType.toString().contains('Timestamp')) {
          model.bookingDate = (rawDate as dynamic).toDate().toIso8601String();
        } else if (rawDate is DateTime) {
          model.bookingDate = rawDate.toIso8601String();
        } else {
          model.bookingDate = rawDate.toString();
        }
      } catch (_) {
        model.bookingDate = DateTime.now().toIso8601String();
      }
    } else {
      model.bookingDate = DateTime.now().toIso8601String();
    }

    // selected_extras (ID-шники)
    final extras = map['selected_extras'];
    if (extras is List) {
      model.selectedExtras = extras.map((e) => e.toString()).toList();
    } else {
      model.selectedExtras = null;
    }

    // menu_selections (Map)
    final menu = map['menu_selections'];
    if (menu is Map) {
      model.menuSelections =
          menu.map((k, v) => MapEntry(k.toString(), v.toString()));
    } else {
      model.menuSelections = null;
    }

    // ── Обогащённые поля ──────────────────────────────

    // _category_name → categoryName
    model.categoryName = map['_category_name']?.toString();

    // _extras_names → extrasNames
    final extrasNames = map['_extras_names'];
    if (extrasNames is List) {
      model.extrasNames = extrasNames.map((e) => e.toString()).toList();
    } else {
      model.extrasNames = null;
    }

    // _menu_items → два параллельных списка
    final menuItems = map['_menu_items'];
    if (menuItems is List && menuItems.isNotEmpty) {
      final categories = <String>[];
      final names = <String>[];
      for (final item in menuItems) {
        if (item is Map) {
          categories.add((item['category'] ?? '—').toString());
          names.add((item['item'] ?? '—').toString());
        }
      }
      model.menuItemCategories = categories;
      model.menuItemNames = names;
    } else {
      model.menuItemCategories = null;
      model.menuItemNames = null;
    }

    return model;
  }

  Map<String, dynamic> toMap() {
    // Восстанавливаем _menu_items из двух параллельных списков
    List<Map<String, String>> menuItems = [];
    final cats = menuItemCategories;
    final names = menuItemNames;
    if (cats != null && names != null) {
      for (int i = 0; i < cats.length && i < names.length; i++) {
        menuItems.add({'category': cats[i], 'item': names[i]});
      }
    }

    return {
      'id': bookingId,
      'restaurant_id': restaurantId,
      'name': name,
      'phone': phone,
      'guests': guests,
      'status': status,
      'booking_date': bookingDate,
      'start_time': startTime,
      'end_time': endTime,
      'totalPrice': totalPrice,
      'restaurant_category_id': restaurantCategoryId,
      'selected_extras': selectedExtras,
      'menu_selections': menuSelections,
      'restaurant_name': restaurantName,
      // Обогащённые поля — доступны офлайн
      '_category_name': categoryName,
      '_extras_names': extrasNames,
      '_menu_items': menuItems,
    };
  }
}
