part of '../view/booking_page.dart';

// ─────────────────────────────────────────────
//  МНОГОШАГОВАЯ ФОРМА БРОНИРОВАНИЯ
//  Шаг 1 — дата/время · Шаг 2 — меню/услуги
//  Шаг 3 — личные данные · Шаг 4 — подтверждение
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

  final _pageController = PageController();
  int _currentStep = 0;

  static const int _lastStep = 3;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _guestsController.dispose();
    _notesController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  /// Сырой переход к шагу без проверок (используется для возврата назад
  /// и после успешной валидации).
  void _goToStep(int step) {
    final target = step.clamp(0, _lastStep);
    _pageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  /// Нажатие «Далее»: пропускаем вперёд только если текущий шаг заполнен.
  void _onNext(BuildContext context, bloc_state.BookingState state) {
    if (!_canLeaveStep(_currentStep, state)) {
      _showStepError(context, _currentStep);
      return;
    }
    _goToStep(_currentStep + 1);
  }

  /// Тап по линии индикатора: назад — всегда, вперёд — только через
  /// заполненные шаги. На первый незаполненный шаг показываем подсказку.
  void _onStepTapped(
      BuildContext context, int target, bloc_state.BookingState state) {
    if (target <= _currentStep) {
      _goToStep(target);
      return;
    }
    for (int step = _currentStep; step < target; step++) {
      if (!_canLeaveStep(step, state)) {
        _goToStep(step);
        _showStepError(context, step);
        return;
      }
    }
    _goToStep(target);
  }

  /// Подсказка о том, что нужно заполнить на конкретном шаге.
  void _showStepError(BuildContext context, int step) {
    String message;
    switch (step) {
      case 0:
        message = 'Выберите категорию, дату и время';
        break;
      case 1:
        message = 'Выберите блюда во всех разделах меню';
        break;
      case 2:
        message = 'Заполните имя, телефон и количество гостей';
        _formKey.currentState?.validate();
        break;
      default:
        return;
    }
    _showBookingSnackBar(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close), // любая иконка
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: _surface,
      ),
      backgroundColor: _surface,
      body: SafeArea(
        child: BlocConsumer<BookingBloc, bloc_state.BookingState>(
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
              _showBookingSnackBar(context, state.errorMessage!, isError: true);
            }
            if (state.isSuccess) {
              _showBookingSnackBar(context, 'Бронирование успешно создано!');
              Navigator.of(context).pop(true);
            }
          },
          builder: (context, state) {
            if (state.isLoading && state.restaurantCategories.isEmpty) {
              return const Center(
                child: CircularProgressIndicator.adaptive(
                    valueColor: AlwaysStoppedAnimation<Color>(_primary)),
              );
            }

            final completion = _stepCompletion(state);

            return Column(
              children: [
                _StepIndicator(
                  currentStep: _currentStep,
                  completed: completion,
                  onStepTap: (i) => _onStepTapped(context, i, state),
                ),
                // const Divider(height: 1, color: _divider),
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (i) => setState(() => _currentStep = i),
                      // Запрещаем свайп вручную — переход только через кнопки,
                      // чтобы нельзя было пролистнуть незаполненный шаг.
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _ScheduleStep(
                          state: state,
                          restaurantId: widget.restaurantId,
                        ),
                        _MenuStep(
                          state: state,
                          restaurantId: widget.restaurantId,
                        ),
                        _ContactStep(
                          guestsController: _guestsController,
                          nameController: _nameController,
                          phoneController: _phoneController,
                        ),
                        _ConfirmStep(
                          state: state,
                          onEditStep: _goToStep,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BlocBuilder<BookingBloc, bloc_state.BookingState>(
        builder: (context, state) => _buildBottomBar(context, state),
      ),
    );
  }

  // ── НИЖНЯЯ ПАНЕЛЬ: Назад / Далее / Забронировать ──
  Widget _buildBottomBar(BuildContext context, bloc_state.BookingState state) {
    final isLast = _currentStep == _lastStep;
    // Кнопка «Далее» активна только если текущий шаг заполнен.
    // На последнем шаге — активна, если бронь готова к отправке.
    final bool canProceed = isLast
        ? _isConfirmStepComplete(state)
        : _canLeaveStep(_currentStep, state);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _divider)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (_currentStep > 0) ...[
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => _goToStep(_currentStep - 1),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Назад',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: state.isLoading
                        ? null
                        : isLast
                            ? (canProceed
                                ? () => _onSubmit(context, state)
                                : null)
                            : () => _onNext(context, state),
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
                            child: CircularProgressIndicator.adaptive(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            isLast
                                ? (widget.bookingId != null
                                    ? 'Обновить бронирование'
                                    : 'Забронировать')
                                : 'Далее',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ОТПРАВКА ─────────────────────────────────
  void _onSubmit(BuildContext context, bloc_state.BookingState state) {
    // Шаг 1 — категория / дата / время
    if (state.selectedRestaurantCategoryId == null) {
      _goToStep(0);
      _showBookingSnackBar(context, 'Пожалуйста, выберите категорию',
          isError: true);
      return;
    }
    if (state.isDateUnavailableForUser(state.selectedDate)) {
      _goToStep(0);
      _showBookingSnackBar(context,
          'Выбранная дата недоступна для бронирования. Выберите другую дату.',
          isError: true);
      return;
    }
    if (!state.isTimeRangeValid()) {
      _goToStep(0);
      _showBookingSnackBar(
          context, 'Время окончания должно быть позже времени начала',
          isError: true);
      return;
    }

    // Шаг 2 — меню
    if (state.menuCategories.isNotEmpty) {
      final totalMenuCategories = state.menuCategories.length;
      final selectedCount = state.selectedMenuItems.length;
      if (selectedCount < totalMenuCategories) {
        final missing = totalMenuCategories - selectedCount;
        _goToStep(1);
        _showBookingSnackBar(
          context,
          missing == 1
              ? 'Выберите блюдо во всех разделах меню'
              : 'Не выбраны блюда в $missing разделах меню',
          isError: true,
        );
        return;
      }
    }

    // Шаг 3 — личные данные
    if (!_isContactStepComplete(state)) {
      _goToStep(2);
      _formKey.currentState?.validate();
      _showBookingSnackBar(
          context, 'Заполните имя, телефон и количество гостей',
          isError: true);
      return;
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
}
