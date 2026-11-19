
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

class ThemeProvider extends ChangeNotifier {
  // Preferencias predeterminadas
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = AppColors.primary;
  bool _showGrid = true;

  // Obtener las preferencias actuales
  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  bool get showGrid => _showGrid;

  // Cargar preferencias guardadas
  Future<void> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final modoGuardado = prefs.getString('themeMode');
    final colorGuardado = prefs.getInt('seedColor');

    _themeMode = ThemeMode.values.firstWhere(
      (modo) => modo.name == modoGuardado,
      orElse: () => ThemeMode.system,
    );

    if (colorGuardado != null) {
      _seedColor = Color(colorGuardado);
    }

    _showGrid = prefs.getBool('showGrid') ?? true;

    notifyListeners();
  }

  // Cambiar modo claro, oscuro o automático
  Future<void> setThemeMode(ThemeMode modo) async {
    _themeMode = modo;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', modo.name);
  }

  // Cambiar color principal
  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('seedColor', color.toARGB32());
  }

  // Activar o desactivar cuadrícula
  Future<void> setShowGrid(bool mostrar) async {
    _showGrid = mostrar;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showGrid', mostrar);
  }

  // Restaurar preferencias predeterminadas
  Future<void> resetPreferences() async {
    _themeMode = ThemeMode.system;
    _seedColor = AppColors.primary;
    _showGrid = true;

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('themeMode');
    await prefs.remove('seedColor');
    await prefs.remove('showGrid');
  }
}