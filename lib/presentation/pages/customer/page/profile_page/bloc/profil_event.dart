abstract class ProfileEvent {}

class LoadUserData extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final String name;
  final String phone;

  UpdateProfile({required this.name, required this.phone});
}

class ResetUpdateStatus extends ProfileEvent {}

class SignOut extends ProfileEvent {}
