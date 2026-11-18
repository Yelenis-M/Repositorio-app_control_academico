import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notas_service.dart';
import 'services/perfil_service.dart';
import 'services/pdf_service.dart'; 
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
      home: const TestBackendScreen(),
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
  final _perfilService = PerfilService();
  final _pdfService = PdfService(); // <-- 2. Instancia agregada

  final _userCtrl = TextEditingController(text: 'gerson');
  final _passCtrl = TextEditingController(text: '123456');

  String _estado = 'Inicia sesión con tus credenciales o Google';
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
      _estado = user != null ? '¡Sesión activa: ${user.nombre}!' : 'Credenciales inválidas';
    });
    if (user != null) await _recargarDatos();
  }

  Future<void> _loginGoogle() async {
    setState(() => _cargando = true);
    final user = await _authService.loginConGoogle();
    setState(() {
      _cargando = false;
      _usuarioLogueado = user;
      _estado = user != null ? '¡Sesión con Google: ${user.nombre}!' : 'Correo no registrado';
    });
    if (user != null) await _recargarDatos();
  }

  Future<void> _recargarDatos() async {
    if (_usuarioLogueado == null) return;
    final cursos = await _notasService.obtenerCursosPorSemestre(
      _usuarioLogueado!.carnet,
      _usuarioLogueado!.carreraId,
      6,
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

  Future<void> _cambiarFoto(bool usarCamara) async {
    if (_usuarioLogueado == null) return;
    setState(() {
      _cargando = true;
      _estado = usarCamara ? 'Abriendo cámara...' : 'Abriendo galería...';
    });

    final res = await _perfilService.cambiarFotoPerfil(
      carnet: _usuarioLogueado!.carnet,
      usarCamara: usarCamara,
    );

    setState(() => _cargando = false);
    _manejarResultadoFoto(res, esBorrado: false);
  }

  Future<void> _borrarFoto() async {
    if (_usuarioLogueado == null) return;
    setState(() {
      _cargando = true;
      _estado = 'Eliminando foto de Firebase...';
    });

    final res = await _perfilService.eliminarFotoPerfil(_usuarioLogueado!.carnet);

    setState(() => _cargando = false);
    _manejarResultadoFoto(res, esBorrado: true);
  }

  void _manejarResultadoFoto(ResultadoFoto res, {required bool esBorrado}) {
    switch (res) {
      case ResultadoFoto.exito:
        setState(() {
          _usuarioLogueado = AuthService.usuarioActual;
          _estado = esBorrado
              ? '¡Foto eliminada de Firestore!'
              : '¡Foto comprimida y guardada en Firestore!';
        });
        break;
      case ResultadoFoto.canceladoPorUsuario:
        setState(() => _estado = 'Selección cancelada.');
        break;
      case ResultadoFoto.permisoDenegado:
        setState(() => _estado = 'Permiso denegado (1ra vez). Intenta de nuevo.');
        break;
      case ResultadoFoto.permisoBloqueadoIrAjustes:
        setState(() => _estado = 'Permiso bloqueado permanentemente.');
        _mostrarDialogoIrAjustes();
        break;
      case ResultadoFoto.camaraNoDisponible:
        setState(() => _estado = 'Cámara o galería no disponible.');
        break;
      case ResultadoFoto.sinInternet:
        setState(() => _estado = 'No hay conexión a internet. Intente más tarde.');
        break;
      case ResultadoFoto.errorDesconocido:
        setState(() => _estado = 'Error al procesar la imagen.');
        break;
    }
  }

  void _mostrarDialogoIrAjustes() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permiso requerido'),
        content: const Text(
          'Has denegado el permiso 2 veces. Habilítalo manualmente en los Ajustes de la aplicación.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              _perfilService.abrirAjustesDePermisos();
            },
            child: const Text('Ir a Ajustes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bytesFoto = _perfilService.decodificarFoto(_usuarioLogueado?.fotoBase64);

    return Scaffold(
      appBar: AppBar(title: const Text('Control Académico - Backend')),
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
                  ElevatedButton(onPressed: _loginNormal, child: const Text('Login Normal')),
                  FilledButton.tonalIcon(
                    onPressed: _loginGoogle,
                    icon: const Icon(Icons.account_circle),
                    label: const Text('Google'),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Text(
              _estado,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_usuarioLogueado != null) ...[
              const Divider(height: 24),
              // SECCIÓN DE FOTO DE PERFIL
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.indigo.shade100,
                backgroundImage: bytesFoto != null ? MemoryImage(bytesFoto) : null,
                child: bytesFoto == null
                    ? const Icon(Icons.person, size: 45, color: Colors.indigo)
                    : null,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: () => _cambiarFoto(true),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Cámara'),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _cambiarFoto(false),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Galería'),
                  ),
                  // <-- 3. Botón de Descargar PDF agregado aquí
                  FilledButton.icon(
                    onPressed: () async {
                      setState(() => _estado = 'Generando PDF de Vida Académica...');
                      await _pdfService.generarYMostrarVidaAcademica(_usuarioLogueado!);
                      setState(() => _estado = '¡PDF generado con éxito!');
                    },
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Descargar PDF'),
                  ),
                  if (_usuarioLogueado?.fotoBase64 != null)
                    IconButton(
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: _borrarFoto,
                      tooltip: 'Quitar foto',
                    ),
                ],
              ),
              const SizedBox(height: 12),
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
                      c.bloqueadoPorPrerequisito
                          ? '🔒 Bloqueado (Falta: ${c.prerequisitosFaltantes})'
                          : 'Nota: ${c.nota ?? "Pendiente"} | Ing: ${c.catedratico ?? "Sin asignar"}',
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