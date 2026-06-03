// ignore_for_file: deprecated_member_use

part of '../view/booking_page.dart';

// ─────────────────────────────────────────────
//  СТРАНИЦА ВЫБОРА МЕНЮ (открывается из шага 2)
// ─────────────────────────────────────────────
class _MenuSelectionPage extends StatelessWidget {
  final bloc_state.BookingState state;

  const _MenuSelectionPage({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close)),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Выберите меню',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (state.selectedMenuItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${state.selectedMenuItems.length} выбрано',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: BlocBuilder<BookingBloc, bloc_state.BookingState>(
        builder: (context, liveState) {
          if (liveState.menuCategories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_outlined,
                      size: 56, color: _textSub.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'Меню недоступно',
                    style: TextStyle(fontSize: 16, color: _textSub),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: liveState.menuCategories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final category = liveState.menuCategories[index];
              return _MenuCategoryCard(
                category: category,
                selectedItemId: liveState.selectedMenuItems[category.id],
              );
            },
          );
        },
      ),
      bottomNavigationBar: _MenuConfirmBar(
        onConfirm: () => Navigator.pop(context),
      ),
    );
  }
}

class _MenuCategoryCard extends StatelessWidget {
  final dynamic category;
  final String? selectedItemId;

  const _MenuCategoryCard({
    required this.category,
    required this.selectedItemId,
  });

  List<Widget> _buildMenuItems(BuildContext context, dynamic category) {
    final items = category.menuItems;
    final List<Widget> result = [];

    void addTile(String itemId, String itemName) {
      final isSelected = selectedItemId == itemId;
      result.add(
        InkWell(
          onTap: () => context.read<BookingBloc>().add(
                UpdateMenuSelectionEvent(category.id.toString(), itemId),
              ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isSelected ? _primary.withOpacity(0.06) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? _primary.withOpacity(0.35)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? _primary : _divider,
                      width: 2,
                    ),
                    color: isSelected ? _primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    itemName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? _primary : _textMain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (items is List) {
      for (final item in items) {
        // LinkedMap<String,dynamic> удовлетворяет `is Map` — проверяем ДО доступа к .id/.name
        if (item is Map) {
          final id = (item['id'] ?? '').toString();
          final name = (item['name'] ?? item['title'] ?? id).toString();
          if (id.isNotEmpty) addTile(id, name);
        }
      }
    } else if (items is Map) {
      for (final entry in (items).entries) {
        final id = entry.key.toString();
        final val = entry.value;
        final name = val is Map
            ? (val['name'] ?? val['title'] ?? id).toString()
            : val.toString();
        addTile(id, name);
      }
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок категории
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              // border: Border(bottom: BorderSide(color: _divider, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ),
                if (selectedItemId != null)
                  const Icon(Icons.check_circle_rounded,
                      color: _success, size: 18),
              ],
            ),
          ),

          // Позиции
          // if (category.description.isNotEmpty)
          //   Padding(
          //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          //     child: Text(
          //       category.description,
          //       style: const TextStyle(fontSize: 13, color: _textSub),
          //     ),
          //   ),

          if (category.menuItems.isNotEmpty)
            ..._buildMenuItems(context, category)
          else
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Нет позиций',
                style: TextStyle(
                    fontSize: 13, color: _textSub, fontStyle: FontStyle.italic),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuConfirmBar extends StatelessWidget {
  final VoidCallback onConfirm;

  const _MenuConfirmBar({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: _cardBg,
        border: Border(top: BorderSide(color: _divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Подтвердить выбор',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
