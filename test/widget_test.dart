// test/widget_test.dart
import 'package:app_control_academico/main.dart';
import 'package:app_control_academico/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Necesario si ThemeProvider usa SharedPreferences
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('La vista de acceso muestra los elementos principales',
      (tester) async {
    // Cargamos la app
    await tester.pumpWidget(const PromediUmApp());
    await tester.pumpAndSettle();

    // Título principal
    expect(find.text('Iniciar sesión'), findsOneWidget);

    // Campos y botón de ingreso
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Contraseña'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);

    // Enlace de recuperación
    expect(find.text('¿Olvidaste tu contraseña?'), findsOneWidget);
  });

  testWidgets('Validación: usuario y contraseña vacíos muestran error',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onSignInWithUser: (usuario, contrasena) async {},
          onSignInWithGoogle: () async {},
          onSendPasswordReset: (correo) async {},
        ),
      ),
    );

    // Toca "Ingresar" sin llenar nada
    await tester.tap(find.text('Ingresar'));
    await tester.pump();

    expect(find.text('Escribe tu usuario.'), findsOneWidget);
    expect(find.text('Escribe tu contraseña.'), findsOneWidget);
  });

  testWidgets('Recuperación: correo no autorizado muestra mensaje',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          onSignInWithUser: (usuario, contrasena) async {},
          onSignInWithGoogle: () async {},
          onSendPasswordReset: (correo) async {
            throw Exception('correo-no-autorizado');
          },
        ),
      ),
    );

    // Abrir diálogo de recuperación
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    // Escribir un correo válido en el diálogo
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo autorizado'),
      'noautorizado@upana.edu.gt',
    );
    await tester.pump();

    // Enviar
    await tester.tap(find.text('Enviar enlace'));
    await tester.pumpAndSettle();

    // Verificar el mensaje amigable en el SnackBar
    expect(
      find.text('El correo no está autorizado. Verifica con el administrador.'),
      findsOneWidget,
    );
  });
}