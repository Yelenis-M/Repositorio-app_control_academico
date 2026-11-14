class CursoModel {
  final String codigo;
  final String nombre;
  final int creditos;
  final String prerequisitos;
  final int semestre;
  final String carreraId;
  double? nota; // Vacío (null) hasta que el usuario lo llene
  String? catedratico; // Vacío (null) hasta que el usuario elija o escriba el catedrático

  CursoModel({
    required this.codigo,
    required this.nombre,
    required this.creditos,
    required this.prerequisitos,
    required this.semestre,
    required this.carreraId,
    this.nota,
    this.catedratico,
  });

  // Aprueba con 61 o más
  bool get aprobado => (nota ?? 0) >= 61.0;

  // Si aprueba suma los créditos, si no 0
  int get creditosObtenidos => aprobado ? creditos : 0;

  factory CursoModel.fromMap(
    Map<String, dynamic> data,
    String documentId, {
    double? nota,
    String? catedratico,
  }) {
    return CursoModel(
      codigo: documentId,
      nombre: data['nombre'] ?? '',
      creditos: (data['creditos'] as num?)?.toInt() ?? 0,
      prerequisitos: data['prerequisitos'] ?? 'Ninguno',
      semestre: (data['semestre'] as num?)?.toInt() ?? 1,
      carreraId: data['carrera_id'] ?? 'sistemas',
      nota: nota,
      catedratico: catedratico,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'codigo': codigo,
      'nombre': nombre,
      'creditos': creditos,
      'prerequisitos': prerequisitos,
      'semestre': semestre,
      'carrera_id': carreraId,
    };
  }
}