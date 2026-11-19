import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Image.asset(
      'assets/images/PromediUm.png',
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width ?? 92,
          height: height ?? 92,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: esquema.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Text(
            'P',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: esquema.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
        );
      },
    );
  }
}