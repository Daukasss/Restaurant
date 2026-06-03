part of '../view/booking_page.dart';

// ─────────────────────────────────────────────
//  ДИАЛОГ ВЫБОРА ВРЕМЕНИ (барабаны начало / конец)
// ─────────────────────────────────────────────
class _TimeSlotPickerDialog extends StatefulWidget {
  final TimeOfDay initialStart;
  final TimeOfDay initialEnd;
  final List<bloc_state.TimeSlot> availableSlots;

  const _TimeSlotPickerDialog({
    required this.initialStart,
    required this.initialEnd,
    required this.availableSlots,
  });

  @override
  State<_TimeSlotPickerDialog> createState() => _TimeSlotPickerDialogState();
}

class _TimeSlotPickerDialogState extends State<_TimeSlotPickerDialog> {
  // Шаги минут
  static const _minuteSteps = [0, 15, 30, 45];

  late int _startHour;
  late int _startMinuteIdx; // индекс в _minuteSteps
  late int _endHour;
  late int _endMinuteIdx;

  // Контроллеры для барабанов
  late FixedExtentScrollController _startHourCtrl;
  late FixedExtentScrollController _startMinCtrl;
  late FixedExtentScrollController _endHourCtrl;
  late FixedExtentScrollController _endMinCtrl;

  // Активная секция: 'start' или 'end'
  String _activeSection = 'start';

  @override
  void initState() {
    super.initState();
    _startHour = widget.initialStart.hour;
    _startMinuteIdx = _nearestMinIdx(widget.initialStart.minute);
    _endHour = widget.initialEnd.hour;
    _endMinuteIdx = _nearestMinIdx(widget.initialEnd.minute);

    _startHourCtrl = FixedExtentScrollController(initialItem: _startHour);
    _startMinCtrl = FixedExtentScrollController(initialItem: _startMinuteIdx);
    _endHourCtrl = FixedExtentScrollController(initialItem: _endHour);
    _endMinCtrl = FixedExtentScrollController(initialItem: _endMinuteIdx);
  }

  @override
  void dispose() {
    _startHourCtrl.dispose();
    _startMinCtrl.dispose();
    _endHourCtrl.dispose();
    _endMinCtrl.dispose();
    super.dispose();
  }

