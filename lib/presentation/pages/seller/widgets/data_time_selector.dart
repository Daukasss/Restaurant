import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class DateTimeSelector extends StatelessWidget {
  final DateTime selectedDate;
  final TimeOfDay selectedTime;
  final List<DateTime> bookedDates;
  final Function() onSelectDate;
  final Function() onSelectTime;

  const DateTimeSelector({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.bookedDates,
    required this.onSelectDate,
    required this.onSelectTime,
  });

  bool isDateBooked(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return bookedDates.any((bookedDate) =>
        bookedDate.year == dateOnly.year &&
        bookedDate.month == dateOnly.month &&
        bookedDate.day == dateOnly.day);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onSelectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: isDateBooked(selectedDate)
                    ? Colors.red.withOpacity(0.1)
                    : Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: isDateBooked(selectedDate)
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDateBooked(selectedDate) ? Colors.red : null,
                    ),
                  ),
                  if (isDateBooked(selectedDate))
                    const Expanded(
                      child: Text(
                        ' (Занято)',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: InkWell(
            onTap: onSelectTime,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

Future<DateTime?> showDatePickerDialog(
    BuildContext context, DateTime selectedDate, List<DateTime> bookedDates) {
  return showDialog<DateTime>(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Выберите дату',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 730)),
                focusedDay: selectedDate,
                selectedDayPredicate: (day) => isSameDay(day, selectedDate),
                enabledDayPredicate: (day) {
                  final dateOnly = DateTime(day.year, day.month, day.day);
                  final isBooked = bookedDates.any((bookedDate) =>
                      bookedDate.year == dateOnly.year &&
                      bookedDate.month == dateOnly.month &&
                      bookedDate.day == dateOnly.day);
                  return !isBooked &&
                      day.isAfter(
                          DateTime.now().subtract(const Duration(days: 1)));
                },
                onDaySelected: (selectedDay, focusedDay) {
                  Navigator.of(context).pop(selectedDay);
                },
                calendarStyle: CalendarStyle(
                  disabledTextStyle: const TextStyle(
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Отмена'),
              ),
            ],
          ),
        ),
      );
    },
  );
}
