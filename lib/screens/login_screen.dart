import 'package:flutter/material.dart';
import 'forgot_password_screen.dart';

/// Vista de acceso de PromediUm.
///
/// La autenticación no vive aquí. La base de datos maneja:
///   - usuario
///   - contraseña
///   - correo electrónico autorizado
///
/// El login valida [usuario] + [contraseña].
/// La recuperación de contraseña valida que el [correo] esté autorizado.
///
/// Si los callbacks siguen en null, la pantalla se puede previsualizar
/// y no intenta conectarse a ningún servicio.
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.onSignInWithUser,
    this.onSignInWithGoogle,
    this.onSendPasswordReset,
  });

  /// Valida usuario + contraseña contra la base de datos.
  final Future<void> Function(String usuario, String contrasena)?
      onSignInWithUser;

  /// Login con Google (sin cambios).
  final Future<void> Function()? onSignInWithGoogle;

  /// Envía el enlace de recuperación a un correo autorizado.
  /// A futuro: valida que el correo exista en la base de datos de Firebase.
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
  bool _ocultarContrasena = true;
  _Tarea _tarea = _Tarea.ninguna;

  bool get _ocupado => _tarea != _Tarea.ninguna;

  static const _rutaLogo = 'assets/images/PromediUm.png';
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
    if (!_formKey.currentState!.validate()) {
      return;
    }
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

  // En tu método _abrirRecuperacion dentro de LoginScreen:
  Future<void> _abrirRecuperacion() async {
    final correoEnviado = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (context) => ForgotPasswordScreen(
          onSendPasswordReset: widget.onSendPasswordReset,
        ),
      ),
    );

    if (correoEnviado != null && mounted) {
      _mostrarAviso('Se envió un enlace de recuperación a $correoEnviado.');
    }
  }

  /// Ejecuta una acción de acceso y traduce cualquier fallo a un aviso claro.
  Future<void> _ejecutar(
    _Tarea tarea,
    Future<void> Function() accion, {
    required bool avisoDePrueba,
  }) async {
    if (_ocupado) {
      return;
    }
    setState(() => _tarea = tarea);
    try {
      await accion();
      if (!mounted) {
        return;
      }
      if (avisoDePrueba) {
        _mostrarAviso(
          'Vista de prueba: el acceso se conectará con Firebase más adelante.',
        );
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      _mostrarAviso(mensajeAmigable(error));
    } finally {
      if (mounted) {
        setState(() => _tarea = _Tarea.ninguna);
      }
    }
  }

  void _mostrarAviso(String mensaje) {
    final mensajero = ScaffoldMessenger.of(context);
    mensajero.hideCurrentSnackBar();
    mensajero.showSnackBar(
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
      body: Stack(
        children: [
          const Positioned.fill(child: _FondoCuadricula()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 28,
                ),
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
                      const _LogoPromediUm(ruta: _rutaLogo),
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
                        'Entra con tu usuario o con Google.',
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
                            TextFormField(
                              controller: _usuarioController,
                              keyboardType: TextInputType.text,
                              textInputAction: TextInputAction.next,
                              enabled: !_ocupado,
                              decoration: const InputDecoration(
                                labelText: 'Usuario',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: _validarUsuario,
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _contrasenaController,
                              obscureText: _ocultarContrasena,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              enabled: !_ocupado,
                              onFieldSubmitted: (_) => _ingresar(),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon:
                                    const Icon(Icons.lock_outline_rounded),
                                suffixIcon: IconButton(
                                  tooltip: _ocultarContrasena
                                      ? 'Mostrar contraseña'
                                      : 'Ocultar contraseña',
                                  onPressed: _ocupado
                                      ? null
                                      : () {
                                          setState(() {
                                            _ocultarContrasena =
                                                !_ocultarContrasena;
                                          });
                                        },
                                  icon: Icon(
                                    _ocultarContrasena
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                ),
                              ),
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
                      FilledButton(
                        onPressed: _tarea == _Tarea.usuario
                            ? () {}
                            : _ocupado
                                ? null
                                : _ingresar,
                        child: _tarea == _Tarea.usuario
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: esquema.onPrimary,
                                ),
                              )
                            : const Text('Ingresar'),
                      ),
                      const SizedBox(height: 22),
                      const _DivisorO(),
                      const SizedBox(height: 22),
                      OutlinedButton.icon(
                        onPressed: _tarea == _Tarea.google
                            ? () {}
                            : _ocupado
                                ? null
                                : _continuarConGoogle,
                        icon: _tarea == _Tarea.google
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  color: esquema.primary,
                                ),
                              )
                            : const _LogoGoogle(tamano: 20),
                        label: const Text('Continuar con Google'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Convierte cualquier fallo en un texto comprensible, sin códigos técnicos.
String mensajeAmigable(Object error) {
  if (_esFalloDeRed(error)) {
    return 'Sin conexión a internet. Por favor verifica tu red e intenta de nuevo.';
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

/// El usuario no es un correo: solo pedimos que no esté vacío.
String? _validarUsuario(String? valor) {
  final usuario = valor?.trim() ?? '';
  if (usuario.isEmpty) {
    return 'Escribe tu usuario.';
  }
  return null;
}

/// El correo se valida aquí porque solo se usa en la recuperación.
String? _validarCorreo(String? valor) {
  final correo = valor?.trim() ?? '';
  if (correo.isEmpty) {
    return 'Escribe tu correo.';
  }
  final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo);
  if (!valido) {
    return 'Escribe un correo válido.';
  }
  return null;
}

class _FondoCuadricula extends StatelessWidget {
  const _FondoCuadricula();

  @override
  Widget build(BuildContext context) {
    final oscuro = Theme.of(context).brightness == Brightness.dark;
    final linea = oscuro
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFF1F2937).withValues(alpha: 0.08);
    return RepaintBoundary(
      child: CustomPaint(
        painter: _CuadriculaPainter(colorLinea: linea),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _CuadriculaPainter extends CustomPainter {
  const _CuadriculaPainter({required this.colorLinea});
  final Color colorLinea;
  static const double _espacio = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final trazo = Paint()
      ..color = colorLinea
      ..strokeWidth = 0.7;
    for (double x = 0; x <= size.width; x += _espacio) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), trazo);
    }
    for (double y = 0; y <= size.height; y += _espacio) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), trazo);
    }
  }

  @override
  bool shouldRepaint(covariant _CuadriculaPainter oldDelegate) {
    return oldDelegate.colorLinea != colorLinea;
  }
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

class _LogoPromediUm extends StatelessWidget {
  const _LogoPromediUm({required this.ruta});
  final String ruta;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Center(
      child: Image.asset(
        ruta,
        width: 92,
        height: 92,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: 92,
            height: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: esquema.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'P',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: esquema.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          );
        },
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

class _LogoGoogle extends StatelessWidget {
  const _LogoGoogle({required this.tamano});
  final double tamano;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(tamano),
      painter: const _LogoGooglePainter(),
    );
  }
}

class _LogoGooglePainter extends CustomPainter {
  const _LogoGooglePainter();
  static const _azul = Color(0xFF4285F4);
  static const _rojo = Color(0xFFEA4335);
  static const _amarillo = Color(0xFFFBBC05);
  static const _verde = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final centro = Offset(size.width / 2, size.height / 2);
    final radio = size.width * 0.36;
    final rect = Rect.fromCircle(center: centro, radius: radio);
    final trazo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.18
      ..strokeCap = StrokeCap.butt;

    trazo.color = _azul;
    canvas.drawArc(rect, -0.45, 1.85, false, trazo);
    trazo.color = _verde;
    canvas.drawArc(rect, 1.45, 0.95, false, trazo);
    trazo.color = _amarillo;
    canvas.drawArc(rect, 2.45, 0.85, false, trazo);
    trazo.color = _rojo;
    canvas.drawArc(rect, 3.35, 1.15, false, trazo);

    canvas.drawRect(
      Rect.fromLTWH(
        size.width * 0.48,
        size.height * 0.41,
        size.width * 0.40,
        size.width * 0.18,
      ),
      Paint()..color = _azul,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DialogoRecuperacion extends StatefulWidget {
  const _DialogoRecuperacion();

  @override
  State<_DialogoRecuperacion> createState() => _DialogoRecuperacionState();
}

class _DialogoRecuperacionState extends State<_DialogoRecuperacion> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  void _enviar() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.of(context).pop(_correoController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recuperar contraseña'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _correoController,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Correo autorizado',
            prefixIcon: Icon(Icons.alternate_email_rounded),
          ),
          validator: _validarCorreo,
          onFieldSubmitted: (_) => _enviar(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _enviar,
          child: const Text('Enviar enlace'),
        ),
      ],
    );
  }
}