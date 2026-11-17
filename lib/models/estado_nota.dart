import 'package:flutter/material.dart';

import 'curso.dart';

/// Nota mínima para aprobar, inclusive.
const double notaMinimaAprobacion = 61;

bool esNotaAprobada(double nota) => nota >= notaMinimaAprobacion;

/// Verde si la nota aprueba y rojo si reprueba.
/// Se ajusta al brillo para que el texto se lea en claro y en oscuro.
Color colorEstadoNota(BuildContext context, {required bool aprobado}) {
  final oscuro = Theme.of(context).brightness == Brightness.dark;
  if (aprobado) {
    return oscuro ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
  }
  return oscuro ? const Color(0xFFEF9A9A) : const Color(0xFFC62828);
}

String formatearNota(double nota) {
  if (nota == nota.roundToDouble()) {
    return nota.toStringAsFixed(0);
  }
  return nota.toStringAsFixed(2);
}

/// [femenino] usa Aprobada / Reprobada, junto al nombre de la materia.
String etiquetaEstado({
  required double? nota,
  required bool femenino,
  String sinNota = 'Sin nota',
}) {
  if (nota == null) return sinNota;
  final aprobada = esNotaAprobada(nota);
  if (femenino) return aprobada ? 'Aprobada' : 'Reprobada';
  return aprobada ? 'Aprobado' : 'Reprobado';
}

String textoBadgeNota(double? nota) {
  if (nota == null) return 'Sin nota';
  return '${formatearNota(nota)} · ${etiquetaEstado(nota: nota, femenino: false)}';
}

class ResumenSemestre {
  const ResumenSemestre({
    required this.aprobados,
    required this.reprobados,
    required this.promedio,
    required this.creditosTotales,
  });

  final int aprobados;
  final int reprobados;
  final double? promedio;
  final int creditosTotales;

  factory ResumenSemestre.desde(List<Curso> cursos) {
    var aprobados = 0;
    var reprobados = 0;
    var suma = 0.0;
    var conNota = 0;
    var creditos = 0;

    for (final curso in cursos) {
      // Sumamos inicialmente los créditos del curso
      creditos += curso.creditos;
      
      final nota = curso.calificacion;
      if (nota == null) continue;
      
      conNota += 1;
      suma += nota;
      
      if (esNotaAprobada(nota)) {
        aprobados += 1;
      } else {
        reprobados += 1;
        // Si la materia está reprobada, restamos sus créditos del total
        creditos -= curso.creditos;
      }
    }

    return ResumenSemestre(
      aprobados: aprobados,
      reprobados: reprobados,
      promedio: conNota == 0 ? null : suma / conNota,
      creditosTotales: creditos,
    );
  }

  String get textoPromedio {
    final valor = promedio;
    if (valor == null) return '—';
    return valor.toStringAsFixed(2);
  }
}