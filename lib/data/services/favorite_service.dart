import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/restaurant.dart';
import 'package:restauran/data/services/abstract/service_export.dart';

class FavoriteService implements AbstractFavoriteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<List<Favorite>> getFavorites() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('Пользователь не авторизован');
    }

    final querySnapshot = await _firestore
        .collection('favorites')
        .where('user_id', isEqualTo: currentUser.uid)
        .get();

    final favorites = <Favorite>[];

    for (var doc in querySnapshot.docs) {
      final data = doc.data();
      data['id'] = (doc.id);

      // Получаем данные ресторана
      if (data['restaurant_id'] != null) {
        final restaurantDoc = await _firestore
            .collection('restaurants')
            .doc(data['restaurant_id'].toString())
            .get();

        if (restaurantDoc.exists) {
          final restaurantData = restaurantDoc.data()!;
          restaurantData['id'] = (restaurantDoc.id);
          data['restaurants'] = restaurantData;

          favorites.add(Favorite.fromJson(data));
        }
      }
    }

    return favorites;
  }
}
