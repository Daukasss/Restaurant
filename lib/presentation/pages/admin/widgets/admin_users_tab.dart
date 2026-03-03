import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Поиск по имени или телефону',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            onChanged: (query) {
              context.read<AdminPanelBloc>().add(SearchUsersEvent(query));
            },
          ),
        ),
        Expanded(
          child: BlocConsumer<AdminPanelBloc, AdminPanelState>(
            listener: (context, state) {
              if (state is AdminPanelError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.message)),
                );
              }
            },
            builder: (context, state) {
              if (state is AdminPanelLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (state is AdminPanelLoaded) {
                if (state.filteredUsers.isEmpty) {
                  return const Center(child: Text('Пользователи не найдены'));
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    context.read<AdminPanelBloc>().add(LoadUsersEvent());
                  },
                  child: ListView.builder(
                    itemCount: state.filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = state.filteredUsers[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2),
                                child: Text(
                                  user['name']?.toString().isNotEmpty == true
                                      ? user['name'][0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name'] ?? 'Имя не указано',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      user['phone'] ?? 'Телефон не указан',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Switch(
                                    value: user['role'] == 'seller',
                                    onChanged: (value) {
                                      context.read<AdminPanelBloc>().add(
                                            ChangeRoleEvent(
                                              user['id'],
                                              user['role'] ?? 'user',
                                            ),
                                          );
                                    },
                                  ),
                                  Text(
                                    user['role'] == 'seller'
                                        ? 'Продавец'
                                        : 'Пользователь',
                                    style: TextStyle(
                                      color: user['role'] == 'seller'
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                          : Colors.grey[600],
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              }

              return const Center(child: Text('Что-то пошло не так'));
            },
          ),
        ),
      ],
    );
  }
}
