import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restauran/data/services/restaurant_service.dart';
import 'package:restauran/presentation/widgets/search_bar.dart';

import '../../../widgets/restaurant_card.dart';
import '../../profile_page/view/profile_page.dart';
import '../../restaurant_detail_page/view/restaurant_detail_page.dart';

import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/filter_bottom_sheet.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc(
        restaurantService: RestaurantService(),
      )..add(LoadRestaurants()),
      child: const HomeView(),
    );
  }
}

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final TextEditingController _searchController = TextEditingController();

  // Кэш: categoryId → название. Избегаем FutureBuilder в build.
  String? _cachedCategoryId;
  String _cachedCategoryName = 'Категория';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Загружает название категории и сохраняет в кэш.
  /// Вызывается только когда categoryId меняется.
  Future<void> _loadCategoryName(String categoryId) async {
    if (_cachedCategoryId == categoryId) return; // уже загружено
    try {
      final doc = await FirebaseFirestore.instance
          .collection('global_categories')
          .doc(categoryId)
          .get();
      if (!mounted) return;
      setState(() {
        _cachedCategoryId = categoryId;
        _cachedCategoryName = doc.exists
            ? (doc.data()?['name'] as String? ?? 'Категория')
            : 'Категория';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cachedCategoryId = categoryId;
        _cachedCategoryName = 'Категория';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<HomeBloc, HomeState>(
          // Слушаем смену категории и подгружаем название
          listener: (context, state) {
            if (state.selectedGlobalCategoryId != null &&
                state.selectedGlobalCategoryId != _cachedCategoryId) {
              _loadCategoryName(state.selectedGlobalCategoryId!);
            }
            if (state.selectedGlobalCategoryId == null) {
              // Сброс кэша при снятии фильтра
              _cachedCategoryId = null;
              _cachedCategoryName = 'Категория';
            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(LoadRestaurants());
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── AppBar ────────────────────────────────────────────────
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    centerTitle: false,
                    title: const Text(
                      'Aq Той',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.person_outline_rounded),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfilePage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  // ── Поиск + фильтр + чипсы ────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Строка поиска + кнопка фильтра
                          Row(
                            children: [
                              Expanded(
                                child: CustomSearchBar(
                                  controller: _searchController,
                                  onChanged: (value) {
                                    context
                                        .read<HomeBloc>()
                                        .add(ApplySearchQuery(value));
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.filter_list_rounded),
                                tooltip: 'Фильтры',
                                onPressed: () {
                                  // Сохраняем bloc ДО открытия шторки,
                                  // пока context ещё активен
                                  final bloc = context.read<HomeBloc>();
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => BlocProvider.value(
                                      value:
                                          bloc, // используем сохранённую ссылку
                                      child: const FilterBottomSheet(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Активные фильтры — чипсы
                          if (state.hasActiveFilters)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (state.searchQuery.isNotEmpty)
                                  _buildChip(
                                    label: '«${state.searchQuery}»',
                                    onRemove: () {
                                      _searchController.clear();
                                      context
                                          .read<HomeBloc>()
                                          .add(ApplySearchQuery(''));
                                    },
                                  ),
                                if (state.selectedGlobalCategoryId != null)
                                  _buildChip(
                                    // Используем кэшированное название — без FutureBuilder!
                                    label: _cachedCategoryId ==
                                            state.selectedGlobalCategoryId
                                        ? _cachedCategoryName
                                        : 'Категория',
                                    onRemove: () {
                                      context.read<HomeBloc>().add(
                                            ApplyCategoryAndDateFilter(
                                              globalCategoryId: null,
                                              selectedDate: state.selectedDate,
                                            ),
                                          );
                                    },
                                  ),
                                if (state.selectedDate != null)
                                  _buildChip(
                                    label: DateFormat('dd MMM yyyy', 'ru')
                                        .format(state.selectedDate!),
                                    onRemove: () {
                                      context.read<HomeBloc>().add(
                                            ApplyCategoryAndDateFilter(
                                              globalCategoryId: state
                                                  .selectedGlobalCategoryId,
                                              selectedDate: null,
                                            ),
                                          );
                                    },
                                  ),
                              ],
                            ),

                          const SizedBox(height: 24),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Text(
                                'Рестораны',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (state.hasActiveFilters)
                                TextButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<HomeBloc>()
                                        .add(ResetAllFilters());
                                  },
                                  child: const Text('Сбросить всё'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Список ресторанов ─────────────────────────────────────
                  if (state.isLoading)
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.filteredRestaurants.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 72,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Ничего не найдено',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverList.separated(
                        itemCount: state.filteredRestaurants.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final restaurant = state.filteredRestaurants[index];
                          return RestaurantCard(
                            name:
                                restaurant['name'] as String? ?? 'Без названия',
                            rating:
                                (restaurant['rating'] as num?)?.toDouble() ??
                                    0.0,
                            location: restaurant['location'] as String? ?? '',
                            imageUrl: restaurant['image_url'] as String? ?? '',
                            onTap: () {
                              final id = restaurant['id'] as String?;
                              if (id != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RestaurantDetailPage(
                                      restaurantId: id,
                                    ),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),

                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required VoidCallback onRemove,
  }) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onRemove,
      backgroundColor: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
