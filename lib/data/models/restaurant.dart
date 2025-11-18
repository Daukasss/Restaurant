class Restaurant {
  final int? id;
  final String name;
  final String? description;
  final String? location;
  final String? phone;
  final String? workingHours;
  // final String? priceRange;
  // final String? category;
  final String? ownerId;
  final List<String>? photos;
  final List<DateTime>? bookedDates;
  final double? rating;
  final int? sumPeople;

  Restaurant({
    this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.phone,
    required this.workingHours,
    // required this.priceRange,
    // required this.category,
    required this.ownerId,
    required this.photos,
    required this.bookedDates,
    required this.rating,
    required this.sumPeople,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    List<String> photosList = [];
    if (json['photos'] != null) {
      photosList = List<String>.from(json['photos']);
    } else if (json['image_url'] != null && json['image_url'].isNotEmpty) {
      photosList = [json['image_url']];
    }

    List<DateTime> bookedDatesList = [];
    if (json['booked_dates'] != null) {
      bookedDatesList = (json['booked_dates'] as List)
          .map((date) => DateTime.parse(date))
          .toList();
    }

    return Restaurant(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      location: json['location'] ?? '',
      phone: json['phone'] ?? '',
      workingHours: json['working_hours'] ?? '',
      // priceRange: json['price_range'] ?? '',
      // category: json['category'] ?? 'Mid-range',
      ownerId: json['owner_id'] ?? '',
      photos: photosList,
      bookedDates: bookedDatesList,
      rating: (json['rating'] == null || json['rating'] == 0.0)
          ? 5.0
          : (json['rating'] as num).toDouble(),
      sumPeople: json['sum_people'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    final bookedDatesStrings =
        bookedDates!.map((date) => date.toIso8601String()).toList();

    return {
      'name': name,
      'description': description,
      'location': location,
      'phone': phone,
      'working_hours': workingHours,
      // 'price_range': priceRange,
      // 'category': category,
      'owner_id': ownerId,
      'image_url': photos!.isNotEmpty ? photos![0] : '',
      'photos': photos,
      'booked_dates': bookedDatesStrings,
      'rating': rating,
      'sum_people': sumPeople,
    };
  }
}

class Favorite {
  final int id;
  final String userId;
  final int restaurantId;
  final Restaurant restaurant;

  Favorite({
    required this.id,
    required this.userId,
    required this.restaurantId,
    required this.restaurant,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'],
      userId: json['user_id'],
      restaurantId: json['restaurant_id'],
      restaurant: Restaurant.fromJson(json['restaurants']),
    );
  }
}
