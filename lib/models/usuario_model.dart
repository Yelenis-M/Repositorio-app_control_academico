class UsuarioModel {
  final String carnet;
  final String usuario;
  final String nombre;
  final String correo;
  final String carrera;
  final String carreraId;
  final int anioIngreso;
  String? fotoBase64; // Foto comprimida guardada en Firestore

  UsuarioModel({
    required this.carnet,
    required this.usuario,
    required this.nombre,
    required this.correo,
    required this.carrera,
    required this.carreraId,
    required this.anioIngreso,
    this.fotoBase64,
  });

  factory UsuarioModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UsuarioModel(
      carnet: documentId,
      usuario: (data['usuario'] ?? '').toString(),
      nombre: (data['nombre'] ?? '').toString(),
      correo: (data['correo'] ?? '').toString(),
      carrera: (data['carrera'] ?? data['carrea'] ?? '').toString().trim(),
      carreraId: (data['carrera_id'] ?? 'sistemas').toString(),
      anioIngreso: (data['anio_ingreso'] as num?)?.toInt() ?? 2024,
      fotoBase64: data['foto_base64']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'usuario': usuario,
      'nombre': nombre,
      'correo': correo,
      'carrera': carrera,
      'carrera_id': carreraId,
      'anio_ingreso': anioIngreso,
      if (fotoBase64 != null) 'foto_base64': fotoBase64,
    };
  }
}