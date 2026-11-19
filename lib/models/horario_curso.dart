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

  /// Devuelve la hora en `00:00`, o null si está vacía o no cumple el formato.
  /// Acepta horas de 00 a 12.
  static String? normalizarHora(String texto) {
    final limpio = texto.trim();
    if (limpio.isEmpty) return null;

    final coincidencia = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(limpio);
    if (coincidencia == null) return null;

    final hora = int.parse(coincidencia.group(1)!);
    final minuto = int.parse(coincidencia.group(2)!);
    if (hora < 0 || hora > 12 || minuto < 0 || minuto > 59) return null;

    final horaTexto = hora.toString().padLeft(2, '0');
    final minutoTexto = minuto.toString().padLeft(2, '0');
    return '$horaTexto:$minutoTexto';
  }
}
