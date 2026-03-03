import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/services/abstract/abstract_booking_service.dart';
import 'package:restauran/data/services/abstract/abstract_category_closure_service.dart';
import 'package:restauran/data/services/abstract/abstract_menu_service.dart';
import 'package:restauran/data/services/abstract/abstract_restaurant_service.dart';
import 'package:restauran/data/services/service_locator.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/widgets/build_menu_tab.dart';
import 'package:restauran/presentation/widgets/result_diolog.dart';
import '../../../widgets/fullscreen_image_viewer.dart';
import '../../booking_page/view/booking_page.dart';
import '../bloc/restaurant_detail_bloc.dart';
import '../bloc/restaurant_detail_event.dart';
import '../bloc/restaurant_detail_state.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantDetailPage extends StatelessWidget {
  final String restaurantId;

  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RestaurantDetailBloc()..add(FetchRestaurantData(restaurantId)),
      child: RestaurantDetailView(restaurantId: restaurantId),
    );
  }
}

class RestaurantDetailView extends StatefulWidget {
  final String restaurantId;

  const RestaurantDetailView({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailView> createState() => _RestaurantDetailViewState();
}

class _RestaurantDetailViewState extends State<RestaurantDetailView>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openImageViewer(List<String> photoUrls, int index) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullscreenImageViewer(
          imageUrls: photoUrls,
          initialIndex: index,
        ),
      ),
    );
  }

  void _showPhoneActionDialog(String phoneNumber) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  phoneNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(
                    Icons.phone,
                  ),
                  title: const Text('Позвонить'),
                  onTap: () {
                    Navigator.pop(context);
                    final cleanPhone =
                        phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
                    launchUrl(Uri.parse('tel:$cleanPhone'));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.chat, color: Colors.green),
                  title: const Text('Написать в WhatsApp'),
                  onTap: () {
                    Navigator.pop(context);
                    String cleanPhone = phoneNumber.replaceAll(
                        RegExp(r'[^\d]'), ''); // только цифры

                    if (cleanPhone.startsWith('8') && cleanPhone.length == 11) {
                      cleanPhone = '+7${cleanPhone.substring(1)}';
                    } else if (cleanPhone.startsWith('7') &&
                        cleanPhone.length == 11) {
                      cleanPhone = '+$cleanPhone';
                    } else if (cleanPhone.startsWith('77') &&
                        cleanPhone.length == 11) {
                      cleanPhone = '+$cleanPhone';
                    }

                    launchUrl(
                      Uri.parse(
                          'https://wa.me/${cleanPhone.replaceAll('+', '')}'),
                      mode: LaunchMode.externalApplication,
                    );
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Отмена'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RestaurantDetailBloc, RestaurantDetailState>(
      listener: (context, state) {
        if (state.error != null) {
          showResultDialog(
            context: context,
            isSuccess: false,
            title: 'Ошибка',
            message: state.error!,
          );
        }
      },
      builder: (context, state) {
        if (state.isLoading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          body: Column(
            children: [
              Expanded(
                child: NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      _buildSliverAppBar(context, state),
                    ];
                  },
                  body: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        tabs: const [Tab(text: 'Обзор'), Tab(text: 'Меню')],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildOverviewTab(state),
                            BuildMenuTab(context: context, state: state),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomBar(context, state),
        );
      },
    );
  }

  Widget _buildSliverAppBar(BuildContext context, RestaurantDetailState state) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            state.photoUrls.isEmpty
                ? Container(
                    color: Colors.grey[300],
                    child: const Center(
                        child: Icon(Icons.image_not_supported, size: 50)),
                  )
                : PageView.builder(
                    itemCount: state.photoUrls.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openImageViewer(state.photoUrls, index),
                        child: Image.network(
                          state.photoUrls[index],
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator()),
                          errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey,
                              child: const Icon(Icons.broken_image)),
                        ),
                      );
                    },
                  ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Text(
                state.restaurant?['name'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            state.isFavorite ? Icons.favorite : Icons.favorite_border,
            color: state.isFavorite ? Colors.red : Colors.white,
          ),
          onPressed: () {
            context
                .read<RestaurantDetailBloc>()
                .add(ToggleFavorite(widget.restaurantId));
          },
        ),
      ],
    );
  }

  Widget _buildOverviewTab(RestaurantDetailState state) {
    final phones = state.restaurant?['phones'];
    final List<String> phoneNumbers;

    if (phones is List && phones.isNotEmpty) {
      phoneNumbers = phones.map((p) => p.toString()).toList();
    } else {
      // Старый формат - один телефон в виде строки (для обратной совместимости)
      final phoneString = (state.restaurant?['phone'] ?? '').toString();
      phoneNumbers = phoneString
          .split(RegExp(r'[,\n]'))
          .map((p) => p.trim())
          .where((p) => p.isNotEmpty)
          .toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Описание',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(state.restaurant?['description'] ?? 'Нет описания.'),
          const SizedBox(height: 16),
          if (state.restaurantCategories.isNotEmpty) ...[
            const Text('Прайс-лист',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...state.restaurantCategories.map((category) {
              return ListTile(
                title: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: category.description != null
                    ? Text(category.description!)
                    : null,
                trailing: Text(
                  '${category.priceRange.toStringAsFixed(0)} ₸',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
          const Text('Контакты',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (phoneNumbers.isEmpty)
            const ListTile(
              leading: Icon(Icons.phone),
              title: Text('Не указан'),
            )
          else
            ...phoneNumbers.map((phone) => ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(phone),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showPhoneActionDialog(phone),
                )),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(state.restaurant?['location'] ?? 'Не указан'),
            onTap: () {
              final location = state.restaurant?['location'];
              if (location != null && location.isNotEmpty) {
                final encodedLocation = Uri.encodeComponent(location);
                final url = 'https://2gis.kz/search/$encodedLocation';
                launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, RestaurantDetailState state) {
    return BottomAppBar(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => BookingBloc(
                    bookingService: getIt<AbstractBookingService>(),
                    restaurantService: getIt<AbstractRestaurantService>(),
                    menuService: getIt<AbstractMenuService>(),
                    closureService: getIt<AbstractCategoryClosureService>(),
                  ),
                  child: BookingPage(
                    restaurantId: widget.restaurantId,
                    restaurantName: state.restaurant?['name'] ?? '',
                  ),
                ),
              ),
            );
          },
          child: const Text('Забронировать'),
        ),
      ),
    );
  }
}
