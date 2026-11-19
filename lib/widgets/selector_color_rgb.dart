import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

/// Abre un selector RGB para cualquier color.
/// Devuelve el color elegido, o null si se cancela.
Future<Color?> mostrarSelectorColorRgb({
  required BuildContext context,
  required Color colorInicial,
  required String titulo,
}) {
  var seleccionado = colorInicial;

  return showDialog<Color>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          final esquema = Theme.of(context).colorScheme;
          final argb = seleccionado.toARGB32();
          final rojo = (argb >> 16) & 0xFF;
          final verde = (argb >> 8) & 0xFF;
          final azul = argb & 0xFF;

          return AlertDialog(
            title: Text(titulo),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ColorPicker(
                    pickerColor: seleccionado,
                    onColorChanged: (color) {
                      setLocal(() => seleccionado = color);
                    },
                    enableAlpha: false,
                    labelTypes: const [ColorLabelType.rgb],
                    pickerAreaHeightPercent: 0.75,
                    displayThumbColor: true,
                    colorPickerWidth: 250,
                    hexInputBar: true,
                    portraitOnly: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'RGB ($rojo, $verde, $azul)',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: esquema.primary,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, seleccionado),
                child: const Text('Listo'),
              ),
            ],
          );
        },
      );
    },
  );
}

String textoRgb(Color color) {
  final argb = color.toARGB32();
  final rojo = (argb >> 16) & 0xFF;
  final verde = (argb >> 8) & 0xFF;
  final azul = argb & 0xFF;
  return 'RGB ($rojo, $verde, $azul)';
}
