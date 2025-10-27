abstract class AbstractAuthServices {
  // Отправка OTP на номер телефона для верификации
  Future<void> sendOtp(String phone);

  // Подтверждение OTP и завершение регистрации
  Future<Map<String, dynamic>> verifyOtpAndRegister(
    String phone,
    String token,
    String password,
    String name,
  );

  // Вход по телефону и паролю
  Future<Map<String, dynamic>> signInWithPhoneAndPassword(
      String phone, String password);

  // Выход из системы
  Future<void> logout();

  // Получение текущего пользователя
  Future<Map<String, dynamic>?> getCurrentUser();

  // Проверка аутентификации
  Future<bool> isAuthenticated();
}
