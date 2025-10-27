import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Если пользователь стирает всё — оставляем +7
    if (text.isEmpty || text == '+') {
      return const TextEditingValue(
        text: '+7 ',
        selection: TextSelection.collapsed(offset: 3),
      );
    }

    // Убираем всё кроме цифр
    String digitsOnly = text.replaceAll(RegExp(r'[^\d]'), '');

    // Всегда начинаем с 7
    if (!digitsOnly.startsWith('7')) {
      digitsOnly = '7$digitsOnly';
    }

    // Ограничиваем длину 11 цифр после +7
    if (digitsOnly.length > 11) {
      digitsOnly = digitsOnly.substring(0, 11);
    }

    // Формат: +7 777 777 77 77
    String formatted = '+7';
    if (digitsOnly.length > 1) {
      formatted += ' ${digitsOnly.substring(1, digitsOnly.length.clamp(1, 4))}';
    }
    if (digitsOnly.length > 4) {
      formatted += ' ${digitsOnly.substring(4, digitsOnly.length.clamp(4, 7))}';
    }
    if (digitsOnly.length > 7) {
      formatted += ' ${digitsOnly.substring(7, digitsOnly.length.clamp(7, 9))}';
    }
    if (digitsOnly.length > 9) {
      formatted += ' ${digitsOnly.substring(9)}';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
