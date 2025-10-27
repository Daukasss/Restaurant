import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../widgets/restaurant_card.dart';
import '../../../../../widgets/search_bar.dart';
import '../../profile_page/view/profile_page.dart';
import '../../restaurant_detail_page/view/restaurant_detail_page.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => HomeBloc()..add(LoadRestaurants()),
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
  String? _selectedCategory;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    context.read<HomeBloc>().add(ApplyFilters(
          // category: _selectedCategory,
          searchQuery: query,
        ));
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = null;
      _searchController.clear();
    });

    context.read<HomeBloc>().add(ResetFilters());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<HomeBloc>().add(LoadRestaurants());
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    centerTitle: false,
                    title: const Text('Aq Tой'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.person_outline),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfilePage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomSearchBar(
                            controller: _searchController,
                            onChanged: _handleSearch,
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Рестораны',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_selectedCategory != null ||
                                  _searchController.text.isNotEmpty)
                                TextButton(
                                  onPressed: _resetFilters,
                                  child: const Text('Сбросить фильтры'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  state.isLoading
                      ? const SliverFillRemaining(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : state.filteredRestaurants.isEmpty
                          ? const SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'Ничего не найдено',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            )
                          : SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final restaurant =
                                      state.filteredRestaurants[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16.0,
                                      vertical: 8.0,
                                    ),
                                    child: RestaurantCard(
                                      name: restaurant['name'],
                                      rating: restaurant['rating'].toDouble(),
                                      // category: restaurant['category'],
                                      location: restaurant['location'],
                                      imageUrl: restaurant['image_url'],
                                      price: restaurant['price_range'],
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                RestaurantDetailPage(
                                              restaurantId: restaurant['id'],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                                childCount: state.filteredRestaurants.length,
                              ),
                            ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
