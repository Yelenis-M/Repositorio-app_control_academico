import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/curso.dart';
import '../models/horario_curso.dart';
import '../models/iconos_materia.dart';

typedef ListaCursos = List<Curso>;
typedef MapaDatos = Map<String, dynamic>;

class NotasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Algoritmo de bloqueo por año de ingreso (Regla 1: Semestre completo)
  int getSemestreMaximoHabilitado(int anioIngreso) {
    final now = DateTime.now();
    final anioActual = now.year;
    final mesActual = now.month;

    final cicloActual = (mesActual <= 6) ? 1 : 2;
    final aniosTranscurridos = anioActual - anioIngreso;

    final semestreMaximo = (aniosTranscurridos * 2) + cicloActual;

    if (semestreMaximo < 1) return 1;
    if (semestreMaximo > 11) return 11;
    return semestreMaximo;
  }

  bool estaSemestreBloqueado(int anioIngreso, int numeroSemestre) {
    final maximoHabilitado = getSemestreMaximoHabilitado(anioIngreso);
    return numeroSemestre > maximoHabilitado;
  }

  // 2. LEER (R): Trae cursos del semestre + datos del alumno + validación de prerrequisitos
  Future<ListaCursos> obtenerCursosPorSemestre(
    String carnet,
    String carreraId,
    int semestre,
  ) async {
    final pensumSnapshot = await _firestore
        .collection('cursos')
        .where('carrera_id', isEqualTo: carreraId)
        .where('semestre', isEqualTo: semestre)
        .get();

    final notasSnapshot = await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('notas')
        .get();

    final Map<String, MapaDatos> mapaDatosUsuario = {};
    final Map<String, double> mapaNotas = {};

    for (var doc in notasSnapshot.docs) {
      final data = doc.data();
      mapaDatosUsuario[doc.id] = data;
      if (data['nota'] != null) {
        mapaNotas[doc.id] = (data['nota'] as num).toDouble();
      }
    }

    final regExpCodigos = RegExp(r'[A-Z]{4}\d{4}');

    final lista = pensumSnapshot.docs.map((doc) {
      final data = doc.data();
      final codigoCurso = (data['codigo'] ?? doc.id).toString();
      final textoPrereq = (data['prerequisitos'] ?? 'Ninguno').toString();

      final coincidencias = regExpCodigos.allMatches(textoPrereq);
      final List<String> faltantes = [];

      for (var match in coincidencias) {
        final codigoReq = match.group(0)!;
        final notaReq = mapaNotas[codigoReq];
        if (notaReq == null || notaReq < 61.0) {
          faltantes.add(codigoReq);
        }
      }

      return Curso.fromMap(
        data,
        doc.id,
        datosUsuario: mapaDatosUsuario[codigoCurso],
        bloqueadoPorPrerequisito: faltantes.isNotEmpty,
        prerequisitosFaltantes: faltantes.join(', '),
      );
    }).toList();

    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  // 3. CREAR / ACTUALIZAR (C / U): Guarda nota (opcional) y personalización del curso
  Future<void> guardarNota(
    String carnet,
    String codigoCurso,
    double? nota, {
    String? catedratico,
    String? catedraticoId,
    String? descripcion,
    HorarioCurso? horario,
    Color? color,
    IconData? icono,
    String carreraId = 'sistemas',
  }) async {
    final MapaDatos datosGuardar = {
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    };

    // Validación 0–100 antes de guardar; si nota es null, borra solo la nota previa
    if (nota != null) {
      double notaSegura = nota;
      if (notaSegura < 0) notaSegura = 0;
      if (notaSegura > 100) notaSegura = 100;
      datosGuardar['nota'] = notaSegura;
    } else {
      datosGuardar['nota'] = FieldValue.delete();
    }

    if (catedratico != null) {
      datosGuardar['catedratico'] = catedratico.trim();
    }
    if (catedraticoId != null) {
      datosGuardar['catedratico_id'] = catedraticoId.trim();
    }
    if (descripcion != null) {
      datosGuardar['descripcion'] = descripcion.trim();
    }
    if (horario != null) {
      datosGuardar['horario'] = horario.toMap();
    }
    if (color != null) {
      datosGuardar['color'] = color.toARGB32();
    }
    if (icono != null) {
      final idx = iconosMateria.indexOf(icono);
      if (idx != -1) {
        datosGuardar['icono_index'] = idx;
      }
    }

    await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('notas')
        .doc(codigoCurso)
        .set(datosGuardar, SetOptions(merge: true))
        .timeout(const Duration(seconds: 3), onTimeout: () {});

    final cursoQuery = await _firestore
        .collection('cursos')
        .where('carrera_id', isEqualTo: carreraId)
        .where('codigo', isEqualTo: codigoCurso)
        .limit(1)
        .get();

    final int semestre = cursoQuery.docs.isNotEmpty
        ? ((cursoQuery.docs.first.data()['semestre'] as num?)?.toInt() ?? 1)
        : 1;

    await obtenerResumenPorSemestre(carnet, carreraId, semestre);
    await obtenerResumenGlobal(carnet, carreraId);
  }

  // Atajo directo para guardar desde un objeto Curso editado en el Frontend de Yelenis
  Future<void> guardarCursoCompleto(String carnet, Curso curso) async {
    await guardarNota(
      carnet,
      curso.id,
      curso.calificacion,
      catedratico: curso.catedraticoNombre,
      catedraticoId: curso.catedraticoId,
      descripcion: curso.descripcion,
      horario: curso.horario,
      color: curso.color,
      icono: curso.icono,
      carreraId: curso.carreraId,
    );
  }

  // 4. ELIMINAR (D): Borra los datos del usuario para un curso (equivalente a sinDatosIngresados)
  Future<void> eliminarNota(
    String carnet,
    String codigoCurso, {
    String carreraId = 'sistemas',
  }) async {
    final cursoQuery = await _firestore
        .collection('cursos')
        .where('carrera_id', isEqualTo: carreraId)
        .where('codigo', isEqualTo: codigoCurso)
        .limit(1)
        .get();

    final int semestre = cursoQuery.docs.isNotEmpty
        ? ((cursoQuery.docs.first.data()['semestre'] as num?)?.toInt() ?? 1)
        : 1;

    await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('notas')
        .doc(codigoCurso)
        .delete()
        .timeout(const Duration(seconds: 3), onTimeout: () {});

    await obtenerResumenPorSemestre(carnet, carreraId, semestre);
    await obtenerResumenGlobal(carnet, carreraId);
  }

  // 5. Estadísticas de UN semestre específico
  Future<MapaDatos> obtenerResumenPorSemestre(
    String carnet,
    String carreraId,
    int semestre,
  ) async {
    final cursos = await obtenerCursosPorSemestre(carnet, carreraId, semestre);

    int aprobados = 0;
    int reprobados = 0;
    int creditosSemestre = 0;
    double sumaNotas = 0.0;
    int cursosEvaluados = 0;

    for (var c in cursos) {
      if (c.calificacion != null) {
        cursosEvaluados++;
        sumaNotas += c.calificacion!;
        if (c.aprobado) {
          aprobados++;
          creditosSemestre += c.creditos;
        } else {
          reprobados++;
        }
      }
    }

    final promedioSemestre = cursosEvaluados > 0
        ? double.parse((sumaNotas / cursosEvaluados).toStringAsFixed(2))
        : 0.0;

    final MapaDatos resumenSemestre = {
      'semestre': semestre,
      'total_cursos_semestre': cursos.length,
      'cursos_evaluados': cursosEvaluados,
      'cursos_aprobados': aprobados,
      'cursos_reprobados': reprobados,
      'creditos_semestre': creditosSemestre,
      'promedio_semestre': promedioSemestre,
      'ultima_actualizacion': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('semestres')
        .doc('semestre_$semestre')
        .set(resumenSemestre, SetOptions(merge: true))
        .timeout(const Duration(seconds: 3), onTimeout: () {});

    return resumenSemestre;
  }

  // Carga los 11 semestres en solo 2 lecturas de Firestore (ideal para login y modo offline)
  Future<ListaCursos> obtenerTodosLosCursos(
    String carnet,
    String carreraId,
  ) async {
    final pensumSnapshot = await _firestore
        .collection('cursos')
        .where('carrera_id', isEqualTo: carreraId)
        .get();

    final notasSnapshot = await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('notas')
        .get();

    final Map<String, MapaDatos> mapaDatosUsuario = {};
    final Map<String, double> mapaNotas = {};

    for (var doc in notasSnapshot.docs) {
      final data = doc.data();
      mapaDatosUsuario[doc.id] = data;
      if (data['nota'] != null) {
        mapaNotas[doc.id] = (data['nota'] as num).toDouble();
      }
    }

    // Mapa código -> nombre real para traducir los prerrequisitos
    final Map<String, String> mapaNombresCursos = {};
    for (var doc in pensumSnapshot.docs) {
      final data = doc.data();
      final codigo = (data['codigo'] ?? doc.id).toString().trim().toUpperCase();
      final nombre = (data['nombre'] ?? '').toString().trim();
      if (codigo.isNotEmpty && nombre.isNotEmpty) {
        mapaNombresCursos[codigo] = nombre;
      }
    }

    final regExpCodigos = RegExp(r'[A-Z]{4}\d{4}');

    final lista = pensumSnapshot.docs.map((doc) {
      final data = doc.data();
      final codigoCurso = (data['codigo'] ?? doc.id).toString();
      final textoPrereq = (data['prerequisitos'] ?? 'Ninguno').toString();

      final coincidencias = regExpCodigos.allMatches(textoPrereq);
      final List<String> faltantes = [];

      for (var match in coincidencias) {
        final codigoReq = match.group(0)!;
        final notaReq = mapaNotas[codigoReq];
        if (notaReq == null || notaReq < 61.0) {
          faltantes.add(codigoReq);
        }
      }

      return Curso.fromMap(
        data,
        doc.id,
        datosUsuario: mapaDatosUsuario[codigoCurso],
        bloqueadoPorPrerequisito: faltantes.isNotEmpty,
        prerequisitosFaltantes: faltantes.join(', '),
        mapaNombresCursos: mapaNombresCursos,
      );
    }).toList();

    lista.sort((a, b) {
      final cmpSem = a.semestre.compareTo(b.semestre);
      if (cmpSem != 0) return cmpSem;
      return a.nombre.compareTo(b.nombre);
    });

    return lista;
  }

  // 6. Estadísticas globales de toda la carrera
  Future<MapaDatos> obtenerResumenGlobal(
    String carnet,
    String carreraId,
  ) async {
    final cursosSnapshot = await _firestore
        .collection('cursos')
        .where('carrera_id', isEqualTo: carreraId)
        .get();

    final notasSnapshot = await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('notas')
        .get();

    final Map<String, double> notasMap = {};
    for (var doc in notasSnapshot.docs) {
      final valor = doc.data()['nota'];
      if (valor != null) {
        notasMap[doc.id] = (valor as num).toDouble();
      }
    }

    int aprobados = 0;
    int reprobados = 0;
    int creditosAcumulados = 0;
    double sumaNotas = 0.0;
    int cursosEvaluados = 0;

    for (var doc in cursosSnapshot.docs) {
      final data = doc.data();
      final codigo = (data['codigo'] ?? doc.id).toString();
      final creditos = (data['creditos'] as num?)?.toInt() ?? 0;

      if (notasMap.containsKey(codigo)) {
        final nota = notasMap[codigo]!;
        cursosEvaluados++;
        sumaNotas += nota;

        if (nota >= 61.0) {
          aprobados++;
          creditosAcumulados += creditos;
        } else {
          reprobados++;
        }
      }
    }

    final promedio = cursosEvaluados > 0
        ? double.parse((sumaNotas / cursosEvaluados).toStringAsFixed(2))
        : 0.0;

    await _firestore.collection('usuarios').doc(carnet).set({
      'promedio_global': promedio,
      'cursos_aprobados': aprobados,
      'cursos_reprobados': reprobados,
      'creditos_acumulados': creditosAcumulados,
      'cursos_evaluados': cursosEvaluados,
    }, SetOptions(merge: true)).timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );

    return {
      'totalCursosPensum': cursosSnapshot.docs.length,
      'cursosEvaluados': cursosEvaluados,
      'aprobados': aprobados,
      'reprobados': reprobados,
      'creditosAcumulados': creditosAcumulados,
      'promedioGlobal': promedio,
    };
  }
}