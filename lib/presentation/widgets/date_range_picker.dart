import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class DateRangePicker extends StatefulWidget {
  final List<DateTime> selectedDates;
  final Function(List<DateTime>) onDatesChanged;
  final List<DateTime>? bookedDates;

  const DateRangePicker({
    super.key,
    required this.selectedDates,
    required this.onDatesChanged,
    this.bookedDates,
  });

  @override
  State<DateRangePicker> createState() => _DateRangePickerState();
}

class _DateRangePickerState extends State<DateRangePicker> {
  late DateTime _focusedDay;
  late DateTime _firstDay;
  late DateTime _lastDay;
  late List<DateTime> _selectedDates;
  late List<DateTime> _bookedDates;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _firstDay = DateTime.now().subtract(const Duration(days: 365));
    _lastDay = DateTime.now().add(const Duration(days: 365));
    _selectedDates = List.from(widget.selectedDates);
    _bookedDates = widget.bookedDates ?? [];
  }

  @override
  void didUpdateWidget(DateRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.bookedDates != oldWidget.bookedDates) {
      _bookedDates = widget.bookedDates ?? [];
    }
  }

  bool _isDateBooked(DateTime day) {
    return _bookedDates.any((bookedDate) => isSameDay(bookedDate, day));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar(
          firstDay: _firstDay,
          lastDay: _lastDay,
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          selectedDayPredicate: (day) {
            return _selectedDates
                .any((selectedDay) => isSameDay(selectedDay, day));
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              if (_selectedDates.any((day) => isSameDay(day, selectedDay))) {
                _selectedDates
                    .removeWhere((day) => isSameDay(day, selectedDay));
              } else {
                _selectedDates.add(selectedDay);
              }
              _focusedDay = focusedDay;
              widget.onDatesChanged(_selectedDates);
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            markerDecoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (_isDateBooked(date)) {
                return Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red,
                    ),
                    width: 8,
                    height: 8,
                  ),
                );
              }
              return null;
            },
          ),
        ),
        const SizedBox(height: 16),
        if (_selectedDates.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Выбранные даты:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedDates.map((date) {
                  return Chip(
                    label: Text('${date.day}/${date.month}/${date.year}'),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        _selectedDates.removeWhere((d) => isSameDay(d, date));
                        widget.onDatesChanged(_selectedDates);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
      ],
    );
  }
}
