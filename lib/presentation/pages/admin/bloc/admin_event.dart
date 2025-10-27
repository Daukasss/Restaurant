abstract class AdminPanelEvent {}

class LoadUsersEvent extends AdminPanelEvent {}

class SearchUsersEvent extends AdminPanelEvent {
  final String query;
  SearchUsersEvent(this.query);
}

class ChangeRoleEvent extends AdminPanelEvent {
  final String userId;
  final String currentRole;
  ChangeRoleEvent(this.userId, this.currentRole);
}
