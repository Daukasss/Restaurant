import 'package:get_it/get_it.dart';
import 'package:restauran/data/services/abstract/abstract_auth_services.dart';
import 'package:restauran/data/services/abstract/service_export.dart';
import 'package:restauran/data/services/auth_services.dart';
import 'package:restauran/data/services/booking_service.dart';
import 'package:restauran/data/services/favorite_service.dart';
import 'package:restauran/data/services/menu_service.dart';
import 'package:restauran/data/services/profile_service.dart';
import 'package:restauran/data/services/restaurant_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final getIt = GetIt.instance;

Future<void> setupLacator() async {
  getIt.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  getIt.registerLazySingleton<AbstractRestaurantService>(
      () => RestaurantService());
  getIt.registerLazySingleton<AbstractProfileService>(() => ProfileService());
  getIt.registerLazySingleton<AbstractMenuService>(() => MenuService());
  getIt.registerLazySingleton<AbstractBookingService>(() => BookingService());
  getIt.registerLazySingleton<AbstractFavoriteService>(() => FavoriteService());
  getIt.registerLazySingleton<AbstractAuthServices>(
    () => AuthService(getIt<SupabaseClient>()),
  );
}
