class CursoModel {
  final String codigo;
  final String nombre;
  final int creditos;
  final String prerequisitos;
  final int semestre;
  final String carreraId;
  double? nota;
  String? catedratico;

  final bool bloqueadoPorPrerequisito;
  final String prerequisitosFaltantes;

  CursoModel({
    required this.codigo,
    required this.nombre,
    required this.creditos,
    required this.prerequisitos,
    required this.semestre,
    required this.carreraId,
    this.nota,
    this.catedratico,
    this.bloqueadoPorPrerequisito = false,
    this.prerequisitosFaltantes = '',
  }
  // Devuelve los prerrequisitos limpios sin códigos molestos (Ej: "Introducción a la Programación, Matemática Básica")
 
  );

  bool get aprobado => (nota ?? 0) >= 61.0;

  int get creditosObtenidos => aprobado ? creditos : 0;
  
  String get prerequisitosNombresLimpios {
    if (prerequisitos.toLowerCase() == 'ninguno') return 'Ninguno';
    
    // Si hay varios separados por coma, limpiamos cada uno quitando el código de 4 letras + 4 números y el guion
    final partes = prerequisitos.split(',');
    final limpias = partes.map((p) {
      // Reemplaza patrones como "SIST2015 -" o "MATE2015 - " por vacío
      return p.replaceAll(RegExp(r'[A-Z]{4}\d{4}\s*-\s*'), '').trim();
    }).toList();

    return limpias.join(', ');
  }

  factory CursoModel.fromMap(
    Map<String, dynamic> data,
    String documentId, {
    double? nota,
    String? catedratico,
    bool bloqueadoPorPrerequisito = false,
    String prerequisitosFaltantes = '',
  }) {
    return CursoModel(
      codigo: (data['codigo'] ?? documentId).toString(),
      nombre: data['nombre'] ?? '',
      creditos: (data['creditos'] as num?)?.toInt() ?? 0,
      prerequisitos: data['prerequisitos'] ?? 'Ninguno',
      semestre: (data['semestre'] as num?)?.toInt() ?? 1,
      carreraId: data['carrera_id'] ?? 'sistemas',
      nota: nota,
      catedratico: catedratico,
      bloqueadoPorPrerequisito: bloqueadoPorPrerequisito,
      prerequisitosFaltantes: prerequisitosFaltantes,
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