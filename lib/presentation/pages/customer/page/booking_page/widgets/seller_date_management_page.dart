import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_event.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_state.dart';
import 'package:restauran/data/models/category_closure.dart';
import 'package:restauran/data/models/restaurant_category.dart';
import 'package:restauran/data/models/booking.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────
const _primary = Color(0xFF1A365D);
const _primaryLight = Color(0xFF2A4A7F);
const _accent = Color(0xFF4A90D9);
const _surface = Color(0xFFF7F9FC);
const _cardBg = Colors.white;
const _textMain = Color(0xFF1A2535);
const _textSub = Color(0xFF6B7A92);
const _divider = Color(0xFFE8EDF5);
const _danger = Color(0xFFE53E3E);
const _success = Color(0xFF38A169);
const _warning = Color(0xFFDD6B20);

class SellerDateManagementPage extends StatefulWidget {
  final String restaurantId;

  const SellerDateManagementPage({super.key, required this.restaurantId});

  @override
  State<SellerDateManagementPage> createState() =>
      _SellerDateManagementPageState();
}

class _SellerDateManagementPageState extends State<SellerDateManagementPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const Text(
          'Управление датами',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: BlocConsumer<BookingBloc, BookingState>(
        listener: (context, state) {
          // Показываем снекбар успеха
          if (state.closureSuccessMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.closureSuccessMessage!),
                backgroundColor: _success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
            // Сбрасываем сообщение через emit напрямую на блоке
            context
                .read<BookingBloc>()
                .emit(state.copyWith(clearClosureSuccessMessage: true));
          }
          // Показываем снекбар ошибки
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: _danger,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
          }
        },
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              // ── Баннер-инструкция ──────────────────────────────────────
              _InfoBanner(
                icon: Icons.info_outline_rounded,
                text:
                    'Выберите категорию и нажмите на дату чтобы заблокировать время.',
              ),
              const SizedBox(height: 20),

              // ── Выбор категории ────────────────────────────────────────
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Text(
                        'Шаг 1 — Выберите категорию',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: _divider),
                    if (state.isCategoriesLoading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: CircularProgressIndicator(color: _primary),
                        ),
                      )
                    else if (state.restaurantCategories.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'Нет доступных категорий',
                            style: TextStyle(color: _textSub, fontSize: 14),
                          ),
                        ),
                      )
                    else
                      ...state.restaurantCategories.map((cat) {
                        final isSelected =
                            state.selectedManagementCategoryId == cat.id;
                        return _CategoryTile(
                          category: cat,
                          isSelected: isSelected,
                          onTap: () {
                            // Сбрасываем выбранный день при смене категории
                            setState(() => _selectedDay = null);
                            context.read<BookingBloc>()
                              ..add(SelectManagementCategoryEvent(
                                cat.id!,
                                restaurantId: widget.restaurantId,
                              ));
                            // LoadCategoryClosuresEvent и LoadBookingsForCategoryEvent
                            // запускаются автоматически внутри _onSelectManagementCategory
                          },
                        );
                      }),
                    const SizedBox(height: 8),
                  ],
                ),
              ),

              // ── Календарь (после выбора категории) ────────────────────
              if (state.selectedManagementCategoryId != null) ...[
                const SizedBox(height: 20),
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Row(
                          children: [
                            const Text(
                              'Шаг 2 — Выберите дату',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              ),
                            ),
                            const Spacer(),
                            if (state.isClosuresLoading)
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _accent),
                              ),
                          ],
                        ),
                      ),
                      // Легенда
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        child: Row(
                          children: [
                            _LegendDot(color: _danger),
                            const SizedBox(width: 6),
                            const Text(
                              'Блокировки',
                              style: TextStyle(fontSize: 12, color: _textSub),
                            ),
                            const SizedBox(width: 16),
                            _LegendDot(color: _warning),
                            const SizedBox(width: 6),
                            const Text(
                              'Бронирования',
                              style: TextStyle(fontSize: 12, color: _textSub),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: _divider),
                      TableCalendar(
                        locale: 'ru_RU',
                        firstDay:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        focusedDay: _focusedDay,
                        selectedDayPredicate: (day) =>
                            _selectedDay != null &&
                            isSameDay(_selectedDay!, day),
                        calendarFormat: CalendarFormat.month,
                        availableCalendarFormats: const {
                          CalendarFormat.month: '',
                        },
                        onDaySelected: (selected, focused) {
                          setState(() {
                            _selectedDay = selected;
                            _focusedDay = focused;
                          });
                        },
                        onPageChanged: (focused) {
                          setState(() => _focusedDay = focused);
                        },
                        calendarBuilders: CalendarBuilders(
                          // Обычные дни — добавляем красную точку если есть блокировки
                          defaultBuilder: (ctx, day, focusedDay) {
                            final hasClosures = state.datesWithClosures.any(
                              (d) =>
                                  d.year == day.year &&
                                  d.month == day.month &&
                                  d.day == day.day,
                            );
                            final hasBookings = state.datesWithBookings.any(
                              (d) =>
                                  d.year == day.year &&
                                  d.month == day.month &&
                                  d.day == day.day,
                            );
                            if (!hasClosures && !hasBookings) return null;
                            // Если есть и блокировка и бронь — показываем оба цвета
                            return _CalendarDayWithTwoDots(
                              day: day,
                              dot1Color:
                                  hasClosures ? _danger : Colors.transparent,
                              dot2Color:
                                  hasBookings ? _warning : Colors.transparent,
                              isSelected: false,
                            );
                          },
                          // Выбранный день
                          selectedBuilder: (ctx, day, focusedDay) {
                            final hasClosures = state.datesWithClosures.any(
                              (d) =>
                                  d.year == day.year &&
                                  d.month == day.month &&
                                  d.day == day.day,
                            );
                            final hasBookings = state.datesWithBookings.any(
                              (d) =>
                                  d.year == day.year &&
                                  d.month == day.month &&
                                  d.day == day.day,
                            );
                            return _CalendarDayWithTwoDots(
                              day: day,
                              dot1Color:
                                  hasClosures ? _danger : Colors.transparent,
                              dot2Color:
                                  hasBookings ? _warning : Colors.transparent,
                              isSelected: true,
                            );
                          },
                          // Сегодняшний день
                          todayBuilder: (ctx, day, focusedDay) {
                            return _CalendarDayWithDot(
                              day: day,
                              dotColor: Colors.transparent,
                              isSelected: false,
                              isToday: true,
                            );
                          },
                          // FIX 2: выходные дни — такой же стиль как обычные
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
                        ),
                        daysOfWeekStyle: const DaysOfWeekStyle(
                          // FIX 2: все дни недели одного цвета
                          weekdayStyle:
                              TextStyle(fontSize: 12, color: _textSub),
                          weekendStyle:
                              TextStyle(fontSize: 12, color: _textSub),
                        ),
                        calendarStyle: const CalendarStyle(
                          outsideDaysVisible: false,
                          defaultTextStyle:
                              TextStyle(fontSize: 14, color: _textMain),
                          // FIX 2: выходные того же цвета что и будни
                          weekendTextStyle:
                              TextStyle(fontSize: 14, color: _textMain),
                          selectedDecoration: BoxDecoration(
                            color: _accent,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Блокировки для выбранного дня ─────────────────────
                // FIX 3: секция всегда видна после выбора дня
                if (_selectedDay != null) ...[
                  const SizedBox(height: 20),
                  _DayClosuresSection(
                    restaurantId: widget.restaurantId,
                    selectedDay: _selectedDay!,
                    closuresForDay: state.closuresForDate(_selectedDay!),
                    bookingsForDay:
                        state.bookingsForManagementDate(_selectedDay!),
                    categoryId: state.selectedManagementCategoryId!,
                    categoryName: state.restaurantCategories
                        .firstWhere(
                          (c) => c.id == state.selectedManagementCategoryId,
                          orElse: () => const RestaurantCategory(
                            restaurantId: '',
                            name: 'Категория',
                            priceRange: 0,
                            globalCategoryId: '',
                            section: 1,
                          ),
                        )
                        .name,
                  ),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Секция блокировок для выбранного дня
//  FIX 1: ElevatedButton.icon обёрнут в SizedBox с фиксированной шириной
//  FIX 3: closuresForDay передаётся снаружи, не пересчитывается внутри
// ─────────────────────────────────────────────────────────────────────────────
class _DayClosuresSection extends StatelessWidget {
  final String restaurantId;
  final DateTime selectedDay;
  final List<CategoryClosure> closuresForDay;
  final List<dynamic> bookingsForDay; // List<Booking>
  final String categoryId;
  final String categoryName;

  const _DayClosuresSection({
    required this.restaurantId,
    required this.selectedDay,
    required this.closuresForDay,
    required this.bookingsForDay,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMMM yyyy', 'ru').format(selectedDay);

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с датой и кнопкой
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Текст даты и счётчика
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dateStr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _textMain,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        closuresForDay.isEmpty
                            ? 'Нет блокировок'
                            : '${closuresForDay.length} блок.',
                        style: TextStyle(
                          fontSize: 12,
                          color: closuresForDay.isEmpty ? _success : _warning,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // FIX 1: SizedBox с фиксированной шириной вместо свободного
                // ElevatedButton.icon в Row — иначе infinite width
                SizedBox(
                  width: 150,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddClosureDialog(context),
                    icon: const Icon(Icons.block_rounded, size: 15),
                    label: const Text('Закрыть время'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _danger,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _divider),

          // ── Предупреждение о разделе ────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _warning.withOpacity(0.07),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _warning.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: _warning, size: 14),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Блокировка закрывает время для всего раздела — пользователи не смогут выбрать ни одну категорию этого раздела в указанное время.',
                      style: TextStyle(
                          fontSize: 11,
                          color: _warning,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Блокировки ──────────────────────────────────────────────
          if (closuresForDay.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        color: _success, size: 36),
                    SizedBox(height: 6),
                    Text(
                      'Блокировок нет',
                      style: TextStyle(
                        color: _textSub,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Нажмите «Закрыть время» чтобы добавить',
                      style: TextStyle(color: _textSub, fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                'БЛОКИРОВКИ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _danger,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            ...closuresForDay.map(
              (closure) => _ClosureTile(
                closure: closure,
                restaurantId: restaurantId,
                categoryId: categoryId,
              ),
            ),
          ],

          // ── Бронирования пользователей ────────────────────────────────
          if (bookingsForDay.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Text(
                'БРОНИРОВАНИЯ',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _warning,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            ...bookingsForDay.map((b) => _BookingTile(booking: b)),
          ],

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _showAddClosureDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<BookingBloc>(),
        child: _AddClosureBottomSheet(
          restaurantId: restaurantId,
          categoryId: categoryId,
          categoryName: categoryName,
          date: selectedDay,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Плашка одной блокировки
// ─────────────────────────────────────────────────────────────────────────────
class _ClosureTile extends StatelessWidget {
  final CategoryClosure closure;
  final String restaurantId;
  final String categoryId;

  const _ClosureTile({
    required this.closure,
    required this.restaurantId,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _danger.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _danger.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _danger.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                const Icon(Icons.access_time_rounded, color: _danger, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  closure.timeRangeText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _danger,
                  ),
                ),
                if (closure.reason != null && closure.reason!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    closure.reason!,
                    style: const TextStyle(fontSize: 12, color: _textSub),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context),
            icon: const Icon(Icons.delete_outline_rounded,
                color: _danger, size: 20),
            tooltip: 'Удалить блокировку',
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Удалить блокировку?',
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: _textMain),
        ),
        content: Text(
          'Время ${closure.timeRangeText} снова станет доступно для бронирования.',
          style: const TextStyle(fontSize: 14, color: _textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Отмена', style: TextStyle(color: _textSub)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<BookingBloc>().add(DeleteCategoryClosureEvent(
                    closureId: closure.id!,
                    restaurantId: restaurantId,
                    categoryId: categoryId,
                  ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Удалить', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom Sheet — добавление блокировки
//  FIX 3: время выбирается прямо здесь, всё работает через StatefulWidget
// ─────────────────────────────────────────────────────────────────────────────
class _AddClosureBottomSheet extends StatefulWidget {
  final String restaurantId;
  final String categoryId;
  final String categoryName;
  final DateTime date;

  const _AddClosureBottomSheet({
    required this.restaurantId,
    required this.categoryId,
    required this.categoryName,
    required this.date,
  });

  @override
  State<_AddClosureBottomSheet> createState() => _AddClosureBottomSheetState();
}

class _AddClosureBottomSheetState extends State<_AddClosureBottomSheet> {
  TimeOfDay _startTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 15, minute: 0);
  final _reasonController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  bool _validate() {
    final startMin = _startTime.hour * 60 + _startTime.minute;
    final endMin = _endTime.hour * 60 + _endTime.minute;
    if (endMin <= startMin) {
      setState(
          () => _validationError = 'Время окончания должно быть позже начала');
      return false;
    }
    setState(() => _validationError = null);
    return true;
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: ThemeData(
            colorScheme: const ColorScheme.light(primary: _primary),
          ),
          child: child!,
        ),
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
      _validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('d MMMM yyyy', 'ru').format(widget.date);

    return Container(
      decoration: const BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Хэндл
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Заголовок
          const Text(
            'Закрыть время',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textMain,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 13, color: _textSub),
              children: [
                TextSpan(
                  text: widget.categoryName,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, color: _primaryLight),
                ),
                const TextSpan(text: ' · '),
                TextSpan(text: dateStr),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // FIX 3: карточки выбора времени с onTap
          Row(
            children: [
              // Начало
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(isStart: true),
                  child: _TimePickerCard(
                    label: 'Начало блокировки',
                    time: _startTime,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_rounded,
                  color: _textSub, size: 20),
              const SizedBox(width: 12),
              // Конец
              Expanded(
                child: GestureDetector(
                  onTap: () => _pickTime(isStart: false),
                  child: _TimePickerCard(
                    label: 'Конец блокировки',
                    time: _endTime,
                  ),
                ),
              ),
            ],
          ),

          // Превью выбранного диапазона
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _danger.withOpacity(0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _danger.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.block_rounded, color: _danger, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Будет закрыто: ${_fmt(_startTime)} – ${_fmt(_endTime)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _danger,
                  ),
                ),
              ],
            ),
          ),

          // Ошибка валидации
          if (_validationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _validationError!,
              style: const TextStyle(color: _danger, fontSize: 12),
            ),
          ],

          const SizedBox(height: 16),

          // Поле причины (опционально)
          TextField(
            controller: _reasonController,
            maxLines: 2,
            style: const TextStyle(fontSize: 14, color: _textMain),
            decoration: InputDecoration(
              hintText: 'Причина (необязательно)',
              hintStyle: const TextStyle(fontSize: 14, color: _textSub),
              filled: true,
              fillColor: _surface,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _divider),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _divider),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _accent),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Кнопки действий
          Row(
            children: [
              // Отмена
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSub,
                    side: const BorderSide(color: _divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 12),
              // Сохранить
              Expanded(
                flex: 2,
                child: BlocBuilder<BookingBloc, BookingState>(
                  builder: (context, state) {
                    return ElevatedButton(
                      onPressed: state.isClosuresLoading
                          ? null
                          : () {
                              if (!_validate()) return;
                              context.read<BookingBloc>().add(
                                    CreateCategoryClosureEvent(
                                      restaurantId: widget.restaurantId,
                                      categoryId: widget.categoryId,
                                      categoryName: widget.categoryName,
                                      date: widget.date,
                                      startTime: _startTime,
                                      endTime: _endTime,
                                      reason:
                                          _reasonController.text.trim().isEmpty
                                              ? null
                                              : _reasonController.text.trim(),
                                    ),
                                  );
                              Navigator.of(context).pop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _danger,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: state.isClosuresLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'Заблокировать',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Вспомогательные виджеты
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  final RestaurantCategory category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? _primary.withOpacity(0.06) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? _primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? _primary.withOpacity(0.12) : _surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.category_outlined,
                color: isSelected ? _primary : _textSub,
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
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? _primary : _textMain,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        '${category.priceRange.toStringAsFixed(0)} ₸',
                        style: const TextStyle(fontSize: 12, color: _textSub),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: _primary, size: 20),
          ],
        ),
      ),
    );
  }
}

/// FIX 3: карточка времени без собственного onTap — обёртывается GestureDetector снаружи
class _TimePickerCard extends StatelessWidget {
  final String label;
  final TimeOfDay time;

  const _TimePickerCard({
    required this.label,
    required this.time,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: _textSub,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _fmt(time),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textMain,
                ),
              ),
              const Icon(Icons.access_time_rounded, color: _accent, size: 16),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Плашка бронирования (для Seller)
// ─────────────────────────────────────────────────────────────────────────────
class _BookingTile extends StatelessWidget {
  final dynamic booking; // Booking

  const _BookingTile({required this.booking});

  String _fmt(dynamic t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final b = booking as Booking;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _warning.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _warning.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_outline_rounded,
                color: _warning, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_fmt(b.startTime)} – ${_fmt(b.endTime)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _warning,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${b.name}  ·  ${b.guests} гост.',
                  style: const TextStyle(fontSize: 12, color: _textSub),
                ),
                if (b.phone.isNotEmpty)
                  Text(
                    b.phone,
                    style: const TextStyle(fontSize: 11, color: _textSub),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: b.status == 'confirmed'
                  ? _success.withOpacity(0.1)
                  : _warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              b.status == 'confirmed' ? 'Подтв.' : 'Ожидает',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: b.status == 'confirmed' ? _success : _warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Ячейка календаря с двумя точками (блокировка + бронь)
// ─────────────────────────────────────────────────────────────────────────────
class _CalendarDayWithTwoDots extends StatelessWidget {
  final DateTime day;
  final Color dot1Color; // Красный = блокировка
  final Color dot2Color; // Оранжевый = бронь
  final bool isSelected;
  final bool isToday;

  const _CalendarDayWithTwoDots({
    required this.day,
    required this.dot1Color,
    required this.dot2Color,
    required this.isSelected,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDot1 = dot1Color != Colors.transparent;
    final hasDot2 = dot2Color != Colors.transparent;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? _accent : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? _primary
                        : _textMain,
              ),
            ),
          ),
        ),
        if (hasDot1 || hasDot2)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasDot1)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 2, right: 1),
                  decoration: BoxDecoration(
                    color: dot1Color,
                    shape: BoxShape.circle,
                  ),
                ),
              if (hasDot2)
                Container(
                  width: 5,
                  height: 5,
                  margin: const EdgeInsets.only(top: 2, left: 1),
                  decoration: BoxDecoration(
                    color: dot2Color,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _CalendarDayWithDot extends StatelessWidget {
  final DateTime day;
  final Color dotColor;
  final bool isSelected;
  final bool isToday;

  const _CalendarDayWithDot({
    required this.day,
    required this.dotColor,
    required this.isSelected,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected ? _accent : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : isToday
                        ? _primary
                        : _textMain,
              ),
            ),
          ),
        ),
        if (dotColor != Colors.transparent)
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;

  const _LegendDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
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
}
