import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/catedratico.dart';

typedef ListaCatedraticos = List<Catedratico>;

class CatedraticosService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // 1. CREAR (C): Guarda un catedrático en la subcolección privada del alumno (evita duplicados)
  Future<bool> guardarCatedratico({
    required String carnet,
    required String nombre,
    String correo = '',
    String telefono = '',
    String horarioOficina = '',
    Color? color,
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
        return false; // Evita duplicados en el mismo usuario
      }
    }

    final nuevo = Catedratico(
      id: '',
      nombre: nombreLimpio,
      correo: correo,
      telefono: telefono,
      horarioOficina: horarioOficina,
      color: color,
    );

    await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('catedraticos')
        .add({
      ...nuevo.toMap(),
      'fecha_registro': FieldValue.serverTimestamp(),
    });

    return true;
  }

  // Crea o actualiza usando el mismo ID que maneja el Frontend (evita desfase de IDs)
  Future<void> guardarOActualizarPorId({
    required String carnet,
    required Catedratico catedratico,
  }) async {
    final docRef = catedratico.id.trim().isNotEmpty
        ? _firestore
            .collection('usuarios')
            .doc(carnet)
            .collection('catedraticos')
            .doc(catedratico.id.trim())
        : _firestore
            .collection('usuarios')
            .doc(carnet)
            .collection('catedraticos')
            .doc();

    await docRef.set({
      ...catedratico.toMap(),
      'fecha_actualizacion': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)).timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
  }

  // 2. LEER (R): Obtiene la lista de Catedratico del alumno ordenados por nombre
  Future<ListaCatedraticos> obtenerCatedraticos(String carnet) async {
    final snapshot = await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('catedraticos')
        .orderBy('nombre')
        .get();

    return snapshot.docs
        .map((doc) => Catedratico.fromMap(doc.data(), doc.id))
        .toList();
  }

  // 3. ACTUALIZAR (U): Edita un catedrático existente
  Future<void> actualizarCatedratico({
    required String carnet,
    required Catedratico catedratico,
  }) async {
    await _firestore
        .collection('usuarios')
        .doc(carnet)
        .collection('catedraticos')
        .doc(catedratico.id)
        .update(catedratico.toMap());
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