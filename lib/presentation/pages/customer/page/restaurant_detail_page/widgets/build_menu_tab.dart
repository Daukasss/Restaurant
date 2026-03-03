import 'package:flutter/material.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/bloc/restaurant_detail_state.dart';
import 'package:restauran/presentation/pages/seller/widgets/menu_item_card.dart';

// ── Design tokens (matches AppTheme & booking_page tokens) ──────────────────
const _primary = Color(0xFF1A365D);
const _primaryLight = Color(0xFF2A4A7F);
const _surface = Color(0xFFF7F9FC);
const _cardBg = Colors.white;
const _textMain = Color(0xFF1A2535);
const _textSub = Color(0xFF6B7A92);
const _divider = Color(0xFFE8EDF5);

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
    if (state.restaurantCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu_outlined,
                size: 56, color: _textSub.withOpacity(0.35)),
            const SizedBox(height: 16),
            Text(
              'Меню отсутствует',
              style: TextStyle(
                fontSize: 16,
                color: _textSub,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final List<Widget> allItems = [];

    for (final restaurantCategory in state.restaurantCategories) {
      final categoryData =
          state.menuByRestaurantCategory[restaurantCategory.id];

      if (categoryData == null) continue;

      final menuCategories =
          categoryData['menuCategories'] as List<Map<String, dynamic>>;
      final menuItemsByMenuCategory =
          categoryData['menuItems'] as Map<String, List<Map<String, dynamic>>>;

      // ── Section header (restaurant category) ──────────────────────────────
      allItems.add(
        Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                    if (restaurantCategory.description != null &&
                        restaurantCategory.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        restaurantCategory.description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.80),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      if (menuCategories.isEmpty) {
        allItems.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
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
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
                _MenuItemTile(item: item),
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
  }
}

/// Карточка блюда — стилизована под AppTheme, использует MenuItemCard внутри
/// или отображает данные напрямую если изображения нет.
class _MenuItemTile extends StatelessWidget {
  final Map<String, dynamic> item;

  const _MenuItemTile({required this.item});

  void _showFullDescription(
      BuildContext context, String name, String description) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => SafeArea(
        child: Container(
          width: double.infinity, // ← растягиваем по ширине
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description.isEmpty ? 'Описание отсутствует' : description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: InteractiveViewer(
                child: Image.network(imageUrl),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String name = (item['name'] ?? '').toString();
    final String rawDescription = (item['description'] ?? '').toString();

    final String description = rawDescription.replaceAll('\n', ' ').trim();

    final String? imageUrl = item['image_url']?.toString();
    final dynamic rawPrice = item['price'];
    final String? price = rawPrice != null ? rawPrice.toString() : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: _cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _divider),
          boxShadow: [
            BoxShadow(
              color: _primary.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 📸 КАРТИНКА — отдельная зона нажатия
              GestureDetector(
                onTap: imageUrl != null && imageUrl.isNotEmpty
                    ? () => _openFullScreenImage(context, imageUrl)
                    : null,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Icon(
                          Icons.fastfood_outlined,
                          color: _primary,
                          size: 24,
                        ),
                ),
              ),

              const SizedBox(width: 14),

              // 📝 ТЕКСТ — отдельная зона нажатия
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      _showFullDescription(context, name, rawDescription),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: _textMain,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSub,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              if (price != null && price.isNotEmpty) ...[
                const SizedBox(width: 12),
                Text(
                  '$price ₸',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
