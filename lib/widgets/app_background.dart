
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/theme_provider.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final configuracion = context.watch<ThemeProvider>();
    final oscuro = Theme.of(context).brightness == Brightness.dark;

    final colorFondo = Theme.of(context).scaffoldBackgroundColor;

    final colorLinea = oscuro
        ? Colors.white.withValues(alpha: 0.07)
        : const Color(0xFF1F2937).withValues(alpha: 0.08);

    return ColoredBox(
      color: colorFondo,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: configuracion.showGrid
              ? CuadriculaPainter(colorLinea: colorLinea)
              : null,
          child: SizedBox.expand(
            child: child,
          ),
        ),
      ),
    );
  }
}

class CuadriculaPainter extends CustomPainter {
  const CuadriculaPainter({
    required this.colorLinea,
  });

  final Color colorLinea;

  static const double _espacio = 28;

  @override
  void paint(Canvas canvas, Size size) {
    final trazo = Paint()
      ..color = colorLinea
      ..strokeWidth = 0.7;

    for (double x = 0; x <= size.width; x += _espacio) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        trazo,
      );
    }

    for (double y = 0; y <= size.height; y += _espacio) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        trazo,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CuadriculaPainter oldDelegate) {
    return oldDelegate.colorLinea != colorLinea;
  }
}
