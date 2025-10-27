import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/services/abstract/abstract_auth_services.dart';
import 'package:restauran/data/services/booking_service.dart';
import 'package:restauran/data/services/favorite_service.dart';
import 'package:restauran/data/services/profile_service.dart';
import 'package:restauran/data/services/service_lacator.dart';
import 'package:restauran/firebase_options.dart';
import 'package:restauran/presentation/pages/auth/pages/register_page/cubit/register_cubit.dart';
import 'package:restauran/presentation/pages/customer/page/profile_page/bloc/profil_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/profile_page/bloc/profil_event.dart';
import 'package:restauran/presentation/pages/seller/page/seller_dashboard/bloc/seller_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/services/restaurant_service.dart';
import 'data/services/supabase_notification_service.dart';
import 'theme/aq_toi.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    await SupabaseNotificationService.handleBackgroundMessage(message);
  } catch (_) {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await Supabase.initialize(
      url: 'https://glniozliuyyjgzfysztu.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdsbmlvemxpdXl5amd6ZnlzenR1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDM2NTgyMjQsImV4cCI6MjA1OTIzNDIyNH0.GjMOr56fDfb-unvpGA50wbXfdAkhU7CLuf5-HomUUns',
    );

    setupLacator();
  } catch (_) {}

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => RegisterCubit(
            getIt<AbstractAuthServices>(),
          ),
        ),
        BlocProvider(
          create: (context) => ProfileBloc(
            restaurantService: RestaurantService(),
            profileService: ProfileService(),
            bookingService: BookingService(),
            favoriteService: FavoriteService(),
          )..add(LoadUserData()),
        ),
        // BlocProvider(
        //   create: (context) => BookingBloc(
        //     bookingService: BookingService(),
        //   ),
        // ),
        BlocProvider(
          create: (context) => SellerBloc(),
        ),
      ],
      child: const AqToi(),
    ),
  );
}
