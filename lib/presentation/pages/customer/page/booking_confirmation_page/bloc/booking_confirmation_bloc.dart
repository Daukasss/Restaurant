import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/services/abstract/abstract_menu_service.dart';

import '../../../../../../data/services/service_locator.dart';
import 'booking_confirmation_event.dart';
import 'booking_confirmation_state.dart';

class BookingConfirmationBloc
    extends Bloc<BookingConfirmationEvent, BookingConfirmationState> {
  final AbstractMenuService _bookingConfirmation = getIt<AbstractMenuService>();

  BookingConfirmationBloc() : super(BookingConfirmationInitial()) {
    on<LoadMenuSelections>(_onLoadMenuSelections);
    on<NavigateToHome>(_onNavigateToHome);
  }

  Future<void> _onLoadMenuSelections(
    LoadMenuSelections event,
    Emitter<BookingConfirmationState> emit,
  ) async {
    emit(BookingConfirmationLoading());
    try {
      final selectedItems = await _bookingConfirmation.loadMenuSelections(
          event.menuSelections as List<Map<String, dynamic>>);
      emit(BookingConfirmationLoaded(selectedItems));
    } catch (error) {
      debugPrint('Error loading menu selections: $error');
      emit(const BookingConfirmationError('Ошибка загрузки данных!'));
    }
  }

  void _onNavigateToHome(
    NavigateToHome event,
    Emitter<BookingConfirmationState> emit,
  ) {
    emit(NavigatingToHome());
  }
}
