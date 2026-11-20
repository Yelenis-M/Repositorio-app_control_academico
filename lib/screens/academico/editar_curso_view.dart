import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/datos_academicos_mock.dart';
import '../../models/catedratico.dart';
import '../../models/curso.dart';
import '../../models/estado_nota.dart';
import '../../models/horario_curso.dart';
import '../../models/iconos_materia.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/selector_color_rgb.dart';
import 'editar_catedratico_view.dart';
import 'form_catedratico_view.dart';

/// Pantalla para modificar color, ícono, catedrático, nota, descripción y horario.
class EditarCursoView extends StatefulWidget {
  const EditarCursoView({
    super.key,
    required this.cursoId,
    this.onActualizar,
  });

  final String cursoId;

  /// Si se define, reemplaza la actualización en la lista local.
  final Future<void> Function(Curso curso)? onActualizar;

  @override
  State<EditarCursoView> createState() => _EditarCursoViewState();
}

class _EditarCursoViewState extends State<EditarCursoView> {
  final _formKey = GlobalKey<FormState>();
  final _calificacion = TextEditingController();
  final _descripcion = TextEditingController();
  final _inicio = TextEditingController();
  final _fin = TextEditingController();

  Curso? _curso;
  String? _catedraticoId;
  late Color _color;
  late IconData _icono;
  bool _inicioEsPm = false;
  bool _finEsPm = false;
  String? _errorHorario;

  @override
  void initState() {
    super.initState();
    final curso = context.read<DatosAcademicosMock>().buscarCurso(widget.cursoId);
    _curso = curso;
    _color = curso?.color ?? AppColors.primary;
    _icono = curso?.icono ?? Icons.menu_book_rounded;
    _catedraticoId = curso?.catedraticoId;
    _descripcion.text = curso?.descripcion ?? '';

    final nota = curso?.calificacion;
    if (nota != null) {
      _calificacion.text = formatearNota(nota);
    }

    final horario = curso?.horario;
    if (horario != null) {
      _inicio.text = horario.inicio;
      _fin.text = horario.fin;
      _inicioEsPm = horario.inicioEsPm;
      _finEsPm = horario.finEsPm;
    }
  }

