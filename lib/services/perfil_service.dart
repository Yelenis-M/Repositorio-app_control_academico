import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'auth_service.dart';

// Estados claros para que el Frontend sepa qué mensaje o diálogo mostrar
enum ResultadoFoto {
  exito,
  canceladoPorUsuario,
  permisoDenegado, // Lo negó 1 vez: mostrar aviso normal
  permisoBloqueadoIrAjustes, // Lo negó 2 veces ("No volver a preguntar"): mostrar botón "Ir a Ajustes"
  camaraNoDisponible, // Error de hardware o cámara deshabilitada
  sinInternet, // No hay conexión para guardar/borrar en Firebase
  errorDesconocido,
}

class PerfilService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // 1. Verificar si hay internet real antes de tocar Firestore
  Future<bool> tieneConexionInternet() async {
    try {
      final resultado = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return resultado.isNotEmpty && resultado[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // 2. Pedir permiso de Cámara o Galería y detectar si lo negó 2 veces
  Future<ResultadoFoto> _verificarPermiso(bool usarCamara) async {
    if (usarCamara) {
      final status = await Permission.camera.request();
      if (status.isGranted) return ResultadoFoto.exito;
      if (status.isPermanentlyDenied || status.isRestricted) {
        return ResultadoFoto.permisoBloqueadoIrAjustes;
      }
      return ResultadoFoto.permisoDenegado;
    } else {
      // En Android 13+ (como tu Pixel con Android 17) se usa Permission.photos; en anteriores, storage
      PermissionStatus status = await Permission.photos.request();
      if (!status.isGranted) {
        final statusStorage = await Permission.storage.request();
        if (statusStorage.isGranted) return ResultadoFoto.exito;
      } else {
        return ResultadoFoto.exito;
      }

      if (status.isPermanentlyDenied) {
        return ResultadoFoto.permisoBloqueadoIrAjustes;
      }
      return ResultadoFoto.permisoDenegado;
    }
  }

  // 3. Tomar foto con Cámara o elegir de Galería, comprimir al 25% y subir a Firestore
  Future<ResultadoFoto> cambiarFotoPerfil({
    required String carnet,
    required bool usarCamara,
  }) async {
    // A) Validar permisos primero
    final estadoPermiso = await _verificarPermiso(usarCamara);
    if (estadoPermiso != ResultadoFoto.exito) {
      return estadoPermiso;
    }

    // B) Abrir Cámara o Galería con compresión automática (max 400px, calidad 25%)
    XFile? imagenSeleccionada;
    try {
      imagenSeleccionada = await _picker.pickImage(
        source: usarCamara ? ImageSource.camera : ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 25,
      );
    } on PlatformException catch (_) {
      return ResultadoFoto.camaraNoDisponible;
    } catch (_) {
      return ResultadoFoto.camaraNoDisponible;
    }

    if (imagenSeleccionada == null) {
      return ResultadoFoto.canceladoPorUsuario;
    }

    // C) Validar que haya internet antes de actualizar la base de datos
    final hayRed = await tieneConexionInternet();
    if (!hayRed) {
      return ResultadoFoto.sinInternet;
    }

    // D) Convertir a Base64 y guardar en Firestore
    try {
      final bytes = await imagenSeleccionada.readAsBytes();
      final String base64String = base64Encode(bytes);

      await _firestore.collection('usuarios').doc(carnet).set({
        'foto_base64': base64String,
      }, SetOptions(merge: true));

      // Actualizar también el usuario en memoria
      if (AuthService.usuarioActual != null &&
          AuthService.usuarioActual!.carnet == carnet) {
        AuthService.usuarioActual!.fotoBase64 = base64String;
      }

      return ResultadoFoto.exito;
    } catch (_) {
      return ResultadoFoto.errorDesconocido;
    }
  }

  // 4. Eliminar foto de perfil (la borra por completo de Firestore)
  Future<ResultadoFoto> eliminarFotoPerfil(String carnet) async {
    final hayRed = await tieneConexionInternet();
    if (!hayRed) {
      return ResultadoFoto.sinInternet;
    }

    try {
      await _firestore.collection('usuarios').doc(carnet).update({
        'foto_base64': FieldValue.delete(),
      });

      if (AuthService.usuarioActual != null &&
          AuthService.usuarioActual!.carnet == carnet) {
        AuthService.usuarioActual!.fotoBase64 = null;
      }

      return ResultadoFoto.exito;
    } catch (_) {
      return ResultadoFoto.errorDesconocido;
    }
  }

  // 5. Abrir la pantalla de Ajustes del sistema cuando el usuario negó el permiso 2 veces
  Future<void> abrirAjustesDePermisos() async {
    await openAppSettings();
  }

  // 6. Helper para convertir el texto Base64 de Firestore en bytes listos para Image.memory()
  Uint8List? decodificarFoto(String? fotoBase64) {
    if (fotoBase64 == null || fotoBase64.isEmpty) return null;
    try {
      return base64Decode(fotoBase64);
    } catch (_) {
      return null;
    }
  }
}