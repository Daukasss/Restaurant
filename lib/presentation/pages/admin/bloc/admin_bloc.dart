import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase/supabase.dart';

import 'admin_event.dart';
import 'admin_state.dart';

class AdminPanelBloc extends Bloc<AdminPanelEvent, AdminPanelState> {
  final SupabaseClient supabase;

  AdminPanelBloc({required this.supabase}) : super(AdminPanelInitial()) {
    on<LoadUsersEvent>(_onLoadUsers);
    on<SearchUsersEvent>(_onSearchUsers);
    on<ChangeRoleEvent>(_onChangeRole);
  }

  Future<void> _onLoadUsers(
    LoadUsersEvent event,
    Emitter<AdminPanelState> emit,
  ) async {
    emit(AdminPanelLoading());

    try {
      final response = await supabase
          .from('profiles')
          .select('id, name, phone, role, created_at')
          .order('created_at', ascending: false);

      final users = List<Map<String, dynamic>>.from(response);

      emit(AdminPanelLoaded(
        users: users,
        filteredUsers: users,
      ));
    } catch (error) {
      emit(AdminPanelError('Не удалось загрузить пользователей'));
    }
  }

  void _onSearchUsers(
    SearchUsersEvent event,
    Emitter<AdminPanelState> emit,
  ) {
    if (state is AdminPanelLoaded) {
      final currentState = state as AdminPanelLoaded;
      final query = event.query;

      final filteredUsers = currentState.users.where((user) {
        final name = user['name']?.toLowerCase() ?? '';
        final phone = user['phone']?.toLowerCase() ?? '';
        return name.contains(query.toLowerCase()) ||
            phone.contains(query.toLowerCase());
      }).toList();

      emit(currentState.copyWith(
        filteredUsers: filteredUsers,
        searchQuery: query,
      ));
    }
  }

  Future<void> _onChangeRole(
    ChangeRoleEvent event,
    Emitter<AdminPanelState> emit,
  ) async {
    try {
      final changeRole = event.currentRole == 'seller' ? 'user' : 'seller';

      await supabase
          .from('profiles')
          .update({'role': changeRole}).eq('id', event.userId);

      add(LoadUsersEvent());
    } catch (error) {
      emit(AdminPanelError('Не удалось изменить роль пользователя'));
    }
  }
}
