import 'dart:async';

import 'package:flutter/material.dart';

import '../models/catedratico.dart';
import '../models/curso.dart';
import '../models/usuario_model.dart';
import '../services/catedraticos_service.dart';
import '../services/notas_service.dart';

/// Provider central del módulo académico conectado a Firestore (con caché offline).
class DatosAcademicosMock extends ChangeNotifier {
  NotasService? _notasServiceInst;
  CatedraticosService? _catedraticosServiceInst;

  // Inicialización perezosa para no fallar si se instancia antes de Firebase.initializeApp
  NotasService get _notasService => _notasServiceInst ??= NotasService();
  CatedraticosService get _catedraticosService =>
      _catedraticosServiceInst ??= CatedraticosService();

  /// Callbacks opcionales conservados por compatibilidad con el Frontend
  Future<void> Function(Catedratico catedratico)? alGuardarCatedratico;
  Future<void> Function(Curso curso)? alActualizarCurso;
  Future<void> Function(String cursoId)? alEliminarInformacionCurso;

  UsuarioModel? _usuarioActual;
  bool _cargando = false;
  final List<Catedratico> _catedraticos = [];
  final List<Curso> _cursos = [];

  UsuarioModel? get usuarioActual => _usuarioActual;
  bool get cargando => _cargando;
  List<Catedratico> get catedraticos => List.unmodifiable(_catedraticos);
  List<Curso> get todosLosCursos => List.unmodifiable(_cursos);

  // --- Estadísticas en tiempo real para Dashboard y pantallas ---
  int get semestreMaximoHabilitado {
    if (_usuarioActual == null) return 1;
    return _notasService.getSemestreMaximoHabilitado(_usuarioActual!.anioIngreso);
  }

  bool estaSemestreBloqueado(int semestre) {
    if (_usuarioActual == null) return false;
    return _notasService.estaSemestreBloqueado(
      _usuarioActual!.anioIngreso,
      semestre,
    );
  }

  int get cursosAprobados =>
      _cursos.where((c) => c.calificacion != null && c.aprobado).length;

  int get cursosReprobados =>
      _cursos.where((c) => c.calificacion != null && !c.aprobado).length;

  int get creditosAcumulados => _cursos.fold<int>(
        0,
        (total, c) => total + c.creditosObtenidos,
      );

  double get promedioGlobal {
    final evaluados = _cursos.where((c) => c.calificacion != null).toList();
    if (evaluados.isEmpty) return 0.0;
    final suma = evaluados.fold<double>(0.0, (acc, c) => acc + c.calificacion!);
    return double.parse((suma / evaluados.length).toStringAsFixed(2));
  }

  int get totalSemestres {
    if (_cursos.isEmpty) return 11;
    return _cursos.fold<int>(
      1,
      (maxSem, c) => c.semestre > maxSem ? c.semestre : maxSem,
    );
  }

  int get totalCursosPensum => _cursos.length;

  int get totalCreditosPensum =>
      _cursos.fold<int>(0, (total, c) => total + c.creditos);

  void actualizarFotoBase64(String? nuevaFoto) {
    if (_usuarioActual == null) return;
    _usuarioActual!.fotoBase64 = nuevaFoto;
    notifyListeners();
  }

  /// Carga todo el pénsum, notas y catedráticos del estudiante logueado
  Future<void> cargarDatosUsuario(UsuarioModel usuario) async {
    _usuarioActual = usuario;
    _cargando = true;
    notifyListeners();

    try {
      final resultados = await Future.wait([
        _notasService.obtenerTodosLosCursos(usuario.carnet, usuario.carreraId),
        _catedraticosService.obtenerCatedraticos(usuario.carnet),
      ]);

      _cursos
        ..clear()
        ..addAll(resultados[0] as List<Curso>);

      _catedraticos
        ..clear()
        ..addAll(resultados[1] as List<Catedratico>);
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  /// Limpia todo en memoria al cerrar sesión para no mezclar cuentas en un mismo celular
  void limpiarSesion() {
    _usuarioActual = null;
    _cursos.clear();
    _catedraticos.clear();
    _cargando = false;
    notifyListeners();
  }

  /// Actualiza el usuario en memoria (útil cuando cambia la foto de perfil)
  void actualizarUsuarioActual(UsuarioModel usuario) {
    _usuarioActual = usuario;
    notifyListeners();
  }

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
      // Evita duplicados por nombre en el mismo usuario
      final yaExisteNombre = _catedraticos.any(
        (item) =>
            item.nombre.trim().toLowerCase() ==
            catedratico.nombre.trim().toLowerCase(),
      );
      if (yaExisteNombre) return;
      _catedraticos.add(catedratico);
    } else {
      _catedraticos[indice] = catedratico;
    }
    _catedraticos.sort((a, b) => a.nombre.compareTo(b.nombre));
    notifyListeners();

    final usuario = _usuarioActual;
    if (usuario != null) {
      _disparar(
        () => _catedraticosService.guardarOActualizarPorId(
          carnet: usuario.carnet,
          catedratico: catedratico,
        ),
      );
    }
    _disparar(() => alGuardarCatedratico?.call(catedratico));
  }

