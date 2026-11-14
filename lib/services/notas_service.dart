import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/curso_model.dart';

typedef ListaCursos = List<CursoModel>;
typedef MapaResumen = Map<String, dynamic>;

class NotasService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. Calcula hasta qué semestre tiene desbloqueado según su año de ingreso
  int getSemestreMaximoHabilitado(int anioIngreso) {
    final now = DateTime.now();
    final anioActual = now.year;
    final mesActual = now.month;

    // Enero-Junio: ciclo 1 | Julio-Diciembre: ciclo 2
    final cicloActual = (mesActual <= 6) ? 1 : 2;
    final aniosTranscurridos = anioActual - anioIngreso;

    final semestreMaximo = (aniosTranscurridos * 2) + cicloActual;

    if (semestreMaximo < 1) return 1;
    if (semestreMaximo > 10) return 10;
    return semestreMaximo;
  }

  bool estaSemestreBloqueado(int anioIngreso, int numeroSemestre) {
    final maximoHabilitado = getSemestreMaximoHabilitado(anioIngreso);
    return numeroSemestre > maximoHabilitado;
  }

  // 2. Trae los cursos del semestre y les une la nota que tenga el alumno
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
    for (var doc in notasSnapshot.docs) {
      final valor = doc.data()['nota'];
      if (valor != null) {
        mapaNotas[doc.id] = (valor as num).toDouble();
      }
    }

    return pensumSnapshot.docs.map((doc) {
      final codigoCurso = doc.id;
      final notaRegistrada = mapaNotas[codigoCurso];
      return CursoModel.fromMap(
        doc.data(),
        codigoCurso,
        nota: notaRegistrada,
      );
    }).toList();
  }

  // 3. Guardar o modificar una nota
  Future<void> guardarNota(String carnet, String codigoCurso, double nota) async {
    await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('notas')
        .doc(codigoCurso)
        .set({
      'nota': nota,
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 4. Borrar una nota
  Future<void> eliminarNota(String carnet, String codigoCurso) async {
    await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('notas')
        .doc(codigoCurso)
        .delete();
  }

  // 5. Resumen global de carrera (Promedio, aprobados, reprobados, créditos)
  Future<MapaResumen> obtenerResumenGlobal(
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

    final promedio = cursosEvaluados > 0 ? (sumaNotas / cursosEvaluados) : 0.0;

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