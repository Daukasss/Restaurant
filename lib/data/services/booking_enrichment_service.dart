import 'package:cloud_firestore/cloud_firestore.dart';

/// Обогащает список бронирований именами категорий, экстра и пунктов меню.
///
/// Раньше сервис работал по принципу N+1: для каждого бронирования
/// последовательно делались отдельные запросы в Firestore (категория,
/// каждый extra, каждый пункт меню). На 10 бронированиях это десятки
/// сетевых round-trip'ов, на 500 — тысячи, поэтому загрузка длилась минутами.
///
/// Теперь:
///   1. Собираем ВСЕ уникальные id из всех бронирований сразу.
///   2. Догружаем каждую коллекцию пачками (whereIn, по 30 id) и параллельно.
///   3. Строим in-memory карты id -> name.
///   4. Обогащаем каждое бронирование локально, без сетевых запросов.
///
/// Сложность падает с O(N * M) сетевых запросов до O(уникальных id / 30).
class BookingEnrichmentService {
  final FirebaseFirestore _firestore;

  /// Максимальный размер списка для оператора whereIn в Firestore.
  static const int _whereInChunkSize = 30;

  BookingEnrichmentService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> enrich(
    List<Map<String, dynamic>> bookings,
  ) async {
    if (bookings.isEmpty) return [];

    // ── 1. Собираем все уникальные id ───────────────────
    final categoryIds = <String>{};
    final extrasIds = <String>{};
    final menuCategoryIds = <String>{};
    final menuItemIds = <String>{};

    for (final booking in bookings) {
      final categoryId = booking['restaurant_category_id']?.toString();
      if (categoryId != null && categoryId.isNotEmpty) {
        categoryIds.add(categoryId);
      }

      final extras = booking['selected_extras'];
      if (extras is List) {
        for (final id in extras) {
          final s = id?.toString();
          if (s != null && s.isNotEmpty) extrasIds.add(s);
        }
      }

      final menuSelections = booking['menu_selections'];
      if (menuSelections is Map) {
        for (final entry in menuSelections.entries) {
          final catId = entry.key?.toString();
          final itemId = entry.value?.toString();
          if (catId != null && catId.isNotEmpty) menuCategoryIds.add(catId);
          if (itemId != null && itemId.isNotEmpty) menuItemIds.add(itemId);
        }
      }
    }

    // ── 2. Догружаем все коллекции параллельно ──────────
    final results = await Future.wait([
      _fetchNames('restaurant_categories', categoryIds),
      _fetchNames('restaurant_extras', extrasIds),
      _fetchNames('menu_categories', menuCategoryIds),
      _fetchNames('menu_items', menuItemIds),
    ]);

    final categoryNames = results[0];
    final extrasNames = results[1];
    final menuCategoryNames = results[2];
    final menuItemNames = results[3];

    // ── 3. Обогащаем локально, без сети ─────────────────
    return bookings.map((booking) {
      final map = Map<String, dynamic>.from(booking);

      // Категория
      final categoryId = map['restaurant_category_id']?.toString();
      map['_category_name'] =
          (categoryId != null) ? (categoryNames[categoryId] ?? '') : '';

      // Extras
      final extras = map['selected_extras'];
      if (extras is List && extras.isNotEmpty) {
        map['_extras_names'] = extras
            .map((id) => extrasNames[id?.toString()])
            .whereType<String>()
            .toList();
      } else {
        map['_extras_names'] = <String>[];
      }

      // Меню
      final menuSelections = map['menu_selections'];
      if (menuSelections is Map && menuSelections.isNotEmpty) {
        map['_menu_items'] = menuSelections.entries.map((entry) {
          return {
            'category': menuCategoryNames[entry.key?.toString()] ?? '—',
            'item': menuItemNames[entry.value?.toString()] ?? '—',
          };
        }).toList();
      } else {
        map['_menu_items'] = <Map<String, String>>[];
      }

      return map;
    }).toList();
  }

  /// Возвращает карту {documentId: name} для всех переданных id,
  /// догружая документы пачками по [_whereInChunkSize] параллельно.
  Future<Map<String, String>> _fetchNames(
    String collection,
    Set<String> ids,
  ) async {
    if (ids.isEmpty) return {};

    final idList = ids.toList();
    final chunks = <List<String>>[];
    for (var i = 0; i < idList.length; i += _whereInChunkSize) {
      chunks.add(idList.sublist(
        i,
        (i + _whereInChunkSize).clamp(0, idList.length),
      ));
    }

    final names = <String, String>{};

    await Future.wait(chunks.map((chunk) async {
      try {
        final snapshot = await _firestore
            .collection(collection)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        for (final doc in snapshot.docs) {
          names[doc.id] = doc.data()['name']?.toString() ?? '';
        }
      } catch (_) {
        // Игнорируем ошибки отдельного чанка, остальные данные подгрузятся.
      }
    }));

    return names;
  }
}
