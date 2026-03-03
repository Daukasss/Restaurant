import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:restauran/data/services/abstract/abstract_auth_services.dart';

class AuthService implements AbstractAuthServices {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // Храним verificationId для OTP
  String? _verificationId;

  AuthService(this._auth, this._firestore);

  @override
  Future<void> sendOtp(String phone) async {
    try {
      // Форматируем номер телефона
      final formattedPhone = _formatPhoneNumber(phone);

      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Автоматическая верификация (на Android)
          debugPrint('Автоматическая верификация завершена');
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint('Ошибка верификации: ${e.message}');
          throw Exception('Ошибка отправки кода: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          // Сохраняем verificationId для последующей проверки
          _verificationId = verificationId;
          debugPrint('Код отправлен, verificationId: $verificationId');
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
          debugPrint('Таймаут автоматического получения');
        },
        timeout: const Duration(seconds: 60),
      );
    } on FirebaseAuthException catch (e) {
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

      if (_verificationId == null) {
        throw Exception('Сначала отправьте код подтверждения');
      }

      // Создаем credentials с OTP кодом
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: token,
      );

      // Входим с помощью phone credential
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('Неверный код подтверждения');
      }

      final user = userCredential.user!;

      // ✅ ИСПРАВЛЕНИЕ: Проверяем существование профиля ПОСЛЕ аутентификации
      final existingProfile =
          await _firestore.collection('profiles').doc(user.uid).get();

      if (existingProfile.exists) {
        // Профиль уже существует, возвращаем данные
        final profileData = existingProfile.data()!;
        return {
          'user': {
            'id': user.uid,
            'name': profileData['name'],
            'phone': _displayPhoneNumber(profileData['phone']),
            'role': profileData['role'],
          }
        };
      }

      // Создаем временный email на основе номера телефона
      final tempEmail =
          '${formattedPhone.replaceAll('+', '').replaceAll(' ', '')}@phone.auth';

      try {
        // Связываем аккаунт с email/password
        final emailCredential = EmailAuthProvider.credential(
          email: tempEmail,
          password: password,
        );
        await user.linkWithCredential(emailCredential);
      } catch (linkError) {
        debugPrint('Ошибка связывания с email: $linkError');
        // Продолжаем даже если не удалось связать
      }

      // Создаем профиль пользователя в Firestore
      try {
        await _firestore.collection('profiles').doc(user.uid).set({
          'id': user.uid,
          'name': name,
          'phone': formattedPhone,
          'email': tempEmail,
          'role': 'user',
          'created_at': FieldValue.serverTimestamp(),
        });
      } catch (profileError) {
        debugPrint('Ошибка создания профиля: $profileError');
        // Удаляем пользователя если не удалось создать профиль
        await user.delete();
        throw Exception('Ошибка создания профиля: $profileError');
      }

      return {
        'user': {
          'id': user.uid,
          'name': name,
          'phone': _displayPhoneNumber(formattedPhone),
          'role': 'user',
        }
      };
    } on FirebaseAuthException catch (e) {
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

      // Создаем email на основе номера телефона
      final tempEmail =
          '${formattedPhone.replaceAll('+', '').replaceAll(' ', '')}@phone.auth';

      // Входим с email и паролем
      final UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(
        email: tempEmail,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Неверный телефон или пароль');
      }

      final user = userCredential.user!;

      // Получаем профиль пользователя из Firestore
      final profileDoc =
          await _firestore.collection('profiles').doc(user.uid).get();

      if (!profileDoc.exists) {
        throw Exception('Профиль пользователя не найден');
      }

      final profileData = profileDoc.data()!;

      return {
        'user': {
          'id': user.uid,
          'name': profileData['name'],
          'phone': _displayPhoneNumber(profileData['phone']),
          'role': profileData['role'],
        }
      };
    } on FirebaseAuthException catch (e) {
      debugPrint('Ошибка входа: ${e.message}');
      throw Exception('Ошибка входа: ${e.message}');
    } catch (e) {
      debugPrint('Ошибка входа: $e');
      throw Exception('Ошибка входа: $e');
    }
  }

  @override
  Future<void> logout() async {
    await _auth.signOut();
  }

  @override
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return null;
      }

      // Получаем профиль из Firestore
      final profileDoc =
          await _firestore.collection('profiles').doc(user.uid).get();

      if (!profileDoc.exists) {
        return null;
      }

      final profileData = profileDoc.data()!;

      return {
        'user': {
          'id': user.uid,
          'name': profileData['name'],
          'phone': _displayPhoneNumber(profileData['phone']),
          'role': profileData['role'],
        }
      };
    } catch (e) {
      debugPrint('Ошибка получения текущего пользователя: $e');
      return null;
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    return _auth.currentUser != null;
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
