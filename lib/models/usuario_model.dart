class UsuarioModel {
  final String carnet;
  final String usuario;
  final String correo;
  final String nombre;
  final String carrera;
  final String carreraId;
  final int anioIngreso;

  UsuarioModel({
    required this.carnet,
    required this.usuario,
    required this.correo,
    required this.nombre,
    required this.carrera,
    required this.carreraId,
    required this.anioIngreso,
  });

  factory UsuarioModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UsuarioModel(
      carnet: documentId,
      usuario: data['usuario'] ?? '',
      correo: data['correo'] ?? '',
      nombre: data['nombre'] ?? '',
      carrera: data['carrera'] ?? '',
      carreraId: data['carrera_id'] ?? 'sistemas',
      anioIngreso: (data['anio_ingreso'] as num?)?.toInt() ?? DateTime.now().year,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'usuario': usuario,
      'correo': correo,
      'nombre': nombre,
      'carrera': carrera,
      'carrera_id': carreraId,
      'anio_ingreso': anioIngreso,
    };
  }
}