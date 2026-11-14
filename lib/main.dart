import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'models/usuario_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PruebaApp());
}

class PruebaApp extends StatelessWidget {
  const PruebaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const TestLoginScreen(),
    );
  }
}

class TestLoginScreen extends StatefulWidget {
  const TestLoginScreen({super.key});

  @override
  State<TestLoginScreen> createState() => _TestLoginScreenState();
}

class _TestLoginScreenState extends State<TestLoginScreen> {
  final _authService = AuthService();
  final _userCtrl = TextEditingController(text: 'gerson');
  final _passCtrl = TextEditingController(text: '123456');

  String _estado = 'Listo para probar';
  UsuarioModel? _usuarioLogueado;
  bool _cargando = false;

  Future<void> _probarLogin() async {
    setState(() {
      _cargando = true;
      _estado = 'Validando con usuario/contraseña...';
    });

    try {
      final user = await _authService.login(_userCtrl.text, _passCtrl.text);
      setState(() {
        _cargando = false;
        _usuarioLogueado = user;
        _estado = user != null
            ? '¡Login Exitoso!'
            : 'Credenciales incorrectas o usuario no encontrado.';
      });
    } catch (e) {
      setState(() {
        _cargando = false;
        _estado = 'Error: $e';
      });
    }
  }

  Future<void> _probarGoogle() async {
    setState(() {
      _cargando = true;
      _estado = 'Abriendo selector de Google...';
    });

    try {
      final user = await _authService.loginConGoogle();
      setState(() {
        _cargando = false;
        _usuarioLogueado = user;
        _estado = user != null
            ? '¡Login con Google Exitoso!'
            : 'Acceso denegado: Ese correo de Google no está en la colección usuarios.';
      });
    } catch (e) {
      setState(() {
        _cargando = false;
        _estado = 'Error con Google: $e';
      });
    }
  }

  Future<void> _probarRecuperacion() async {
    final correo = _usuarioLogueado?.correo ?? _userCtrl.text.trim();
    if (!correo.contains('@')) {
      setState(() {
        _estado = 'Escribe el correo en la primera caja para enviar el link.';
      });
      return;
    }

    try {
      await _authService.enviarCorreoRecuperacion(correo);
      setState(() {
        _estado = '¡Correo de recuperación enviado a $correo!';
      });
    } catch (e) {
      setState(() {
        _estado = 'Error al enviar correo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prueba de Auth Completo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(
                labelText: 'Usuario / Carné / Correo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (_cargando)
              const CircularProgressIndicator()
            else
              Column(
                children: [
                  Wrap(
                    spacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _probarLogin,
                        child: const Text('Probar Login'),
                      ),
                      OutlinedButton(
                        onPressed: _probarRecuperacion,
                        child: const Text('Olvidé Contraseña'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: _probarGoogle,
                    icon: const Icon(Icons.account_circle),
                    label: const Text('Continuar con Google'),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            Text(
              _estado,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_usuarioLogueado != null) ...[
              const Divider(height: 30),
              Text('Nombre: ${_usuarioLogueado!.nombre}'),
              Text('Carné: ${_usuarioLogueado!.carnet}'),
              Text('Correo: ${_usuarioLogueado!.correo}'),
              Text('Carrera: ${_usuarioLogueado!.carrera}'),
              Text('Año Ingreso: ${_usuarioLogueado!.anioIngreso}'),
            ],
          ],
        ),
      ),
    );
  }
}