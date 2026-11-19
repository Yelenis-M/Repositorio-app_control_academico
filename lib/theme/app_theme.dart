import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData build({
    required Brightness brightness,
    required Color seedColor,
  }) {
    final esOscuro = brightness == Brightness.dark;

    // Generar una paleta adaptada al modo claro u oscuro.
    final esquemaBase = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    // Mantener el color seleccionado como color principal.
    final esquema = esquemaBase.copyWith(
      primary: seedColor,
      onPrimary:
          ThemeData.estimateBrightnessForColor(seedColor) ==
                  Brightness.dark
              ? Colors.white
              : Colors.black,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      brightness: brightness,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: esOscuro
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      
      // 👇 Configuración global del AppBar y la barra de estado del sistema
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: esOscuro
            ? SystemUiOverlayStyle.light // Iconos blancos para la barra de estado en modo oscuro
            : SystemUiOverlayStyle.dark,  // Iconos oscuros para la barra de estado en modo claro
      ),
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
          backgroundColor: esquema.primary,
          foregroundColor: esquema.onPrimary,
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

      // Personalizar los interruptores.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return esquema.onPrimary;
          }
          return esquema.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return esquema.primary;
          }
          return esquema.surfaceContainerHighest;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return esquema.primary;
          }
          return esquema.outline;
        }),
      ),
    );
  }
}