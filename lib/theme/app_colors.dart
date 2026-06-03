import 'package:flutter/material.dart';

/// Единая палитра приложения.
/// Используется во всех экранах формы создания/редактирования ресторана.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1A365D);
  static const Color primaryLight = Color(0xFF2A4A7F);
  static const Color accent = Color(0xFF4A90D9);
  static const Color surface = Color(0xFFF7F9FC);
  static const Color cardBg = Colors.white;
  static const Color textMain = Color(0xFF1A2535);
  static const Color textSub = Color(0xFF6B7A92);
  static const Color divider = Color(0xFFE8EDF5);
  static const Color danger = Color(0xFFE53E3E);
  static const Color success = Color(0xFF38A169);

  /// Мягкая тень для карточек.
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: primary.withOpacity(0.06),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
