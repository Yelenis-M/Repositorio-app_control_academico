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

      usuarioActual = UsuarioModel.fromMap(datosEstudiante, carnetDocId);
      return usuarioActual!;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error de Firebase Auth (${e.code}): ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Error general al autenticar: $e');
      rethrow;
    }
  }

  // 2. Iniciar sesión con botón de Google (Validando que exista en Firestore)
  // Devuelve null únicamente si el usuario cerró la ventana sin elegir cuenta.
  Future<UsuarioModel?> loginConGoogle() async {
    try {
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // Cancelado por el usuario
      }

      final String correoGoogle = googleUser.email.trim();

      final query = await _firestore
          .collection('usuarios')
          .where('correo', isEqualTo: correoGoogle)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        await _googleSignIn.signOut();
        throw Exception('correo-no-autorizado');
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      final doc = query.docs.first;
      usuarioActual = UsuarioModel.fromMap(doc.data(), doc.id);
      return usuarioActual;
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
        usuarioActual = UsuarioModel.fromMap(doc.data(), doc.id);
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
          usuarioActual = UsuarioModel.fromMap(doc.data(), doc.id);
          return usuarioActual;
        }
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}