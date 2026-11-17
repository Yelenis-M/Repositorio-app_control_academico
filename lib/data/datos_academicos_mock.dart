import 'dart:async';

import 'package:flutter/material.dart';

import '../models/catedratico.dart';
import '../models/curso.dart';
import '../models/horario_curso.dart';

/// Datos locales del módulo académico.
///
/// Las vistas solo hablan con estos métodos. Cuando Gerson conecte Firestore
/// puede reemplazar el cuerpo de cada método (o asignar los callbacks) sin
/// cambiar las pantallas.
class DatosAcademicosMock extends ChangeNotifier {
  DatosAcademicosMock() {
    _catedraticos = List.of(_catedraticosIniciales);
    _cursos = List.of(_cursosIniciales);
  }

  /// Se invoca después de crear o editar un catedrático en memoria.
  Future<void> Function(Catedratico catedratico)? alGuardarCatedratico;

  /// Se invoca después de actualizar la información editable de un curso.
  Future<void> Function(Curso curso)? alActualizarCurso;

  /// Se invoca después de borrar catedrático, nota, horario, ícono y color.
  Future<void> Function(String cursoId)? alEliminarInformacionCurso;

  late final List<Catedratico> _catedraticos;
  late final List<Curso> _cursos;

  List<Catedratico> get catedraticos => List.unmodifiable(_catedraticos);

  List<Curso> cursosDelSemestre(int semestre) {
    return List.unmodifiable(
      _cursos.where((curso) => curso.semestre == semestre),
    );
  }

  Curso? buscarCurso(String id) {
    for (final curso in _cursos) {
      if (curso.id == id) return curso;
    }
    return null;
  }

  Catedratico? buscarCatedratico(String? id) {
    if (id == null) return null;
    for (final catedratico in _catedraticos) {
      if (catedratico.id == id) return catedratico;
    }
    return null;
  }

  void guardarCatedratico(Catedratico catedratico) {
    final indice = _catedraticos.indexWhere((item) => item.id == catedratico.id);
    if (indice == -1) {
      _catedraticos.add(catedratico);
    } else {
      _catedraticos[indice] = catedratico;
    }
    notifyListeners();
    _disparar(() => alGuardarCatedratico?.call(catedratico));
  }

  void eliminarCatedratico(String id) {
    _catedraticos.removeWhere((item) => item.id == id);
    notifyListeners();
    // Si tienes algún callback para Firestore, puedes agregarlo aquí también
  }

  void actualizarCurso(Curso curso) {
    final indice = _cursos.indexWhere((item) => item.id == curso.id);
    if (indice == -1) return;
    _cursos[indice] = curso;
    notifyListeners();
    _disparar(() => alActualizarCurso?.call(curso));
  }

  void limpiarInformacionCurso(String cursoId) {
    final indice = _cursos.indexWhere((item) => item.id == cursoId);
    if (indice == -1) return;
    _cursos[indice] = _cursos[indice].sinDatosIngresados();
    notifyListeners();
    _disparar(() => alEliminarInformacionCurso?.call(cursoId));
  }

  void _disparar(Future<void>? Function() accion) {
    final futuro = accion();
    if (futuro != null) {
      unawaited(futuro);
    }
  }
}

const List<Catedratico> _catedraticosIniciales = [
  Catedratico(
    id: 'cat-carlos',
    nombre: 'Ing. Carlos Andrés Méndez López',
    correo: 'carlos.mendez@upana.edu.gt',
    telefono: '5551-1001',
    color: Color(0xFF00838F),
    horarioOficina: 'Lunes y miércoles, 02:00 PM - 04:00 PM',
  ),
  Catedratico(
    id: 'cat-ana',
    nombre: 'Licda. Ana Lucía Ruiz Pérez',
    correo: 'ana.ruiz@upana.edu.gt',
    telefono: '5551-1002',
    color: Color(0xFF6A1B9A),
    horarioOficina: 'Martes y jueves, 10:00 AM - 12:00 PM',
  ),
  Catedratico(
    id: 'cat-luis',
    nombre: 'Ing. Luis Fernando Herrera Díaz',
    correo: 'luis.herrera@upana.edu.gt',
    telefono: '5551-1003',
    color: Color(0xFFEF6C00),
    horarioOficina: 'Viernes, 08:00 AM - 11:00 AM',
  ),
  Catedratico(
    id: 'cat-patricia',
    nombre: 'Dra. Patricia Gómez Salazar',
    correo: 'patricia.gomez@upana.edu.gt',
    telefono: '5551-1004',
    color: Color(0xFF1565C0),
    horarioOficina: 'Lunes, 03:00 PM - 05:00 PM',
  ),
  Catedratico(
    id: 'cat-jorge',
    nombre: 'Mtro. Jorge Antonio Castillo Ramírez',
    correo: 'jorge.castillo@upana.edu.gt',
    telefono: '5551-1005',
    color: Color(0xFF2E7D32),
    horarioOficina: 'Miércoles, 09:00 AM - 11:00 AM',
  ),
];