  @override
  void dispose() {
    _calificacion.dispose();
    _descripcion.dispose();
    _inicio.dispose();
    _fin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curso = _curso;
    if (curso == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Editar asignatura'),
        ),
        body: const AppBackground(
          child: Center(child: Text('No se encontró la materia.')),
        ),
      );
    }

    final esquema = Theme.of(context).colorScheme;
    final catedratico = context.watch<DatosAcademicosMock>().buscarCatedratico(
          _catedraticoId,
        );
    final nota = _leerNota(_calificacion.text);
    final colorNota = nota == null
        ? esquema.onSurfaceVariant
        : colorEstadoNota(context, aprobado: esNotaAprobada(nota));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Editar asignatura'),
      ),
      body: AppBackground(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            children: [
              Text(
                curso.nombre,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'El nombre, los créditos y los requisitos no se pueden editar.',
                style: TextStyle(
                  fontSize: 13,
                  color: esquema.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              const _TituloSeccion('Color de la materia'),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Icon(
                    Icons.palette_outlined,
                    color: esquema.primary,
                  ),
                  title: const Text('Color de la materia'),
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
              const SizedBox(height: 18),
              const _TituloSeccion('Ícono de la materia'),
              const SizedBox(height: 8),
              AppCard(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: iconosMateria.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, indice) {
                    final icono = iconosMateria[indice];
                    final seleccionado = icono == _icono;
                    return Material(
                      color: seleccionado
                          ? _color
                          : esquema.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => setState(() => _icono = icono),
                        child: Icon(
                          icono,
                          size: 22,
                          color: seleccionado
                              ? AppColors.contraste(_color)
                              : esquema.onSurfaceVariant,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              const _TituloSeccion('Catedrático'),
              const SizedBox(height: 8),
              AppCard(
                padding: EdgeInsets.zero,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: (catedratico?.color ?? esquema.primary)
                        .withValues(alpha: 0.16),
                    child: Icon(
                      Icons.person_rounded,
                      color: catedratico?.color ?? esquema.primary,
                    ),
                  ),
                  title: Text(catedratico?.nombre ?? 'Seleccionar profesor'),
                  subtitle: Text(
                    catedratico == null
                        ? 'Abre la lista de profesores'
                        : catedratico.correo,
                  ),
                  trailing: Icon(Icons.expand_more, color: esquema.primary),
                  onTap: _abrirSelectorProfesor,
                ),
              ),
              const SizedBox(height: 18),
              const _TituloSeccion('Calificación'),
              const SizedBox(height: 8),
              AppTextField(
                controller: _calificacion,
                label: 'Calificación',
                hint: 'Ejemplo: 85',
                prefixIcon: Icons.grade_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  LengthLimitingTextInputFormatter(6),
                ],
                onChanged: (_) => setState(() {}),
                validator: _validarCalificacion,
              ),
              const SizedBox(height: 8),
              Text(
                nota == null
                    ? 'Sin calificación todavía. 61 o más es aprobado.'
                    : etiquetaEstado(nota: nota, femenino: false),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorNota,
                ),
              ),
              const SizedBox(height: 18),
              const _TituloSeccion('Descripción del curso'),
              const SizedBox(height: 8),
              AppTextField(
                controller: _descripcion,
                label: 'Descripción del curso',
                hint: 'Notas o detalles de la materia',
                prefixIcon: Icons.notes_outlined,
                textCapitalization: TextCapitalization.sentences,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 3,
                maxLines: 5,
                maxLength: 400,
              ),
              const SizedBox(height: 18),
              const _TituloSeccion('Horario'),
              const SizedBox(height: 8),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Formato 00:00. Define si es AM o PM.',
                      style: TextStyle(
                        fontSize: 13,
                        color: esquema.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _FilaHora(
                      etiqueta: 'Desde',
                      controller: _inicio,
                      esPm: _inicioEsPm,
                      onPeriodo: (esPm) => setState(() => _inicioEsPm = esPm),
                      onChanged: () {
                        final norm = HorarioCurso.normalizarHora(_inicio.text);
                        setState(() {
                          _errorHorario = null;
                          if (norm != null) {
                            final h = int.parse(norm.split(':')[0]);
                            if (h >= 13) _inicioEsPm = true;
                            if (h == 0) _inicioEsPm = false;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    _FilaHora(
                      etiqueta: 'Hasta',
                      controller: _fin,
                      esPm: _finEsPm,
                      onPeriodo: (esPm) => setState(() => _finEsPm = esPm),
                      onChanged: () {
                        final norm = HorarioCurso.normalizarHora(_fin.text);
                        setState(() {
                          _errorHorario = null;
                          if (norm != null) {
                            final h = int.parse(norm.split(':')[0]);
                            if (h >= 13) _finEsPm = true;
                            if (h == 0) _finEsPm = false;
                          }
                        });
                      },
                    ),
                    if (_vistaPreviaHorario != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _vistaPreviaHorario!,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: esquema.primary,
                        ),
                      ),
                    ],
                    if (_errorHorario != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _errorHorario!,
                        style: TextStyle(color: esquema.error, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                text: 'Actualizar',
                icon: Icons.check_rounded,
                width: double.infinity,
                onPressed: _actualizar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? get _vistaPreviaHorario {
    final inicio = HorarioCurso.normalizarHora(_inicio.text);
    final fin = HorarioCurso.normalizarHora(_fin.text);
    if (inicio == null || fin == null) return null;
    return HorarioCurso(
      inicio: inicio,
      fin: fin,
      inicioEsPm: _inicioEsPm,
      finEsPm: _finEsPm,
    ).etiqueta;
  }

  Future<void> _elegirColor() async {
    final color = await mostrarSelectorColorRgb(
      context: context,
      colorInicial: _color,
      titulo: 'Color de la materia',
    );
    if (color == null || !mounted) return;
    setState(() => _color = color);
  }

  Future<void> _abrirSelectorProfesor() async {
    final id = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        final alto = MediaQuery.sizeOf(sheetContext).height * 0.72;
        return SizedBox(
          height: alto,
          child: _SelectorCatedratico(
            seleccionadoId: _catedraticoId,
            onSeleccionar: (profesorId) {
              Navigator.pop(sheetContext, profesorId);
            },
            onEditar: (profesorId) {
              Navigator.push(
                sheetContext,
                MaterialPageRoute(
                  builder: (_) => EditarCatedraticoView(
                    catedraticoId: profesorId,
                  ),
                ),
              );
            },
            onCrear: () async {
              final nuevo = await Navigator.push<Catedratico>(
                sheetContext,
                MaterialPageRoute(
                  builder: (_) => const FormCatedraticoView(),
                ),
              );
              if (nuevo != null && sheetContext.mounted) {
                Navigator.pop(sheetContext, nuevo.id);
              }
            },
          ),
        );
      },
    );

    if (id == null || !mounted) return;
    setState(() => _catedraticoId = id);
  }

  Future<void> _actualizar() async {
    final errorHorario = _validarHorario();
    final formularioValido = _formKey.currentState!.validate();
    setState(() => _errorHorario = errorHorario);
    if (!formularioValido || errorHorario != null) return;

    final curso = _curso;
    if (curso == null) return;

    final inicio = HorarioCurso.normalizarHora(_inicio.text);
    final fin = HorarioCurso.normalizarHora(_fin.text);
    final horario = (inicio == null || fin == null)
        ? null
        : HorarioCurso(
            inicio: inicio,
            fin: fin,
            inicioEsPm: _inicioEsPm,
            finEsPm: _finEsPm,
          );

    final actualizado = curso.conDatosDeUsuario(
      catedraticoId: _catedraticoId,
      calificacion: _leerNota(_calificacion.text),
      descripcion: _descripcion.text.trim(),
      horario: horario,
      color: _color,
      icono: _icono,
    );

    final datos = context.read<DatosAcademicosMock>();
    final callback = widget.onActualizar;
    if (callback != null) {
      await callback(actualizado);
    } else {
      datos.actualizarCurso(actualizado);
    }

    final hayInternet = await datos.tieneConexionInternet();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            hayInternet
                ? 'Materia actualizada'
                : 'Guardado de forma local (sin internet). Se sincronizará con la nube al reconectarte.',
          ),
        ),
      );
    Navigator.pop(context);
  }

  String? _validarCalificacion(String? valor) {
    final texto = valor?.trim() ?? '';
    if (texto.isEmpty) return null;
    if (_leerNota(texto) == null) {
      return 'Escribe una calificación entre 0 y 100.';
    }
    return null;
  }

  String? _validarHorario() {
    final inicioTexto = _inicio.text.trim();
    final finTexto = _fin.text.trim();
    if (inicioTexto.isEmpty && finTexto.isEmpty) return null;
    if (inicioTexto.isEmpty || finTexto.isEmpty) {
      return 'Completa el horario de inicio y de fin (00:00).';
    }

    final inicioNorm = HorarioCurso.normalizarHora(inicioTexto);
    final finNorm = HorarioCurso.normalizarHora(finTexto);
    if (inicioNorm == null || finNorm == null) {
      return 'Usa una hora válida en formato 12h o 24h (ej. 03:00 o 15:00).';
    }

    final horaInicio = int.parse(inicioNorm.split(':')[0]);
    final horaFin = int.parse(finNorm.split(':')[0]);

    if ((horaInicio >= 13 && !_inicioEsPm) || (horaFin >= 13 && !_finEsPm)) {
      return 'Las horas de 13:00 a 23:59 corresponden a PM.';
    }
    if ((horaInicio == 0 && _inicioEsPm) || (horaFin == 0 && _finEsPm)) {
      return 'Las horas de 00:00 a 00:59 corresponden a AM.';
    }

    final horario = HorarioCurso(
      inicio: inicioNorm,
      fin: finNorm,
      inicioEsPm: _inicioEsPm,
      finEsPm: _finEsPm,
    );

    if (!horario.esRangoValido) {
      return 'La hora de fin debe ser posterior a la hora de inicio.';
    }
    return null;
  }
}

double? _leerNota(String texto) {
  final limpio = texto.trim().replaceAll(',', '.');
  if (limpio.isEmpty) return null;
  final nota = double.tryParse(limpio);
  if (nota == null || nota < 0 || nota > 100) return null;
  return nota;
}

class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

class _FilaHora extends StatelessWidget {
  const _FilaHora({
    required this.etiqueta,
    required this.controller,
    required this.esPm,
    required this.onPeriodo,
    required this.onChanged,
  });

  final String etiqueta;
  final TextEditingController controller;
  final bool esPm;
  final ValueChanged<bool> onPeriodo;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(etiqueta),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 110,
              child: AppTextField(
                controller: controller,
                hint: '00:00',
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                  _FormateadorHora(),
                ],
                onChanged: (_) => onChanged(),
              ),
            ),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('AM')),
                ButtonSegment(value: true, label: Text('PM')),
              ],
              selected: {esPm},
              onSelectionChanged: (seleccion) => onPeriodo(seleccion.first),
            ),
          ],
        ),
      ],
    );
  }
}

