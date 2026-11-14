class CursoModel {
  final String codigo;
  final String nombre;
  final int creditos;
  final String prerequisitos;
  final int semestre;
  final String carreraId;
  double? nota; // Null si aún no se le ha ingresado nota

  CursoModel({
    required this.codigo,
    required this.nombre,
    required this.creditos,
    required this.prerequisitos,
    required this.semestre,
    required this.carreraId,
    this.nota,
  });

  // Regla de negocio: aprueba con 61 o más
  bool get aprobado => (nota ?? 0) >= 61.0;

  // Si aprueba gana los créditos completos, si reprueba gana 0
  int get creditosObtenidos => aprobado ? creditos : 0;

  // Mapea los datos desde Firestore
  factory CursoModel.fromMap(
    Map<String, dynamic> data,
    String documentId, {
    double? nota,
  }) {
    return CursoModel(
      codigo: documentId,
      nombre: data['nombre'] ?? '',
      creditos: (data['creditos'] as num?)?.toInt() ?? 0,
      prerequisitos: data['prerequisitos'] ?? 'Ninguno',
      semestre: (data['semestre'] as num?)?.toInt() ?? 1,
      carreraId: data['carrera_id'] ?? 'sistemas',
      nota: nota,
    );
  }

  // Convierte a Map si se necesita registrar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'creditos': creditos,
      'prerequisitos': prerequisitos,
      'semestre': semestre,
      'carrera_id': carreraId,
    };
  }
}