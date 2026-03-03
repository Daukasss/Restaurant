import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restauran/data/services/abstract/abstract_category_closure_service.dart';
import 'package:restauran/data/services/category_closure_service.dart';

import '../../data/services/auth_services.dart';
import '../../data/services/booking_service.dart';
import '../../data/services/favorite_service.dart';
import '../../data/services/menu_service.dart';
import '../../data/services/profile_service.dart';
import '../../data/services/restaurant_service.dart';
import '../../data/services/abstract/abstract_auth_services.dart';
import '../../data/services/abstract/service_export.dart';

final getIt = GetIt.instance;

Future<void> setupLocator() async {
  print("🚀 SETUP LOCATOR START");

  /// Firebase - просто регистрируем уже существующие экземпляры
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance);

  /// Services
  getIt.registerLazySingleton<AbstractRestaurantService>(
      () => RestaurantService());
  getIt.registerLazySingleton<AbstractProfileService>(() => ProfileService());
  getIt.registerLazySingleton<AbstractMenuService>(() => MenuService());
  getIt.registerLazySingleton<AbstractBookingService>(() => BookingService());
  getIt.registerLazySingleton<AbstractFavoriteService>(() => FavoriteService());
  getIt.registerLazySingleton<AbstractCategoryClosureService>(
      () => CategoryClosureService());

  /// Auth
  getIt.registerSingleton<AbstractAuthServices>(
    AuthService(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
    ),
  );

  print("✅ SETUP LOCATOR DONE");
}