/// Inserta automáticamente los dos puntos al escribir el tercer dígito
/// (HHMM -> HH:MM) y preserva la posición del cursor al editar en el medio.
class _FormateadorHora extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitos = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitado = digitos.length > 4 ? digitos.substring(0, 4) : digitos;

    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      // Solo insertamos ':' cuando ya hay al menos 3 dígitos,
      // así "12" no se muestra como "12:".
      if (i == 2 && limitado.length > 2) buffer.write(':');
      buffer.write(limitado[i]);
    }
    final texto = buffer.toString();

    // Cuántos dígitos había antes del cursor en el texto crudo.
    final cursorCrudo =
        newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final digitosAntesDelCursor = newValue.text
        .substring(0, cursorCrudo)
        .replaceAll(RegExp(r'\D'), '')
        .length;

    // Reubicamos el cursor contando solo dígitos en el texto formateado.
    var offset = 0;
    var contados = 0;
    while (offset < texto.length && contados < digitosAntesDelCursor) {
      if (texto[offset] != ':') contados++;
      offset++;
    }

    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

class _SelectorCatedratico extends StatelessWidget {
  const _SelectorCatedratico({
    required this.seleccionadoId,
    required this.onSeleccionar,
    required this.onEditar,
    required this.onCrear,
  });

