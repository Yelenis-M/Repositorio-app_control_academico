import 'package:flutter/material.dart';

/// Profesor creado por el usuario. Los datos viven en memoria hasta que
/// se conecte Firestore.
class Catedratico {
  const Catedratico({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.color,
    this.horarioOficina = '',
  });

  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final Color color;
  final String horarioOficina;

  Catedratico copyWith({
    String? nombre,
    String? correo,
    String? telefono,
    Color? color,
    String? horarioOficina,
  }) {
    return Catedratico(
      id: id,
      nombre: nombre ?? this.nombre,
      correo: correo ?? this.correo,
      telefono: telefono ?? this.telefono,
      color: color ?? this.color,
      horarioOficina: horarioOficina ?? this.horarioOficina,
    );
  }
}