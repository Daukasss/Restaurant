// ignore_for_file: avoid_print, use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/presentation/pages/seller/page/add_edit_restaurant/bloc/restaurant_state.dart';
import 'package:restauran/presentation/pages/seller/page/add_edit_restaurant/widget/restaurant_categories_widget.dart';
import 'package:restauran/theme/app_colors.dart';

import '../../../../../widgets/custom_text_field.dart';
import '../../../../../widgets/photo_gallery.dart';
import '../widget/restaurant_extras_widget.dart';
import '../bloc/restaurant_bloc.dart';
import '../bloc/restaurant_event.dart';

class AddRestaurantPage extends StatefulWidget {
  final String restaurantId;
  final String restaurantName;
  final Map<String, dynamic>? restaurant;

  const AddRestaurantPage({
    super.key,
    this.restaurant,
    required this.restaurantId,
    required this.restaurantName,
  });

  @override
  State<AddRestaurantPage> createState() => _AddRestaurantPageState();
}

class _AddRestaurantPageState extends State<AddRestaurantPage> {
  // Контроллеры живут всё время жизни страницы
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _phonesController = TextEditingController();
  final _sumPeopleController = TextEditingController();

  final PageController _pageController = PageController();
  static const int _totalSteps = 4;
  int _currentStep = 0;

  bool _controllersInitialized = false;

  static const List<String> _stepTitles = [
    'Информация',
    'Категории',
    'Фото',
    'Готово',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _phonesController.dispose();
    _sumPeopleController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initControllers(RestaurantState state) {
    _nameController.text = state.name;
    _descriptionController.text = state.description;
    _locationController.text = state.location;
    _phonesController.text = state.phones.join('\n');
    _sumPeopleController.text = state.sumPeople;
    _controllersInitialized = true;
  }

  // Обязательные поля первого шага.
  bool _isStep1Valid(RestaurantState state) =>
      state.name.trim().isNotEmpty && state.location.trim().isNotEmpty;

  bool _canProceedFrom(int step, RestaurantState state) {
    if (step == 0) return _isStep1Valid(state);
    return true;
  }

  void _goNext(RestaurantState state) {
    if (!_canProceedFrom(_currentStep, state)) {
      _showStepError();
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goBack() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  // Переход на конкретный шаг по тапу на индикатор.
  // Назад — всегда; вперёд — только если шаг 1 заполнен.
  void _goToStep(int index, RestaurantState state) {
    if (index == _currentStep) return;
    if (index > 0 && !_isStep1Valid(state)) {
      _showStepError();
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    );
  }

  // Статусы заполненности шагов для подсветки линий индикатора.
  List<bool> _stepCompletion(RestaurantState state) => [
        _isStep1Valid(state),
        state.restaurantCategories.isNotEmpty,
        state.photoUrls.isNotEmpty,
        _isStep1Valid(state),
      ];

  void _showStepError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Заполните название и местоположение, чтобы продолжить'),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final bloc = RestaurantBloc();
        bloc.add(LoadRestaurantData(
          restaurant: widget.restaurant,
          restaurantId: widget.restaurantId,
        ));
        bloc.add(LoadBookedDates(restaurantId: widget.restaurantId));
        return bloc;
      },
      child: BlocConsumer<RestaurantBloc, RestaurantState>(
        listener: (context, state) {
          if (!_controllersInitialized &&
              !state.isLoading &&
              state.name.isNotEmpty) {
            _initControllers(state);
          }
          if (state.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            appBar: AppBar(
              backgroundColor: AppColors.surface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: AppColors.textMain),
                onPressed: () => Navigator.of(context).pop(),
              ),
              surfaceTintColor: Colors.transparent,
              // title: Text(
              //   state.isEditing ? 'Редактирование ресторана' : 'Новый ресторан',
              //   style: const TextStyle(
              //     fontWeight: FontWeight.w600,
              //     color: Colors.white,
              //   ),
              // ),
            ),
            body: state.isLoading && !_controllersInitialized
                ? const Center(
                    child: CircularProgressIndicator.adaptive(
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary)),
                  )
                : Column(
                    children: [
                      _StepIndicator(
                        currentStep: _currentStep,
                        titles: _stepTitles,
                        completed: _stepCompletion(state),
                        onStepTap: (i) => _goToStep(i, state),
                      ),
                      Expanded(
                        child: PageView(
                          controller: _pageController,
                          physics: const ClampingScrollPhysics(),
                          onPageChanged: (index) {
                            // Запрещаем свайп вперёд, если шаг 1 не заполнен.
                            if (index > 0 && !_isStep1Valid(state)) {
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                _pageController.animateToPage(
                                  0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              });
                              _showStepError();
                              return;
                            }
                            setState(() => _currentStep = index);
                          },
                          children: [
                            _StepInfo(
                              nameController: _nameController,
                              descriptionController: _descriptionController,
                              locationController: _locationController,
                              phonesController: _phonesController,
                              sumPeopleController: _sumPeopleController,
                            ),
                            _StepCategories(
                              restaurantId: widget.restaurantId,
                              state: state,
                            ),
                            _StepPhotos(state: state),
                            _StepReview(state: state),
                          ],
                        ),
                      ),
                      _BottomBar(
                        currentStep: _currentStep,
                        totalSteps: _totalSteps,
                        isEditing: state.isEditing,
                        isSaving: state.isLoading,
                        onBack: _goBack,
                        onNext: () => _goNext(state),
                        onSubmit: () => context
                            .read<RestaurantBloc>()
                            .add(SaveRestaurant(context)),
                      ),
                    ],
                  ),
          );
        },
      ),
    );
  }
}

