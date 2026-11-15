import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_card.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';


class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            const Text(
              'APARIENCIA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.1,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            AppCard(
              child: Column(
                children: [
                  // 1. Selector de Modo (Claro / Oscuro / Sistema)
                  ListTile(
                    leading: Icon(
                      Icons.contrast_rounded,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Modo de pantalla'),
                    subtitle: Text(_obtenerTextoModo(themeProvider.themeMode)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _mostrarDialogoModo(context, themeProvider),
                  ),
                  const Divider(height: 1),

                  // 2. Selector de Color Principal
                  ListTile(
                    leading: Icon(
                      Icons.palette_outlined,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Color principal'),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: themeProvider.seedColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.outline, width: 1),
                      ),
                    ),
                    onTap: () => _mostrarDialogoColores(context, themeProvider),
                  ),
                  const Divider(height: 1),

                  // 3. Interruptor de Cuadrícula
                  SwitchListTile(
                    secondary: Icon(
                      Icons.grid_on_rounded,
                      color: colorScheme.primary,
                    ),
                    title: const Text('Fondo cuadriculado'),
                    subtitle: const Text('Estilo hoja de libreta'),
                    value: themeProvider.showGrid,
                    onChanged: (bool valor) {
                      themeProvider.setShowGrid(valor);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _obtenerTextoModo(ThemeMode modo) {
    switch (modo) {
      case ThemeMode.light:
        return 'Modo Claro';
      case ThemeMode.dark:
        return 'Modo Oscuro';
      case ThemeMode.system:
        return 'Automático (Sistema)';
    }
  }

  void _mostrarDialogoModo(BuildContext context, ThemeProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Seleccionar modo',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.light_mode_outlined),
                  label: const Text('Modo Claro'),
                  onPressed: () {
                    provider.setThemeMode(ThemeMode.light);
                    Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: const Text('Modo Oscuro'),
                  onPressed: () {
                    provider.setThemeMode(ThemeMode.dark);
                    Navigator.pop(sheetContext);
                  },
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.brightness_auto_outlined),
                  label: const Text('Automático (Sistema)'),
                  onPressed: () {
                    provider.setThemeMode(ThemeMode.system);
                    Navigator.pop(sheetContext);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  
void _mostrarDialogoColores(BuildContext context, ThemeProvider provider) {
  Color colorSeleccionado = provider.seedColor;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final esquema = Theme.of(context).colorScheme;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Personalizar color',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Elige el color que identificará tu aplicación.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Vista previa del color seleccionado
                    Container(
                      width: 65,
                      height: 65,
                      decoration: BoxDecoration(
                        color: colorSeleccionado,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: esquema.outline,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check,
                        color: ThemeData.estimateBrightnessForColor(
                          colorSeleccionado,
                        ) == Brightness.dark
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Selector de colores
                    ColorPicker(
                      pickerColor: colorSeleccionado,
                      onColorChanged: (Color color) {
                        setState(() {
                          colorSeleccionado = color;
                        });
                      },
                      enableAlpha: false,
                      displayThumbColor: true,
                      // labelTypes: const [],
                      paletteType: PaletteType.hsv,
                      pickerAreaHeightPercent: 0.65,
                    ),
                    
                    const SizedBox(height: 12),

                    // Guardar selección
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          provider.setSeedColor(colorSeleccionado);
                          Navigator.pop(sheetContext);
                        },
                        child: const Text('Guardar color'),
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Cancelar'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

}