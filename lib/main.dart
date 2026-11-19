import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'data/datos_academicos_mock.dart';
import 'firebase_options.dart';
import 'screens/academico/semestre_view.dart';
import 'screens/dashboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

// Llave global de navegación para controlar rutas sin depender del context directo
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inicializar Firebase y activar caché offline ilimitado
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // 2. Cargar preferencias de apariencia (SharedPreferences)
  final themeProvider = ThemeProvider();
  await themeProvider.loadPreferences();

  // 3. Auto-Login (funciona incluso sin internet desde caché local)
  final authService = AuthService();
  final datosAcademicos = DatosAcademicosMock();
  final usuarioActivo = await authService.verificarSesionActiva();
  if (usuarioActivo != null) {
    await datosAcademicos.cargarDatosUsuario(usuarioActivo);
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: datosAcademicos),
      ],
      child: PromediUmApp(
        initialRoute: usuarioActivo != null ? '/dashboard' : '/login',
      ),
    ),
  );
}

class PromediUmApp extends StatelessWidget {
  const PromediUmApp({
    super.key,
    this.initialRoute = '/login',
  });

  final String initialRoute;

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
      builder: (context, child) {
        final esOscuro = Theme.of(context).brightness == Brightness.dark;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: esOscuro
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark,
          child: child ?? const SizedBox.shrink(),
        );
      },
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => LoginScreen(
              onSignInWithUser: (usuario, contrasena) async {
                final auth = AuthService();
                final datos = context.read<DatosAcademicosMock>();
                final usuarioLogueado = await auth.login(usuario, contrasena);
                await datos.cargarDatosUsuario(usuarioLogueado);
                navigatorKey.currentState?.pushReplacementNamed('/dashboard');
              },
              onSignInWithGoogle: () async {
                final auth = AuthService();
                final datos = context.read<DatosAcademicosMock>();
                final usuarioLogueado = await auth.loginConGoogle();
                if (usuarioLogueado == null) return; // Cerró ventana de Google
                await datos.cargarDatosUsuario(usuarioLogueado);
                navigatorKey.currentState?.pushReplacementNamed('/dashboard');
              },
              onSendPasswordReset: (correo) async {
                await AuthService().enviarCorreoRecuperacion(correo);
              },
            ),
        '/dashboard': (context) => DashboardScreen(
              onLogout: () async {
                final datos = context.read<DatosAcademicosMock>();
                await AuthService().logout();
                datos.limpiarSesion();
                navigatorKey.currentState?.pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              onOpenSemester: (semestre, bloqueado) {
                navigatorKey.currentState?.pushNamed(
                  '/semestre',
                  arguments: {
                    'semestre': semestre,
                    'bloqueado': bloqueado,
                  },
                );
              },
            ),
        '/settings': (context) => const SettingsScreen(),
        '/semestre': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          final int numeroSemestre = args?['semestre'] ?? 1;
          final bool esBloqueado = args?['bloqueado'] ?? false;

          return SemestreView(
            numeroSemestre: numeroSemestre,
            esBloqueado: esBloqueado,
          );
        },
      },
    );
  }
}