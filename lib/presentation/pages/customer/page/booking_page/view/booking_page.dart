// ─────────────────────────────────────────────
//  BOOKING PAGE — LIBRARY ENTRY POINT
//  Экран бронирования собран из part-файлов.
//  Здесь: оболочка (роль seller/user) + общая навигация.
//  Сама форма разбита на 4 шага (см. widgets/steps/*).
// ─────────────────────────────────────────────
library;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:restauran/data/models/booking.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_event.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/bloc/booking_state.dart'
    as bloc_state;
import 'package:restauran/presentation/pages/customer/page/booking_page/widgets/extras_bottom_sheet.dart';
import 'package:restauran/presentation/pages/customer/page/booking_page/widgets/seller_date_management_page.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/widgets/build_menu_tab.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/bloc/restaurant_detail_bloc.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/bloc/restaurant_detail_event.dart';
import 'package:restauran/presentation/pages/customer/page/restaurant_detail_page/bloc/restaurant_detail_state.dart'
    as detail_state;

// ── Дизайн-токены и общие виджеты ──
part '../widgets/booking_theme.dart';
part '../widgets/booking_shared.dart';
part '../widgets/step_indicator.dart';

// ── Боттом-шиты и диалоги ──
part '../widgets/category_bottom_sheet.dart';
part '../widgets/menu_selection_page.dart';
part '../widgets/time_picker_dialog.dart';
part '../widgets/calendar_picker_dialog.dart';
part '../widgets/management_pages.dart';

// ── Форма + 4 шага ──
part '../widgets/booking_form_page.dart';
part '../widgets/steps/schedule_step.dart';
part '../widgets/steps/menu_step.dart';
part '../widgets/steps/contact_step.dart';
part '../widgets/steps/confirm_step.dart';

// ─────────────────────────────────────────────
//  MAIN BOOKING PAGE (оболочка + опциональный BottomNav)
// ─────────────────────────────────────────────
class BookingPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final String? bookingId;
  final Booking? existingBooking;

  const BookingPage({
    super.key,
    required this.restaurantId,
    required this.restaurantName,
    this.bookingId,
    this.existingBooking,
  });

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
        body: Center(
            child: CircularProgressIndicator.adaptive(
                valueColor: AlwaysStoppedAnimation<Color>(_primary))),
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
//  MENU TAB PAGE (оборачивает BuildMenuTab в RestaurantDetailBloc)
// ─────────────────────────────────────────────
class _MenuTabPage extends StatelessWidget {
  final String restaurantId;

  const _MenuTabPage({required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      // appBar: AppBar(
      //   backgroundColor: _primary,
      //   foregroundColor: Colors.white,
      //   elevation: 0,
      //   automaticallyImplyLeading: false,
      //   centerTitle: true,
      //   title: const Text(
      //     'Меню',
      //     style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      //   ),
      // ),
      body: SafeArea(
        child: BlocBuilder<RestaurantDetailBloc,
            detail_state.RestaurantDetailState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation<Color>(_primary)),
              );
            }
            return BuildMenuTab(context: context, state: state);
          },
        ),
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
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.date_range_outlined,
                activeIcon: Icons.date_range,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.restaurant_menu_outlined,
                activeIcon: Icons.restaurant_menu,
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
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isActive ? _primary.withOpacity(0.10) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? _primary : _textSub,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
