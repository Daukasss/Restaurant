part of '../../view/booking_page.dart';

// ─────────────────────────────────────────────
//  ШАГ 4 — ПОДТВЕРЖДЕНИЕ (сводка · цена)
//  Кнопка отправки находится в нижней панели формы.
// ─────────────────────────────────────────────
class _ConfirmStep extends StatelessWidget {
  final bloc_state.BookingState state;

  /// Переход к конкретному шагу при нажатии «изменить».
  final ValueChanged<int> onEditStep;

  const _ConfirmStep({
    required this.state,
    required this.onEditStep,
  });

  String _fmtTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String get _categoryName {
    if (state.selectedRestaurantCategoryId == null) return 'Не выбрана';
    try {
      return state.restaurantCategories
          .firstWhere((c) => c.id == state.selectedRestaurantCategoryId)
          .name;
    } catch (_) {
      return 'Не выбрана';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasMenu = state.menuCategories.isNotEmpty;
    final extrasCount = state.selectedExtraIds.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // ── Расписание ──
        _SummaryGroup(
          title: 'Дата и время',
          onEdit: () => onEditStep(0),
          rows: [
            _SummaryRow(
                icon: Icons.category_outlined,
                label: 'Категория',
                value: _categoryName),
            _SummaryRow(
              icon: Icons.calendar_today_outlined,
              label: 'Дата',
              value: DateFormat('d MMMM yyyy', 'ru').format(state.selectedDate),
            ),
            _SummaryRow(
              icon: Icons.access_time_rounded,
              label: 'Время',
              value:
                  '${_fmtTime(state.startTime)} — ${_fmtTime(state.endTime)}',
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Меню и услуги ──
        _SummaryGroup(
          title: 'Меню и услуги',
          onEdit: () => onEditStep(1),
          rows: [
            _SummaryRow(
              icon: Icons.restaurant_outlined,
              label: 'Меню',
              value: hasMenu
                  ? 'Выбрано ${state.selectedMenuItems.length} из ${state.menuCategories.length}'
                  : 'Не требуется',
            ),
            _SummaryRow(
              icon: Icons.add_circle_outline,
              label: 'Доп. услуги',
              value: extrasCount > 0 ? '$extrasCount выбрано' : 'Нет',
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ── Личные данные ──
        _SummaryGroup(
          title: 'Личные данные',
          onEdit: () => onEditStep(2),
          rows: [
            _SummaryRow(
              icon: Icons.people_alt_outlined,
              label: 'Гостей',
              value: state.guests.isEmpty ? '—' : state.guests,
            ),
            _SummaryRow(
              icon: Icons.person_outline_rounded,
              label: 'Имя',
              value: state.name.isEmpty ? '—' : state.name,
            ),
            _SummaryRow(
              icon: Icons.phone_outlined,
              label: 'Телефон',
              value: state.phone.isEmpty ? '—' : state.phone,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // ── Цена ──
        _buildPriceCard(state),
      ],
    );
  }

  // ── PRICE CARD ───────────────────────────────
  Widget _buildPriceCard(bloc_state.BookingState state) {
    final price = state.calculateBookingPrice();
    final hasPrice = price != 'Цена не указана';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Итоговая стоимость',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.75),
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasPrice ? '$price ₸' : 'Цена не указана',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }
}

// ── Группа сводки с заголовком и кнопкой «изменить» ──
class _SummaryGroup extends StatelessWidget {
  final String title;
  final List<_SummaryRow> rows;
  final VoidCallback onEdit;

  const _SummaryGroup({
    required this.title,
    required this.rows,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onEdit,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 14, color: _accent),
                        SizedBox(width: 4),
                        Text(
                          'Изменить',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...rows,
          ],
        ),
      ),
    );
  }
}

// ── Строка сводки ──
class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _textSub),
          const SizedBox(width: 10),
          SizedBox(
            width: 90, // одинаковая ширина для всех label
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _textSub,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textMain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
