import '../../theme/aq_toi.dart';
import '../models/restaurant.dart';
import 'package:restauran/data/services/abstract/service_export.dart';

class FavoriteService implements AbstractFavoriteService {
  @override
  Future<List<Favorite>> getFavorites() async {
    final response = await supabase
        .from('favorites')
        .select('*, restaurants(*)')
        .eq('user_id', supabase.auth.currentUser!.id);

    return List<Map<String, dynamic>>.from(response)
        .map((json) => Favorite.fromJson(json))
        .toList();
  }
}
