import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../theme/aq_toi.dart';
import '../../../widgets/result_diolog.dart';
import '../../customer/page/profile_page/view/profile_page.dart';
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_state.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          AdminPanelBloc(supabase: supabase)..add(LoadUsersEvent()),
      child: const AdminPanelView(),
    );
  }
}

class AdminPanelView extends StatefulWidget {
  const AdminPanelView({super.key});

  @override
  State<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends State<AdminPanelView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfilePage(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'User Role',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
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
              ],
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

                  return ListView.builder(
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

                                      showResultDialog(
                                        context: context,
                                        isSuccess: true,
                                        title: 'Роль изменена',
                                        message:
                                            'Роль пользователя изменена на ${user['role'] == 'seller' ? 'пользователь' : 'продавец'}',
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
                  );
                }

                return const Center(child: Text('Что-то пошло не так'));
              },
            ),
          ),
        ],
      ),
    );
  }
}
