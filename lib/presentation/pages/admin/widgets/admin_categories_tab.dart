import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/models/global_category.dart';
import 'package:restauran/data/models/restaurant.dart';
import '../bloc/admin_category_bloc.dart';
import '../bloc/admin_category_event.dart';
import '../bloc/admin_category_state.dart';

class AdminCategoriesTab extends StatefulWidget {
  const AdminCategoriesTab({super.key});

  @override
  State<AdminCategoriesTab> createState() => _AdminCategoriesTabState();
}

class _AdminCategoriesTabState extends State<AdminCategoriesTab> {
  final _searchController = TextEditingController();
  int? _selectedSection;

  @override
  void initState() {
    super.initState();
    context.read<AdminCategoryBloc>().add(LoadGlobalCategoriesEvent());
    context.read<AdminCategoryBloc>().add(LoadAvailableRestaurantsEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ================= ВСПОМОГАТЕЛЬНЫЕ МЕТОДЫ =================

  /// Получить название ресторана по ID
  String _getRestaurantName(String id, List<Restaurant> restaurants) {
    final restaurant = restaurants.firstWhere(
      (r) => r.id == id,
      orElse: () => Restaurant(
          id: id,
          name: 'Неизвестный ресторан',
          description: '',
          location: '',
          phone: '',
          workingHours: '',
          ownerId: '',
          photos: [],
          bookedDates: [],
          rating: null,
          sumPeople: null),
    );
    return restaurant.name;
  }

  /// Показать диалог мультивыбора ресторанов
  Future<List<String>> _showRestaurantMultiSelectDialog(
    List<Restaurant> allRestaurants,
    List<String> selectedIds,
  ) async {
    final tempSelected = Set<String>.from(selectedIds);
    final searchController = TextEditingController();
    String searchQuery = '';

    return await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filteredRestaurants = searchQuery.isEmpty
              ? allRestaurants
              : allRestaurants
                  .where((r) =>
                      r.name.toLowerCase().contains(searchQuery.toLowerCase()))
                  .toList();

          return AlertDialog(
            title: const Text('Выберите рестораны'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Поиск
                  TextField(
                    controller: searchController,
                    decoration: const InputDecoration(
                      hintText: 'Поиск ресторана',
                      prefixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onChanged: (query) {
                      searchQuery = query;
                      setDialogState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  // Выбранные чипы
                  if (tempSelected.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: tempSelected.map((id) {
                        final name = _getRestaurantName(id, allRestaurants);
                        return Chip(
                          label:
                              Text(name, style: const TextStyle(fontSize: 12)),
                          onDeleted: () =>
                              setDialogState(() => tempSelected.remove(id)),
                        );
                      }).toList(),
                    ),
                  const Divider(height: 24),
                  // Список доступных
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredRestaurants.length,
                      itemBuilder: (context, index) {
                        final restaurant = filteredRestaurants[index];
                        final isSelected = tempSelected.contains(restaurant.id);
                        return CheckboxListTile(
                          title: Text(restaurant.name),
                          value: isSelected,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (checked) {
                            setDialogState(() {
                              if (checked == true) {
                                tempSelected.add(restaurant.id!);
                              } else {
                                tempSelected.remove(restaurant.id);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, []),
                child: const Text('Очистить'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(dialogContext, tempSelected.toList()),
                child: const Text('Готово'),
              ),
            ],
          );
        },
      ),
    ).then((value) => value ?? selectedIds);
  }

  // ================= ADD =================
  void _showAddCategoryDialog() {
    final bloc = context.read<AdminCategoryBloc>();
    final availableRestaurants = state is AdminCategoryLoaded
        ? (state as AdminCategoryLoaded).availableRestaurants
        : <Restaurant>[];

    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final descriptionController = TextEditingController();
    int selectedSection = 1;
    bool isGlobal = true;
    List<String> selectedRestaurantIds = [];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Добавить категорию'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Название *'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Цена *'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Описание (необязательно)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Раздел:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<int>(
                        title: const Text('Раздел 1'),
                        value: 1,
                        groupValue: selectedSection,
                        onChanged: (v) =>
                            setDialogState(() => selectedSection = v ?? 1),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<int>(
                        title: const Text('Раздел 2'),
                        value: 2,
                        groupValue: selectedSection,
                        onChanged: (v) =>
                            setDialogState(() => selectedSection = v ?? 2),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Для всех ресторанов'),
                  value: isGlobal,
                  onChanged: (v) => setDialogState(() {
                    isGlobal = v;
                    if (isGlobal) selectedRestaurantIds.clear();
                  }),
                ),
                // ✅ Выбор ресторанов (показывается только если !isGlobal)
                if (!isGlobal) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Выбранные рестораны:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            TextButton(
                              onPressed: () async {
                                final result =
                                    await _showRestaurantMultiSelectDialog(
                                  availableRestaurants,
                                  selectedRestaurantIds,
                                );
                                setDialogState(
                                    () => selectedRestaurantIds = result);
                              },
                              child: const Text('Изменить'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (selectedRestaurantIds.isEmpty)
                          const Text(
                            'Не выбрано',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: selectedRestaurantIds.map((id) {
                              final name =
                                  _getRestaurantName(id, availableRestaurants);
                              return Chip(
                                label: Text(name,
                                    style: const TextStyle(fontSize: 11)),
                                onDeleted: () => setDialogState(
                                    () => selectedRestaurantIds.remove(id)),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                // Валидация
                if (nameController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Заполните обязательные поля')),
                  );
                  return;
                }
                if (!isGlobal && selectedRestaurantIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Выберите хотя бы один ресторан')),
                  );
                  return;
                }

                final raw = priceController.text.trim().replaceAll(',', '.');
                final price = double.tryParse(raw);
                if (price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Некорректная цена')),
                  );
                  return;
                }

                bloc.add(
                  AddGlobalCategoryEvent(
                    name: nameController.text.trim(),
                    section: selectedSection,
                    defaultPrice: price,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    isGlobal: isGlobal,
                    restaurantIds: selectedRestaurantIds,
                  ),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= EDIT =================
  void _showEditCategoryDialog(GlobalCategory category) {
    final bloc = context.read<AdminCategoryBloc>();
    final availableRestaurants = state is AdminCategoryLoaded
        ? (state as AdminCategoryLoaded).availableRestaurants
        : <Restaurant>[];

    final nameController = TextEditingController(text: category.name);
    final priceController =
        TextEditingController(text: category.defaultPrice.toString());
    final descriptionController =
        TextEditingController(text: category.description ?? '');
    int selectedSection = category.section;
    bool isGlobal = category.isGlobal;
    List<String> selectedRestaurantIds =
        List.from(category.restaurantIds ?? []);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Редактировать категорию'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Название *'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Цена *'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                      labelText: 'Описание (необязательно)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Раздел:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<int>(
                        title: const Text('Раздел 1'),
                        value: 1,
                        groupValue: selectedSection,
                        onChanged: (v) =>
                            setDialogState(() => selectedSection = v ?? 1),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<int>(
                        title: const Text('Раздел 2'),
                        value: 2,
                        groupValue: selectedSection,
                        onChanged: (v) =>
                            setDialogState(() => selectedSection = v ?? 2),
                      ),
                    ),
                  ],
                ),
                SwitchListTile(
                  title: const Text('Для всех ресторанов'),
                  value: isGlobal,
                  onChanged: (v) => setDialogState(() {
                    isGlobal = v;
                    if (isGlobal) selectedRestaurantIds.clear();
                  }),
                ),
                // ✅ Выбор ресторанов при редактировании
                if (!isGlobal) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Выбранные рестораны:',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                            TextButton(
                              onPressed: () async {
                                final result =
                                    await _showRestaurantMultiSelectDialog(
                                  availableRestaurants,
                                  selectedRestaurantIds,
                                );
                                setDialogState(
                                    () => selectedRestaurantIds = result);
                              },
                              child: const Text('Изменить'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (selectedRestaurantIds.isEmpty)
                          const Text(
                            'Не выбрано',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          )
                        else
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: selectedRestaurantIds.map((id) {
                              final name =
                                  _getRestaurantName(id, availableRestaurants);
                              return Chip(
                                label: Text(name,
                                    style: const TextStyle(fontSize: 11)),
                                onDeleted: () => setDialogState(
                                    () => selectedRestaurantIds.remove(id)),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty ||
                    priceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Заполните обязательные поля')),
                  );
                  return;
                }
                if (!isGlobal && selectedRestaurantIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Выберите хотя бы один ресторан')),
                  );
                  return;
                }

                final raw = priceController.text.trim().replaceAll(',', '.');
                final price = double.tryParse(raw);
                if (price == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Некорректная цена')),
                  );
                  return;
                }

                bloc.add(
                  UpdateGlobalCategoryEvent(
                    categoryId: category.id!,
                    name: nameController.text.trim(),
                    section: selectedSection,
                    defaultPrice: price,
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    isGlobal: isGlobal,
                    restaurantIds: selectedRestaurantIds,
                  ),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STATE GETTER =================
  AdminCategoryState get state {
    try {
      return context.read<AdminCategoryBloc>().state;
    } catch (_) {
      return AdminCategoryInitial();
    }
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ===== TOP PANEL =====
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Поиск категорий',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (q) => context
                      .read<AdminCategoryBloc>()
                      .add(SearchGlobalCategoriesEvent(q)),
                ),
                const SizedBox(height: 12),
                SegmentedButton<int?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('Все')),
                    ButtonSegment(value: 1, label: Text('Раздел 1')),
                    ButtonSegment(value: 2, label: Text('Раздел 2')),
                  ],
                  selected: {_selectedSection},
                  onSelectionChanged: (s) {
                    setState(() => _selectedSection = s.first);
                    context
                        .read<AdminCategoryBloc>()
                        .add(FilterCategoriesBySectionEvent(s.first));
                  },
                ),
              ],
            ),
          ),

          // ===== LIST =====
          Expanded(
            child: BlocConsumer<AdminCategoryBloc, AdminCategoryState>(
              listener: (context, state) {
                if (state is AdminCategorySuccess) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else if (state is AdminCategoryError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              builder: (context, state) {
                if (state is AdminCategoryLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdminCategoryLoaded) {
                  if (state.filteredCategories.isEmpty) {
                    return const Center(child: Text('Нет категорий'));
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      context
                          .read<AdminCategoryBloc>()
                          .add(LoadGlobalCategoriesEvent());
                      context
                          .read<AdminCategoryBloc>()
                          .add(LoadAvailableRestaurantsEvent());
                    },
                    child: ListView.builder(
                      itemCount: state.filteredCategories.length,
                      itemBuilder: (context, index) {
                        final category = state.filteredCategories[index];

                        return Card(
                          margin: const EdgeInsets.all(12),
                          child: ListTile(
                            title: Text(category.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    '${category.defaultPrice.toStringAsFixed(0)} Тг'),
                                if (!category.isGlobal &&
                                    category.restaurantIds?.isNotEmpty == true)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Рестораны: ${category.restaurantIds!.length}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () =>
                                      _showEditCategoryDialog(category),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    context.read<AdminCategoryBloc>().add(
                                          DeleteGlobalCategoryEvent(
                                              category.id!),
                                        );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }

                return Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      context
                          .read<AdminCategoryBloc>()
                          .add(LoadGlobalCategoriesEvent());
                      context
                          .read<AdminCategoryBloc>()
                          .add(LoadAvailableRestaurantsEvent());
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Загрузить категории'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        icon: const Icon(Icons.add),
        label: const Text('Добавить'),
      ),
    );
  }
}
