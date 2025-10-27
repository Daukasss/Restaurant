import 'package:flutter/material.dart';
import 'package:restauran/data/services/abstract/abstract_auth_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService implements AbstractAuthServices {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  @override
  Future<void> sendOtp(String phone) async {
    try {
      // Форматируем номер телефона
      final formattedPhone = _formatPhoneNumber(phone);

      // Отправляем OTP на номер телефона
      await _supabase.auth.signInWithOtp(
        phone: formattedPhone,
      );
    } on AuthException catch (e) {
      debugPrint('Ошибка отправки кода: ${e.message}');

      throw Exception('Ошибка отправки кода: ${e.message}');
    } catch (e) {
      debugPrint('Ошибка отправки кода: $e');
      throw Exception('Ошибка отправки кода: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> verifyOtpAndRegister(
      String phone, String token, String password, String name) async {
    try {
      // Форматируем номер телефона
      final formattedPhone = _formatPhoneNumber(phone);

      // Проверяем, существует ли уже пользователь с таким телефоном
      final existingUser = await _supabase
          .from('profiles')
          .select('phone')
          .eq('phone', formattedPhone)
          .maybeSingle();

      if (existingUser != null) {
        throw Exception('Пользователь с таким номером телефона уже существует');
      }

      // Проверяем OTP
      final otpResponse = await _supabase.auth.verifyOTP(
        phone: formattedPhone,
        token: token,
        type: OtpType.sms,
      );

      if (otpResponse.user == null) {
        throw Exception('Неверный код подтверждения');
      }

      // Создаем пользователя с паролем
      // Примечание: Supabase не позволяет напрямую установить пароль при верификации OTP
      // Поэтому нам нужно сначала верифицировать OTP, а затем обновить пароль

      // Обновляем пароль пользователя
      await _supabase.auth.updateUser(
        UserAttributes(
          password: password,
        ),
      );

      // Создаем профиль пользователя
      try {
        await _supabase.from('profiles').insert({
          'id': otpResponse.user!.id,
          'name': name,
          'phone': formattedPhone,
          'role': 'user',
          'created_at': DateTime.now().toIso8601String(),
        });
      } catch (profileError) {
        debugPrint('Ошибка создания профиля: $profileError');
        throw Exception('Ошибка создания профиля: $profileError');
      }

      return {
        'user': {
          'id': otpResponse.user!.id,
          'name': name,
          'phone': _displayPhoneNumber(formattedPhone),
          'role': 'user',
        }
      };
    } on AuthException catch (e) {
      debugPrint('Ошибка регистрации: ${e.message}');
      throw Exception('Ошибка регистрации: ${e.message}');
    } catch (e) {
      debugPrint('Ошибка регистрации: $e');
      throw Exception('Ошибка регистрации: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> signInWithPhoneAndPassword(
      String phone, String password) async {
    try {
      // Форматируем номер телефона
      final formattedPhone = _formatPhoneNumber(phone);

      // Входим с телефоном и паролем
      final response = await _supabase.auth.signInWithPassword(
        phone: formattedPhone,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Неверный телефон или пароль');
      }

      // Получаем профиль пользователя
      final profileResponse = await _supabase
          .from("profiles")
          .select('id, name, phone, created_at, role')
          .eq('id', response.user!.id)
          .single();

      return {
        'user': {
          'id': response.user!.id,
          'name': profileResponse['name'],
          'phone': _displayPhoneNumber(profileResponse['phone']),
          'role': profileResponse['role'],
        }
      };
    } on AuthException catch (e) {
      throw Exception('Ошибка входа: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка входа: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;

      if (user == null) {
        return null;
      }

      final profileResponse = await _supabase
          .from("profiles")
          .select('id, name, phone, created_at, role')
          .eq('id', user.id)
          .single();

      return {
        'user': {
          'id': user.id,
          'name': profileResponse['name'],
          'phone': _displayPhoneNumber(profileResponse['phone']),
          'role': profileResponse['role'],
        }
      };
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _supabase.auth.currentUser != null;
  }

  // Вспомогательный метод для форматирования номера телефона
  String _formatPhoneNumber(String phone) {
    // Удаляем все нецифровые символы кроме +
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Проверяем, начинается ли номер с +
    if (!cleaned.startsWith('+')) {
      // Если номер начинается с 8 или 7, заменяем на +7 (для России/Казахстана)
      if (cleaned.startsWith('8') || cleaned.startsWith('7')) {
        cleaned = '+7${cleaned.substring(1)}';
      } else {
        // Иначе добавляем +7 по умолчанию
        cleaned = '+7$cleaned';
      }
    }

    return cleaned;
  }

  // Дополнительный метод для отображения номера в красивом формате
  String _displayPhoneNumber(String phone) {
    final cleaned = _formatPhoneNumber(phone);

    // Форматируем для отображения: +7 999 123 45 67
    if (cleaned.startsWith('+7') && cleaned.length == 12) {
      return '+7 ${cleaned.substring(2, 5)} ${cleaned.substring(5, 8)} ${cleaned.substring(8, 10)} ${cleaned.substring(10)}';
    }

    return cleaned;
  }
}
