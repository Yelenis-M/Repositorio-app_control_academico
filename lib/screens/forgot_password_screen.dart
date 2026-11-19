import 'package:flutter/material.dart';

import '../widgets/app_background.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';

/// Solicita el correo de recuperacion. Firebase enviara el enlace;
/// la aplicacion no administra directamente el cambio de contrasena.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({
    super.key,
    this.onSendPasswordReset,
  });

  /// Punto de conexion para que Gerson implemente Firebase.
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
    if (!_formKey.currentState!.validate() || _enviando) return;

    setState(() => _enviando = true);
    try {
      final correo = _correoController.text.trim();
      final enviar = widget.onSendPasswordReset;

      if (enviar == null) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;
        _mostrarAviso(
          'Vista de prueba: Gerson conectara el envio del enlace con Firebase.',
        );
        return;
      }

      await enviar(correo);
      if (!mounted) return;
      Navigator.of(context).pop(correo);
    } catch (error) {
      if (!mounted) return;
      _mostrarAviso(_mensajeErrorRecuperacion(error));
    } finally {
      if (mounted) setState(() => _enviando = false);
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

  String? _validarCorreo(String? valor) {
    final correo = valor?.trim() ?? '';
    if (correo.isEmpty) return 'Escribe tu correo.';
    final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(correo);
    if (!valido) return 'Escribe un correo válido.';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final esquema = tema.colorScheme;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: IconButton(
                  tooltip: 'Regresar',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: _enviando ? null : () => Navigator.of(context).pop(),
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
                          const _PostItRecuperacion(),
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
                            'Escribe el correo asociado a tu cuenta y te enviaremos un enlace para crear una nueva contraseña.',
                            style: tema.textTheme.bodyLarge?.copyWith(
                              color: esquema.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Form(
                            key: _formKey,
                            child: AppTextField(
                              controller: _correoController,
                              label: 'Correo',
                              hint: 'ejemplo@correo.com',
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_enviando,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.email],
                              onFieldSubmitted: (_) => _enviarEnlace(),
                              validator: _validarCorreo,
                            ),
                          ),
                          const SizedBox(height: 28),
                          AppButton(
                            text: 'Enviar enlace',
                            onPressed: _enviarEnlace,
                            isLoading: _enviando,
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
      ),
    );
  }
}

class _PostItRecuperacion extends StatelessWidget {
  const _PostItRecuperacion();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Transform.rotate(
        angle: 0.03,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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
    );
  }
}

String _mensajeErrorRecuperacion(Object error) {
  final detalle = error.toString().toLowerCase();
  if (detalle.contains('network') || detalle.contains('socket') ||
      detalle.contains('timeout') || detalle.contains('connection')) {
    return 'Sin conexión a internet. Verifica tu red e intenta de nuevo.';
  }
  if (detalle.contains('user-not-found') || detalle.contains('email-not-found') ||
      detalle.contains('correo-no-autorizado')) {
    return 'No se pudo encontrar una cuenta autorizada con ese correo.';
  }
  return 'No se pudo enviar el enlace. Inténtalo nuevamente.';
}
