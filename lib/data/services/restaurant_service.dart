// ignore_for_file: prefer_collection_literals

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:restauran/data/services/abstract/service_export.dart';
import '../models/restaurant.dart';
import '../models/restaurant_category.dart';
import '../models/restaurant_extra.dart';

class RestaurantService implements AbstractRestaurantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Future<List<RestaurantExtra>> getRestaurantExtras(String restaurantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('restaurant_extras')
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RestaurantExtra.fromJson(data);
      }).toList();
    } catch (error) {
      debugPrint('Ошибка загрузки extras: $error');
      throw Exception('Failed to load restaurant extras: $error');
    }
  }

  /// Возвращает список ID ресторанов, доступных по выбранной категории и дате.
  ///
  /// Логика:
  /// 1. Ресторан должен иметь активную категорию с globalCategoryId (если указан).
  /// 2. Ресторан должен быть свободен на дату (если указана):
  ///    — проверяем, нет ли бронирований на этот раздел (section) в эту дату.
  ///    — раздел берём из globalCategory, т.е. все категории одного раздела конкурируют.
  Future<List<String>> getRestaurantsAvailableForDateAndSection({
    DateTime? date,
    int? section,
    String? globalCategoryId,
  }) async {
    // Если ничего не задано — возвращаем пустой список
    // (вызывающий код не должен вызывать эту функцию без параметров)
    if (globalCategoryId == null && date == null && section == null) {
      return [];
    }

    try {
      // ── Шаг 1: получаем все рестораны ──────────────────────────────────────
      // Не фильтруем по is_active здесь — у тебя может не быть этого поля.
      final restaurantsSnap = await _firestore.collection('restaurants').get();

      final allRestaurantIds = restaurantsSnap.docs.map((d) => d.id).toList();

      if (allRestaurantIds.isEmpty) return [];

      // ── Шаг 2: фильтр по категории ─────────────────────────────────────────
      // Оставляем только те рестораны, у которых есть активная restaurant_category
      // с нужным global_category_id.
      Set<String> restaurantsWithCategory;

      if (globalCategoryId != null) {
        final catSnap = await _firestore
            .collection('restaurant_categories')
            .where('global_category_id', isEqualTo: globalCategoryId)
            .where('is_active', isEqualTo: true)
            .get();

        restaurantsWithCategory = catSnap.docs
            .map((d) => d.data()['restaurant_id'] as String)
            .toSet();
      } else {
        // Нет фильтра по категории — все рестораны проходят
        restaurantsWithCategory = allRestaurantIds.toSet();
      }

      if (restaurantsWithCategory.isEmpty) return [];

      // ── Шаг 3: фильтр по дате + разделу ───────────────────────────────────
      // Если дата не указана — возвращаем то что есть после фильтра по категории.
      if (date == null || section == null) {
        return restaurantsWithCategory.toList();
      }

      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // Получаем все restaurant_categories этого раздела для ресторанов из выборки
      // Нам нужно знать: какие categoryId относятся к section у каждого ресторана.
      //
      // Алгоритм:
      // а) Берём все global_categories с нужным section
      // б) Находим restaurant_categories, которые ссылаются на эти global_categories
      //    и принадлежат ресторанам из нашей выборки
      // в) Проверяем category_closures на эту дату для этих категорий
      // г) Ресторан занят, если хоть одна его категория того же раздела заблокирована

      // а) Глобальные категории с нужным section
      final globalCatsSnap = await _firestore
          .collection('global_categories')
          .where('section', isEqualTo: section)
          .where('is_active', isEqualTo: true)
          .get();

      final globalCatIds = globalCatsSnap.docs.map((d) => d.id).toSet();

      if (globalCatIds.isEmpty) {
        // Нет глобальных категорий этого раздела — все проходят
        return restaurantsWithCategory.toList();
      }

      // б) Категории ресторанов, относящихся к этому разделу
      // Firestore whereIn ограничен 30 элементами — делаем батчи
      final Map<String, Set<String>> restaurantToSectionCategoryIds = {};

      final globalCatIdsList = globalCatIds.toList();
      for (int i = 0; i < globalCatIdsList.length; i += 30) {
        final batch = globalCatIdsList.skip(i).take(30).toList();
        final rcSnap = await _firestore
            .collection('restaurant_categories')
            .where('global_category_id', whereIn: batch)
            .where('is_active', isEqualTo: true)
            .get();

        for (final doc in rcSnap.docs) {
          final data = doc.data();
          final rId = data['restaurant_id'] as String?;
          if (rId == null || !restaurantsWithCategory.contains(rId)) continue;

          restaurantToSectionCategoryIds.putIfAbsent(rId, () => {});
          restaurantToSectionCategoryIds[rId]!.add(doc.id);
        }
      }

      // в) Получаем category_closures на эту дату
      final closuresSnap = await _firestore
          .collection('category_closures')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .get();

      // Набор category_id, заблокированных на эту дату
      final blockedCategoryIds = closuresSnap.docs
          .map((d) => d.data()['category_id'] as String)
          .toSet();

      // г) Так же проверяем bookings — бронирование на эту дату по section
      final bookingsSnap = await _firestore
          .collection('bookings')
          .where('booking_date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('booking_date', isLessThan: Timestamp.fromDate(endOfDay))
          .where('status', whereIn: ['pending', 'confirmed']).get();

      // restaurantId -> Set<categoryId> которые заняты через bookings
      final Map<String, Set<String>> bookedCategoryIdsByRestaurant = {};
      for (final doc in bookingsSnap.docs) {
        final data = doc.data();
        final rId = data['restaurant_id'] as String?;
        final catId = data['category_id'] as String?;
        if (rId == null || catId == null) continue;
        bookedCategoryIdsByRestaurant.putIfAbsent(rId, () => {});
        bookedCategoryIdsByRestaurant[rId]!.add(catId);
      }

      // ── Шаг 4: финальная фильтрация ────────────────────────────────────────
      final available = <String>[];

      for (final restaurantId in restaurantsWithCategory) {
        final sectionCatIds =
            restaurantToSectionCategoryIds[restaurantId] ?? {};

        if (sectionCatIds.isEmpty) {
          // У ресторана нет категорий этого раздела — он не подходит для фильтра
          continue;
        }

        // Ресторан занят если хоть одна его категория того же раздела:
        // — заблокирована через category_closures, ИЛИ
        // — забронирована через bookings
        final bookedCats = bookedCategoryIdsByRestaurant[restaurantId] ?? {};

        final isBusy = sectionCatIds.any((catId) =>
            blockedCategoryIds.contains(catId) || bookedCats.contains(catId));

        if (!isBusy) {
          available.add(restaurantId);
        }
      }

      return available;
    } catch (error) {
      debugPrint('Ошибка фильтрации ресторанов: $error');
      return [];
    }
  }

  @override
  Future<RestaurantExtra> addRestaurantExtra(RestaurantExtra extra) async {
    try {
      final data = extra.toJson();
      data['created_at'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('restaurant_extras').add(data);

      final doc = await docRef.get();
      final responseData = doc.data()!;
      responseData['id'] = doc.id;

      return RestaurantExtra.fromJson(responseData);
    } catch (error) {
      debugPrint('Ошибка добавления extra: $error');
      throw Exception('Failed to add restaurant extra: $error');
    }
  }

  @override
  Future<RestaurantExtra> updateRestaurantExtra(RestaurantExtra extra) async {
    try {
      final data = extra.toJson();
      data.remove('id');
      data['updated_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('restaurant_extras')
          .doc(extra.id)
          .update(data);

      final doc =
          await _firestore.collection('restaurant_extras').doc(extra.id).get();

      final responseData = doc.data()!;
      responseData['id'] = doc.id;

      return RestaurantExtra.fromJson(responseData);
    } catch (error) {
      debugPrint('Ошибка обновления extra: $error');
      throw Exception('Failed to update restaurant extra: $error');
    }
  }

  @override
  Future<void> deleteRestaurantExtra(String extraId) async {
    try {
      await _firestore
          .collection('restaurant_extras')
          .doc(extraId)
          .update({'is_active': false});
    } catch (error) {
      debugPrint('Ошибка удаления extra: $error');
      throw Exception('Failed to delete restaurant extra: $error');
    }
  }

  @override
  Future<RestaurantCategory?> getRestaurantCategoryById(
      String categoryId) async {
    try {
      final doc = await _firestore
          .collection('restaurant_categories')
          .doc(categoryId)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      if (data['is_active'] != true) return null;

      data['id'] = doc.id;
      return RestaurantCategory.fromJson(data);
    } catch (error) {
      debugPrint('Ошибка загрузки категории: $error');
      throw Exception('Failed to load restaurant category: $error');
    }
  }

  @override
  Future<List<RestaurantCategory>> getRestaurantCategories(
      String restaurantId) async {
    try {
      final querySnapshot = await _firestore
          .collection('restaurant_categories')
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('is_active', isEqualTo: true)
          .orderBy('created_at')
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return RestaurantCategory.fromJson(data);
      }).toList();
    } catch (error) {
      debugPrint('Ошибка загрузки категорий: $error');
      throw Exception('Failed to load restaurant categories: $error');
    }
  }

  @override
  Future<RestaurantCategory> addRestaurantCategory(
      RestaurantCategory category) async {
    try {
      final data = category.toJson();
      data['created_at'] = FieldValue.serverTimestamp();

      final docRef =
          await _firestore.collection('restaurant_categories').add(data);

      final doc = await docRef.get();
      final responseData = doc.data()!;
      responseData['id'] = doc.id;

      return RestaurantCategory.fromJson(responseData);
    } catch (error) {
      debugPrint('Ошибка добавления категории: $error');
      throw Exception('Failed to add restaurant category: $error');
    }
  }

  @override
  Future<RestaurantCategory> updateRestaurantCategory(
      RestaurantCategory category) async {
    try {
      final data = category.toJson();
      data.remove('id');
      data['updated_at'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('restaurant_categories')
          .doc(category.id)
          .update(data);

      final doc = await _firestore
          .collection('restaurant_categories')
          .doc(category.id)
          .get();

      final responseData = doc.data()!;
      responseData['id'] = doc.id;

      return RestaurantCategory.fromJson(responseData);
    } catch (error) {
      debugPrint('Ошибка обновления категории: $error');
      throw Exception('Failed to update restaurant category: $error');
    }
  }

  @override
  Future<void> deleteRestaurantCategory(String categoryId) async {
    try {
      await _firestore
          .collection('restaurant_categories')
          .doc(categoryId)
          .update({'is_active': false});
    } catch (error) {
      debugPrint('Ошибка удаления категории: $error');
      throw Exception('Failed to delete restaurant category: $error');
    }
  }

  @override
  Future<Map<String, dynamic>> getRestaurantData(String restaurantId) async {
    try {
      final doc =
          await _firestore.collection('restaurants').doc(restaurantId).get();

      if (!doc.exists) {
        throw Exception('Ресторан не найден');
      }

      final restaurantData = doc.data()!;
      final categories = await getRestaurantCategories(restaurantId);

      final sumPeople = restaurantData['sum_people'] ?? 0;
      final pricePerGuest =
          double.tryParse(restaurantData['price_range']?.toString() ?? '0') ??
              0.0;

      return {
        'sumPeople': sumPeople,
        'pricePerGuest': pricePerGuest,
        'categories': categories,
      };
    } catch (error) {
      debugPrint('Ошибка загрузки данных ресторана: $error');
      throw Exception('Failed to load restaurant data');
    }
  }

  /// Генерирует новый ID документа заранее, до сохранения.
  /// Используется при создании ресторана, чтобы ID был известен для загрузки фото.
  String generateRestaurantId() {
    return _firestore.collection('restaurants').doc().id;
  }

  @override
  Future<void> saveRestaurant(Restaurant restaurant,
      {String? existingId, String? newId}) async {
    try {
      final data = restaurant.toJson();

      if (existingId != null) {
        // Обновление существующего ресторана
        data.remove('id');
        data['updated_at'] = FieldValue.serverTimestamp();

        await _firestore.collection('restaurants').doc(existingId).update(data);
      } else {
        // Создание нового ресторана
        data['created_at'] = FieldValue.serverTimestamp();

        if (newId != null) {
          // Используем заранее сгенерированный ID (чтобы фото уже были привязаны)
          await _firestore.collection('restaurants').doc(newId).set(data);
        } else {
          await _firestore.collection('restaurants').add(data);
        }
      }
    } catch (error) {
      debugPrint('Ошибка сохранения ресторана: $error');
      throw Exception('Failed to save restaurant: $error');
    }
  }

  @override
  Future<List<DateTime>> getRestaurantBookedDates(String restaurantId) async {
    try {
      final doc =
          await _firestore.collection('restaurants').doc(restaurantId).get();

      if (!doc.exists || doc.data()?['booked_dates'] == null) {
        return [];
      }

      return List<String>.from(doc.data()!['booked_dates'])
          .map((e) => DateTime.parse(e))
          .toList();
    } catch (error) {
      debugPrint('Ошибка загрузки забронированных дат: $error');
      return [];
    }
  }

  @override
  Future<List<DateTime>> getBookedDates(String restaurantId) async {
    try {
      final restaurantDates = await getRestaurantBookedDates(restaurantId);

      final querySnapshot = await _firestore
          .collection('bookings')
          .where('restaurant_id', isEqualTo: restaurantId)
          .where('status', whereIn: ['pending', 'confirmed']).get();

      final bookingDates = querySnapshot.docs.map<DateTime>((doc) {
        final data = doc.data();
        final bookingTime = data['booking_time'];

        DateTime date;
        if (bookingTime is Timestamp) {
          date = bookingTime.toDate();
        } else {
          date = DateTime.parse(bookingTime);
        }

        return DateTime(date.year, date.month, date.day);
      }).toList();

      return [...restaurantDates, ...bookingDates].toSet().toList();
    } catch (error) {
      debugPrint('Ошибка загрузки всех забронированных дат: $error');
      return [];
    }
  }

  @override
  Future<void> updateRestaurantBookedDates(
      String restaurantId, DateTime newDate) async {
    try {
      final existingDates = await getRestaurantBookedDates(restaurantId);
      final dateOnly = DateTime(newDate.year, newDate.month, newDate.day);

      final dateExists = existingDates.any((date) =>
          date.year == dateOnly.year &&
          date.month == dateOnly.month &&
          date.day == dateOnly.day);

      if (!dateExists) {
        final updatedDates = [...existingDates, dateOnly];
        updatedDates.sort();

        await _firestore.collection('restaurants').doc(restaurantId).update({
          'booked_dates': updatedDates.map((d) => d.toIso8601String()).toList(),
        });
      }
    } catch (error) {
      debugPrint('Ошибка обновления забронированных дат: $error');
    }
  }

  Future<void> removeBookedDate(
      String restaurantId, DateTime dateToRemove) async {
    try {
      final existingDates = await getRestaurantBookedDates(restaurantId);
      final dateOnly =
          DateTime(dateToRemove.year, dateToRemove.month, dateToRemove.day);

      final updatedDates = existingDates
          .where((date) => !(date.year == dateOnly.year &&
              date.month == dateOnly.month &&
              date.day == dateOnly.day))
          .toList();

      await _firestore.collection('restaurants').doc(restaurantId).update({
        'booked_dates': updatedDates.map((d) => d.toIso8601String()).toList(),
      });
    } catch (error) {
      debugPrint('Ошибка удаления забронированной даты: $error');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRestaurants() async {
    try {
      final querySnapshot = await _firestore
          .collection('restaurants')
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (error) {
      debugPrint('Ошибка загрузки ресторанов: $error');
      throw Exception('Failed to load restaurants');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRestaurantsByUserId(
      String userId) async {
    try {
      debugPrint('[Firebase] Fetching restaurants for userId: $userId');

      final querySnapshot = await _firestore
          .collection('restaurants')
          .where('owner_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      debugPrint(
          '[Firebase] Restaurants fetched successfully: ${querySnapshot.docs.length} restaurants found');

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (error) {
      debugPrint('[Firebase] Error fetching restaurants: $error');
      debugPrint('[Firebase] Error type: ${error.runtimeType}');
      throw Exception('Failed to load restaurants for user: $error');
    }
  }

  @override
  Future<void> deleteRestaurant(String restaurantId) async {
    try {
      debugPrint(
          '[Firebase] Starting cascade delete for restaurant $restaurantId');

      final extrasSnapshot = await _firestore
          .collection('restaurant_extras')
          .where('restaurant_id', isEqualTo: restaurantId)
          .get();

      for (var doc in extrasSnapshot.docs) {
        await doc.reference.delete();
      }

      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('restaurant_id', isEqualTo: restaurantId)
          .get();

      for (var doc in notificationsSnapshot.docs) {
        await doc.reference.delete();
      }

      final bookingsSnapshot = await _firestore
          .collection('bookings')
          .where('restaurant_id', isEqualTo: restaurantId)
          .get();

      for (var bookingDoc in bookingsSnapshot.docs) {
        final extrasSubcollection =
            await bookingDoc.reference.collection('booking_extras').get();

        for (var extraDoc in extrasSubcollection.docs) {
          await extraDoc.reference.delete();
        }

        await bookingDoc.reference.delete();
      }

      final categoriesSnapshot = await _firestore
          .collection('restaurant_categories')
          .where('restaurant_id', isEqualTo: restaurantId)
          .get();

      final categoryIds = categoriesSnapshot.docs.map((doc) => doc.id).toList();

      if (categoryIds.isNotEmpty) {
        for (final categoryId in categoryIds) {
          final menuItemsSnapshot = await _firestore
              .collection('menu_items')
              .where('category_id', isEqualTo: categoryId)
              .get();

          for (var doc in menuItemsSnapshot.docs) {
            await doc.reference.delete();
          }
        }
      }

      for (var doc in categoriesSnapshot.docs) {
        await doc.reference.delete();
      }

      final menuCategoriesSnapshot = await _firestore
          .collection('menu_categories')
          .where('restaurant_id', isEqualTo: restaurantId)
          .get();

      for (var doc in menuCategoriesSnapshot.docs) {
        await doc.reference.delete();
      }

      await _firestore.collection('restaurants').doc(restaurantId).delete();

      debugPrint(
          '[Firebase] Restaurant $restaurantId deleted successfully with all related data');
    } catch (error) {
      debugPrint('[Firebase] Error deleting restaurant: $error');
      throw Exception('Failed to delete restaurant: $error');
    }
  }
}
