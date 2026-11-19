import 'package:flutter/material.dart';
import 'horario_curso.dart';
import 'iconos_materia.dart';

/// Materia del plan de estudios unificada (Frontend + Backend Firestore).
class Curso {
  const Curso({
    required this.id,
    required this.semestre,
    required this.nombre,
    required this.creditos,
    required this.requisitos,
    this.carreraId = 'sistemas',
    this.catedraticoId,
    this.catedraticoNombre,
    this.calificacion,
    this.descripcion = '',
    this.horario,
    this.color,
    this.icono,
    this.prerequisitosTexto = 'Ninguno',
    this.bloqueadoPorPrerequisito = false,
    this.prerequisitosFaltantes = '',
  });

  final String id;
  final int semestre;
  final String nombre;
  final int creditos;
  final List<String> requisitos;
  final String carreraId;
  final String? catedraticoId;
  final String? catedraticoNombre;
  final double? calificacion;
  final String descripcion;
  final HorarioCurso? horario;
  final Color? color;
  final IconData? icono;

  // Reglas de negocio de Backend
  final String prerequisitosTexto;
  final bool bloqueadoPorPrerequisito;
  final String prerequisitosFaltantes;

  // Getters de Yelenis y tuyos unificados
  bool get tieneCalificacion => calificacion != null;
  String get codigo => id;
  double? get nota => calificacion;
  String? get catedratico => catedraticoNombre;
  bool get aprobado => (calificacion ?? 0) >= 61.0;
  int get creditosObtenidos => aprobado ? creditos : 0;

  String get prerequisitosNombresLimpios {
    if (requisitos.isEmpty) return 'Ninguno';
    return requisitos.join(', ');
  }

  Curso sinDatosIngresados() {
    return Curso(
      id: id,
      semestre: semestre,
      nombre: nombre,
      creditos: creditos,
      requisitos: requisitos,
      carreraId: carreraId,
      descripcion: '',
      prerequisitosTexto: prerequisitosTexto,
      bloqueadoPorPrerequisito: bloqueadoPorPrerequisito,
      prerequisitosFaltantes: prerequisitosFaltantes,
    );
  }

  Curso conDatosDeUsuario({
    required String? catedraticoId,
    required double? calificacion,
    required String descripcion,
    required HorarioCurso? horario,
    required Color? color,
    required IconData? icono,
    String? catedraticoNombre,
  }) {
    return Curso(
      id: id,
      semestre: semestre,
      nombre: nombre,
      creditos: creditos,
      requisitos: requisitos,
      carreraId: carreraId,
      catedraticoId: catedraticoId,
      catedraticoNombre: catedraticoNombre ?? this.catedraticoNombre,
      calificacion: calificacion,
      descripcion: descripcion,
      horario: horario,
      color: color,
      icono: icono,
      prerequisitosTexto: prerequisitosTexto,
      bloqueadoPorPrerequisito: bloqueadoPorPrerequisito,
      prerequisitosFaltantes: prerequisitosFaltantes,
    );
  }

  factory Curso.fromMap(
    Map<String, dynamic> dataCurso,
    String documentId, {
    Map<String, dynamic>? datosUsuario,
    bool bloqueadoPorPrerequisito = false,
    String prerequisitosFaltantes = '',
  }) {
    final codigoLimpio = (dataCurso['codigo'] ?? documentId).toString();
    final textoPrereq = (dataCurso['prerequisitos'] ?? 'Ninguno').toString();

    // Convierte "SIST2015 - Intro a la Prog, MATE2015 - Mate" -> ['Intro a la Prog', 'Mate']
    final List<String> listaRequisitos = _extraerNombresRequisitos(textoPrereq);

    // Extraer personalización y nota guardada en usuarios/{carnet}/notas/{codigo}
    final notaRaw = datosUsuario?['nota'];
    final double? calificacion = notaRaw != null ? (notaRaw as num).toDouble() : null;

    final String? catId = _textoOpcional(datosUsuario?['catedratico_id']);
    final String? catNombre = _textoOpcional(datosUsuario?['catedratico']);
    final String desc = (datosUsuario?['descripcion'] ?? '').toString();
    final HorarioCurso? horario = HorarioCurso.fromDynamic(datosUsuario?['horario']);

    final colorInt = (datosUsuario?['color'] as num?)?.toInt();
    final Color? color = colorInt != null ? Color(colorInt) : null;

    final iconoIndex = (datosUsuario?['icono_index'] as num?)?.toInt();
    final IconData? icono =
        (iconoIndex != null && iconoIndex >= 0 && iconoIndex < iconosMateria.length)
            ? iconosMateria[iconoIndex]
            : null;

    return Curso(
      id: codigoLimpio,
      semestre: (dataCurso['semestre'] as num?)?.toInt() ?? 1,
      nombre: (dataCurso['nombre'] ?? '').toString(),
      creditos: (dataCurso['creditos'] as num?)?.toInt() ?? 0,
      requisitos: listaRequisitos,
      carreraId: (dataCurso['carrera_id'] ?? 'sistemas').toString(),
      catedraticoId: catId,
      catedraticoNombre: catNombre,
      calificacion: calificacion,
      descripcion: desc,
      horario: horario,
      color: color,
      icono: icono,
      prerequisitosTexto: textoPrereq,
      bloqueadoPorPrerequisito: bloqueadoPorPrerequisito,
      prerequisitosFaltantes: prerequisitosFaltantes,
    );
  }

  static List<String> _extraerNombresRequisitos(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty || limpio.toLowerCase() == 'ninguno') return const [];

    return limpio
        .split(',')
        .map((p) => p.replaceAll(RegExp(r'[A-Z]{4}\d{4}\s*-\s*'), '').trim())
        .where((p) => p.isNotEmpty)
        .toList();
  }

  static String? _textoOpcional(dynamic valor) {
    if (valor == null) return null;
    final texto = valor.toString().trim();
    return texto.isEmpty ? null : texto;
  }
}