  final String? seleccionadoId;
  final ValueChanged<String> onSeleccionar;
  final ValueChanged<String> onEditar;
  final Future<void> Function() onCrear;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final profesores = context.watch<DatosAcademicosMock>().catedraticos;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              'Seleccionar profesor',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: esquema.onSurface,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              itemCount: profesores.length,
              separatorBuilder: (context, indice) => const SizedBox(height: 12),
              itemBuilder: (context, indice) {
                final profesor = profesores[indice];
                final seleccionado = profesor.id == seleccionadoId;
                return AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                profesor.color.withValues(alpha: 0.16),
                            child: Icon(
                              Icons.person_rounded,
                              color: profesor.color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profesor.nombre,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  profesor.correo,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: esquema.onSurfaceVariant,
                                  ),
                                ),
                                if (seleccionado)
                                  Text(
                                    'Seleccionado',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: esquema.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Editar',
                              type: AppButtonType.secondary,
                              onPressed: () => onEditar(profesor.id),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: AppButton(
                              text: 'Seleccionar',
                              onPressed: () => onSeleccionar(profesor.id),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: AppButton(
              text: 'Crear profesor',
              icon: Icons.person_add_alt_1_rounded,
              width: double.infinity,
              onPressed: () {
                onCrear();
              },
            ),
          ),
        ],
      ),
    );
  }
}