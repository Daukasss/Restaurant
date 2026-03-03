import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:restauran/data/models/global_category.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedCategoryId;
  DateTime? _selectedDate;

  late final Stream<QuerySnapshot> _categoriesStream;

  @override
  void initState() {
    super.initState();

    // Читаем начальное состояние из bloc ОДИН РАЗ при открытии шторки
    final blocState = context.read<HomeBloc>().state;
    _selectedCategoryId = blocState.selectedGlobalCategoryId;
    _selectedDate = blocState.selectedDate;

    _categoriesStream = FirebaseFirestore.instance
        .collection('global_categories')
        .where('is_active', isEqualTo: true)
        .orderBy('name')
        .snapshots();
  }

  /// Безопасный setState — не вызываем если виджет уже уничтожен
  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  @override
  Widget build(BuildContext context) {
    // Убрали BlocBuilder — он вызывал rebuild на disposed виджет.
    // Локальный стейт (_selectedCategoryId, _selectedDate) управляется сами.
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── HEADER ──────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Фильтр',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),
              if (_selectedCategoryId != null || _selectedDate != null)
                TextButton(
                  onPressed: () {
                    context.read<HomeBloc>().add(ResetAllFilters());
                    Navigator.pop(context);
                  },
                  child: const Text('Сбросить'),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // ── КАТЕГОРИИ ───────────────────────────────────────────────────────
          const Text(
            'Категория',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Выберите тип мероприятия',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),

          StreamBuilder<QuerySnapshot>(
            stream: _categoriesStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final categories = snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                data['id'] = doc.id;
                return GlobalCategory.fromJson(data);
              }).toList();

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((cat) {
                  final isSelected = _selectedCategoryId == cat.id;
                  return ChoiceChip(
                    label: Text(cat.name),
                    selected: isSelected,
                    onSelected: (_) {
                      _safeSetState(() {
                        if (isSelected) {
                          _selectedCategoryId = null;
                          _selectedDate = null;
                        } else {
                          _selectedCategoryId = cat.id;
                          _selectedDate = null;
                        }
                      });
                    },
                  );
                }).toList(),
              );
            },
          ),

          // ── ДАТА (только если выбрана категория) ────────────────────────────
          if (_selectedCategoryId != null) ...[
            const SizedBox(height: 32),
            const Text(
              'Дата',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Выберите дату для проверки доступности',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final now = DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? now,
                  firstDate: now,
                  lastDate: now.add(const Duration(days: 365)),
                );
                // mounted проверка после await!
                if (picked != null) {
                  _safeSetState(() => _selectedDate = picked);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedDate != null
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade300,
                    width: _selectedDate != null ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: _selectedDate != null
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                          ? 'Выберите дату'
                          : DateFormat('dd MMMM yyyy', 'ru')
                              .format(_selectedDate!),
                      style: TextStyle(
                        color: _selectedDate == null
                            ? Colors.grey
                            : Colors.black87,
                        fontWeight: _selectedDate != null
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      color: _selectedDate != null
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),

          // ── КНОПКИ ──────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Отмена'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedCategoryId == null
                      ? null
                      : () {
                          context.read<HomeBloc>().add(
                                ApplyCategoryAndDateFilter(
                                  globalCategoryId: _selectedCategoryId,
                                  selectedDate: _selectedDate,
                                ),
                              );
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Применить'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
