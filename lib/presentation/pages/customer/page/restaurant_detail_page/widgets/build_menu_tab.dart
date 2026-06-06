import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/bloc/restaurant_detail_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/bloc/restaurant_detail_state.dart';
import 'package:restauran/presentation/pages/seller/widgets/menu_item_title.dart';

// ── Design tokens (matches AppTheme & booking_page tokens) ──────────────────
const _primary = Color(0xFF1A365D);
const _primaryLight = Color(0xFF2A4A7F);
// const _cardBg = Colors.white;
const _textMain = Color(0xFF1A2535);
const _textSub = Color(0xFF6B7A92);
const _divider = Color(0xFFE8EDF5);
const _surface = Color(0xFFF7F9FC);

class BuildMenuTab extends StatelessWidget {
  const BuildMenuTab({
    super.key,
    required this.context,
    required this.state,
  });

  final BuildContext context;
  final RestaurantDetailState state;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('profiles')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .get(),
        builder: (context, snapshot) {
          final role = snapshot.data?.get('role');

          return Scaffold(
            appBar: role == 'seller'
                ? AppBar(
                    surfaceTintColor: Colors.transparent,
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    backgroundColor: _surface,
                  )
                : null,
            backgroundColor: _surface,
            body: BlocBuilder<RestaurantDetailBloc, RestaurantDetailState>(
                builder: (context, state) {
              if (state.restaurantCategories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.restaurant_menu_outlined,
                        size: 56,
                        color: _textSub.withOpacity(0.35),
                      ),
                      const SizedBox(height: 16),
                      const Text('Меню отсутствует'),
                    ],
                  ),
                );
              }

              final List<Widget> allItems = [];

              for (final restaurantCategory in state.restaurantCategories) {
                final categoryData =
                    state.menuByRestaurantCategory[restaurantCategory.id];

                if (categoryData == null) continue;

                final menuCategories = categoryData['menuCategories']
                    as List<Map<String, dynamic>>;
                final menuItemsByMenuCategory = categoryData['menuItems']
                    as Map<String, List<Map<String, dynamic>>>;

                // ── Section header (restaurant category) ──────────────────────────────
                allItems.add(
                  Padding(
                    padding: const EdgeInsets.only(top: 0, bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_primary, _primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _primary.withOpacity(0.22),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                restaurantCategory.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              // if (restaurantCategory.description != null &&
                              //     restaurantCategory.description!.isNotEmpty) ...[
                              //   const SizedBox(height: 4),
                              //   Text(
                              //     restaurantCategory.description!,
                              //     style: TextStyle(
                              //       fontSize: 13,
                              //       color: Colors.white.withOpacity(0.80),
                              //     ),
                              //   ),
                              // ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );

                if (menuCategories.isEmpty) {
                  allItems.add(
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                      child: Text(
                        'В этой категории нет меню',
                        style: TextStyle(
                          fontSize: 14,
                          color: _textSub,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  );
                } else {
                  for (final menuCategory in menuCategories) {
                    final menuCategoryId = menuCategory['id'] as String;
                    final menuCategoryName = menuCategory['name'] as String;
                    final items = menuItemsByMenuCategory[menuCategoryId] ?? [];

                    // ── Menu sub-category label ──────────────────────────────────────
                    allItems.add(
                      Padding(
                        padding: const EdgeInsets.only(top: 20, bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 18,
                              decoration: BoxDecoration(
                                color: _primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              menuCategoryName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _textMain,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (items.isEmpty) {
                      allItems.add(
                        const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                          child: Text(
                            'В этой категории нет блюд',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSub,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      );
                    } else {
                      // ── Menu item cards ────────────────────────────────────────────
                      for (final item in items) {
                        allItems.add(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: MenuItemTile(item: item),
                          ),
                        );
                      }
                    }
                  }
                }

                // Divider between restaurant categories
                allItems.add(
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Container(height: 1, color: _divider),
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: allItems,
                ),
              );
            }),
          );
        });
  }
}
