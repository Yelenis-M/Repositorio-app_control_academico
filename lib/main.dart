import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/login_screen.dart';
import 'theme/theme_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Crear y cargar las preferencias del usuario
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
      title: 'PromediUm',
      debugShowCheckedModeBanner: false,

      // Modo de apariencia seleccionado
      themeMode: configuracion.themeMode,

      // Tema claro
      theme: AppTheme.build(
        brightness: Brightness.light,
        seedColor: configuracion.seedColor,
      ),

      // Tema oscuro
      darkTheme: AppTheme.build(
        brightness: Brightness.dark,
        seedColor: configuracion.seedColor,
      ),

      home: LoginScreen(
        // Login con usuario + contraseña (NO correo)
        onSignInWithUser: (usuario, contrasena) async {
          await Future.delayed(const Duration(seconds: 1));

          // Simulación de credenciales inválidas
          if (usuario == 'error') {
            throw Exception('credenciales-invalidas');
          }

          debugPrint(
            'Simulacion: Inicio de sesion exitoso con usuario "$usuario"',
          );
        },

        onSignInWithGoogle: () async {
          await Future.delayed(const Duration(seconds: 1));
          debugPrint(
            'Simulacion: Inicio de sesion con Google exitoso',
          );
        },

        // Recuperación: aquí SÍ se usa el correo autorizado
        onSendPasswordReset: (correo) async {
          await Future.delayed(const Duration(seconds: 1));

          // Si el correo contiene "error" o "noautorizado", simulamos que no está en la BD
          if (correo.contains('error') || correo.contains('noautorizado')) {
            throw Exception('correo-no-autorizado');
          }

          debugPrint(
            'Simulacion: Correo de recuperacion enviado a $correo',
          );
        },
      ),
    );
  }
}