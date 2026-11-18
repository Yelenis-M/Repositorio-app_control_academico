import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/curso_model.dart';

typedef ListaCursos = List<CursoModel>;
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

  // 2. LEER (R): Trae cursos del semestre + valida prerrequisitos (Soporta múltiples pénsums)
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

    final Map<String, double> mapaNotas = {};
    final Map<String, String> mapaCatedraticos = {};

    for (var doc in notasSnapshot.docs) {
      final data = doc.data();
      if (data['nota'] != null) {
        mapaNotas[doc.id] = (data['nota'] as num).toDouble();
      }
      if (data['catedratico'] != null &&
          data['catedratico'].toString().trim().isNotEmpty) {
        mapaCatedraticos[doc.id] = data['catedratico'].toString().trim();
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

      return CursoModel.fromMap(
        data,
        doc.id,
        nota: mapaNotas[codigoCurso],
        catedratico: mapaCatedraticos[codigoCurso],
        bloqueadoPorPrerequisito: faltantes.isNotEmpty,
        prerequisitosFaltantes: faltantes.join(', '),
      );
    }).toList();

    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  // 3. CREAR / ACTUALIZAR (C / U): Guarda o sobreescribe nota y catedrático del curso
  Future<void> guardarNota(
    String carnet,
    String codigoCurso,
    double nota, {
    String? catedratico,
    String? horario, // <-- Nuevo campo opcional de horario para el curso
    String carreraId = 'sistemas',
  }) async {
    final Map<String, dynamic> datosGuardar = {
      'nota': nota,
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    };

    if (nota < 0) nota = 0;
    if (nota > 100) nota = 100;

    if (catedratico != null) {
      datosGuardar['catedratico'] = catedratico.trim();
    }

    if (horario != null) {
      datosGuardar['horario'] = horario.trim(); // <-- Guarda el string del horario (ej. "Viernes, 9:00 am a 11:00 pm")
    }

    await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('notas')
        .doc(codigoCurso)
        .set(datosGuardar, SetOptions(merge: true));

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

  // 4. ELIMINAR (D): Borra el registro de nota/catedrático de un curso y recalcula promedios
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
        .delete();

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
      if (c.nota != null) {
        cursosEvaluados++;
        sumaNotas += c.nota!;
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
        .set(resumenSemestre, SetOptions(merge: true));

    return resumenSemestre;
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
    }, SetOptions(merge: true));

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