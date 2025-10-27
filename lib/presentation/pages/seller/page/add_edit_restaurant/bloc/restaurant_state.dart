import 'package:equatable/equatable.dart';
import '../../../../../../data/models/restaurant_category.dart';
import '../../../../../../data/models/restaurant_extra.dart';

class RestaurantState extends Equatable {
  final String name;
  final String description;
  final String location;
  final List<String>
      phones; // <CHANGE> Изменено с String phone на List<String> phones
  final String workingHours;
  final String priceRange;
  final String sumPeople;
  final String category;
  final List<String> photoUrls;
  final List<DateTime> restaurantBookedDates;
  final List<DateTime> visibleBookedDates;
  final bool isLoading;
  final bool isEditing;
  final String? error;
  final bool isSuccess;
  final double rating;
  final int restaurantId;
  final List<DateTime> tempBookedDates;
  final List<RestaurantCategory> restaurantCategories;
  final bool isCategoriesLoading;
  final List<RestaurantExtra> restaurantExtras;
  final bool isExtrasLoading;

  const RestaurantState({
    this.name = '',
    this.description = '',
    this.location = '',
    this.phones = const [], // <CHANGE> Изменено значение по умолчанию
    this.workingHours = '',
    this.priceRange = '',
    this.sumPeople = '',
    this.category = 'Mid-range',
    this.photoUrls = const [],
    this.restaurantBookedDates = const [],
    this.visibleBookedDates = const [],
    this.isLoading = false,
    this.isEditing = false,
    this.error,
    this.isSuccess = false,
    this.rating = 5.0,
    this.restaurantId = 0,
    this.tempBookedDates = const [],
    this.restaurantCategories = const [],
    this.isCategoriesLoading = false,
    this.restaurantExtras = const [],
    this.isExtrasLoading = false,
  });

  RestaurantState copyWith({
    String? name,
    String? description,
    String? location,
    List<String>? phones, // <CHANGE> Изменено с String? phone
    String? workingHours,
    String? priceRange,
    String? sumPeople,
    String? category,
    List<String>? photoUrls,
    List<DateTime>? restaurantBookedDates,
    List<DateTime>? visibleBookedDates,
    bool? isLoading,
    bool? isEditing,
    String? error,
    bool? isSuccess,
    double? rating,
    int? restaurantId,
    List<DateTime>? tempBookedDates,
    List<RestaurantCategory>? restaurantCategories,
    bool? isCategoriesLoading,
    List<RestaurantExtra>? restaurantExtras,
    bool? isExtrasLoading,
  }) {
    return RestaurantState(
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      phones: phones ?? this.phones, // <CHANGE> Изменено
      workingHours: workingHours ?? this.workingHours,
      priceRange: priceRange ?? this.priceRange,
      sumPeople: sumPeople ?? this.sumPeople,
      category: category ?? this.category,
      photoUrls: photoUrls ?? this.photoUrls,
      restaurantBookedDates:
          restaurantBookedDates ?? this.restaurantBookedDates,
      visibleBookedDates: visibleBookedDates ?? this.visibleBookedDates,
      isLoading: isLoading ?? this.isLoading,
      isEditing: isEditing ?? this.isEditing,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
      rating: rating ?? this.rating,
      restaurantId: restaurantId ?? this.restaurantId,
      tempBookedDates: tempBookedDates ?? this.tempBookedDates,
      restaurantCategories: restaurantCategories ?? this.restaurantCategories,
      isCategoriesLoading: isCategoriesLoading ?? this.isCategoriesLoading,
      restaurantExtras: restaurantExtras ?? this.restaurantExtras,
      isExtrasLoading: isExtrasLoading ?? this.isExtrasLoading,
    );
  }

  @override
  List<Object?> get props => [
        name,
        description,
        location,
        phones, // <CHANGE> Изменено с phone
        workingHours,
        priceRange,
        sumPeople,
        category,
        photoUrls,
        restaurantBookedDates,
        visibleBookedDates,
        isLoading,
        isEditing,
        error,
        isSuccess,
        rating,
        restaurantId,
        tempBookedDates,
        restaurantCategories,
        isCategoriesLoading,
        restaurantExtras,
        isExtrasLoading,
      ];
}
