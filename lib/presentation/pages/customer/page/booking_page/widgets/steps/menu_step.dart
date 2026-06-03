part of '../../view/booking_page.dart';

// ─────────────────────────────────────────────
//  ШАГ 2 — МЕНЮ · ДОПОЛНИТЕЛЬНЫЕ УСЛУГИ
// ─────────────────────────────────────────────
class _MenuStep extends StatelessWidget {
  final bloc_state.BookingState state;
  final String restaurantId;

  const _MenuStep({
    required this.state,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    final hasMenu = state.menuCategories.isNotEmpty;
    final hasExtras = state.restaurantExtras.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (hasMenu)
          _buildMenuButton(context)
        else
          const _InfoBanner(
            icon: Icons.info_outline_rounded,
            text: 'Для этой категории меню не требуется',
          ),
        if (hasExtras) ...[
          const SizedBox(height: 16),
          _buildExtrasButton(context),
        ],
        if (!hasMenu && !hasExtras) ...[
          const SizedBox(height: 16),
          const _InfoBanner(
            icon: Icons.check_circle_outline_rounded,
            text: 'Нет данных для заполнения — переходите дальше',
          ),
        ],
      ],
    );
  }

  // ── MENU BUTTON ──────────────────────────────
  Widget _buildMenuButton(BuildContext context) {
    final selectedCount = state.selectedMenuItems.length;
    final totalItems = state.menuCategories.length;
    final isComplete = selectedCount == totalItems && totalItems > 0;
    final isEmpty = selectedCount == 0;

    return _SectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<BookingBloc>(),
                child: _MenuSelectionPage(state: state),
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isEmpty
                      ? _danger.withOpacity(0.08)
                      : _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.restaurant_outlined,
                    color: isEmpty ? _danger : _primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Меню',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSub,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEmpty
                          ? 'Обязательно выберите блюда'
                          : isComplete
                              ? 'Все блюда выбраны'
                              : 'Выбрано $selectedCount из $totalItems',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selectedCount > 0
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isEmpty
                            ? _danger
                            : isComplete
                                ? _success
                                : _textMain,
                      ),
                    ),
                  ],
                ),
              ),
              if (isComplete)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$selectedCount',
                    style: const TextStyle(
                        color: _success,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                )
              else if (!isEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${totalItems - selectedCount} осталось',
                    style: const TextStyle(
                        color: _danger,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: _textSub),
            ],
          ),
        ),
      ),
    );
  }

  // ── EXTRAS BUTTON ────────────────────────────
  Widget _buildExtrasButton(BuildContext context) {
    final selectedCount = state.selectedExtraIds.length;

    return _SectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showExtrasBottomSheet(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_circle_outline,
                    color: _primary, size: 20),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Дополнительные услуги',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSub,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Можно добавить по желанию',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _textMain,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectedCount > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$selectedCount',
                    style: const TextStyle(
                        color: _success,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: _textSub),
            ],
          ),
        ),
      ),
    );
  }

  void _showExtrasBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<BookingBloc>(),
        child: ExtrasBottomSheet(restaurantId: restaurantId),
      ),
    );
  }
}
