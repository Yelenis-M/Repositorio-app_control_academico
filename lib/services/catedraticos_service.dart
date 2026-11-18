import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/catedratico_model.dart';

typedef ListaModelosCatedraticos = List<CatedraticoModel>;

class CatedraticosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. CREAR (C): Guarda un catedrático en la subcolección privada del alumno (evita duplicados)
  Future<bool> guardarCatedratico({
    required String carnet,
    required String nombre,
    String correo = '',
    String telefono = '',
    String horario = '',
  }) async {
    final nombreLimpio = nombre.trim();
    if (nombreLimpio.isEmpty) return false;

    final existentes = await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('catedraticos')
        .get();

    for (var doc in existentes.docs) {
      final nombreActual = (doc.data()['nombre'] ?? '').toString().trim();
      if (nombreActual.toLowerCase() == nombreLimpio.toLowerCase()) {
        return false; // Ya existe un catedrático con ese nombre en este usuario
      }
    }

    await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('catedraticos')
        .add({
      'nombre': nombreLimpio,
      'correo': correo.trim(),
      'telefono': telefono.trim(),
      'horario': horario.trim(),
      'fecha_registro': FieldValue.serverTimestamp(),
    });

    return true;
  }

  // 2. LEER (R): Obtiene la lista de objetos CatedraticoModel del alumno ordenados por nombre
  Future<ListaModelosCatedraticos> obtenerCatedraticos(String carnet) async {
    final snapshot = await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('catedraticos')
        .orderBy('nombre')
        .get();

    return snapshot.docs
        .map((doc) => CatedraticoModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // 3. ACTUALIZAR (U): Edita los datos de un catedrático existente
  Future<void> actualizarCatedratico({
    required String carnet,
    required String idDocumento,
    required String nombre,
    String correo = '',
    String telefono = '',
    String horario = '',
  }) async {
    await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('catedraticos')
        .doc(idDocumento)
        .update({
      'nombre': nombre.trim(),
      'correo': correo.trim(),
      'telefono': telefono.trim(),
      'horario': horario.trim(),
    });
  }

  // 4. ELIMINAR (D): Borra un catedrático de la agenda del alumno
  Future<void> eliminarCatedratico(String carnet, String idDocumento) async {
    await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('catedraticos')
        .doc(idDocumento)
        .delete();
  }
}