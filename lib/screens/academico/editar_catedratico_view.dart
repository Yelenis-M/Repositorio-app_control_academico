import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/datos_academicos_mock.dart';
import '../../models/catedratico.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/selector_color_rgb.dart';

class EditarCatedraticoView extends StatefulWidget {
  const EditarCatedraticoView({
    super.key,
    required this.catedraticoId,
  });

  final String catedraticoId;

  @override
  State<EditarCatedraticoView> createState() => _EditarCatedraticoViewState();
}

class _EditarCatedraticoViewState extends State<EditarCatedraticoView> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _telefono = TextEditingController();
  final _correo = TextEditingController();
  final _horarioOficina = TextEditingController();

  late Color _color;
  Catedratico? _catedratico;

  @override
  void initState() {
    super.initState();
    final existente = context.read<DatosAcademicosMock>().buscarCatedratico(
          widget.catedraticoId,
        );

    _catedratico = existente;
    _color = existente?.color ?? AppColors.primary;
    _nombre.text = existente?.nombre ?? '';
    _telefono.text = existente?.telefono ?? '';
    _correo.text = existente?.correo ?? '';
    _horarioOficina.text = existente?.horarioOficina ?? '';
  }

  @override
  void dispose() {
    _nombre.dispose();
    _telefono.dispose();
    _correo.dispose();
    _horarioOficina.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Editar catedrático'),
      ),
      body: AppBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              AppTextField(
                controller: _nombre,
                label: 'Nombre y apellidos',
                prefixIcon: Icons.person_outline,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (valor) {
                  if (valor == null || valor.trim().isEmpty) {
                    return 'Escribe el nombre y los apellidos.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(
                    Icons.palette_outlined,
                    color: esquema.primary,
                  ),
                  title: const Text('Color del catedrático'),
                  trailing: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: _color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: esquema.outline.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                  ),
                  onTap: _elegirColor,
                ),
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _telefono,
                label: 'Teléfono',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _correo,
                label: 'Correo electrónico',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (valor) {
                  final texto = valor?.trim() ?? '';
                  if (texto.isEmpty) {
                    return 'Escribe el correo electrónico.';
                  }
                  final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                      .hasMatch(texto);
                  if (!valido) return 'Escribe un correo válido.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: _horarioOficina,
                label: 'Horario de oficina/asesoría',
                prefixIcon: Icons.schedule_outlined,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Actualizar',
                icon: Icons.save_outlined,
                width: double.infinity,
                onPressed: _guardar,
              ),
              const SizedBox(height: 12),
              // Botón de eliminar con diseño secundario o de alerta
              AppButton(
                text: 'Eliminar catedrático',
                icon: Icons.delete_outline_rounded,
                width: double.infinity,
                type: AppButtonType.secondary,
                onPressed: _confirmarEliminacion,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _elegirColor() async {
    final color = await mostrarSelectorColorRgb(
      context: context,
      colorInicial: _color,
      titulo: 'Color del catedrático',
    );
    if (color == null || !mounted) return;
    setState(() => _color = color);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    final cursoActual = _catedratico;
    if (cursoActual == null) return;

    final actualizado = Catedratico(
      id: cursoActual.id,
      nombre: _nombre.text.trim(),
      correo: _correo.text.trim(),
      telefono: _telefono.text.trim(),
      color: _color,
      horarioOficina: _horarioOficina.text.trim(),
    );

    context.read<DatosAcademicosMock>().guardarCatedratico(actualizado);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Catedrático actualizado'),
      ),
    );
    Navigator.pop(context);
  }

  // Diálogo de advertencia para eliminar
  void _confirmarEliminacion() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar catedrático'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar este catedrático? Una vez que se borre no se puede recuperar esta información.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () {
                Navigator.pop(dialogContext); // Cierra el diálogo
                _eliminarCatedratico();
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  void _eliminarCatedratico() {
    final id = widget.catedraticoId;
    context.read<DatosAcademicosMock>().eliminarCatedratico(id);

    if (!mounted) return;
    
    // Regresamos dos veces o al inicio según tu navegación para salir del perfil y edición
    Navigator.of(context).popUntil((route) => route.isFirst);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Catedrático eliminado'),
      ),
    );
  }
}