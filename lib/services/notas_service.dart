import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/curso_model.dart';

typedef ListaCursos = List<CursoModel>;
typedef MapaDatos = Map<String, dynamic>;
typedef ListaMapas = List<MapaDatos>;

class NotasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Algoritmo de bloqueo: calcula el semestre máximo habilitado según año de ingreso
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

  // 2. LEER (R): Trae los cursos del semestre ordenados por nombre + nota + catedrático
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
      if (data['catedratico'] != null) {
        mapaCatedraticos[doc.id] = data['catedratico'].toString();
      }
    }

    final lista = pensumSnapshot.docs.map((doc) {
      final codigoCurso = doc.id;
      return CursoModel.fromMap(
        doc.data(),
        codigoCurso,
        nota: mapaNotas[codigoCurso],
        catedratico: mapaCatedraticos[codigoCurso],
      );
    }).toList();

    lista.sort((a, b) => a.nombre.compareTo(b.nombre));
    return lista;
  }

  // 3. CREAR / ACTUALIZAR (C / U): Guarda o edita nota y catedrático, y recalcula promedios
  Future<void> guardarNota(
    String carnet,
    String codigoCurso,
    double nota, {
    String? catedratico,
    String carreraId = 'sistemas',
  }) async {
    final MapaDatos datosGuardar = {
      'nota': nota,
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    };

    if (catedratico != null) {
      datosGuardar['catedratico'] = catedratico.trim();
    }

    await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('notas')
        .doc(codigoCurso)
        .set(datosGuardar, SetOptions(merge: true));

    final cursoDoc = await _firestore.collection('cursos').doc(codigoCurso).get();
    final int semestre = (cursoDoc.data()?['semestre'] as num?)?.toInt() ?? 1;

    await obtenerResumenPorSemestre(carnet, carreraId, semestre);
    await obtenerResumenGlobal(carnet, carreraId);
  }

  // 4. ELIMINAR (D): Borra el registro de nota/catedrático de un curso y recalcula promedios
  Future<void> eliminarNota(
    String carnet,
    String codigoCurso, {
    String carreraId = 'sistemas',
  }) async {
    final cursoDoc = await _firestore.collection('cursos').doc(codigoCurso).get();
    final int semestre = (cursoDoc.data()?['semestre'] as num?)?.toInt() ?? 1;

    await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('notas')
        .doc(codigoCurso)
        .delete();

    await obtenerResumenPorSemestre(carnet, carreraId, semestre);
    await obtenerResumenGlobal(carnet, carreraId);
  }

  // 5. Estadísticas de UN semestre específico (y sincroniza en usuarios/{carnet}/semestres)
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

  // 6. Estadísticas globales de toda la carrera (y sincroniza en el documento del usuario)
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
      final codigo = doc.id;
      final data = doc.data();
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

  // 7. CRUD CATEDRÁTICOS - CREAR (C)
  Future<void> guardarCatedratico({
    required String nombre,
    String especialidad = '',
    String correo = '',
    String telefono = '',
  }) async {
    await _firestore.collection('catedraticos').add({
      'nombre': nombre.trim(),
      'especialidad': especialidad.trim(),
      'correo': correo.trim(),
      'telefono': telefono.trim(),
      'fecha_registro': FieldValue.serverTimestamp(),
    });
  }

  // 8. CRUD CATEDRÁTICOS - LEER (R)
  Future<ListaMapas> obtenerCatedraticos() async {
    final snapshot = await _firestore
        .collection('catedraticos')
        .orderBy('nombre')
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // 9. CRUD CATEDRÁTICOS - ACTUALIZAR (U)
  Future<void> actualizarCatedratico({
    required String idDocumento,
    required String nombre,
    String especialidad = '',
    String correo = '',
    String telefono = '',
  }) async {
    await _firestore.collection('catedraticos').doc(idDocumento).update({
      'nombre': nombre.trim(),
      'especialidad': especialidad.trim(),
      'correo': correo.trim(),
      'telefono': telefono.trim(),
    });
  }

  // 10. CRUD CATEDRÁTICOS - ELIMINAR (D)
  Future<void> eliminarCatedratico(String idDocumento) async {
    await _firestore.collection('catedraticos').doc(idDocumento).delete();
  }
}