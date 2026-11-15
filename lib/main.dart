import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';

// Llave global de navegación para controlar rutas sin depender del context directo
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crear y cargar las preferencias del usuario desde SharedPreferences
  final themeProvider = ThemeProvider();
  await themeProvider.loadPreferences();

  runApp(
    ChangeNotifierProvider.value(
      value: themeProvider,
      child: const PromediUmApp(),
    ),
  );
}

class PromediUmApp extends StatelessWidget {
  const PromediUmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final configuracion = context.watch<ThemeProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'PromediUm',
      debugShowCheckedModeBanner: false,
      themeMode: configuracion.themeMode,
      theme: AppTheme.build(
        brightness: Brightness.light,
        seedColor: configuracion.seedColor,
      ),
      darkTheme: AppTheme.build(
        brightness: Brightness.dark,
        seedColor: configuracion.seedColor,
      ),
      // Ruta inicial por la que arranca la app
      initialRoute: '/login',
      // Definición centralizada de rutas nombradas
      routes: {
        '/login': (context) => LoginScreen(
              onSignInWithUser: (usuario, contrasena) async {
                await Future.delayed(const Duration(seconds: 1));
                if (usuario == 'error@upana.edu.gt' || contrasena == 'error') {
                  throw Exception('wrong-password');
                }
                // Navega al dashboard limpiando el historial del login
                navigatorKey.currentState?.pushReplacementNamed('/dashboard');
              },
              onSignInWithGoogle: () async {
                await Future.delayed(const Duration(seconds: 1));
                navigatorKey.currentState?.pushReplacementNamed('/dashboard');
              },
              onSendPasswordReset: (correo) async {
                await Future.delayed(const Duration(seconds: 1));
                if (correo.contains('error') || correo.contains('noautorizado')) {
                  throw Exception('correo-no-autorizado');
                }
              },
            ),
        '/dashboard': (context) => DashboardScreen(
              onLogout: () {
                // Cierra sesión limpiando todo y volviendo al login
                navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
            ),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}