const List<Curso> _cursosIniciales = [
  Curso(
    id: 's1-mate',
    semestre: 1,
    nombre: 'Matemática Básica',
    creditos: 5,
    requisitos: [],
    catedraticoId: 'cat-ana',
    calificacion: 88,
    descripcion: 'Fundamentos de álgebra y funciones.',
    horario: HorarioCurso(
      inicio: '07:00',
      fin: '08:30',
      inicioEsPm: false,
      finEsPm: false,
    ),
    color: Color(0xFF6A1B9A),
    icono: Icons.calculate_rounded,
  ),
  Curso(
    id: 's1-prog',
    semestre: 1,
    nombre: 'Programación I',
    creditos: 5,
    requisitos: [],
    catedraticoId: 'cat-carlos',
    calificacion: 92,
    descripcion: 'Introducción a la lógica y a la programación.',
    horario: HorarioCurso(
      inicio: '09:00',
      fin: '10:30',
      inicioEsPm: false,
      finEsPm: false,
    ),
    color: Color(0xFF00838F),
    icono: Icons.code_rounded,
  ),
  Curso(
    id: 's1-com',
    semestre: 1,
    nombre: 'Comunicación y Redacción',
    creditos: 3,
    requisitos: [],
    catedraticoId: 'cat-jorge',
    calificacion: 80,
    descripcion: 'Redacción académica y expresión escrita.',
    horario: HorarioCurso(
      inicio: '11:00',
      fin: '12:30',
      inicioEsPm: false,
      finEsPm: true,
    ),
    color: Color(0xFF2E7D32),
    icono: Icons.edit_note_rounded,
  ),
  Curso(
    id: 's1-met',
    semestre: 1,
    nombre: 'Metodología de la Investigación',
    creditos: 3,
    requisitos: [],
    catedraticoId: 'cat-patricia',
    calificacion: 76,
    descripcion: 'Diseño de investigaciones y citación.',
    horario: HorarioCurso(
      inicio: '02:00',
      fin: '03:30',
      inicioEsPm: true,
      finEsPm: true,
    ),
    color: Color(0xFF1565C0),
    icono: Icons.auto_stories_rounded,
  ),
  Curso(
    id: 's2-mate',
    semestre: 2,
    nombre: 'Matemática Intermedia',
    creditos: 5,
    requisitos: ['Matemática Básica'],
    catedraticoId: 'cat-ana',
    calificacion: 70,
    descripcion: 'Cálculo y aplicaciones básicas.',
    horario: HorarioCurso(
      inicio: '07:00',
      fin: '08:40',
      inicioEsPm: false,
      finEsPm: false,
    ),
    color: Color(0xFF6A1B9A),
    icono: Icons.functions_rounded,
  ),
  Curso(
    id: 's2-prog',
    semestre: 2,
    nombre: 'Programación II',
    creditos: 5,
    requisitos: ['Programación I'],
    catedraticoId: 'cat-carlos',
    calificacion: 81,
    descripcion: 'Estructuras de control y programación orientada a objetos.',
    horario: HorarioCurso(
      inicio: '09:00',
      fin: '10:40',
      inicioEsPm: false,
      finEsPm: false,
    ),
    color: Color(0xFF00838F),
    icono: Icons.terminal_rounded,
  ),
  Curso(
    id: 's2-fis',
    semestre: 2,
    nombre: 'Física I',
    creditos: 4,
    requisitos: ['Matemática Básica'],
    catedraticoId: 'cat-luis',
    calificacion: 61,
    descripcion: 'Mecánica clásica. La nota mínima de aprobación es 61.',
    horario: HorarioCurso(
      inicio: '01:00',
      fin: '02:30',
      inicioEsPm: true,
      finEsPm: true,
    ),
    color: Color(0xFFEF6C00),
    icono: Icons.science_rounded,
  ),
  Curso(
    id: 's2-conta',
    semestre: 2,
    nombre: 'Contabilidad General',
    creditos: 3,
    requisitos: [],
    catedraticoId: 'cat-jorge',
    calificacion: 59,
    descripcion: 'Estados financieros y registro contable.',
    horario: HorarioCurso(
      inicio: '03:00',
      fin: '04:30',
      inicioEsPm: true,
      finEsPm: true,
    ),
    color: Color(0xFF2E7D32),
    icono: Icons.account_balance_rounded,
  ),
  Curso(
    id: 's3-ed',
    semestre: 3,
    nombre: 'Estructuras de Datos',
    creditos: 4,
    requisitos: ['Programación II'],
    catedraticoId: 'cat-carlos',
    calificacion: 90,
    descripcion: 'Listas, árboles, grafos y complejidad.',
    horario: HorarioCurso(
      inicio: '07:00',
      fin: '08:30',
      inicioEsPm: false,
      finEsPm: false,
    ),
    color: Color(0xFF00838F),
    icono: Icons.account_tree_rounded,
  ),
  Curso(
    id: 's3-bd',
    semestre: 3,
    nombre: 'Bases de Datos I',
    creditos: 4,
    requisitos: ['Programación II'],
    catedraticoId: 'cat-patricia',
    calificacion: 84,
    descripcion: 'Modelo relacional y SQL.',
    horario: HorarioCurso(
      inicio: '09:00',
      fin: '10:30',
      inicioEsPm: false,
      finEsPm: false,
    ),
    color: Color(0xFF1565C0),
    icono: Icons.storage_rounded,
  ),
  Curso(
    id: 's3-est',
    semestre: 3,
    nombre: 'Estadística I',
    creditos: 3,
    requisitos: ['Matemática Intermedia'],
    catedraticoId: 'cat-ana',
    calificacion: 72,
    descripcion: 'Probabilidad descriptiva y distribuciones.',
    horario: HorarioCurso(
      inicio: '11:00',
      fin: '12:30',
      inicioEsPm: false,
      finEsPm: true,
    ),
    color: Color(0xFF6A1B9A),
    icono: Icons.analytics_rounded,
  ),
  Curso(
    id: 's3-elec',
    semestre: 3,
    nombre: 'Electrónica Básica',
    creditos: 4,
    requisitos: ['Física I'],
    catedraticoId: 'cat-luis',
    calificacion: 55,
    descripcion: 'Circuitos y componentes electrónicos.',
    horario: HorarioCurso(
      inicio: '02:00',
      fin: '03:40',
      inicioEsPm: true,
      finEsPm: true,
    ),
    color: Color(0xFFEF6C00),
    icono: Icons.memory_rounded,
  ),
  Curso(
    id: 's4-prog',
    semestre: 4,
    nombre: 'Programación IV',
    creditos: 4,
    requisitos: ['Estructuras de Datos'],
    catedraticoId: 'cat-carlos',
    calificacion: 86,
    descripcion:
        'Desarrollo de aplicaciones móviles con Flutter y patrones de interfaz.',
    horario: HorarioCurso(
      inicio: '07:00',
      fin: '08:30',
      inicioEsPm: false,
      finEsPm: false,
    ),
    color: Color(0xFF00838F),
    icono: Icons.rocket_launch_rounded,
  ),
  Curso(
    id: 's4-bd',
    semestre: 4,
    nombre: 'Bases de Datos II',
    creditos: 4,
    requisitos: ['Bases de Datos I'],
    catedraticoId: 'cat-patricia',
    calificacion: 78,
    descripcion: 'Consultas avanzadas, transacciones e índices.',
    horario: HorarioCurso(
      inicio: '09:00',
      fin: '10:30',
      inicioEsPm: false,
      finEsPm: false,
    ),
    color: Color(0xFF1565C0),
    icono: Icons.storage_rounded,
  ),
  Curso(
    id: 's4-redes',
    semestre: 4,
    nombre: 'Redes de Computadoras',
    creditos: 4,
    requisitos: ['Electrónica Básica'],
    catedraticoId: 'cat-luis',
    calificacion: 54,
    descripcion: 'Modelos de red, direccionamiento y protocolos.',
    horario: HorarioCurso(
      inicio: '11:00',
      fin: '12:30',
      inicioEsPm: false,
      finEsPm: true,
    ),
    color: Color(0xFFEF6C00),
    icono: Icons.wifi_rounded,
  ),
  Curso(
    id: 's4-soft',
    semestre: 4,
    nombre: 'Ingeniería de Software',
    creditos: 4,
    requisitos: ['Programación II', 'Estructuras de Datos'],
    catedraticoId: 'cat-jorge',
    calificacion: 91,
    descripcion: 'Requisitos, diseño y ciclo de vida del software.',
    horario: HorarioCurso(
      inicio: '02:00',
      fin: '03:30',
      inicioEsPm: true,
      finEsPm: true,
    ),
    color: Color(0xFF2E7D32),
    icono: Icons.account_tree_rounded,
  ),
  Curso(
    id: 's4-so',
    semestre: 4,
    nombre: 'Sistemas Operativos',
    creditos: 4,
    requisitos: ['Estructuras de Datos'],
    catedraticoId: 'cat-carlos',
    calificacion: 60,
    descripcion: 'Procesos, memoria y sistemas de archivos.',
    horario: HorarioCurso(
      inicio: '04:00',
      fin: '05:30',
      inicioEsPm: true,
      finEsPm: true,
    ),
    color: Color(0xFF00838F),
    icono: Icons.memory_rounded,
  ),
  Curso(
    id: 's5-ia',
    semestre: 5,
    nombre: 'Inteligencia Artificial',
    creditos: 4,
    requisitos: ['Estadística I', 'Estructuras de Datos'],
    icono: Icons.psychology_rounded,
    color: Color(0xFF6A1B9A),
  ),
  Curso(
    id: 's5-seg',
    semestre: 5,
    nombre: 'Seguridad Informática',
    creditos: 4,
    requisitos: ['Redes de Computadoras'],
    icono: Icons.security_rounded,
    color: Color(0xFFC62828),
  ),
  Curso(
    id: 's5-proy',
    semestre: 5,
    nombre: 'Administración de Proyectos',
    creditos: 3,
    requisitos: ['Ingeniería de Software'],
    icono: Icons.groups_rounded,
    color: Color(0xFF2E7D32),
  ),
  Curso(
    id: 's5-arq',
    semestre: 5,
    nombre: 'Arquitectura de Computadoras',
    creditos: 4,
    requisitos: ['Sistemas Operativos'],
    icono: Icons.computer_rounded,
    color: Color(0xFF1565C0),
  ),
  // ==========================
  // CURSOS DEL SEMESTRE 5 (Bloqueado / Solo lectura)
  // ==========================
  Curso(
    id: 's5-ia',
    semestre: 5,
    nombre: 'Inteligencia Artificial',
    creditos: 4,
    requisitos: ['Estadística I', 'Estructuras de Datos'],
    catedraticoId: 'cat-ana',
    calificacion: 85, // Calificación de prueba para visualizar en solo lectura
    descripcion: 'Redes neuronales, aprendizaje automático y procesamiento de lenguaje natural.',
    horario: HorarioCurso(
      inicio: '07:00',
      fin: '08:30',
      inicioEsPm: false,
      finEsPm: false,
    ),
    color: Color(0xFF6A1B9A),
    icono: Icons.psychology_rounded,
  ),
  Curso(
    id: 's5-seg',
    semestre: 5,
    nombre: 'Seguridad Informática',
    creditos: 4,
    requisitos: ['Redes de Computadoras'],
    catedraticoId: 'cat-luis',
    calificacion: 90,
    descripcion: 'Criptografía, seguridad en redes y gestión de vulnerabilidades.',
    horario: HorarioCurso(
      inicio: '09:00',
      fin: '10:30',
      inicioEsPm: false,
      finEsPm: false,
    ),
    color: Color(0xFFC62828),
    icono: Icons.security_rounded,
  ),
  Curso(
    id: 's5-proy',
    semestre: 5,
    nombre: 'Administración de Proyectos',
    creditos: 3,
    requisitos: ['Ingeniería de Software'],
    catedraticoId: 'cat-jorge',
    calificacion: 78,
    descripcion: 'Metodologías ágiles, estimación y gestión de equipos de desarrollo.',
    horario: HorarioCurso(
      inicio: '11:00',
      fin: '12:30',
      inicioEsPm: false,
      finEsPm: true,
    ),
    color: Color(0xFF2E7D32),
    icono: Icons.groups_rounded,
  ),
  Curso(
    id: 's5-arq',
    semestre: 5,
    nombre: 'Arquitectura de Computadoras',
    creditos: 4,
    requisitos: ['Sistemas Operativos'],
    catedraticoId: 'cat-carlos',
    calificacion: 65,
    descripcion: 'Estructura de procesadores, jerarquía de memoria y rendimiento.',
    horario: HorarioCurso(
      inicio: '02:00',
      fin: '03:30',
      inicioEsPm: true,
      finEsPm: true,
    ),
    color: Color(0xFF1565C0),
    icono: Icons.computer_rounded,
  ),
];