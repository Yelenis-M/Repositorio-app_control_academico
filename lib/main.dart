import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notas_service.dart';
import 'models/usuario_model.dart';
import 'models/curso_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ControlAcademicoApp());
}

class ControlAcademicoApp extends StatelessWidget {
  const ControlAcademicoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control Académico UPANA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const TestBackendScreen(), // Yelenis cambiará esto por su LoginScreen()
    );
  }
}

class TestBackendScreen extends StatefulWidget {
  const TestBackendScreen({super.key});

  @override
  State<TestBackendScreen> createState() => _TestBackendScreenState();
}

class _TestBackendScreenState extends State<TestBackendScreen> {
  final _authService = AuthService();
  final _notasService = NotasService();

  final _userCtrl = TextEditingController(text: 'gerson');
  final _passCtrl = TextEditingController(text: '123456');

  String _estado = 'Inicia sesión para probar el CRUD';
  UsuarioModel? _usuarioLogueado;
  List<CursoModel> _cursos = [];
  Map<String, dynamic>? _resumen;
  bool _cargando = false;

  Future<void> _loginNormal() async {
    setState(() => _cargando = true);
    final user = await _authService.login(_userCtrl.text, _passCtrl.text);
    setState(() {
      _cargando = false;
      _usuarioLogueado = user;
      _estado = user != null ? '¡Sesión activa!' : 'Credenciales inválidas';
    });
    if (user != null) await _recargarDatos();
  }

  Future<void> _loginGoogle() async {
    setState(() => _cargando = true);
    final user = await _authService.loginConGoogle();
    setState(() {
      _cargando = false;
      _usuarioLogueado = user;
      _estado = user != null ? '¡Sesión con Google activa!' : 'Correo no registrado';
    });
    if (user != null) await _recargarDatos();
  }

  Future<void> _recargarDatos() async {
    if (_usuarioLogueado == null) return;
    final cursos = await _notasService.obtenerCursosPorSemestre(
      _usuarioLogueado!.carnet,
      _usuarioLogueado!.carreraId,
      6, // Semestre 6 donde está Programación IV (SIST2053)
    );
    final resumen = await _notasService.obtenerResumenGlobal(
      _usuarioLogueado!.carnet,
      _usuarioLogueado!.carreraId,
    );
    setState(() {
      _cursos = cursos;
      _resumen = resumen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Control Académico - Backend Listo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _userCtrl,
              decoration: const InputDecoration(labelText: 'Usuario / Carné / Correo'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña'),
            ),
            const SizedBox(height: 12),
            if (_cargando)
              const CircularProgressIndicator()
            else
              Wrap(
                spacing: 10,
                children: [
                  ElevatedButton(onPressed: _loginNormal, child: const Text('Login')),
                  FilledButton.tonalIcon(
                    onPressed: _loginGoogle,
                    icon: const Icon(Icons.account_circle),
                    label: const Text('Google'),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Text(_estado, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (_usuarioLogueado != null) ...[
              const Divider(height: 24),
              if (_resumen != null)
                Card(
                  color: Colors.indigo.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        Text('Promedio Global: ${_resumen!['promedioGlobal']}'),
                        Text('Aprobados: ${_resumen!['aprobados']} | Créditos: ${_resumen!['creditosAcumulados']}'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              const Text('Semestre 6 (Prueba CRUD):', style: TextStyle(fontWeight: FontWeight.bold)),
              for (var c in _cursos)
                Card(
                  child: ListTile(
                    title: Text('${c.codigo} - ${c.nombre}'),
                    subtitle: Text(
                      'Nota: ${c.nota ?? "Pendiente"} | Ing: ${c.catedratico ?? "Sin asignar"}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check, color: Colors.green),
                          onPressed: () async {
                            await _notasService.guardarNota(
                              _usuarioLogueado!.carnet,
                              c.codigo,
                              95,
                              catedratico: 'Ing. Carlos Méndez',
                            );
                            await _recargarDatos();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.grey),
                          onPressed: () async {
                            await _notasService.eliminarNota(_usuarioLogueado!.carnet, c.codigo);
                            await _recargarDatos();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}