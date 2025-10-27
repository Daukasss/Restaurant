import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthOtpSent extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String role;
  final String name;
  final String phone;

  const AuthAuthenticated({
    required this.userId,
    required this.role,
    required this.name,
    required this.phone,
  });

  @override
  List<Object?> get props => [userId, role, name, phone];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
