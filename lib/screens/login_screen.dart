import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
import '../widgets/app_button.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_text_field.dart';
import 'forgot_password_screen.dart';

/// Pantalla de acceso de PromediUm.
///
/// La autenticacion se conecta mediante callbacks para que Gerson pueda
/// integrar Firebase sin mezclar esa logica con la interfaz.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onSignInWithUser,
    this.onSignInWithGoogle,
    this.onSendPasswordReset,
  });

  /// En el futuro, Gerson validara usuario y contrasena con Firebase/servicio.
  final Future<void> Function(String usuario, String contrasena)?
      onSignInWithUser;

  /// En el futuro, Gerson conectara el inicio de sesion con Google.
  final Future<void> Function()? onSignInWithGoogle;

  /// En el futuro, Gerson conectara Firebase para enviar el correo de recuperacion.
  final Future<void> Function(String correo)? onSendPasswordReset;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _Tarea { ninguna, usuario, google }

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usuarioController = TextEditingController();
  final _contrasenaController = TextEditingController();

  late final AnimationController _entrada;
  late final Animation<double> _opacidad;
  late final Animation<Offset> _desplazamiento;

  _Tarea _tarea = _Tarea.ninguna;

  bool get _ocupado => _tarea != _Tarea.ninguna;

  static const _postIt = Color(0xFFB7F3EA);
  static const _tintaPostIt = Color(0xFF115E59);

  @override
  void initState() {
    super.initState();
    _entrada = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _opacidad = CurvedAnimation(parent: _entrada, curve: Curves.easeOut);
    _desplazamiento = Tween<Offset>(
      begin: const Offset(0, -0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entrada, curve: Curves.easeOutCubic));
    _entrada.forward();
  }

  @override
  void dispose() {
    _entrada.dispose();
    _usuarioController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  Future<void> _ingresar() async {
    if (!_formKey.currentState!.validate() || _ocupado) return;

    final usuario = _usuarioController.text.trim();
    final contrasena = _contrasenaController.text;
    final acceso = widget.onSignInWithUser;

    await _ejecutar(_Tarea.usuario, () async {
      if (acceso == null) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        return;
      }
      await acceso(usuario, contrasena);
    }, avisoDePrueba: acceso == null);
  }

  Future<void> _continuarConGoogle() async {
    final acceso = widget.onSignInWithGoogle;

    await _ejecutar(_Tarea.google, () async {
      if (acceso == null) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        return;
      }
      await acceso();
    }, avisoDePrueba: acceso == null);
  }

  Future<void> _abrirRecuperacion() async {
    final correoEnviado = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(
          onSendPasswordReset: widget.onSendPasswordReset,
        ),
      ),
    );

    if (correoEnviado != null && mounted) {
      _mostrarAviso('Se solicito el enlace de recuperacion para $correoEnviado.');
    }
  }

  Future<void> _ejecutar(
    _Tarea tarea,
    Future<void> Function() accion, {
    required bool avisoDePrueba,
  }) async {
    if (_ocupado) return;

    setState(() => _tarea = tarea);
    try {
      await accion();
      if (!mounted) return;

      if (avisoDePrueba) {
        _mostrarAviso(
          'Vista de prueba: Gerson conectara esta accion con Firebase.',
        );
      }
    } catch (error) {
      if (!mounted) return;
      _mostrarAviso(mensajeAmigable(error));
    } finally {
      if (mounted) setState(() => _tarea = _Tarea.ninguna);
    }
  }

  void _mostrarAviso(String mensaje) {
    final mensajero = ScaffoldMessenger.of(context);
    mensajero
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(mensaje),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _TarjetaPostIt(
                      opacidad: _opacidad,
                      desplazamiento: _desplazamiento,
                      color: _postIt,
                      colorTexto: _tintaPostIt,
                    ),
                    const SizedBox(height: 28),
                    const AppLogo(width: 92, height: 92),
                    const SizedBox(height: 20),
                    Text(
                      'Iniciar sesión',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Accede con tu correo electrónico o usuario, o continúa con Google.',
                      textAlign: TextAlign.center,
                      style: tema.textTheme.bodyLarge?.copyWith(
                        color: esquema.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _usuarioController,
                            label: 'Correo o usuario',
                            prefixIcon: Icons.person_outline_rounded,
                            enabled: !_ocupado,
                            textInputAction: TextInputAction.next,
                            validator: _validarUsuario,
                          ),
                          const SizedBox(height: 14),
                          AppTextField(
                            controller: _contrasenaController,
                            label: 'Contraseña',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: true,
                            enabled: !_ocupado,
                            visibilityToggleEnabled: !_ocupado,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => _ingresar(),
                            validator: (valor) {
                              if (valor == null || valor.isEmpty) {
                                return 'Escribe tu contraseña.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _ocupado ? null : _abrirRecuperacion,
                        child: const Text('¿Olvidaste tu contraseña?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppButton(
                      text: 'Ingresar',
                      onPressed: _ingresar,
                      isLoading: _tarea == _Tarea.usuario,
                    ),
                    const SizedBox(height: 22),
                    const _DivisorO(),
                    const SizedBox(height: 22),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _ocupado ? null : _continuarConGoogle,
                        child: _tarea == _Tarea.google
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: esquema.primary,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image(
                                    image: AssetImage(
                                      'assets/images/google_logo.png',
                                    ),
                                    width: 20,
                                    height: 20,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(width: 10),
                                  Text('Continuar con Google'),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String mensajeAmigable(Object error) {
  if (error.toString().toLowerCase().contains('google-no-disponible')) {
    return 'El inicio de sesión con Google no está disponible en este momento. Intenta ingresar con tu correo o usuario.';
  }
  if (_esFalloDeRed(error)) {
    return 'Sin conexión a internet. Verifica tu red e intenta de nuevo.';
  }
  if (_sonCredencialesInvalidas(error)) {
    return 'Usuario o contraseña incorrectos. Verifica tus credenciales.';
  }
  if (_esCorreoNoAutorizado(error)) {
    return 'El correo no está autorizado. Verifica con el administrador.';
  }
  return 'Ocurrió un error inesperado. Inténtalo más tarde.';
}

bool _esFalloDeRed(Object error) {
  final tipo = error.runtimeType.toString();
  if (tipo == 'SocketException' ||
      tipo == 'TimeoutException' ||
      tipo == 'HandshakeException' ||
      tipo == 'ClientException') {
    return true;
  }

  final detalle = error.toString().toLowerCase();
  const senales = [
    'socketexception',
    'failed host lookup',
    'network-request-failed',
    'network_error',
    'connection abort',
    'connection reset',
    'timed out',
    'xmlhttprequest error',
  ];
  return senales.any(detalle.contains);
}

bool _sonCredencialesInvalidas(Object error) {
  final detalle = error.toString().toLowerCase();
  const senales = [
    'wrong-password',
    'invalid-credential',
    'invalid-email',
    'user-not-found',
    'invalid-login-credentials',
    'invalid_grant',
    'user-disabled',
    'credenciales-invalidas',
    'usuario-no-existe',
    'contrasena-incorrecta',
  ];
  return senales.any(detalle.contains);
}

bool _esCorreoNoAutorizado(Object error) {
  final detalle = error.toString().toLowerCase();
  const senales = [
    'correo-no-autorizado',
    'email-not-authorized',
    'email-not-found',
    'correo-no-existe',
    'unauthorized-email',
  ];
  return senales.any(detalle.contains);
}

String? _validarUsuario(String? valor) {
  if (valor == null || valor.trim().isEmpty) {
    return 'Escribe tu correo o usuario.';
  }
  return null;
}

class _TarjetaPostIt extends StatelessWidget {
  const _TarjetaPostIt({
    required this.opacidad,
    required this.desplazamiento,
    required this.color,
    required this.colorTexto,
  });

  final Animation<double> opacidad;
  final Animation<Offset> desplazamiento;
  final Color color;
  final Color colorTexto;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: opacidad,
      child: SlideTransition(
        position: desplazamiento,
        child: Align(
          child: Transform.rotate(
            angle: -0.05,
            child: Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Text(
                    '¡qué bueno verte!',
                    style: TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: colorTexto,
                      height: 1,
                    ),
                  ),
                ),
                Transform.rotate(
                  angle: 0.04,
                  child: Container(
                    width: 58,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xE6F4F0E6),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DivisorO extends StatelessWidget {
  const _DivisorO();

  @override
  Widget build(BuildContext context) {
    final estilo = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        );
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('o', style: estilo),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}