
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData build({
    required Brightness brightness,
    required Color seedColor,
  }) {
    final esOscuro = brightness == Brightness.dark;

    final esquema = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.expressive,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      brightness: brightness,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: esOscuro
          ? AppColors.darkBackground
          : AppColors.lightBackground,
    );

    final borde = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: esquema.outlineVariant,
      ),
    );

    return base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: esquema.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: borde,
        enabledBorder: borde,
        focusedBorder: borde.copyWith(
          borderSide: BorderSide(
            color: esquema.primary,
            width: 1.6,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: esquema.outline,
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