  void eliminarCatedratico(String id) {
    _catedraticos.removeWhere((item) => item.id == id);
    notifyListeners();

    final usuario = _usuarioActual;
    if (usuario != null) {
      _disparar(() => _catedraticosService.eliminarCatedratico(usuario.carnet, id));
    }
  }

  void actualizarCurso(Curso curso) {
    final indice = _cursos.indexWhere((item) => item.id == curso.id);
    if (indice == -1) return;

    // Blindaje 0-100 en memoria y sincronización del nombre de catedrático para el PDF
    double? notaSegura = curso.calificacion;
    if (notaSegura != null) {
      if (notaSegura < 0) notaSegura = 0;
      if (notaSegura > 100) notaSegura = 100;
    }

    final catEncontrado = buscarCatedratico(curso.catedraticoId);
    final cursoNormalizado = curso.conDatosDeUsuario(
      catedraticoId: curso.catedraticoId,
      catedraticoNombre: catEncontrado?.nombre ?? curso.catedraticoNombre,
      calificacion: notaSegura,
      descripcion: curso.descripcion,
      horario: curso.horario,
      color: curso.color,
      icono: curso.icono,
    );

    _cursos[indice] = cursoNormalizado;
    _recalcularPrerrequisitosEnMemoria();
    notifyListeners();

    final usuario = _usuarioActual;
    if (usuario != null) {
      _disparar(
        () => _notasService.guardarCursoCompleto(usuario.carnet, cursoNormalizado),
      );
    }
    _disparar(() => alActualizarCurso?.call(cursoNormalizado));
  }

  void limpiarInformacionCurso(String cursoId) {
    final indice = _cursos.indexWhere((item) => item.id == cursoId);
    if (indice == -1) return;

    final cursoLimpio = _cursos[indice].sinDatosIngresados();
    _cursos[indice] = cursoLimpio;
    _recalcularPrerrequisitosEnMemoria();
    notifyListeners();

    final usuario = _usuarioActual;
    if (usuario != null) {
      _disparar(
        () => _notasService.eliminarNota(
          usuario.carnet,
          cursoId,
          carreraId: usuario.carreraId,
        ),
      );
    }
    _disparar(() => alEliminarInformacionCurso?.call(cursoId));
  }

  /// Recalcula al instante qué cursos superiores se desbloquean o bloquean al cambiar una nota
  void _recalcularPrerrequisitosEnMemoria() {
    final Map<String, double> mapaNotas = {
      for (final c in _cursos)
        if (c.calificacion != null) c.id: c.calificacion!,
    };
    final regExpCodigos = RegExp(r'[A-Z]{4}\d{4}');

    for (int i = 0; i < _cursos.length; i++) {
      final c = _cursos[i];
      final coincidencias = regExpCodigos.allMatches(c.prerequisitosTexto);
      final List<String> faltantes = [];

      for (final match in coincidencias) {
        final codigoReq = match.group(0)!;
        final notaReq = mapaNotas[codigoReq];
        if (notaReq == null || notaReq < 61.0) {
          faltantes.add(codigoReq);
        }
      }

      final bloqueado = faltantes.isNotEmpty;
      final textoFaltantes = faltantes.join(', ');

      if (c.bloqueadoPorPrerequisito != bloqueado ||
          c.prerequisitosFaltantes != textoFaltantes) {
        _cursos[i] = Curso(
          id: c.id,
          semestre: c.semestre,
          nombre: c.nombre,
          creditos: c.creditos,
          requisitos: c.requisitos,
          carreraId: c.carreraId,
          catedraticoId: c.catedraticoId,
          catedraticoNombre: c.catedraticoNombre,
          calificacion: c.calificacion,
          descripcion: c.descripcion,
          horario: c.horario,
          color: c.color,
          icono: c.icono,
          prerequisitosTexto: c.prerequisitosTexto,
          bloqueadoPorPrerequisito: bloqueado,
          prerequisitosFaltantes: textoFaltantes,
        );
      }
    }
  }

  void _disparar(Future<void>? Function() accion) {
    final futuro = accion();
    if (futuro != null) {
      unawaited(futuro.catchError((_) {}));
    }
  }
}