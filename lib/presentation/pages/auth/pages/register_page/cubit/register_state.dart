part of 'register_cubit.dart';

sealed class RegisterState extends Equatable {
  const RegisterState();

  @override
  List<Object> get props => [];
}

final class RegisterInitial extends RegisterState {}

final class RegisterLoading extends RegisterState {}

final class RegisterOtpSent extends RegisterState {}

final class RegisterSuccess extends RegisterState {
  final String message;

  const RegisterSuccess(this.message);

  @override
  List<Object> get props => [message];
}

final class RegisterError extends RegisterState {
  final String error;

  const RegisterError(this.error);

  @override
  List<Object> get props => [error];
}
