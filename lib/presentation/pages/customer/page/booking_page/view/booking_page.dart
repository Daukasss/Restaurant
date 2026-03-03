import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restauran/data/models/booking.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:restauran/data/models/menu_item.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_event.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_state.dart'
    as bloc_state;
import 'package:restauran/presentation/pages/customer/page/booking_page/widgets/seller_date_management_page.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/widgets/build_menu_tab.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/bloc/restaurant_detail_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/bloc/restaurant_detail_event.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/bloc/restaurant_detail_state.dart'
    as detail_state;

// ─────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────
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

// ─────────────────────────────────────────────
//  MAIN BOOKING PAGE (Shell with optional BottomNav)
// ─────────────────────────────────────────────
class BookingPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String? bookingId;
  final Booking? existingBooking;

  const BookingPage({
    Key? key,
    required this.restaurantId,
    required this.restaurantName,
    this.bookingId,
    this.existingBooking,
  }) : super(key: key);

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  int _selectedTab = 0;
  bool _isSeller = false;
  bool _roleLoaded = false;
  late final RestaurantDetailBloc _restaurantDetailBloc;

  @override
  void initState() {
    super.initState();
    _restaurantDetailBloc = RestaurantDetailBloc()
      ..add(FetchRestaurantData(widget.restaurantId));
    _loadRole();

    if (widget.existingBooking != null) {
      // Режим редактирования — загружаем данные существующей брони
      context.read<BookingBloc>().add(
            InitEditBookingEvent(widget.existingBooking!, widget.restaurantId),
          );
    } else {
      // Режим создания — стандартная загрузка
      context.read<BookingBloc>()
        ..add(LoadUserInfoEvent())
        ..add(LoadRestaurantDataEvent(widget.restaurantId))
        ..add(LoadRestaurantCategoriesEvent(widget.restaurantId))
        ..add(LoadRestaurantExtrasEvent(widget.restaurantId))
        ..add(LoadRestaurantBookedDatesEvent(widget.restaurantId));
    }
  }

  Future<void> _loadRole() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _roleLoaded = true);
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('profiles')
          .doc(user.uid)
          .get();
      final role = doc.data()?['role'] as String? ?? '';
      setState(() {
        _isSeller = role == 'seller';
        _roleLoaded = true;
      });
    } catch (_) {
      setState(() => _roleLoaded = true);
    }
  }

  @override
  void dispose() {
    _restaurantDetailBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_roleLoaded) {
      return const Scaffold(
        backgroundColor: _surface,
        body: Center(child: CircularProgressIndicator(color: _primary)),
      );
    }

    if (!_isSeller) {
      return _BookingFormPage(
        restaurantId: widget.restaurantId,
        restaurantName: widget.restaurantName,
        bookingId: widget.bookingId,
        existingBooking: widget.existingBooking,
      );
    }

    // Seller — с BottomNavigationBar
    return Scaffold(
      backgroundColor: _surface,
      body: BlocProvider.value(
        value: _restaurantDetailBloc,
        child: IndexedStack(
          index: _selectedTab,
          children: [
            _BookingFormPage(
              restaurantId: widget.restaurantId,
              restaurantName: widget.restaurantName,
              bookingId: widget.bookingId,
              existingBooking: widget.existingBooking,
            ),
            _DateManagementPage(restaurantId: widget.restaurantId),
            _MenuTabPage(restaurantId: widget.restaurantId),
          ],
        ),
      ),
      bottomNavigationBar: _SellerBottomNav(
        currentIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  MENU TAB PAGE (wraps BuildMenuTab with RestaurantDetailBloc)
// ─────────────────────────────────────────────
class _MenuTabPage extends StatelessWidget {
  final String restaurantId;

  const _MenuTabPage({required this.restaurantId});

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
          'Меню',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body:
          BlocBuilder<RestaurantDetailBloc, detail_state.RestaurantDetailState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }
          return BuildMenuTab(context: context, state: state);
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SELLER BOTTOM NAV
// ─────────────────────────────────────────────
class _SellerBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SellerBottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        border: const Border(top: BorderSide(color: _divider, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month,
                label: '',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.date_range_outlined,
                activeIcon: Icons.date_range,
                label: '',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.restaurant_menu_outlined,
                activeIcon: Icons.restaurant_menu,
                label: '',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? _primary.withOpacity(0.10)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isActive ? activeIcon : icon,
                  color: isActive ? _primary : _textSub,
                  size: 24,
                ),
              ),
              if (label.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: isActive ? _primary : _textSub,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BOOKING FORM PAGE
// ─────────────────────────────────────────────
class _BookingFormPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String? bookingId;
  final Booking? existingBooking;

  const _BookingFormPage({
    required this.restaurantId,
    required this.restaurantName,
    this.bookingId,
    this.existingBooking,
  });

  @override
  State<_BookingFormPage> createState() => _BookingFormPageState();
}

class _BookingFormPageState extends State<_BookingFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guestsController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _guestsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: _buildAppBar(),
      body: BlocConsumer<BookingBloc, bloc_state.BookingState>(
        listener: (context, state) {
          if (_nameController.text != state.name) {
            _nameController.text = state.name;
          }
          if (_phoneController.text != state.phone) {
            _phoneController.text = state.phone;
          }
          if (_guestsController.text != state.guests) {
            _guestsController.text = state.guests;
          }
          if (state.errorMessage != null) {
            _showSnackBar(context, state.errorMessage!, isError: true);
          }
          if (state.isSuccess) {
            _showSnackBar(context, 'Бронирование успешно создано!');
            Navigator.of(context).pop(true);
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.restaurantCategories.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: _primary),
            );
          }
          final categorySelected = state.selectedRestaurantCategoryId != null;

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                _buildCategoryButton(context, state),
                // Дата и время показываются только после выбора категории
                if (categorySelected) ...[
                  const SizedBox(height: 20),
                  _buildDateRow(context, state),
                  const SizedBox(height: 20),
                  _buildTimeRow(context, state),
                ] else ...[
                  const SizedBox(height: 16),
                  _buildSelectCategoryHint(),
                ],
                const SizedBox(height: 20),
                _buildGuestsField(context),
                const SizedBox(height: 20),
                if (state.menuCategories.isNotEmpty) ...[
                  _buildMenuButton(context, state),
                  const SizedBox(height: 20),
                ],
                if (state.restaurantExtras.isNotEmpty) ...[
                  _buildExtrasSection(context, state),
                  const SizedBox(height: 20),
                ],
                _buildContactSection(context),
                const SizedBox(height: 20),
                _buildPriceCard(state),
                const SizedBox(height: 24),
                _buildSubmitButton(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Text(
        widget.bookingId != null ? 'Редактирование' : 'Бронирование',
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.white.withOpacity(0.15)),
      ),
    );
  }

  // ── CATEGORY BUTTON ──────────────────────────
  Widget _buildCategoryButton(
      BuildContext context, bloc_state.BookingState state) {
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
            : () => _showCategoryBottomSheet(context, state),
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
                    Text(
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
              Icon(
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

  void _showCategoryBottomSheet(
      BuildContext context, bloc_state.BookingState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryBottomSheet(
        state: state,
        restaurantId: widget.restaurantId,
        bloc: context.read<BookingBloc>(),
      ),
    );
  }

  // ── DATE ROW ─────────────────────────────────
  Widget _buildDateRow(BuildContext context, bloc_state.BookingState state) {
    return _SectionCard(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          final picked = await showDialog<DateTime>(
            context: context,
            builder: (dialogCtx) => _CalendarPickerDialog(
              initialDate: state.isDateUnavailableForUser(state.selectedDate)
                  ? DateTime.now()
                  : state.selectedDate,
              unavailableDates: state.unavailableDatesForCategory,
            ),
          );
          if (picked != null) {
            context.read<BookingBloc>()
              ..add(UpdateDateEvent(picked))
              ..add(LoadExistingBookingsForDateEvent(
                  picked, widget.restaurantId));
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
                child: const Icon(Icons.calendar_today_outlined,
                    color: _primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Дата',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textSub,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
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
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: _textSub),
            ],
          ),
        ),
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

  // ── TIME ROW ──────────────────────────────────
  Widget _buildTimeRow(BuildContext context, bloc_state.BookingState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TimeCard(
                label: 'Начало',
                time: state.startTime,
                onTap: () async {
                  final result =
                      await showDialog<({TimeOfDay start, TimeOfDay end})?>(
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
                },
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
                onTap: () async {
                  final result =
                      await showDialog<({TimeOfDay start, TimeOfDay end})?>(
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
                },
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
            child: Row(
              children: [
                Icon(Icons.error_outline_rounded, color: _danger, size: 16),
                const SizedBox(width: 8),
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

  // ── GUESTS ───────────────────────────────────
  Widget _buildGuestsField(BuildContext context) {
    return TextFormField(
      controller: _guestsController,
      keyboardType: TextInputType.number,
      style: const TextStyle(fontSize: 15, color: _textMain),
      decoration: _inputDecoration(
        label: 'Количество гостей',
        hint: 'Введите количество',
        icon: Icons.people_alt_outlined,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Введите количество гостей';
        if ((int.tryParse(v) ?? 0) <= 0) return 'Введите корректное число';
        return null;
      },
      onChanged: (v) => context.read<BookingBloc>().add(UpdateGuestsEvent(v)),
    );
  }

  // ── MENU BUTTON ──────────────────────────────
  Widget _buildMenuButton(BuildContext context, bloc_state.BookingState state) {
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
                    Text(
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

  // ── EXTRAS ───────────────────────────────────
  Widget _buildExtrasSection(
      BuildContext context, bloc_state.BookingState state) {
    return _SectionCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                const Text(
                  'Дополнительные услуги',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _textMain,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...state.restaurantExtras.map((extra) {
              final isSelected = state.selectedExtraIds.contains(extra.id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => context
                      .read<BookingBloc>()
                      .add(ToggleExtraSelectionEvent(extra.id!)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? _primary.withOpacity(0.06) : _surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isSelected ? _primary.withOpacity(0.4) : _divider,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isSelected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              color: isSelected ? _primary : _textSub,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                extra.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected ? _primary : _textMain,
                                ),
                              ),
                            ),
                            Text(
                              '${extra.price.toStringAsFixed(0)} ₸',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? _primary : _textSub,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Описание
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _showExtraDescription(context,
                                    extra.name, extra.description ?? ''),
                                child: Text(
                                  extra.description ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: isSelected ? _primary : _textSub,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showExtraDescription(
      BuildContext context, String title, String description) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description.isEmpty ? 'Описание отсутствует' : description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── CONTACT ──────────────────────────────────
  Widget _buildContactSection(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          style: const TextStyle(fontSize: 15, color: _textMain),
          decoration: _inputDecoration(
            label: 'Имя',
            hint: 'Введите ваше имя',
            icon: Icons.person_outline_rounded,
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Введите ваше имя' : null,
          onChanged: (v) => context.read<BookingBloc>().add(UpdateNameEvent(v)),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 15, color: _textMain),
          decoration: _inputDecoration(
            label: 'Телефон',
            hint: '+7 (___) ___-__-__',
            icon: Icons.phone_outlined,
          ),
          validator: (v) =>
              (v == null || v.isEmpty) ? 'Введите номер телефона' : null,
          onChanged: (v) =>
              context.read<BookingBloc>().add(UpdatePhoneEvent(v)),
        ),
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
        gradient: LinearGradient(
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

  // ── SUBMIT ───────────────────────────────────
  Widget _buildSubmitButton(
      BuildContext context, bloc_state.BookingState state) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: state.isLoading ? null : () => _onSubmit(context, state),
        style: ElevatedButton.styleFrom(
          backgroundColor: _primary,
          disabledBackgroundColor: _primary.withOpacity(0.45),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: state.isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                widget.bookingId != null
                    ? 'Обновить бронирование'
                    : 'Забронировать',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }

  void _onSubmit(BuildContext context, bloc_state.BookingState state) {
    if (!_formKey.currentState!.validate()) return;

    if (state.selectedRestaurantCategoryId == null) {
      _showSnackBar(context, 'Пожалуйста, выберите категорию', isError: true);
      return;
    }

    // Проверяем что выбранная дата не заблокирована/занята
    if (state.isDateUnavailableForUser(state.selectedDate)) {
      _showSnackBar(context,
          'Выбранная дата недоступна для бронирования. Выберите другую дату.',
          isError: true);
      return;
    }

    if (!state.isTimeRangeValid()) {
      _showSnackBar(context, 'Время окончания должно быть позже времени начала',
          isError: true);
      return;
    }

    // Проверяем что все блюда выбраны (если меню есть)
    if (state.menuCategories.isNotEmpty) {
      final totalMenuCategories = state.menuCategories.length;
      final selectedCount = state.selectedMenuItems.length;
      if (selectedCount < totalMenuCategories) {
        final missing = totalMenuCategories - selectedCount;
        _showSnackBar(
          context,
          missing == 1
              ? 'Выберите блюдо во всех разделах меню'
              : 'Не выбраны блюда в $missing разделах меню',
          isError: true,
        );
        return;
      }
    }

    final priceStr = state.calculateBookingPrice();
    final totalPrice =
        priceStr != 'Цена не указана' ? int.tryParse(priceStr) : null;

    if (widget.bookingId != null) {
      context.read<BookingBloc>().add(UpdateBookingEvent(
            bookingId: widget.bookingId,
            name: state.name,
            phone: state.phone,
            guests: state.guests,
            selectedDate: state.selectedDate,
            startTime: state.startTime,
            endTime: state.endTime,
            restaurantId: widget.restaurantId,
            restaurantName: widget.restaurantName,
            selectedMenuItems: state.selectedMenuItems,
            restaurantCategoryId: state.selectedRestaurantCategoryId,
            selectedExtraIds: state.selectedExtraIds,
            totalPrice: totalPrice,
          ));
    } else {
      context.read<BookingBloc>().add(SubmitBookingEvent(
            name: state.name,
            phone: state.phone,
            guests: state.guests,
            notes: _notesController.text,
            selectedDate: state.selectedDate,
            startTime: state.startTime,
            endTime: state.endTime,
            restaurantId: widget.restaurantId,
            restaurantName: widget.restaurantName,
            selectedMenuItems: state.selectedMenuItems,
            restaurantCategoryId: state.selectedRestaurantCategoryId,
            selectedExtraIds: state.selectedExtraIds,
            totalPrice: totalPrice,
          ));
    }
  }

  // ── HELPERS ──────────────────────────────────
  InputDecoration _inputDecoration(
      {required String label, required String hint, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: _textSub.withOpacity(0.6), fontSize: 14),
      labelStyle: const TextStyle(color: _textSub, fontSize: 14),
      prefixIcon: Icon(icon, color: _primary, size: 20),
      filled: true,
      fillColor: _cardBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _divider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _danger, width: 1.5),
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: isError ? _danger : _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CATEGORY BOTTOM SHEET
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
                    const SizedBox(height: 16),
                  ],
                  if (section2.isNotEmpty) ...[
                    const SizedBox(height: 8),
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

// ─────────────────────────────────────────────
//  MENU SELECTION PAGE (отдельная страница)
// ─────────────────────────────────────────────
class _MenuSelectionPage extends StatelessWidget {
  final bloc_state.BookingState state;

  const _MenuSelectionPage({required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Выберите меню',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        actions: [
          if (state.selectedMenuItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${state.selectedMenuItems.length} выбрано',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: BlocBuilder<BookingBloc, bloc_state.BookingState>(
        builder: (context, liveState) {
          if (liveState.menuCategories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_outlined,
                      size: 56, color: _textSub.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text(
                    'Меню недоступно',
                    style: TextStyle(fontSize: 16, color: _textSub),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: liveState.menuCategories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final category = liveState.menuCategories[index];
              return _MenuCategoryCard(
                category: category,
                selectedItemId: liveState.selectedMenuItems[category.id],
              );
            },
          );
        },
      ),
      bottomNavigationBar: _MenuConfirmBar(
        onConfirm: () => Navigator.pop(context),
      ),
    );
  }
}

class _MenuCategoryCard extends StatelessWidget {
  final dynamic category;
  final String? selectedItemId;

  const _MenuCategoryCard({
    required this.category,
    required this.selectedItemId,
  });

  List<Widget> _buildMenuItems(BuildContext context, dynamic category) {
    final items = category.menuItems;
    final List<Widget> result = [];

    void addTile(String itemId, String itemName) {
      final isSelected = selectedItemId == itemId;
      result.add(
        InkWell(
          onTap: () => context.read<BookingBloc>().add(
                UpdateMenuSelectionEvent(category.id.toString(), itemId),
              ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color:
                  isSelected ? _primary.withOpacity(0.06) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? _primary.withOpacity(0.35)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? _primary : _divider,
                      width: 2,
                    ),
                    color: isSelected ? _primary : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 13)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    itemName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? _primary : _textMain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (items is List) {
      for (final item in items) {
        // LinkedMap<String,dynamic> satisfies `is Map` — check BEFORE accessing .id/.name
        if (item is Map) {
          final id = (item['id'] ?? '').toString();
          final name = (item['name'] ?? item['title'] ?? id).toString();
          if (id.isNotEmpty) addTile(id, name);
        }
      }
    } else if (items is Map) {
      for (final entry in (items as Map).entries) {
        final id = entry.key.toString();
        final val = entry.value;
        final name = val is Map
            ? (val['name'] ?? val['title'] ?? id).toString()
            : val.toString();
        addTile(id, name);
      }
    }

    return result;
  }

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.04),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              border:
                  const Border(bottom: BorderSide(color: _divider, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    category.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _primary,
                    ),
                  ),
                ),
                if (selectedItemId != null)
                  const Icon(Icons.check_circle_rounded,
                      color: _success, size: 18),
              ],
            ),
          ),

          // Items
          if (category.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                category.description,
                style: const TextStyle(fontSize: 13, color: _textSub),
              ),
            ),

          if (category.menuItems.isNotEmpty)
            ..._buildMenuItems(context, category)
          else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Нет позиций',
                style: TextStyle(
                    fontSize: 13, color: _textSub, fontStyle: FontStyle.italic),
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _MenuConfirmBar extends StatelessWidget {
  final VoidCallback onConfirm;

  const _MenuConfirmBar({required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: _cardBg,
        border: Border(top: BorderSide(color: _divider)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Подтвердить выбор',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  DATE MANAGEMENT PAGE (Seller Tab 2)
// ─────────────────────────────────────────────
class _DateManagementPage extends StatelessWidget {
  final String restaurantId;

  const _DateManagementPage({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    // Делегируем весь UI в отдельный виджет SellerDateManagementPage
    return SellerDateManagementPage(restaurantId: restaurantId);
  }
}

// ─────────────────────────────────────────────
//  MENU MANAGEMENT PAGE (Seller Tab 3)
// ─────────────────────────────────────────────
class _MenuManagementPage extends StatelessWidget {
  final String restaurantId;

  const _MenuManagementPage({required this.restaurantId});

  List<Widget> _buildManagementItems(dynamic items) {
    final result = <Widget>[];

    void addTile(String name) {
      result.add(ListTile(
        leading: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: _accent,
            shape: BoxShape.circle,
          ),
        ),
        title:
            Text(name, style: const TextStyle(fontSize: 14, color: _textMain)),
        dense: true,
      ));
    }

    if (items is Map) {
      for (final entry in (items as Map).entries) {
        final val = entry.value;
        final name = val is Map
            ? (val['name'] ?? val['title'] ?? entry.key).toString()
            : val.toString();
        addTile(name);
      }
    } else if (items is List) {
      for (final item in items) {
        if (item is Map) {
          addTile((item['name'] ?? item['title'] ?? '').toString());
        }
      }
    }
    return result;
  }

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
          'Меню',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      body: BlocBuilder<BookingBloc, bloc_state.BookingState>(
        builder: (context, state) {
          if (state.menuCategories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu_outlined,
                      size: 64, color: _textSub.withOpacity(0.35)),
                  const SizedBox(height: 16),
                  const Text(
                    'Меню не настроено',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _textSub),
                  ),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.menuCategories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) {
              final cat = state.menuCategories[i];
              return _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: const BoxDecoration(
                        border: Border(bottom: BorderSide(color: _divider)),
                      ),
                      child: Text(
                        cat.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                    ),
                    ..._buildManagementItems(cat.menuItems),
                    const SizedBox(height: 8),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SHARED WIDGETS
// ─────────────────────────────────────────────
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

class _TimeCard extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeCard({
    required this.label,
    required this.time,
    required this.onTap,
  });

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11,
                  color: _textSub,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _fmt(time),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: _textMain,
                    letterSpacing: 1,
                  ),
                ),
                const Icon(Icons.access_time_rounded, color: _accent, size: 18),
              ],
            ),
          ],
        ),
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
              style: TextStyle(
                  fontSize: 13,
                  color: _primaryLight,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── КАСТОМНЫЙ ДИАЛОГ ВЫБОРА ВРЕМЕНИ — БАРАБАН (ListWheelScrollView) ──────────
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
          // ── Заголовок ──────────────────────────────────
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

          // ── Занятые слоты ───────────────────────────────
          if (hasBusySlots) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
              child: _TimelineWidget(slots: widget.availableSlots),
            ),
            const Divider(height: 1, color: _divider),
          ],

          const SizedBox(height: 16),

          // ── Переключатель Начало / Конец ────────────────
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

          // ── Барабан ─────────────────────────────────────
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
                        if (editing)
                          _startHour = i;
                        else
                          _endHour = i;
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
                        if (editing)
                          _startMinuteIdx = i;
                        else
                          _endMinuteIdx = i;
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

          // ── Итоговая строка ─────────────────────────────
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

          // ── Ошибка ──────────────────────────────────────
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
                    Icon(Icons.error_outline_rounded, color: _danger, size: 15),
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

          // ── Кнопка ──────────────────────────────────────
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

// ── Барабан с ListWheelScrollView ─────────────────────────────────────────────
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

// ── Переключатель Начало / Конец ──────────────────────────────────────────────
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

// ── Список занятых слотов ─────────────────────────────────────────────────────
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

// ── КАСТОМНЫЙ ДИАЛОГ ВЫБОРА ДАТЫ С TABLE_CALENDAR ────────────────────────────
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
                if (!isUnavailable)
                  return null; // прошедшие дни — дефолтный вид
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