// ==================== ИНДИКАТОР ШАГОВ ====================

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> titles;
  final List<bool> completed;
  final ValueChanged<int> onStepTap;

  const _StepIndicator({
    required this.currentStep,
    required this.titles,
    required this.completed,
    required this.onStepTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // ── Линии-индикаторы ──
          Row(
            children: List.generate(titles.length, (i) {
              final isDone = completed[i];
              final isCurrent = i == currentStep;
              final Color color = isDone
                  ? AppColors.primary
                  : isCurrent
                      ? AppColors.primary.withOpacity(0.35)
                      : AppColors.divider;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: i == titles.length - 1 ? 0 : 6,
                  ),
                  child: GestureDetector(
                    onTap: () => onStepTap(i),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      height: 5,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          // ── Подпись текущего шага ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                titles[currentStep],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMain,
                ),
              ),
              Text(
                'Шаг ${currentStep + 1} из ${titles.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSub,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ==================== ОБЩИЕ ВИДЖЕТЫ ШАГОВ ====================

class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: AppColors.textSub),
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class _SoftCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _SoftCard({
    required this.child,
    // ignore: unused_element_parameter
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textMain,
      ),
    );
  }
}

// ==================== ШАГ 1 — ИНФОРМАЦИЯ ====================

class _StepInfo extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final TextEditingController phonesController;
  final TextEditingController sumPeopleController;

  const _StepInfo({
    required this.nameController,
    required this.descriptionController,
    required this.locationController,
    required this.phonesController,
    required this.sumPeopleController,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RestaurantBloc>();

    return _StepScaffold(
      title: 'Общая информация',
      subtitle: 'Расскажите гостям о вашем ресторане',
      children: [
        _SoftCard(
          child: Column(
            children: [
              CustomTextField(
                controller: nameController,
                onChanged: (v) => bloc.add(UpdateName(v)),
                hintText: 'Название ресторана*',
                prefixIcon: Icons.restaurant,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: descriptionController,
                onChanged: (v) => bloc.add(UpdateDescription(v)),
                hintText: 'Описание',
                prefixIcon: Icons.description,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: locationController,
                onChanged: (v) => bloc.add(UpdateLocation(v)),
                hintText: 'Местоположение *',
                prefixIcon: Icons.location_on,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomTextField(
                controller: phonesController,
                onChanged: (v) => bloc.add(UpdatePhone(v)),
                hintText: 'Номера телефонов',
                prefixIcon: Icons.phone,
                isMultiplePhones: true,
                keyboardType: TextInputType.multiline,
              ),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text(
                  'Введите каждый номер с новой строки',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSub,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: sumPeopleController,
                onChanged: (v) => bloc.add(UpdateSumPeople(v)),
                hintText: 'Кол-во мест в одном столе',
                prefixIcon: Icons.people,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ==================== ШАГ 2 — КАТЕГОРИИ И ОПЦИИ ====================

class _StepCategories extends StatelessWidget {
  final String restaurantId;
  final RestaurantState state;

  const _StepCategories({required this.restaurantId, required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RestaurantBloc>();

    return _StepScaffold(
      title: 'Категории и опции',
      subtitle: 'Выберите категории кухни и дополнительные услуги',
      children: [
        const _SectionLabel('Категории ресторана'),
        const SizedBox(height: 12),
        SellerCategoriesWidget(
          restaurantId: restaurantId,
          availableCategories: state.availableGlobalCategories,
          restaurantCategories: state.restaurantCategories,
          isLoading: state.isCategoriesLoading,
          onActivateCategory: (id, price, desc) => bloc.add(
            ActivateRestaurantCategory(
              globalCategoryId: id,
              price: price,
              description: desc,
            ),
          ),
          onUpdateCategory: (id, price, desc, active) => bloc.add(
            UpdateRestaurantCategory(
              categoryId: id,
              price: price,
              description: desc,
              isActive: active,
            ),
          ),
          onDeactivateCategory: (id) =>
              bloc.add(DeactivateRestaurantCategory(id)),
        ),
        const SizedBox(height: 28),
        const _SectionLabel('Дополнительные опции'),
        if (!state.isEditing) ...[
          const SizedBox(height: 8),
          const Text(
            'Опции можно добавить после создания ресторана',
            style: TextStyle(fontSize: 13, color: AppColors.textSub),
          ),
        ],
        const SizedBox(height: 16),
        RestaurantExtrasWidget(
          extras: state.restaurantExtras,
          isLoading: state.isExtrasLoading,
          onAddExtra: (name, price, desc) => bloc.add(
            AddRestaurantExtra(name: name, price: price, description: desc),
          ),
          onUpdateExtra: (id, name, price, desc) => bloc.add(
            UpdateRestaurantExtra(
              extraId: id,
              name: name,
              price: price,
              description: desc,
            ),
          ),
          onRemoveExtra: (id) => bloc.add(RemoveRestaurantExtra(id)),
        ),
      ],
    );
  }
}

// ==================== ШАГ 3 — ФОТО ====================

class _StepPhotos extends StatelessWidget {
  final RestaurantState state;

  const _StepPhotos({required this.state});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RestaurantBloc>();

    return _StepScaffold(
      title: 'Фотографии',
      subtitle: 'Добавьте качественные снимки. Первое фото — главное',
      children: [
        // if (state.photoUrls.isNotEmpty)
        //   Container(
        //     margin: const EdgeInsets.only(bottom: 16),
        //     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        //     decoration: BoxDecoration(
        //       color: AppColors.accent.withOpacity(0.1),
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //     child: Row(
        //       children: [
        //         const Icon(Icons.star, color: AppColors.accent, size: 18),
        //         const SizedBox(width: 8),
        //         // Text(
        //         //   'Загружено фото: ${state.photoUrls.length}',
        //         //   style: const TextStyle(
        //         //     color: AppColors.primary,
        //         //     fontWeight: FontWeight.w600,
        //         //   ),
        //         // ),
        //       ],
        //     ),
        //   ),
        _SoftCard(
          child: PhotoGallery(
            photoUrls: state.photoUrls,
            onAddPhoto: () =>
                bloc.add(AddPhoto(restaurantId: state.restaurantId)),
            onRemovePhoto: (index) => bloc.add(RemovePhoto(index)),
          ),
        ),
      ],
    );
  }
}

// ==================== ШАГ 4 — ПОДТВЕРЖДЕНИЕ ====================

class _StepReview extends StatelessWidget {
  final RestaurantState state;

  const _StepReview({required this.state});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Подтверждение',
      subtitle: 'Проверьте данные перед сохранением',
      children: [
        _SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _reviewRow(Icons.restaurant, 'Название',
                  state.name.isEmpty ? '—' : state.name),
              _reviewRow(Icons.location_on, 'Местоположение',
                  state.location.isEmpty ? '—' : state.location),
              _reviewRow(
                Icons.phone,
                'Телефоны',
                state.phones.isEmpty ? '—' : state.phones.join(', '),
              ),
              _reviewRow(Icons.people, 'Мест за столом',
                  state.sumPeople.isEmpty ? '—' : state.sumPeople),
              if (state.description.isNotEmpty)
                _reviewRow(Icons.description, 'Описание', state.description),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _statCard(
                Icons.category,
                '${state.restaurantCategories.length}',
                'Категорий',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                Icons.add_box,
                '${state.restaurantExtras.length}',
                'Опций',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                Icons.image,
                '${state.photoUrls.length}',
                'Фото',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reviewRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSub,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMain,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSub),
          ),
        ],
      ),
    );
  }
}

// ==================== НИЖНЯЯ ПАНЕЛЬ НАВИГАЦИИ ====================

class _BottomBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final bool isEditing;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const _BottomBar({
    required this.currentStep,
    required this.totalSteps,
    required this.isEditing,
    required this.isSaving,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentStep == totalSteps - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (currentStep > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: isSaving ? null : onBack,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Назад'),
              ),
            ),
          if (currentStep > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isSaving ? null : (isLast ? onSubmit : onNext),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      isLast
                          ? (isEditing
                              ? 'Обновить ресторан'
                              : 'Создать ресторан')
                          : 'Далее',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
