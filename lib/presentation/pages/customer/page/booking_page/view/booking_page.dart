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
  @override
  void initState() {
    super.initState();

    if (widget.existingBooking != null) {
      context.read<BookingBloc>().add(
            InitEditBookingEvent(widget.existingBooking!, widget.restaurantId),
          );
    } else {
      context.read<BookingBloc>()
        ..add(LoadUserInfoEvent())
        ..add(LoadRestaurantDataEvent(widget.restaurantId))
        ..add(LoadRestaurantCategoriesEvent(widget.restaurantId))
        ..add(LoadRestaurantExtrasEvent(widget.restaurantId))
        ..add(LoadRestaurantBookedDatesEvent(widget.restaurantId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BookingFormPage(
      restaurantId: widget.restaurantId,
      restaurantName: widget.restaurantName,
      bookingId: widget.bookingId,
      existingBooking: widget.existingBooking,
    );
  }
}

// ─────────────────────────────────────────────
//  MENU TAB PAGE
// ─────────────────────────────────────────────
class MenuTabPage extends StatelessWidget {
  final String restaurantId;

  const MenuTabPage({super.key, required this.restaurantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
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
            return BuildMenuTab(
              context: context,
              state: state,
            );
          },
        ),
      ),
    );
  }
}
