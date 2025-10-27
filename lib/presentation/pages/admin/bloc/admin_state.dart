abstract class AdminPanelState {}

class AdminPanelInitial extends AdminPanelState {}

class AdminPanelLoading extends AdminPanelState {}

class AdminPanelLoaded extends AdminPanelState {
  final List<Map<String, dynamic>> users;
  final List<Map<String, dynamic>> filteredUsers;
  final String searchQuery;

  AdminPanelLoaded({
    required this.users,
    required this.filteredUsers,
    this.searchQuery = '',
  });

  AdminPanelLoaded copyWith({
    List<Map<String, dynamic>>? users,
    List<Map<String, dynamic>>? filteredUsers,
    String? searchQuery,
  }) {
    return AdminPanelLoaded(
      users: users ?? this.users,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class AdminPanelError extends AdminPanelState {
  final String message;
  AdminPanelError(this.message);
}
