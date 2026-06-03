part of '../../view/booking_page.dart';

// ─────────────────────────────────────────────
//  ШАГ 1 — КАТЕГОРИЯ · ДАТА · ВРЕМЯ
// ─────────────────────────────────────────────
class _ScheduleStep extends StatelessWidget {
  final bloc_state.BookingState state;
  final String restaurantId;

  const _ScheduleStep({
    required this.state,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    final categorySelected = state.selectedRestaurantCategoryId != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _buildCategoryButton(context),
        if (!categorySelected) ...[
          const SizedBox(height: 16),
          _buildSelectCategoryHint(),
        ],
        if (categorySelected) ...[
          const SizedBox(height: 16),
          _buildDateRow(context),
          const SizedBox(height: 16),
          _buildTimeRow(context),
        ],
      ],
    );
  }

  // ── CATEGORY ─────────────────────────────────
  Widget _buildCategoryButton(BuildContext context) {
    final selected = state.selectedRestaurantCategoryId != null
        ? state.restaurantCategories.firstWhere(
            (c) => c.id == state.selectedRestaurantCategoryId,
            orElse: () => state.restaurantCategories.first,
          )
        : null;

    return _SectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: state.isCategoriesLoading
            ? null
            : () => _showCategoryBottomSheet(context),
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
                child: const Icon(Icons.category_outlined,
                    color: _primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Категория',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSub,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      selected?.name ?? 'Выберите категорию',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: selected != null
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected != null ? _textMain : _textSub,
                      ),
                    ),
                    if (selected != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '${selected.priceRange.toStringAsFixed(0)} ₸ / гость',
                        style: const TextStyle(fontSize: 12, color: _accent),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: _textSub,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCategoryBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryBottomSheet(
        state: state,
        restaurantId: restaurantId,
        bloc: context.read<BookingBloc>(),
      ),
    );
  }

  // ── SELECT CATEGORY HINT ─────────────────────
  Widget _buildSelectCategoryHint() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.touch_app_outlined,
              color: _accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Выберите категорию чтобы увидеть доступные даты и время',
              style: TextStyle(
                fontSize: 13,
                color: _primaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── DATE ROW ─────────────────────────────────
  Widget _buildDateRow(BuildContext context) {
    final isLoadingDates = state.isUnavailableDatesLoading;
    return _SectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: isLoadingDates
            ? null
            : () async {
                final picked = await showDialog<DateTime>(
                  context: context,
                  builder: (dialogCtx) => _CalendarPickerDialog(
                    initialDate:
                        state.isDateUnavailableForUser(state.selectedDate)
                            ? DateTime.now()
                            : state.selectedDate,
                    unavailableDates: state.unavailableDatesForCategory,
                  ),
                );
                if (picked != null) {
                  context.read<BookingBloc>()
                    ..add(UpdateDateEvent(picked))
                    ..add(
                        LoadExistingBookingsForDateEvent(picked, restaurantId));
                }
              },
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
                child: isLoadingDates
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_primary),
                        ),
                      )
                    : const Icon(Icons.calendar_today_outlined,
                        color: _primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Дата',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSub,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    isLoadingDates
                        ? const Text(
                            'Загрузка доступных дат...',
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSub,
                              fontWeight: FontWeight.w400,
                            ),
                          )
                        : Text(
                            DateFormat('d MMMM yyyy', 'ru')
                                .format(state.selectedDate),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: _textMain,
                            ),
                          ),
                  ],
                ),
              ),
              if (!isLoadingDates)
                const Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: _textSub),
            ],
          ),
        ),
      ),
    );
  }

  // ── TIME ROW ──────────────────────────────────
  Widget _buildTimeRow(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TimeCard(
                label: 'Начало',
                time: state.startTime,
                onTap: () => _pickTime(context),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _divider,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: _textSub),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TimeCard(
                label: 'Конец',
                time: state.endTime,
                onTap: () => _pickTime(context),
              ),
            ),
          ],
        ),
        if (!state.isTimeRangeValid()) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _danger.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _danger.withOpacity(0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline_rounded, color: _danger, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Время окончания должно быть позже времени начала',
                    style: TextStyle(
                        fontSize: 12,
                        color: _danger,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final result = await showDialog<({TimeOfDay start, TimeOfDay end})?>(
      context: context,
      builder: (ctx) => _TimeSlotPickerDialog(
        initialStart: state.startTime,
        initialEnd: state.endTime,
        availableSlots: state.availableTimeSlots,
      ),
    );
    if (result != null) {
      context.read<BookingBloc>()
        ..add(UpdateStartTimeEvent(result.start))
        ..add(UpdateEndTimeEvent(result.end));
    }
  }
}
