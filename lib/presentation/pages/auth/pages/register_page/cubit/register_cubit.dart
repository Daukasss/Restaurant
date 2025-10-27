import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../../../../data/services/abstract/abstract_auth_services.dart';

part 'register_state.dart';

class RegisterCubit extends Cubit<RegisterState> {
  final AbstractAuthServices _authService;
  RegisterCubit(this._authService) : super(RegisterInitial());

  // Отправка OTP на номер телефона
  Future<void> sendOtp({required String phone}) async {
    if (phone.isEmpty) {
      emit(const RegisterError('Пожалуйста, введите номер телефона'));
      return;
    }

    emit(RegisterLoading());
    try {
      await _authService.sendOtp(phone);
      emit(RegisterOtpSent());
    } catch (e) {
      emit(RegisterError(e.toString()));
    }
  }
}
