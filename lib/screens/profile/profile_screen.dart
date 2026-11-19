import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/datos_academicos_mock.dart';
import '../../services/auth_service.dart';
import '../../services/perfil_service.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.nombreCompleto,
    required this.carne,
    required this.carrera,
    required this.universidad,
    required this.periodoActual,
    required this.correo,
    this.fotoUrl,
    this.onEditPhoto,
    this.onResetPassword,
    this.onLogout,
  });

  final String nombreCompleto;
  final String carne;
  final String carrera;
  final String universidad;
  final String periodoActual;
  final String correo;
  final String? fotoUrl;

  final VoidCallback? onEditPhoto;
  final Future<void> Function(String correo)? onResetPassword;
  final VoidCallback? onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PerfilService _perfilService = PerfilService();
  bool _procesandoFoto = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final datos = context.watch<DatosAcademicosMock>();
    final fotoBase64 = datos.usuarioActual?.fotoBase64;
    final bytesFoto = _perfilService.decodificarFoto(fotoBase64);

    ImageProvider? imagenAvatar;
    if (bytesFoto != null) {
      imagenAvatar = MemoryImage(bytesFoto);
    } else if (widget.fotoUrl != null) {
      imagenAvatar = NetworkImage(widget.fotoUrl!);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
            onPressed: () {
              Navigator.pushNamed(context, '/settings');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar + Botón Editar Foto
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.15),
                      backgroundImage: imagenAvatar,
                      child: _procesandoFoto
                          ? const CircularProgressIndicator(strokeWidth: 2.5)
                          : (imagenAvatar == null
                              ? Icon(
                                  Icons.person_rounded,
                                  size: 56,
                                  color: colorScheme.primary,
                                )
                              : null),
                    ),
                    Material(
                      color: colorScheme.primary,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _procesandoFoto
                            ? null
                            : (widget.onEditPhoto ??
                                () => _mostrarOpcionesFoto(
                                      context,
                                      datos,
                                      tieneFoto: bytesFoto != null,
                                    )),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            size: 18,
                            color: colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.nombreCompleto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.correo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'TU INFORMACIÓN',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  children: [
                    _InfoTile(
                      icon: Icons.badge_outlined,
                      label: 'ID / Carné',
                      value: widget.carne,
                    ),
                    const Divider(height: 1),
                    _InfoTile(
                      icon: Icons.school_outlined,
                      label: 'Carrera',
                      value: widget.carrera,
                    ),
                    const Divider(height: 1),
                    _InfoTile(
                      icon: Icons.account_balance_outlined,
                      label: 'Universidad',
                      value: widget.universidad,
                    ),
                    const Divider(height: 1),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Período actual',
                      value: widget.periodoActual,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              AppButton(
                text: 'Cambiar contraseña',
                icon: Icons.lock_reset_rounded,
                type: AppButtonType.secondary,
                onPressed: () => _confirmarCambioContrasena(context),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text(
                    'Cerrar sesión',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    if (widget.onLogout != null) {
                      widget.onLogout!();
                    } else {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarOpcionesFoto(
    BuildContext context,
    DatosAcademicosMock datos, {
    required bool tieneFoto,
  }) {
    final esquema = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Foto de perfil',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.photo_camera_outlined, color: esquema.primary),
                  title: const Text('Tomar foto con cámara'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _ejecutarCambioFoto(datos, usarCamara: true);
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.photo_library_outlined, color: esquema.primary),
                  title: const Text('Elegir de la galería'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _ejecutarCambioFoto(datos, usarCamara: false);
                  },
                ),
                if (tieneFoto)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.delete_outline, color: Colors.red),
                    title: const Text(
                      'Eliminar foto actual',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _ejecutarEliminacionFoto(datos);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _ejecutarCambioFoto(
    DatosAcademicosMock datos, {
    required bool usarCamara,
  }) async {
    setState(() => _procesandoFoto = true);
    final resultado = await _perfilService.cambiarFotoPerfil(
      carnet: widget.carne,
      usarCamara: usarCamara,
    );
    if (!mounted) return;
    setState(() => _procesandoFoto = false);

    if (resultado == ResultadoFoto.exito) {
      datos.actualizarFotoBase64(AuthService.usuarioActual?.fotoBase64);
      _mostrarAviso('Foto de perfil actualizada.');
      return;
    }
    _manejarErrorFoto(resultado);
  }

  Future<void> _ejecutarEliminacionFoto(DatosAcademicosMock datos) async {
    setState(() => _procesandoFoto = true);
    final resultado = await _perfilService.eliminarFotoPerfil(widget.carne);
    if (!mounted) return;
    setState(() => _procesandoFoto = false);

    if (resultado == ResultadoFoto.exito) {
      datos.actualizarFotoBase64(null);
      _mostrarAviso('Foto de perfil eliminada.');
      return;
    }
    _manejarErrorFoto(resultado);
  }

  void _manejarErrorFoto(ResultadoFoto resultado) {
    switch (resultado) {
      case ResultadoFoto.exito:
      case ResultadoFoto.canceladoPorUsuario:
        return;
      case ResultadoFoto.permisoDenegado:
        _mostrarAviso('Permiso denegado. Necesitas autorizar el acceso para continuar.');
        return;
      case ResultadoFoto.permisoBloqueadoIrAjustes:
        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Permiso bloqueado'),
            content: const Text(
              'El permiso fue denegado permanentemente. Habilítalo desde los ajustes de tu teléfono.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _perfilService.abrirAjustesDePermisos();
                },
                child: const Text('Ir a Ajustes'),
              ),
            ],
          ),
        );
        return;
      case ResultadoFoto.camaraNoDisponible:
        _mostrarAviso('La cámara o galería no está disponible en este dispositivo.');
        return;
      case ResultadoFoto.sinInternet:
        _mostrarAviso('Sin conexión a internet. Conéctate para actualizar tu foto.');
        return;
      case ResultadoFoto.errorDesconocido:
        _mostrarAviso('No se pudo actualizar la foto. Intenta de nuevo.');
        return;
    }
  }

  void _mostrarAviso(String mensaje) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(mensaje),
        ),
      );
  }

  void _confirmarCambioContrasena(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Text(
          'Enviaremos un enlace de restablecimiento de contraseña a tu correo registrado:\n\n${widget.correo}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                if (widget.onResetPassword != null) {
                  await widget.onResetPassword!(widget.correo);
                }
                if (context.mounted) {
                  _mostrarAviso('Enlace enviado a ${widget.correo}');
                }
              } catch (_) {
                if (context.mounted) {
                  _mostrarAviso(
                    'No se pudo enviar el correo. Verifica tu conexión e inténtalo más tarde.',
                  );
                }
              }
            },
            child: const Text('Enviar enlace'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.primary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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