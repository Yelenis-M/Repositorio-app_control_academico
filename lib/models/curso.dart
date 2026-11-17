import 'package:flutter/material.dart';

import 'horario_curso.dart';

/// Materia del plan de estudios.
///
/// El nombre, los créditos y los requisitos llegan del plan (más adelante,
/// de Firestore) y no se editan en la app. El resto lo completa el usuario.
class Curso {
  const Curso({
    required this.id,
    required this.semestre,
    required this.nombre,
    required this.creditos,
    required this.requisitos,
    this.catedraticoId,
    this.calificacion,
    this.descripcion = '',
    this.horario,
    this.color,
    this.icono,
  });

  final String id;
  final int semestre;
  final String nombre;
  final int creditos;
  final List<String> requisitos;
  final String? catedraticoId;
  final double? calificacion;
  final String descripcion;
  final HorarioCurso? horario;
  final Color? color;
  final IconData? icono;

  bool get tieneCalificacion => calificacion != null;

  /// Conserva nombre, créditos, requisitos y descripción.
  /// Borra catedrático, calificación, horario, ícono y color.
  Curso sinDatosIngresados() {
    return Curso(
      id: id,
      semestre: semestre,
      nombre: nombre,
      creditos: creditos,
      requisitos: requisitos,
      descripcion: descripcion,
    );
  }

  Curso conDatosDeUsuario({
    required String? catedraticoId,
    required double? calificacion,
    required String descripcion,
    required HorarioCurso? horario,
    required Color? color,
    required IconData? icono,
  }) {
    return Curso(
      id: id,
      semestre: semestre,
      nombre: nombre,
      creditos: creditos,
      requisitos: requisitos,
      catedraticoId: catedraticoId,
      calificacion: calificacion,
      descripcion: descripcion,
      horario: horario,
      color: color,
      icono: icono,
    );
  }
}
