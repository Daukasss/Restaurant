import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'admin_event.dart';
import 'admin_state.dart';

class AdminPanelBloc extends Bloc<AdminPanelEvent, AdminPanelState> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AdminPanelBloc() : super(AdminPanelInitial()) {
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
      final querySnapshot = await _firestore
          .collection('profiles')
          .orderBy('created_at', descending: true)
          .get();

      final users = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

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

      await _firestore.collection('profiles').doc(event.userId).update({
        'role': changeRole,
        'updated_at': FieldValue.serverTimestamp(),
      });

      add(LoadUsersEvent());
    } catch (error) {
      emit(AdminPanelError('Не удалось изменить роль пользователя'));
    }
  }
}
