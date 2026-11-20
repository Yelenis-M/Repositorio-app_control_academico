/// Horario elegido por el usuario, en formato `00:00 AM - 00:00 PM`.
class HorarioCurso {
  const HorarioCurso({
    required this.inicio,
    required this.fin,
    required this.inicioEsPm,
    required this.finEsPm,
  });

  /// Hora de 12 horas ya normalizada, por ejemplo `08:00`.
  final String inicio;
  final String fin;
  final bool inicioEsPm;
  final bool finEsPm;

  String get etiqueta {
    final periodoInicio = inicioEsPm ? 'PM' : 'AM';
    final periodoFin = finEsPm ? 'PM' : 'AM';
    return '$inicio $periodoInicio - $fin $periodoFin';
  }

  /// Minutos transcurridos desde las 00:00 para comparar horas en formato 24h.
  int get inicioEnMinutos => _aMinutos24h(inicio, inicioEsPm);
  int get finEnMinutos => _aMinutos24h(fin, finEsPm);

  /// Verdadero solo si la hora de fin es posterior a la de inicio.
  bool get esRangoValido => finEnMinutos > inicioEnMinutos;

  static int _aMinutos24h(String horaNormalizada, bool esPm) {
    final partes = horaNormalizada.split(':');
    int hora = int.parse(partes[0]);
    final int minuto = int.parse(partes[1]);

    // Si el usuario escribió formato 24h (00:xx o 13:00–23:59), ya está en 24h
    if (hora == 0 || hora >= 13) {
      return (hora * 60) + minuto;
    }

    // Si escribió formato 12h (01:00–12:59), aplicamos AM/PM
    if (esPm) {
      if (hora != 12) hora += 12; // 03:00 PM -> 15:00, 12:00 PM -> 12:00
    } else {
      if (hora == 12) hora = 0; // 12:00 AM -> 00:00, 09:00 AM -> 09:00
    }
    return (hora * 60) + minuto;
  }

  Map<String, dynamic> toMap() {
    return {
      'inicio': inicio,
      'fin': fin,
      'inicioEsPm': inicioEsPm,
      'finEsPm': finEsPm,
      'etiqueta': etiqueta,
    };
  }

  static HorarioCurso? fromDynamic(dynamic raw) {
    if (raw == null) return null;

    if (raw is Map<String, dynamic>) {
      final inicio = raw['inicio']?.toString() ?? '';
      final fin = raw['fin']?.toString() ?? '';
      if (inicio.isEmpty || fin.isEmpty) return null;
      return HorarioCurso(
        inicio: inicio,
        fin: fin,
        inicioEsPm: raw['inicioEsPm'] == true,
        finEsPm: raw['finEsPm'] == true,
      );
    }

    // Compatibilidad si en BD se guardó como texto tipo "09:00 AM - 11:00 AM"
    if (raw is String && raw.trim().isNotEmpty) {
      final match = RegExp(
        r'(\d{1,2}:\d{2})\s*(AM|PM)\s*-\s*(\d{1,2}:\d{2})\s*(AM|PM)',
        caseSensitive: false,
      ).firstMatch(raw.trim());

      if (match != null) {
        final ini = normalizarHora(match.group(1)!);
        final fin = normalizarHora(match.group(3)!);
        if (ini != null && fin != null) {
          return HorarioCurso(
            inicio: ini,
            fin: fin,
            inicioEsPm: match.group(2)!.toUpperCase() == 'PM',
            finEsPm: match.group(4)!.toUpperCase() == 'PM',
          );
        }
      }
    }
    return null;
  }

  /// Acepta tanto formato 12h (01:00–12:59) como 24h (00:00–23:59).
  static String? normalizarHora(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return null;
    final coincidencia = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(limpio);
    if (coincidencia == null) return null;
    final hora = int.parse(coincidencia.group(1)!);
    final minuto = int.parse(coincidencia.group(2)!);
    if (hora < 0 || hora > 23 || minuto < 0 || minuto > 59) return null;
    final horaTexto = hora.toString().padLeft(2, '0');
    final minutoTexto = minuto.toString().padLeft(2, '0');
    return '$horaTexto:$minutoTexto';
  }
}