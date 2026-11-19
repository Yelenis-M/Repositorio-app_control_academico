import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Catedratico {
  const Catedratico({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    Color? color,
    this.horarioOficina = '',
  }) : color = color ?? AppColors.primary;
  // ...el resto de campos, copyWith, fromMap y toMap queda igual

  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final Color color;
  final String horarioOficina;

  // Alias por compatibilidad con lógica previa
  String get horario => horarioOficina;

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

  factory Catedratico.fromMap(Map<String, dynamic> data, String documentId) {
    final colorInt = (data['color'] as num?)?.toInt();
    // Lee 'horario_oficina' o el antiguo 'horario' para no romper registros previos
    final textoHorario = (data['horario_oficina'] ?? data['horario'] ?? '').toString();

    return Catedratico(
      id: documentId,
      nombre: (data['nombre'] ?? '').toString(),
      correo: (data['correo'] ?? '').toString(),
      telefono: (data['telefono'] ?? '').toString(),
      color: colorInt != null ? Color(colorInt) : null,
      horarioOficina: textoHorario,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre.trim(),
      'correo': correo.trim(),
      'telefono': telefono.trim(),
      'horario_oficina': horarioOficina.trim(),
      'horario': horarioOficina.trim(),
      'color': color.toARGB32(),
    };
  }
}