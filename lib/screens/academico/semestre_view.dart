import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/datos_academicos_mock.dart';
import '../../models/curso.dart';
import '../../models/estado_nota.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import 'curso_view.dart';

/// Listado de materias de un semestre, con resumen y orden alfabético.
class SemestreView extends StatefulWidget {
  const SemestreView({
    super.key,
    required this.numeroSemestre,
    this.esBloqueado = false,
    this.onAbrirCurso,
  });

  final int numeroSemestre;
  final bool esBloqueado;

  /// Si se define, reemplaza la navegación hacia el detalle del curso.
  final void Function(Curso curso)? onAbrirCurso;

  @override
  State<SemestreView> createState() => _SemestreViewState();
}

class _SemestreViewState extends State<SemestreView> {
  bool _ascendente = true;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final datos = context.watch<DatosAcademicosMock>();
    final cursos = [...datos.cursosDelSemestre(widget.numeroSemestre)];
    cursos.sort((a, b) {
      final comparacion = a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
      return _ascendente ? comparacion : -comparacion;
    });

    final resumen = ResumenSemestre.desde(cursos);
    final cantidad = cursos.length;
    final textoCantidad = cantidad == 1 ? '1 curso' : '$cantidad cursos';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: const Text('Cursos'),
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _ascendente = !_ascendente),
            icon: const Icon(Icons.sort_by_alpha),
            label: Text(_ascendente ? 'A-Z' : 'Z-A'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Text(
              'Semestre ${widget.numeroSemestre} - $textoCantidad',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: esquema.onSurfaceVariant,
              ),
            ),
            if (widget.esBloqueado) ...[
              const SizedBox(height: 12),
              AppCard(
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, color: esquema.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Este semestre es de solo lectura. Puedes consultar las materias, sin modificarlas.',
                        style: TextStyle(
                          fontSize: 13,
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            _CuadroResumen(resumen: resumen),
            const SizedBox(height: 24),
            const Text(
              'Todos tus cursos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (cursos.isEmpty)
              AppCard(
                child: Column(
                  children: [
                    Icon(
                      Icons.menu_book_outlined,
                      size: 40,
                      color: esquema.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay cursos en este semestre.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: esquema.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else
              for (var i = 0; i < cursos.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _TarjetaMateria(
                  curso: cursos[i],
                  nombreCatedratico: datos
                          .buscarCatedratico(cursos[i].catedraticoId)
                          ?.nombre ??
                      'Sin catedrático',
                  onTap: () => _abrirCurso(cursos[i]),
                ),
              ],
          ],
        ),
      ),
    );
  }

  void _abrirCurso(Curso curso) {
    final abrir = widget.onAbrirCurso;
    if (abrir != null) {
      abrir(curso);
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CursoView(
          cursoId: curso.id,
          soloLectura: widget.esBloqueado,
        ),
      ),
    );
  }
}

class _CuadroResumen extends StatelessWidget {
  const _CuadroResumen({required this.resumen});

  final ResumenSemestre resumen;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return AppCard(
      child: Column(
        children: [
          _FilaResumen(
            icono: Icons.check_circle_outline,
            etiqueta: 'Cursos Aprobados',
            valor: '${resumen.aprobados}',
            colorValor: colorEstadoNota(context, aprobado: true),
          ),
          const Divider(height: 22),
          _FilaResumen(
            icono: Icons.cancel_outlined,
            etiqueta: 'Cursos Reprobados',
            valor: '${resumen.reprobados}',
            colorValor: colorEstadoNota(context, aprobado: false),
          ),
          const Divider(height: 22),
          _FilaResumen(
            icono: Icons.insights_outlined,
            etiqueta: 'Promedio por semestre',
            valor: resumen.textoPromedio,
            colorValor: esquema.onSurface,
          ),
          const Divider(height: 22),
          _FilaResumen(
            icono: Icons.military_tech_outlined,
            etiqueta: 'Sumatoria de créditos totales por semestre',
            valor: '${resumen.creditosTotales}',
            colorValor: esquema.onSurface,
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  const _FilaResumen({
    required this.icono,
    required this.etiqueta,
    required this.valor,
    required this.colorValor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;
  final Color colorValor;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: colorValor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            etiqueta,
            style: TextStyle(
              fontSize: 14,
              height: 1.3,
              color: esquema.onSurface,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          valor,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorValor,
          ),
        ),
      ],
    );
  }
}

class _TarjetaMateria extends StatelessWidget {
  const _TarjetaMateria({
    required this.curso,
    required this.nombreCatedratico,
    required this.onTap,
  });

  final Curso curso;
  final String nombreCatedratico;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final nota = curso.calificacion;
    final colorEstado = nota == null
        ? esquema.onSurfaceVariant
        : colorEstadoNota(context, aprobado: esNotaAprobada(nota));
    final colorIcono = curso.color ?? esquema.primary;
    final icono = curso.icono ?? Icons.menu_book_rounded;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorIcono,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icono,
                    color: AppColors.contraste(colorIcono),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              curso.nombre,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            etiquetaEstado(nota: nota, femenino: true),
                            style: TextStyle(
                              color: colorEstado,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              nombreCatedratico,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: esquema.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _BadgeNota(nota: nota, color: colorEstado),
                        ],
                      ),
                    ],
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

class _BadgeNota extends StatelessWidget {
  const _BadgeNota({
    required this.nota,
    required this.color,
  });

  final double? nota;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        textoBadgeNota(nota),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
