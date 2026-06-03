part of '../view/booking_page.dart';

// ─────────────────────────────────────────────
//  ДИАЛОГ ВЫБОРА ДАТЫ (table_calendar)
// ─────────────────────────────────────────────
class _CalendarPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final Set<DateTime> unavailableDates;

  const _CalendarPickerDialog({
    required this.initialDate,
    required this.unavailableDates,
  });

  @override
  State<_CalendarPickerDialog> createState() => _CalendarPickerDialogState();
}

class _CalendarPickerDialogState extends State<_CalendarPickerDialog> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate;
    _selectedDay = widget.initialDate;
  }

  bool _isUnavailable(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    return widget.unavailableDates
        .any((u) => u.year == d.year && u.month == d.month && u.day == d.day);
  }

  bool _isPast(DateTime day) {
    final today = DateTime.now();
    return day.isBefore(DateTime(today.year, today.month, today.day));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Заголовок
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
            child: Row(
              children: [
                const Text(
                  'Выберите дату',
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
          // Легенда
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _danger.withOpacity(0.15),
                    border: Border.all(color: _danger, width: 1.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Занято',
                  style: TextStyle(fontSize: 12, color: _textSub),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.15),
                    border: Border.all(color: _accent, width: 1.5),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Выбрано',
                  style: TextStyle(fontSize: 12, color: _textSub),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _divider),
          // Календарь
          TableCalendar(
            locale: 'ru_RU',
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) =>
                _selectedDay != null && isSameDay(_selectedDay!, day),
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {
              CalendarFormat.month: '',
            },
            enabledDayPredicate: (day) => !_isUnavailable(day) && !_isPast(day),
            onDaySelected: (selected, focused) {
              if (!_isUnavailable(selected) && !_isPast(selected)) {
                setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                });
              }
            },
            onPageChanged: (focused) {
              setState(() => _focusedDay = focused);
            },
            calendarBuilders: CalendarBuilders(
              // Недоступные (занятые) дни — красный фон
              disabledBuilder: (ctx, day, focusedDay) {
                final isUnavailable = _isUnavailable(day);
                if (!isUnavailable) {
                  return null; // прошедшие дни — дефолтный вид
                }
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _danger.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _danger.withOpacity(0.4)),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _danger.withOpacity(0.7),
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ),
                );
              },
              // Выбранный день
              selectedBuilder: (ctx, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
              // Сегодня
              todayBuilder: (ctx, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    border: Border.all(color: _primary, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ),
                );
              },
              // Доступные дни
              defaultBuilder: (ctx, day, focusedDay) {
                return Container(
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textMain,
                      ),
                    ),
                  ),
                );
              },
              // Дни недели
              dowBuilder: (ctx, day) {
                final text = DateFormat.E('ru_RU').format(day);
                return Center(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _textSub,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _textMain,
              ),
              leftChevronIcon:
                  Icon(Icons.chevron_left_rounded, color: _primary),
              rightChevronIcon:
                  Icon(Icons.chevron_right_rounded, color: _primary),
            ),
            daysOfWeekStyle: const DaysOfWeekStyle(
              weekdayStyle: TextStyle(fontSize: 12, color: _textSub),
              weekendStyle: TextStyle(fontSize: 12, color: _textSub),
            ),
            calendarStyle: const CalendarStyle(
              outsideDaysVisible: false,
            ),
          ),
          // Кнопка подтверждения
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _selectedDay != null
                    ? () => Navigator.pop(context, _selectedDay)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  _selectedDay != null
                      ? 'Выбрать ${DateFormat('d MMMM', 'ru').format(_selectedDay!)}'
                      : 'Выберите дату',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
