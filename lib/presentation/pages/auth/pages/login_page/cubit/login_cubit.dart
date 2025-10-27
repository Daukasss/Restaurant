// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/services/abstract/abstract_auth_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../data/services/service_lacator.dart';
import 'login_state.dart' as custom_auth_state;
import 'login_state.dart';

class AuthCubit extends Bloc<AuthEvent, custom_auth_state.AuthState> {
  final AbstractAuthServices _authService;

  AuthCubit({AbstractAuthServices? authService})
      : _authService = authService ?? getIt<AbstractAuthServices>(),
        super(AuthInitial());

  // Проверка текущей сессии
  Future<void> checkCurrentSession() async {
    emit(AuthLoading());
    try {
      final userData = await _authService.getCurrentUser();
      if (userData != null && userData['user'] != null) {
        emit(AuthAuthenticated(
          userId: userData['user']['id'],
          role: userData['user']['role'] ?? 'user',
          name: userData['user']['name'] ?? '',
          phone: userData['user']['phone'] ?? '',
        ));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  // Отправка OTP на номер телефона
  Future<void> sendOtp({required String phone}) async {
    if (phone.isEmpty) {
      if (!isClosed) {
        emit(const AuthError('Пожалуйста, введите номер телефона'));
      }
      return;
    }

    if (!isClosed) emit(AuthLoading());

    try {
      await _authService.sendOtp(phone);
      if (!isClosed) emit(AuthOtpSent());
    } catch (e) {
      if (!isClosed) emit(AuthError(e.toString()));
    }
  }

  // Вход по телефону и паролю
  Future<void> signInWithPhoneAndPassword(
      {required String phone, required String password}) async {
    if (phone.isEmpty || password.isEmpty) {
      if (!isClosed) {
        emit(const AuthError('Пожалуйста, введите номер телефона и пароль'));
      }
      return;
    }

    if (!isClosed) emit(AuthLoading());

    try {
      final userData =
          await _authService.signInWithPhoneAndPassword(phone, password);

      if (!isClosed) {
        if (userData['user'] != null) {
          emit(AuthAuthenticated(
            userId: userData['user']['id'],
            role: userData['user']['role'] ?? 'user',
            name: userData['user']['name'] ?? '',
            phone: userData['user']['phone'] ?? '',
          ));
        } else {
          emit(const AuthError(
              'Не удалось войти. Проверьте номер телефона и пароль.'));
        }
      }
    } on AuthException catch (e) {
      if (!isClosed) emit(AuthError(e.message));
    } catch (e) {
      if (!isClosed) emit(AuthError('Произошла ошибка: ${e.toString()}'));
    }
  }

  // Верификация OTP и регистрация
  Future<void> verifyOtpAndRegister({
    required String phone,
    required String token,
    required String password,
    String? name,
  }) async {
    if (token.isEmpty) {
      if (!isClosed) {
        emit(const AuthError('Пожалуйста, введите код подтверждения'));
      }
      return;
    }

    if (!isClosed) emit(AuthLoading());

    try {
      final userData = await _authService.verifyOtpAndRegister(
          phone, token, password, name ?? 'User');

      if (!isClosed) {
        if (userData['user'] != null) {
          emit(AuthAuthenticated(
            userId: userData['user']['id'],
            role: userData['user']['role'] ?? 'user',
            name: userData['user']['name'] ?? '',
            phone: userData['user']['phone'] ?? '',
          ));
        } else {
          emit(const AuthError(
              'Не удалось зарегистрироваться. Попробуйте еще раз.'));
        }
      }
    } catch (e) {
      if (!isClosed) emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError('Ошибка при выходе: ${e.toString()}'));
    }
  }
}

abstract class AuthEvent {}
