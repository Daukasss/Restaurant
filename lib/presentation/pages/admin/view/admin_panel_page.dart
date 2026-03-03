import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/presentation/pages/admin/widgets/admin_categories_tab.dart';
import 'package:restauran/presentation/pages/admin/widgets/admin_users_tab.dart'
    show AdminUsersTab;
import '../bloc/admin_bloc.dart';
import '../bloc/admin_event.dart';
import '../bloc/admin_category_bloc.dart';
import '../bloc/admin_category_event.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => AdminPanelBloc()..add(LoadUsersEvent()),
        ),
        BlocProvider(
          create: (context) =>
              AdminCategoryBloc()..add(LoadGlobalCategoriesEvent()),
        ),
      ],
      child: const AdminPanelView(),
    );
  }
}

class AdminPanelView extends StatefulWidget {
  const AdminPanelView({super.key});

  @override
  State<AdminPanelView> createState() => _AdminPanelViewState();
}

class _AdminPanelViewState extends State<AdminPanelView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ панель'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Пользователи',
            ),
            Tab(
              icon: Icon(Icons.category),
              text: 'Категории',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          AdminUsersTab(),
          AdminCategoriesTab(),
        ],
      ),
    );
  }
}
