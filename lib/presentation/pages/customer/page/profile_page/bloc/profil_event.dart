import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserData extends ProfileEvent {}

class UpdateProfile extends ProfileEvent {
  final String name;
  final String phone;

  const UpdateProfile({
    required this.name,
    required this.phone,
  });

  @override
  List<Object?> get props => [name, phone];
}

class SignOut extends ProfileEvent {}

class ResetUpdateStatus extends ProfileEvent {}
