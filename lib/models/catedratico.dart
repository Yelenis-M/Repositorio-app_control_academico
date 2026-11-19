import 'package:flutter/material.dart';
import '../theme/app_colors.dart'; // Asegúrate de importar tu archivo de colores

/// Profesor creado por el usuario. Los datos viven en memoria hasta que
/// se conecte Firestore.
class Catedratico {
  const Catedratico({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    Color? color, // Ahora es opcional (nullable en el parámetro)
    this.horarioOficina = '',
  }) : color = color ?? AppColors.primary; // 👈 Si es null, asigna el color primario por defecto

  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final Color color; // Ya no es nullable, siempre tendrá un color seguro
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