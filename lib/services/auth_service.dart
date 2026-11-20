import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/usuario_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Sesión activa en memoria
  static UsuarioModel? usuarioActual;

  Future<UsuarioModel> _construirUsuarioConCarrera(
    Map<String, dynamic> data,
    String docId,
  ) async {
    final usuarioBase = UsuarioModel.fromMap(data, docId);
    if (usuarioBase.carrera.isNotEmpty) {
      return usuarioBase;
    }

    String nombreCarrera = '';
    try {
      final docCarrera = await _firestore
          .collection('carreras')
          .doc(usuarioBase.carreraId)
          .get()
          .timeout(const Duration(seconds: 3));
      if (docCarrera.exists) {
        final datosCarrera = docCarrera.data();
        nombreCarrera =
            (datosCarrera?['nombre'] ?? datosCarrera?['carrera'] ?? '')
                .toString()
                .trim();
      }
    } catch (_) {
      try {
        final docCache = await _firestore
            .collection('carreras')
            .doc(usuarioBase.carreraId)
            .get(const GetOptions(source: Source.cache));
        if (docCache.exists) {
          final datosCarrera = docCache.data();
          nombreCarrera =
              (datosCarrera?['nombre'] ?? datosCarrera?['carrera'] ?? '')
                  .toString()
                  .trim();
        }
      } catch (_) {}
    }

    if (nombreCarrera.isEmpty) return usuarioBase;

    return UsuarioModel(
      carnet: usuarioBase.carnet,
      usuario: usuarioBase.usuario,
      nombre: usuarioBase.nombre,
      correo: usuarioBase.correo,
      carrera: nombreCarrera,
      carreraId: usuarioBase.carreraId,
      anioIngreso: usuarioBase.anioIngreso,
      fotoBase64: usuarioBase.fotoBase64,
    );
  }

  // 1. Iniciar sesión con Correo, Usuario o Carné + Contraseña
  Future<UsuarioModel> login(String identificador, String password) async {
    try {
      final String input = identificador.trim();
      Map<String, dynamic>? datosEstudiante;
      String? carnetDocId;

      if (input.contains('@')) {
        final query = await _firestore
            .collection('usuarios')
            .where('correo', isEqualTo: input)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          datosEstudiante = query.docs.first.data();
          carnetDocId = query.docs.first.id;
        }
      } else {
        final query = await _firestore
            .collection('usuarios')
            .where('usuario', isEqualTo: input)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) {
          datosEstudiante = query.docs.first.data();
          carnetDocId = query.docs.first.id;
        } else {
          final docPorCarnet = await _firestore
              .collection('usuarios')
              .doc(input)
              .get();
          if (docPorCarnet.exists) {
            datosEstudiante = docPorCarnet.data();
            carnetDocId = docPorCarnet.id;
          }
        }
      }

      if (datosEstudiante == null || carnetDocId == null) {
        throw Exception('usuario-no-existe');
      }

      final String correoRegistrado =
          (datosEstudiante['correo'] ?? '').toString().trim();
      if (correoRegistrado.isEmpty) {
        throw Exception('correo-no-autorizado');
      }

      await _auth.signInWithEmailAndPassword(
        email: correoRegistrado,
        password: password.trim(),
      );

      usuarioActual =
          await _construirUsuarioConCarrera(datosEstudiante, carnetDocId);
      return usuarioActual!;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error de Firebase Auth (${e.code}): ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error general al autenticar: $e');
      rethrow;
    }
  }

  // 2. Iniciar sesión con botón de Google (en paralelo y con margen de 12s)
  Future<UsuarioModel?> loginConGoogle() async {
    try {
      // Límite corto para que signOut() nunca bloquee la apertura del selector
      await _googleSignIn
          .signOut()
          .timeout(const Duration(seconds: 2), onTimeout: () => null);

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // Cancelado por el usuario
      }

      // Todo el proceso posterior a elegir cuenta en paralelo y con margen de 12s
      return await Future<UsuarioModel?>(() async {
        final String correoGoogle = googleUser.email.trim();

        final resultados = await Future.wait([
          _firestore
              .collection('usuarios')
              .where('correo', isEqualTo: correoGoogle)
              .limit(1)
              .get(),
          googleUser.authentication,
        ]);

        final query = resultados[0] as QuerySnapshot<Map<String, dynamic>>;
        final googleAuth = resultados[1] as GoogleSignInAuthentication;

        if (query.docs.isEmpty) {
          await _googleSignIn
              .signOut()
              .timeout(const Duration(seconds: 2), onTimeout: () => null);
          throw Exception('correo-no-autorizado');
        }

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        await _auth.signInWithCredential(credential);

        final doc = query.docs.first;
        usuarioActual = await _construirUsuarioConCarrera(doc.data(), doc.id);
        return usuarioActual;
      }).timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw Exception('google-no-disponible');
    } catch (e) {
      debugPrint('Error en loginConGoogle: $e');
      rethrow;
    }
  }

  // 3. Enviar correo de recuperación de contraseña (verificando que esté registrado)
  Future<void> enviarCorreoRecuperacion(String correo) async {
    final correoLimpio = correo.trim();
    final query = await _firestore
        .collection('usuarios')
        .where('correo', isEqualTo: correoLimpio)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('correo-no-autorizado');
    }

    await _auth.sendPasswordResetEmail(email: correoLimpio);
  }

  // 4. Cerrar sesión completa
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    usuarioActual = null;
  }

  // 5. Verifica al abrir la app si ya hay una sesión activa en el celular (Funciona Offline)
  Future<UsuarioModel?> verificarSesionActiva() async {
    final userFirebase = _auth.currentUser;
    if (userFirebase == null || userFirebase.email == null) {
      return null;
    }

    try {
      final query = await _firestore
          .collection('usuarios')
          .where('correo', isEqualTo: userFirebase.email)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 3));

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        usuarioActual = await _construirUsuarioConCarrera(doc.data(), doc.id);
        return usuarioActual;
      }
    } catch (_) {
      try {
        final queryCache = await _firestore
            .collection('usuarios')
            .where('correo', isEqualTo: userFirebase.email)
            .limit(1)
            .get(const GetOptions(source: Source.cache));

        if (queryCache.docs.isNotEmpty) {
          final doc = queryCache.docs.first;
          usuarioActual =
              await _construirUsuarioConCarrera(doc.data(), doc.id);
          return usuarioActual;
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}