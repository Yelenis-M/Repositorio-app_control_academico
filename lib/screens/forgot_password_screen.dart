import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.onSendPasswordReset});

  final Future<void> Function(String correo)? onSendPasswordReset;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _correoController.dispose();
    super.dispose();
  }

  Future<void> _enviarEnlace() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);
    try {
      final correo = _correoController.text.trim();
      if (widget.onSendPasswordReset != null) {
        await widget.onSendPasswordReset!(correo);
      } else {
        await Future.delayed(const Duration(seconds: 1));
      }

      if (!mounted) return;
      Navigator.of(context).pop(correo);
    } catch (e) {
      if (!mounted) return;
      _mostrarAviso('El correo no está registrado o no autorizado.');
    } finally {
      if (mounted) setState(() => _enviando = false);
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Tarjeta Post-it Rosa "nos pasa a todos"
                            Align(
                              alignment: Alignment.center,
                              child: Transform.rotate(
                                angle: 0.03,
                                child: Stack(
                                  alignment: Alignment.topCenter,
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(top: 10),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF48FB1),
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Color(0x33000000),
                                            blurRadius: 10,
                                            offset: Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: const Text(
                                        'nos pasa a todos',
                                        style: TextStyle(
                                          fontFamily: 'Caveat',
                                          fontSize: 26,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 48,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: const Color(0xE6F4F0E6),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 36),
                            Text(
                              '¿Olvidaste tu\ncontraseña?',
                              style: tema.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Escribe tu correo y te enviamos un enlace para crear una nueva.',
                              style: tema.textTheme.bodyLarge?.copyWith(
                                color: esquema.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Form(
                              key: _formKey,
                              child: TextFormField(
                                controller: _correoController,
                                keyboardType: TextInputType.emailAddress,
                                enabled: !_enviando,
                                decoration: const InputDecoration(
                                  labelText: 'Correo',
                                  prefixIcon: Icon(Icons.alternate_email_rounded),
                                ),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Escribe tu correo.';
                                  }
                                  return null;
                                },
                                onFieldSubmitted: (_) => _enviarEnlace(),
                              ),
                            ),
                            const SizedBox(height: 28),
                            FilledButton(
                              onPressed: _enviando ? null : _enviarEnlace,
                              child: _enviando
                                  ? SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        color: esquema.onPrimary,
                                      ),
                                    )
                                  : const Text('Enviar enlace'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Fondo de cuadrícula reutilizado para mantener la consistencia visual
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