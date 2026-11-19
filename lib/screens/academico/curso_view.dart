import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/datos_academicos_mock.dart';
import '../../models/curso.dart';
import '../../models/estado_nota.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'contacto_catedratico_view.dart';
import 'editar_curso_view.dart';

/// Detalle de una materia: resumen, datos del plan y datos del usuario.
class CursoView extends StatelessWidget {
  const CursoView({
    super.key,
    required this.cursoId,
    this.soloLectura = false,
    this.onEliminarInformacion,
  });

  final String cursoId;
  final bool soloLectura;

  /// Si se define, reemplaza el borrado local de la información ingresada.
  final Future<void> Function(String cursoId)? onEliminarInformacion;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final datos = context.watch<DatosAcademicosMock>();
    final curso = datos.buscarCurso(cursoId);
    final bloqueadoTotal =
        soloLectura || (curso?.bloqueadoPorPrerequisito ?? false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Si está bloqueado o en solo lectura, no mostramos los botones de edición ni borrado
          if (!bloqueadoTotal) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: Material(
                color: esquema.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: curso == null ? null : () => _abrirEdicion(context),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: esquema.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Editar',
                          style: TextStyle(
                            color: esquema.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: 'Eliminar información',
              color: esquema.primary,
              onPressed:
                  curso == null ? null : () => _confirmarEliminacion(context),
              icon: const Icon(Icons.delete_outline),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: AppBackground(
        child: curso == null
            ? const Center(child: Text('No se encontró la materia.'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                children: [
                  if (bloqueadoTotal) ...[
                    AppCard(
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, color: esquema.primary),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              curso.bloqueadoPorPrerequisito
                                  ? 'Curso bloqueado. Debes aprobar primero: ${curso.prerequisitosFaltantes}.'
                                  : 'Semestre en solo lectura. No es posible editar ni borrar datos.',
                              style: TextStyle(color: esquema.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _CajaIcono(curso: curso),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          curso.nombre,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ResumenCalificacion(curso: curso),
                  const SizedBox(height: 22),
                  const _SeparadorInformacion(),
                  const SizedBox(height: 16),
                  _BloqueInfo(
                    icono: Icons.account_tree_outlined,
                    titulo: 'Requisitos',
                    child: _ListaRequisitos(requisitos: curso.requisitos),
                  ),
                  const SizedBox(height: 12),
                  _bloqueCatedratico(context, datos, curso),
                  const SizedBox(height: 12),
                  _BloqueInfo(
                    icono: Icons.schedule_outlined,
                    titulo: 'Horario del curso',
                    child: Text(curso.horario?.etiqueta ?? 'Sin horario'),
                  ),
                  const SizedBox(height: 12),
                  _BloqueInfo(
                    icono: Icons.notes_outlined,
                    titulo: 'Descripción del curso',
                    child: Text(
                      curso.descripcion.trim().isEmpty
                          ? 'Sin descripción'
                          : curso.descripcion,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _bloqueCatedratico(
    BuildContext context,
    DatosAcademicosMock datos,
    Curso curso,
  ) {
    final catedratico = datos.buscarCatedratico(curso.catedraticoId);
    final puedeAbrir = catedratico != null;

    return _BloqueInfo(
      icono: Icons.person_outline,
      titulo: 'Catedrático',
      onTap: puedeAbrir
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ContactoCatedraticoView(
                    catedraticoId: catedratico.id,
                    soloLectura: soloLectura,
                  ),
                ),
              );
            }
          : null,
      child: Text(catedratico?.nombre ?? 'Sin asignar'),
    );
  }

  void _abrirEdicion(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditarCursoView(cursoId: cursoId),
      ),
    );
  }

  Future<void> _confirmarEliminacion(BuildContext context) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar información'),
          content: const Text(
            'Se borrarán los datos de catedrático, calificación y horario, '
            'descripción y también las configuraciones de ícono y color de esta materia.',
          ),
          actions: [
            AppButton(
              text: 'Cancelar',
              type: AppButtonType.text,
              onPressed: () => Navigator.pop(dialogContext, false),
            ),
            AppButton(
              text: 'Eliminar',
              onPressed: () => Navigator.pop(dialogContext, true),
            ),
          ],
        );
      },
    );

    if (confirmar != true || !context.mounted) return;

    final callback = onEliminarInformacion;
    if (callback != null) {
      await callback(cursoId);
    } else {
      context.read<DatosAcademicosMock>().limpiarInformacionCurso(cursoId);
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Se eliminó la información de la materia.'),
      ),
    );
  }
}

class _CajaIcono extends StatelessWidget {
  const _CajaIcono({required this.curso});

