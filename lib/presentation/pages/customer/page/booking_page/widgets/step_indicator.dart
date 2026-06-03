part of '../view/booking_page.dart';

// ─────────────────────────────────────────────
//  STEP MODEL + STATUS HELPERS
// ─────────────────────────────────────────────

/// Названия и количество шагов формы бронирования.
const List<String> _kStepTitles = [
  'Дата и время',
  'Меню и услуги',
  'Личные данные',
  'Подтверждение',
];

/// Шаг 1 заполнен: выбрана категория, дата доступна, время корректно.
bool _isScheduleStepComplete(bloc_state.BookingState s) {
  if (s.selectedRestaurantCategoryId == null) return false;
  if (s.isDateUnavailableForUser(s.selectedDate)) return false;
  return s.isTimeRangeValid();
}

/// Шаг 2 заполнен (для подсветки индикатора).
/// Подсвечивается ТОЛЬКО когда:
///   • выбрана категория ресторана, И
///   • у этой категории есть меню, И
///   • выбраны позиции во всех разделах меню.
/// Если категория не выбрана или в ней нет блюд — шаг НЕ считается
/// заполненным (линия остаётся серой), а не помечается автоматически.
bool _isMenuStepComplete(bloc_state.BookingState s) {
  if (s.selectedRestaurantCategoryId == null) return false;
  if (s.menuCategories.isEmpty) return false;
  return s.selectedMenuItems.length == s.menuCategories.length;
}

/// Можно ли уйти со 2-го шага вперёд.
/// Меню обязательно к заполнению только если оно реально есть у ресторана.
/// Если блюд нет — выбирать нечего, поэтому переход разрешён.
bool _canLeaveMenuStep(bloc_state.BookingState s) {
  if (s.menuCategories.isEmpty) return true;
  return s.selectedMenuItems.length == s.menuCategories.length;
}

/// Шаг 3 заполнен: указаны имя, телефон и корректное количество гостей.
bool _isContactStepComplete(bloc_state.BookingState s) {
  if (s.name.trim().isEmpty) return false;
  if (s.phone.trim().isEmpty) return false;
  if (s.guests.trim().isEmpty) return false;
  return (int.tryParse(s.guests) ?? 0) > 0;
}

/// Шаг 4 (подтверждение) готов, когда можно отправить бронь:
/// шаг 1 заполнен, шаг 2 пройден (или меню отсутствует), шаг 3 заполнен.
bool _isConfirmStepComplete(bloc_state.BookingState s) {
  return _isScheduleStepComplete(s) &&
      _canLeaveMenuStep(s) &&
      _isContactStepComplete(s);
}

/// Можно ли уйти с указанного шага вперёд (для блокировки навигации).
bool _canLeaveStep(int step, bloc_state.BookingState s) {
  switch (step) {
    case 0:
      return _isScheduleStepComplete(s);
    case 1:
      return _canLeaveMenuStep(s);
    case 2:
      return _isContactStepComplete(s);
    default:
      return true;
  }
}

/// Список статусов всех 4 шагов (для подсветки линий индикатора).
List<bool> _stepCompletion(bloc_state.BookingState s) => [
      _isScheduleStepComplete(s),
      _isMenuStepComplete(s),
      _isContactStepComplete(s),
      _isConfirmStepComplete(s),
    ];

// ─────────────────────────────────────────────
//  STEP INDICATOR (4 линии сверху)
// ─────────────────────────────────────────────
class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<bool> completed;
  final ValueChanged<int> onStepTap;

  const _StepIndicator({
    required this.currentStep,
    required this.completed,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          // ── Четыре линии-индикатора ──
          Row(
            children: List.generate(_kStepTitles.length, (i) {
              final isDone = completed[i];
              final isCurrent = i == currentStep;
              // Заполнен → primary; текущий, но пустой → полупрозрачный primary; иначе серый
              final Color color = isDone
                  ? _primary
                  : isCurrent
                      ? _primary.withOpacity(0.35)
                      : _divider;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == _kStepTitles.length - 1 ? 0 : 6,
                  ),
                  child: GestureDetector(
                    onTap: () => onStepTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // ── Подпись текущего шага ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _kStepTitles[currentStep],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textMain,
                ),
              ),
              Text(
                'Шаг ${currentStep + 1} из ${_kStepTitles.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textSub,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