  int _nearestMinIdx(int minute) {
    int best = 0;
    int bestDiff = 999;
    for (int i = 0; i < _minuteSteps.length; i++) {
      final diff = (minute - _minuteSteps[i]).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        best = i;
      }
    }
    return best;
  }

  String _fmt2(int v) => v.toString().padLeft(2, '0');

  String get _startLabel =>
      '${_fmt2(_startHour)}:${_fmt2(_minuteSteps[_startMinuteIdx])}';
  String get _endLabel =>
      '${_fmt2(_endHour)}:${_fmt2(_minuteSteps[_endMinuteIdx])}';

  int get _startTotalMin => _startHour * 60 + _minuteSteps[_startMinuteIdx];
  int get _endTotalMin => _endHour * 60 + _minuteSteps[_endMinuteIdx];

  bool get _isValid => _endTotalMin > _startTotalMin;

  bool get _hasConflict {
    if (!_isValid) return false;
    for (final slot in widget.availableSlots) {
      if (!slot.isAvailable) {
        final s = slot.startTime.hour * 60 + slot.startTime.minute;
        final e = slot.endTime.hour * 60 + slot.endTime.minute;
        if (!(_endTotalMin <= s || _startTotalMin >= e)) return true;
      }
    }
    return false;
  }

  // Длительность для бейджа
  String get _durationLabel {
    if (!_isValid) return '—';
    final diff = _endTotalMin - _startTotalMin;
    final h = diff ~/ 60;
    final m = diff % 60;
    if (h > 0 && m > 0) return '$h ч $m мин';
    if (h > 0) return '$h ч';
    return '$m мин';
  }

  void _switchSection(String section) {
    setState(() => _activeSection = section);
  }

  @override
  Widget build(BuildContext context) {
    final hasBusySlots = widget.availableSlots.any((s) => !s.isAvailable);
    final bool editing = _activeSection == 'start';

    final hourCtrl = editing ? _startHourCtrl : _endHourCtrl;
    final minCtrl = editing ? _startMinCtrl : _endMinCtrl;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Заголовок ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
            child: Row(
              children: [
                const Text(
                  'Выберите время',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _textMain,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _textSub),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // ── Занятые слоты ──
          if (hasBusySlots) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: _TimelineWidget(slots: widget.availableSlots),
            ),
            const Divider(height: 1, color: _divider),
          ],

          const SizedBox(height: 16),

          // ── Переключатель Начало / Конец ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: [
                  _SegBtn(
                    label: 'Начало',
                    value: _startLabel,
                    active: _activeSection == 'start',
                    onTap: () => _switchSection('start'),
                  ),
                  _SegBtn(
                    label: 'Конец',
                    value: _endLabel,
                    active: _activeSection == 'end',
                    onTap: () => _switchSection('end'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Барабан ──
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Подсветка выбранного элемента
                Positioned(
                  left: 20,
                  right: 20,
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _primary.withOpacity(0.18)),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Часы
                    _WheelDrum(
                      controller: hourCtrl,
                      itemCount: 24,
                      label: (i) => _fmt2(i),
                      onChanged: (i) => setState(() {
                        if (editing) {
                          _startHour = i;
                        } else {
                          _endHour = i;
                        }
                      }),
                    ),

                    // Разделитель
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        ':',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: _textMain.withOpacity(0.6),
                          height: 1,
                        ),
                      ),
                    ),

                    // Минуты
                    _WheelDrum(
                      controller: minCtrl,
                      itemCount: _minuteSteps.length,
                      label: (i) => _fmt2(_minuteSteps[i]),
                      onChanged: (i) => setState(() {
                        if (editing) {
                          _startMinuteIdx = i;
                        } else {
                          _endMinuteIdx = i;
                        }
                      }),
                    ),
                  ],
                ),

                // Верхний и нижний градиент-fade
                Positioned(
                  top: 0,
                  left: 20,
                  right: 20,
                  child: IgnorePointer(
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white, Colors.white.withOpacity(0)],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 20,
                  right: 20,
                  child: IgnorePointer(
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.white, Colors.white.withOpacity(0)],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Итоговая строка ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(
                    '$_startLabel — $_endLabel',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textMain,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isValid
                          ? _primary.withOpacity(0.10)
                          : _danger.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _durationLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _isValid ? _primary : _danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Ошибка ──
          if (!_isValid || _hasConflict)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: BoxDecoration(
                  color: _danger.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _danger.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: _danger, size: 15),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        !_isValid
                            ? 'Время окончания должно быть позже начала'
                            : 'Выбранное время пересекается с занятым слотом',
                        style: const TextStyle(
                          fontSize: 12,
                          color: _danger,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Кнопка ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isValid && !_hasConflict
                    ? () => Navigator.pop(
                          context,
                          (
                            start: TimeOfDay(
                              hour: _startHour,
                              minute: _minuteSteps[_startMinuteIdx],
                            ),
                            end: TimeOfDay(
                              hour: _endHour,
                              minute: _minuteSteps[_endMinuteIdx],
                            ),
                          ),
                        )
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _divider,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(
                  'Готово · $_startLabel — $_endLabel',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Барабан с ListWheelScrollView ──
class _WheelDrum extends StatelessWidget {
  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int) label;
  final ValueChanged<int> onChanged;

  const _WheelDrum({
    required this.controller,
    required this.itemCount,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 180,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 52,
        perspective: 0.003,
        diameterRatio: 1.6,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onChanged,
        childDelegate: ListWheelChildBuilderDelegate(
          builder: (ctx, idx) {
            if (idx < 0 || idx >= itemCount) return null;
            final selected =
                controller.hasClients && controller.selectedItem == idx;
            return AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: TextStyle(
                fontSize: selected ? 36 : 26,
                fontWeight: FontWeight.w800,
                color: selected ? _primary : _textSub.withOpacity(0.45),
                letterSpacing: -1,
              ),
              child: Center(child: Text(label(idx))),
            );
          },
          childCount: itemCount,
        ),
      ),
    );
  }
}

// ── Переключатель Начало / Конец ──
class _SegBtn extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  const _SegBtn({
    required this.label,
    required this.value,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _primary.withOpacity(0.10),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: active ? _textSub : _textSub.withOpacity(0.5),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: active ? _primary : _textSub.withOpacity(0.4),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Список занятых слотов ──
class _TimelineWidget extends StatelessWidget {
  final List<bloc_state.TimeSlot> slots;

  const _TimelineWidget({required this.slots});

  @override
  Widget build(BuildContext context) {
    final busy = slots.where((s) => !s.isAvailable).toList();
    if (busy.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _danger.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _danger.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ЗАНЯТО СЕГОДНЯ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: _danger.withOpacity(0.7),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          ...busy.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                          color: _danger, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${s.displayText} занято',
                      style: TextStyle(
                        fontSize: 12,
                        color: _danger.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