  final Curso curso;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    // Agregamos el operador de respaldo por seguridad si el modelo aún devuelve nullable
    final color = curso.color ?? esquema.primary;
    final icono = curso.icono ?? Icons.menu_book_rounded;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icono, color: AppColors.contraste(color)),
    );
  }
}

class _ResumenCalificacion extends StatelessWidget {
  const _ResumenCalificacion({required this.curso});

  final Curso curso;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final nota = curso.calificacion;
    final colorEstado = nota == null
        ? esquema.onSurfaceVariant
        : colorEstadoNota(context, aprobado: esNotaAprobada(nota));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de calificación',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          _FilaDato(
            etiqueta: 'Calificación',
            valor: nota == null ? '—' : formatearNota(nota),
          ),
          const SizedBox(height: 8),
          _FilaDato(
            etiqueta: 'Créditos',
            valor: '${curso.creditos}',
          ),
          const SizedBox(height: 8),
          _FilaDato(
            etiqueta: 'Estado',
            valor: nota == null
                ? 'Sin calificación'
                : etiquetaEstado(nota: nota, femenino: false),
            colorValor: colorEstado,
          ),
        ],
      ),
    );
  }
}

class _FilaDato extends StatelessWidget {
  const _FilaDato({
    required this.etiqueta,
    required this.valor,
    this.colorValor,
  });

  final String etiqueta;
  final String valor;
  final Color? colorValor;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            etiqueta,
            style: TextStyle(color: esquema.onSurfaceVariant),
          ),
        ),
        Text(
          valor,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: colorValor ?? esquema.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SeparadorInformacion extends StatelessWidget {
  const _SeparadorInformacion();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Flexible(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'Información del curso',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _BloqueInfo extends StatelessWidget {
  const _BloqueInfo({
    required this.icono,
    required this.titulo,
    required this.child,
    this.onTap,
  });

  final IconData icono;
  final String titulo;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(icono, color: esquema.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      DefaultTextStyle.merge(
                        style: TextStyle(
                          fontSize: 15,
                          color: esquema.onSurface,
                          height: 1.35,
                        ),
                        child: child,
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: esquema.primary),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lista de requisitos con viñetas, wrap de texto y "ver más / ver menos".
class _ListaRequisitos extends StatefulWidget {
  const _ListaRequisitos({required this.requisitos});

  final List<String> requisitos;

  @override
  State<_ListaRequisitos> createState() => _ListaRequisitosState();
}

class _ListaRequisitosState extends State<_ListaRequisitos> {
  static const _maxVisibles = 4;
  bool _expandido = false;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    if (widget.requisitos.isEmpty) {
      return const Text('Ninguno');
    }

    final visibles = _expandido
        ? widget.requisitos
        : widget.requisitos.take(_maxVisibles).toList();
    final restantes = widget.requisitos.length - visibles.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final requisito in visibles)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 8),
                  child: Icon(
                    Icons.circle,
                    size: 6,
                    color: esquema.primary,
                  ),
                ),
                // Expanded permite que el texto haga wrap y no desborde
                Expanded(
                  child: Text(
                    requisito,
                    softWrap: true,
                  ),
                ),
              ],
            ),
          ),
        if (restantes > 0 || _expandido)
          TextButton(
            onPressed: () => setState(() => _expandido = !_expandido),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              _expandido ? 'Ver menos' : 'Ver $restantes más',
            ),
          ),
      ],
    );
  }
}