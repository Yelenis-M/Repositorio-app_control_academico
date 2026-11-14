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
  Future<UsuarioModel?> login(String identificador, String password) async {
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
        return null;
      }

      final String correoRegistrado =
          (datosEstudiante['correo'] ?? '').toString().trim();

      if (correoRegistrado.isEmpty) {
        return null;
      }

      await _auth.signInWithEmailAndPassword(
        email: correoRegistrado,
        password: password.trim(),
      );

      usuarioActual = UsuarioModel.fromMap(datosEstudiante, carnetDocId);
      return usuarioActual;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error de Firebase Auth (${e.code}): ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Error general al autenticar: $e');
      rethrow;
    }
  }

  // 2. Iniciar sesión con botón de Google (Validando que exista en Firestore)
  Future<UsuarioModel?> loginConGoogle() async {
    try {
      // Forzar selector de cuenta para que siempre deje elegir el correo
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        return null; // El usuario cerró la ventana sin elegir cuenta
      }

      final String correoGoogle = googleUser.email.trim();

      // Verificar primero si ese correo está autorizado en nuestra colección 'usuarios'
      final query = await _firestore
          .collection('usuarios')
          .where('correo', isEqualTo: correoGoogle)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        // No es un estudiante registrado: cerramos la sesión de Google y denegamos acceso
        await _googleSignIn.signOut();
        return null;
      }

      // Si sí existe en Firestore, obtenemos los tokens y autenticamos en Firebase Auth
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

  // 3. Enviar correo de recuperación de contraseña
  Future<void> enviarCorreoRecuperacion(String correo) async {
    await _auth.sendPasswordResetEmail(email: correo.trim());
  }

  // 4. Cerrar sesión completa
  Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    usuarioActual = null;
  }
}