class CatedraticoModel {
  final String id;
  final String nombre;
  final String correo;
  final String telefono;
  final String horario;

  CatedraticoModel({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.telefono,
    required this.horario,
  });

  factory CatedraticoModel.fromMap(Map<String, dynamic> data, String documentId) {
    return CatedraticoModel(
      id: documentId,
      nombre: (data['nombre'] ?? '').toString(),
      correo: (data['correo'] ?? '').toString(),
      telefono: (data['telefono'] ?? '').toString(),
      horario: (data['horario'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'telefono': telefono,
      'horario': horario,
    };
  }
}