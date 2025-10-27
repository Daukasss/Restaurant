import '../../models/restaurant.dart';

abstract class AbstractFavoriteService {
  Future<List<Favorite>> getFavorites();
}
