// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/data/services/abstract/abstract_auth_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../data/services/service_lacator.dart';
import 'auth_state.dart' as my_auth;

class AuthCubit extends Bloc<AuthEvent, my_auth.AuthState> {
  final AbstractAuthServices _authService;

  AuthCubit({AbstractAuthServices? authService})
      : _authService = authService ?? getIt<AbstractAuthServices>(),
        super(my_auth.AuthInitial());

  // Проверка текущей сессии
  Future<void> checkCurrentSession() async {
    emit(my_auth.AuthLoading());
    try {
      final userData = await _authService.getCurrentUser();
      if (userData != null && userData['user'] != null) {
        emit(my_auth.AuthAuthenticated(
          userId: userData['user']['id'],
          role: userData['user']['role'] ?? 'user',
          name: userData['user']['name'] ?? '',
          phone: userData['user']['phone'] ?? '',
        ));
      } else {
        emit(my_auth.AuthUnauthenticated());
      }
    } catch (e) {
      emit(my_auth.AuthUnauthenticated());
    }
  }

  // Отправка OTP
  Future<void> sendOtp({required String phone}) async {
    if (phone.isEmpty) {
      if (!isClosed) {
        emit(const my_auth.AuthError('Пожалуйста, введите номер телефона'));
      }
      return;
    }

    if (!isClosed) emit(my_auth.AuthLoading());

    try {
      await _authService.sendOtp(phone);
      if (!isClosed) emit(my_auth.AuthOtpSent());
    } catch (e) {
      if (!isClosed) emit(my_auth.AuthError(e.toString()));
    }
  }

  // Вход по телефону и паролю
  Future<void> signInWithPhoneAndPassword(
      {required String phone, required String password}) async {
    if (phone.isEmpty || password.isEmpty) {
      if (!isClosed) {
        emit(const my_auth.AuthError(
            'Пожалуйста, введите номер телефона и пароль'));
      }
      return;
    }

    if (!isClosed) emit(my_auth.AuthLoading());

    try {
      final userData =
          await _authService.signInWithPhoneAndPassword(phone, password);

      if (!isClosed) {
        if (userData['user'] != null) {
          emit(my_auth.AuthAuthenticated(
            userId: userData['user']['id'],
            role: userData['user']['role'] ?? 'user',
            name: userData['user']['name'] ?? '',
            phone: userData['user']['phone'] ?? '',
          ));
        } else {
          emit(const my_auth.AuthError(
              'Не удалось войти. Проверьте номер телефона и пароль.'));
        }
      }
    } on AuthException catch (e) {
      if (!isClosed) emit(my_auth.AuthError(e.message));
    } catch (e) {
      if (!isClosed) {
        emit(my_auth.AuthError('Произошла ошибка: ${e.toString()}'));
      }
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
        emit(const my_auth.AuthError('Пожалуйста, введите код подтверждения'));
      }
      return;
    }

    if (!isClosed) emit(my_auth.AuthLoading());

    try {
      final userData = await _authService.verifyOtpAndRegister(
          phone, token, password, name ?? 'User');

      if (!isClosed) {
        if (userData['user'] != null) {
          emit(my_auth.AuthAuthenticated(
            userId: userData['user']['id'],
            role: userData['user']['role'] ?? 'user',
            name: userData['user']['name'] ?? '',
            phone: userData['user']['phone'] ?? '',
          ));
        } else {
          emit(const my_auth.AuthError(
              'Не удалось зарегистрироваться. Попробуйте еще раз.'));
        }
      }
    } catch (e) {
      if (!isClosed) emit(my_auth.AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      emit(my_auth.AuthUnauthenticated());
    } catch (e) {
      emit(my_auth.AuthError('Ошибка при выходе: ${e.toString()}'));
    }
  }
}

abstract class AuthEvent {}
