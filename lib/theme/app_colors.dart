
import 'package:flutter/material.dart';

class AppColors {
  // Color principal predeterminado de PromediUm
  static const Color primary = Color(0xFF00ACC1);

  /// Blanco o negro según el fondo, para íconos sobre un color elegido por el usuario.
  static Color contraste(Color fondo) {
    return ThemeData.estimateBrightnessForColor(fondo) == Brightness.dark
        ? Colors.white
        : Colors.black;
  }

  // Colores de fondo
  static const Color lightBackground = Color(0xFFF4F8FA);
  static const Color darkBackground = Color(0xFF12161C);

  // Colores de tarjetas
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color darkCard = Color(0xFF1E252D);
}
