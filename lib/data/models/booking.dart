class Booking {
  final int? id;
  final String? userId;
  final String name;
  final String phone;
  final int guests;
  final DateTime bookingTime;
  final String status;
  final Map<int, int> menu_selections;
  final int restaurantId;
  final int? restaurantCategoryId;
  final List<int>? selectedExtraIds;

  Booking(
    this.restaurantId, {
    this.id,
    this.userId,
    required this.name,
    required this.phone,
    required this.guests,
    required this.bookingTime,
    required this.status,
    required this.menu_selections,
    this.restaurantCategoryId,
    this.selectedExtraIds,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'guests': guests,
      'booking_time': bookingTime.toIso8601String(),
      'status': status,
      'menu_selections': menu_selections.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'restaurant_id': restaurantId,
      'restaurant_category_id': restaurantCategoryId,
      'selected_extras': selectedExtraIds,
    };
  }

  factory Booking.fromJson(Map<String, dynamic> json) {
    // FIXED: Parse menu_selections by iterating instead of casting
    Map<int, int> parsedMenuSelections = {};
    final menuData = json['menu_selections'];
    if (menuData != null && menuData is Map) {
      menuData.forEach((key, value) {
        try {
          final intKey = key is int ? key : int.parse(key.toString());
          final intValue = value is int ? value : int.parse(value.toString());
          parsedMenuSelections[intKey] = intValue;
        } catch (e) {
          // Handle parsing error if necessary
        }
      });
    }

    // FIXED: Handle both column names
    List<int>? parsedExtras;
    if (json['selected_extras'] != null) {
      parsedExtras =
          (json['selected_extras'] as List).map((e) => e as int).toList();
    } else if (json['selected_extra_ids'] != null) {
      parsedExtras =
          (json['selected_extra_ids'] as List).map((e) => e as int).toList();
    }

    return Booking(
      json['restaurant_id'] as int,
      id: json['id'] as int?,
      userId: json['user_id'] as String?,
      name: json['name'] as String,
      phone: json['phone'] as String,
      guests: json['guests'] as int,
      bookingTime: DateTime.parse(json['booking_time'] as String),
      status: json['status'] as String,
      menu_selections: parsedMenuSelections,
      restaurantCategoryId: json['restaurant_category_id'] as int?,
      selectedExtraIds: parsedExtras,
    );
  }

  Booking copyWith({
    int? id,
    String? userId,
    String? name,
    String? phone,
    int? guests,
    DateTime? bookingTime,
    String? status,
    Map<int, int>? menu_selections,
    int? restaurantId,
    int? restaurantCategoryId,
    List<int>? selectedExtraIds,
  }) {
    return Booking(
      restaurantId ?? this.restaurantId,
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      guests: guests ?? this.guests,
      bookingTime: bookingTime ?? this.bookingTime,
      status: status ?? this.status,
      menu_selections: menu_selections ?? this.menu_selections,
      restaurantCategoryId: restaurantCategoryId ?? this.restaurantCategoryId,
      selectedExtraIds: selectedExtraIds ?? this.selectedExtraIds,
    );
  }
}
