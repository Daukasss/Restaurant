part of '../view/booking_page.dart';

// ─────────────────────────────────────────────
//  CATEGORY BOTTOM SHEET (выбор категории зала)
// ─────────────────────────────────────────────
class _CategoryBottomSheet extends StatelessWidget {
  final bloc_state.BookingState state;
  final String restaurantId;
  final BookingBloc bloc;

  const _CategoryBottomSheet({
    required this.state,
    required this.restaurantId,
    required this.bloc,
  });

  @override
  Widget build(BuildContext context) {
    final section1 =
        state.restaurantCategories.where((c) => c.section == 1).toList();
    final section2 =
        state.restaurantCategories.where((c) => c.section == 2).toList();

    return Container(
      decoration: const BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(left: 20, bottom: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Выберите категорию',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textMain,
                ),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (section1.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ...section1.map((cat) => _buildCategoryTile(context, cat)),
                  ],
                  if (section2.isNotEmpty) ...[
                    ...section2.map((cat) => _buildCategoryTile(context, cat)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, dynamic category) {
    final isSelected = state.selectedRestaurantCategoryId == category.id;

    bool isBlocked = false;
    for (final b in state.existingBookings) {
      if (b.categorySection == category.section) {
        isBlocked = true;
        break;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isBlocked
            ? null
            : () {
                bloc.add(SelectRestaurantCategoryEvent(category.id!,
                    restaurantId: restaurantId));
                bloc.add(LoadMenuCategoriesEvent(
                  restaurantId,
                  restaurantCategoryId: category.id,
                ));
                bloc.add(LoadExistingBookingsForDateEvent(
                  state.selectedDate,
                  restaurantId,
                ));
                // Явно загружаем недоступные даты с секцией категории
                bloc.add(LoadUnavailableDatesForCategoryEvent(
                  restaurantId: restaurantId,
                  categoryId: category.id!,
                  categorySection: category.section,
                ));
                Navigator.pop(context);
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isBlocked
                ? _surface
                : isSelected
                    ? _primary.withOpacity(0.07)
                    : _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isBlocked
                  ? _divider
                  : isSelected
                      ? _primary.withOpacity(0.5)
                      : _divider,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isBlocked
                      ? _divider
                      : isSelected
                          ? _primary.withOpacity(0.12)
                          : _primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_rounded
                      : Icons.table_restaurant_outlined,
                  color: isBlocked
                      ? _textSub
                      : isSelected
                          ? _primary
                          : _primary.withOpacity(0.6),
                  size: 18,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isBlocked ? _textSub : _textMain,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isBlocked
                          ? 'Занято на выбранную дату'
                          : '${category.priceRange.toStringAsFixed(0)} ₸ за гостя',
                      style: TextStyle(
                        fontSize: 12,
                        color: isBlocked ? _danger : _textSub,
                      ),
                    ),
                  ],
                ),
              ),
              if (isBlocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Занято',
                    style: TextStyle(
                      fontSize: 11,
                      color: _danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
