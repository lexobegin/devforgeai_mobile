// lib/core/theme/app_theme.dart
//
// Tema visual de DevForge AI Mobile.
//
// - Modo oscuro por defecto (coherente con el frontend web).
// - Modo claro disponible.
// - Colores, tipografías, radios y sombras unificados.

import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTheme {
  const AppTheme._();

  // ==================================================================
  // Radios y espaciados comunes
  // ==================================================================
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;

  // ==================================================================
  // Tema oscuro (por defecto)
  // ==================================================================
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: AppColors.brand500,
      onPrimary: Colors.white,
      primaryContainer: AppColors.brand700,
      onPrimaryContainer: AppColors.brand100,
      secondary: AppColors.brand400,
      onSecondary: Colors.white,
      surface: AppColors.surface900,
      onSurface: AppColors.surface100,
      surfaceContainerHighest: AppColors.surface800,
      surfaceContainerHigh: AppColors.surface800,
      surfaceContainer: AppColors.surface900,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.surface700,
      outlineVariant: AppColors.surface800,
    );

    return _baseTheme(scheme, brightness: Brightness.dark);
  }

  // ==================================================================
  // Tema claro
  // ==================================================================
  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: AppColors.brand600,
      onPrimary: Colors.white,
      primaryContainer: AppColors.brand100,
      onPrimaryContainer: AppColors.brand900,
      secondary: AppColors.brand500,
      onSecondary: Colors.white,
      surface: AppColors.surface50,
      onSurface: AppColors.surface900,
      surfaceContainerHighest: AppColors.surface100,
      surfaceContainerHigh: AppColors.surface100,
      surfaceContainer: AppColors.surface50,
      error: AppColors.danger,
      onError: Colors.white,
      outline: AppColors.surface300,
      outlineVariant: AppColors.surface200,
    );

    return _baseTheme(scheme, brightness: Brightness.light);
  }

  // ==================================================================
  // Tema base compartido
  // ==================================================================
  static ThemeData _baseTheme(
    ColorScheme scheme, {
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppColors.surface950 : scheme.surface,

      // ----------------------------------------------------------------
      // AppBar
      // ----------------------------------------------------------------
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppColors.surface900 : scheme.surface,
        foregroundColor: isDark
            ? AppColors.surface100
            : AppColors.surface900,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: isDark ? AppColors.surface100 : AppColors.surface900,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ----------------------------------------------------------------
      // Cards
      // ----------------------------------------------------------------
      cardTheme: CardThemeData(
        color: isDark ? AppColors.surface900 : Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: BorderSide(
            color: isDark ? AppColors.surface800 : AppColors.surface200,
          ),
        ),
        margin: EdgeInsets.zero,
      ),

      // ----------------------------------------------------------------
      // Inputs
      // ----------------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surface800 : AppColors.surface100,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.surface700 : AppColors.surface300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide(
            color: isDark ? AppColors.surface700 : AppColors.surface300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(
            color: AppColors.brand500,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(
            color: AppColors.danger,
            width: 1.5,
          ),
        ),
        labelStyle: TextStyle(
          color: isDark ? AppColors.surface400 : AppColors.surface600,
        ),
        hintStyle: TextStyle(
          color: isDark ? AppColors.surface500 : AppColors.surface400,
        ),
      ),

      // ----------------------------------------------------------------
      // Botones
      // ----------------------------------------------------------------
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brand600,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand400,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark
              ? AppColors.surface100
              : AppColors.surface800,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          side: BorderSide(
            color: isDark ? AppColors.surface700 : AppColors.surface300,
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // ----------------------------------------------------------------
      // Floating Action Button
      // ----------------------------------------------------------------
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand600,
        foregroundColor: Colors.white,
        elevation: 2,
      ),

      // ----------------------------------------------------------------
      // Dialogs
      // ----------------------------------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.surface900 : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        titleTextStyle: TextStyle(
          color: isDark ? AppColors.surface100 : AppColors.surface900,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // ----------------------------------------------------------------
      // Bottom Sheet
      // ----------------------------------------------------------------
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppColors.surface900 : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(radiusLg),
          ),
        ),
        modalBackgroundColor: isDark ? AppColors.surface900 : Colors.white,
      ),

      // ----------------------------------------------------------------
      // Snackbar
      // ----------------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.surface800 : AppColors.surface900,
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),

      // ----------------------------------------------------------------
      // Divider
      // ----------------------------------------------------------------
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.surface800 : AppColors.surface200,
        thickness: 1,
        space: 1,
      ),

      // ----------------------------------------------------------------
      // Tabs
      // ----------------------------------------------------------------
      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? AppColors.brand300 : AppColors.brand700,
        unselectedLabelColor:
            isDark ? AppColors.surface400 : AppColors.surface600,
        indicatorColor: AppColors.brand500,
        indicatorSize: TabBarIndicatorSize.tab,
      ),

      // ----------------------------------------------------------------
      // ListTile
      // ----------------------------------------------------------------
      listTileTheme: ListTileThemeData(
        iconColor: isDark ? AppColors.surface400 : AppColors.surface600,
        textColor: isDark ? AppColors.surface100 : AppColors.surface900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMd),
        ),
      ),
    );
  }
}