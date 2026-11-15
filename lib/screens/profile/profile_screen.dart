import 'package:flutter/material.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';


class ProfileScreen extends StatelessWidget {
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

  /// Callbacks para que Gerson conecte Firebase Storage / Auth
  final VoidCallback? onEditPhoto;
  final Future<void> Function(String correo)? onResetPassword;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                      backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                      backgroundImage:
                          fotoUrl != null ? NetworkImage(fotoUrl!) : null,
                      child: fotoUrl == null
                          ? Icon(
                              Icons.person_rounded,
                              size: 56,
                              color: colorScheme.primary,
                            )
                          : null,
                    ),
                    Material(
                      color: colorScheme.primary,
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onEditPhoto ??
                            () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  content: Text(
                                    'Selector de foto listo para conectar con Storage.',
                                  ),
                                ),
                              );
                            },
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

              // Nombre del estudiante (Solo lectura)
              Text(
                nombreCompleto,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                correo,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 28),

              // Sección TU INFORMACIÓN
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
                      value: carne,
                    ),
                    const Divider(height: 1),
                    _InfoTile(
                      icon: Icons.school_outlined,
                      label: 'Carrera',
                      value: carrera,
                    ),
                    const Divider(height: 1),
                    _InfoTile(
                      icon: Icons.account_balance_outlined,
                      label: 'Universidad',
                      value: universidad,
                    ),
                    const Divider(height: 1),
                    _InfoTile(
                      icon: Icons.calendar_today_outlined,
                      label: 'Período actual',
                      value: periodoActual,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Botón Cambiar Contraseña
              AppButton(
                text: 'Cambiar contraseña',
                icon: Icons.lock_reset_rounded,
                type: AppButtonType.secondary,
                onPressed: () => _confirmarCambioContrasena(context),
              ),
              const SizedBox(height: 12),

              // Botón Cerrar Sesión
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
                    if (onLogout != null) {
                      onLogout!();
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

  void _confirmarCambioContrasena(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cambiar contraseña'),
        content: Text(
          'Enviaremos un enlace de restablecimiento de contraseña a tu correo registrado:\n\n$correo',
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
                if (onResetPassword != null) {
                  await onResetPassword!(correo);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text('Enlace enviado a $correo'),
                    ),
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'No se pudo enviar el correo. Inténtalo más tarde.',
                      ),
                    ),
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