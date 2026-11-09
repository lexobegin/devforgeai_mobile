// lib/core/theme/app_colors.dart
//
// Paleta de colores de DevForge AI Mobile.
//
// Coherente con el frontend web (React + Tailwind):
//   - `brand`: azul/indigo principal.
//   - `surface`: grises para fondos, textos y bordes.
//   - Colores semánticos: success, warning, danger, info.

import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // ==================================================================
  // Brand (indigo)
  // ==================================================================
  static const Color brand50 = Color(0xFFEEF2FF);
  static const Color brand100 = Color(0xFFE0E7FF);
  static const Color brand200 = Color(0xFFC7D2FE);
  static const Color brand300 = Color(0xFFA5B4FC);
  static const Color brand400 = Color(0xFF818CF8);
  static const Color brand500 = Color(0xFF6366F1);
  static const Color brand600 = Color(0xFF4F46E5);
  static const Color brand700 = Color(0xFF4338CA);
  static const Color brand800 = Color(0xFF3730A3);
  static const Color brand900 = Color(0xFF312E81);

  // ==================================================================
  // Surface (slate)
  // ==================================================================
  static const Color surface50 = Color(0xFFF8FAFC);
  static const Color surface100 = Color(0xFFF1F5F9);
  static const Color surface200 = Color(0xFFE2E8F0);
  static const Color surface300 = Color(0xFFCBD5E1);
  static const Color surface400 = Color(0xFF94A3B8);
  static const Color surface500 = Color(0xFF64748B);
  static const Color surface600 = Color(0xFF475569);
  static const Color surface700 = Color(0xFF334155);
  static const Color surface800 = Color(0xFF1E293B);
  static const Color surface900 = Color(0xFF0F172A);
  static const Color surface950 = Color(0xFF020617);

  // ==================================================================
  // Semánticos
  // ==================================================================
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFF34D399);
  static const Color successDark = Color(0xFF059669);

  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFBBF24);
  static const Color warningDark = Color(0xFFD97706);

  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFF87171);
  static const Color dangerDark = Color(0xFFDC2626);

  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFF60A5FA);
  static const Color infoDark = Color(0xFF2563EB);

  // ==================================================================
  // Paleta de colaboradores (mismos colores que el frontend web)
  // ==================================================================
  static const List<Color> colaboradores = [
    Color(0xFFF87171), // red
    Color(0xFFFB923C), // orange
    Color(0xFFFACC15), // yellow
    Color(0xFF4ADE80), // green
    Color(0xFF22D3EE), // cyan
    Color(0xFF60A5FA), // blue
    Color(0xFFA78BFA), // violet
    Color(0xFFF472B6), // pink
  ];

  /// Devuelve un color estable para un id de usuario.
  static Color colorPorId(String id) {
    return colaboradores[id.hashCode.abs() % colaboradores.length];
  }
}