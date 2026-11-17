import 'package:app_control_academico/data/datos_academicos_mock.dart';
import 'package:app_control_academico/models/estado_nota.dart';
import 'package:app_control_academico/models/horario_curso.dart';
import 'package:app_control_academico/screens/academico/semestre_view.dart';
import 'package:app_control_academico/theme/app_colors.dart';
import 'package:app_control_academico/theme/app_theme.dart';
import 'package:app_control_academico/theme/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  test('61 aprueba, 60 reprueba y el horario usa 00:00', () {
    expect(esNotaAprobada(61), isTrue);
    expect(esNotaAprobada(60), isFalse);
    expect(HorarioCurso.normalizarHora('8:05'), '08:05');
    expect(HorarioCurso.normalizarHora('13:00'), isNull);
    expect(HorarioCurso.normalizarHora(''), isNull);

    const horario = HorarioCurso(
      inicio: '07:00',
      fin: '08:30',
      inicioEsPm: false,
      finEsPm: false,
    );
    expect(horario.etiqueta, '07:00 AM - 08:30 AM');
  });

  testWidgets('El semestre muestra materias, resumen y orden A-Z', (tester) async {
    await _montarSemestre(tester, const Size(360, 800));

    expect(find.text('Cursos'), findsOneWidget);
    expect(find.text('Semestre 4 - 5 cursos'), findsOneWidget);
    expect(find.text('Cursos Aprobados'), findsOneWidget);
    expect(find.text('Cursos Reprobados'), findsOneWidget);
    expect(find.text('Promedio por semestre'), findsOneWidget);
    expect(
      find.text('Sumatoria de créditos totales por semestre'),
      findsOneWidget,
    );
    expect(find.text('Todas tus materias'), findsOneWidget);
    expect(find.text('73.80'), findsOneWidget);
    expect(find.text('20'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Programación IV'), 250);
    expect(find.text('Aprobada'), findsWidgets);
    expect(find.text('86 · Aprobado'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Redes de Computadoras'), 250);
    expect(find.text('Reprobada'), findsWidgets);
    expect(find.text('54 · Reprobado'), findsOneWidget);

    await tester.tap(find.text('A-Z'));
    await tester.pumpAndSettle();
    expect(find.text('Z-A'), findsOneWidget);
  });

  testWidgets('La materia abre su detalle, edición y lista de profesores',
      (tester) async {
    await _montarSemestre(tester, const Size(360, 800));

    await tester.scrollUntilVisible(find.text('Redes de Computadoras'), 250);
    await tester.tap(find.text('Redes de Computadoras'));
    await tester.pumpAndSettle();

    expect(find.text('Información del curso'), findsOneWidget);
    expect(find.text('Requisitos'), findsOneWidget);
    expect(find.text('Catedrático'), findsOneWidget);
    expect(find.text('Horario del curso'), findsOneWidget);
    expect(find.text('Descripción del curso'), findsOneWidget);
    expect(find.text('Electrónica Básica'), findsOneWidget);
    expect(find.text('Reprobado'), findsOneWidget);
    expect(find.text('11:00 AM - 12:30 PM'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar'));
    await tester.pumpAndSettle();

    expect(find.text('Editar asignatura'), findsOneWidget);
    expect(find.text('Ícono de la materia'), findsOneWidget);
    expect(find.text('Color de la materia'), findsWidgets);

    await tester.scrollUntilVisible(find.text('Actualizar'), 300);
    expect(find.text('Actualizar'), findsOneWidget);

    final profesor = find.widgetWithText(
      ListTile,
      'Ing. Luis Fernando Herrera Díaz',
    );
    await tester.scrollUntilVisible(profesor, 300);
    await tester.tap(profesor);
    await tester.pumpAndSettle();

    expect(find.text('Seleccionar profesor'), findsOneWidget);
    expect(find.text('Crear profesor'), findsOneWidget);
    expect(find.text('Seleccionar'), findsWidgets);

    await tester.tap(find.text('Crear profesor'));
    await tester.pumpAndSettle();

    expect(find.text('Nombre y apellidos'), findsOneWidget);
    expect(find.text('Correo electrónico'), findsOneWidget);
    expect(find.text('Horario de oficina/asesoría'), findsOneWidget);
    expect(find.text('Guardar'), findsOneWidget);
  });

  testWidgets('Eliminar información borra nota, horario, catedrático e ícono',
      (tester) async {
    await _montarSemestre(tester, const Size(390, 844));

    await tester.scrollUntilVisible(find.text('Sistemas Operativos'), 250);
    await tester.tap(find.text('Sistemas Operativos'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Eliminar información'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('catedrático, calificación y horario'),
      findsOneWidget,
    );
    expect(find.text('Cancelar'), findsOneWidget);
    expect(find.text('Eliminar'), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.text('Sin asignar'), findsOneWidget);
    expect(find.text('Sin horario'), findsOneWidget);
    expect(find.text('Sin calificación'), findsOneWidget);
    expect(find.text('Procesos, memoria y sistemas de archivos.'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Cursos Reprobados'),
      -400,
    );
    expect(find.text('Sin catedrático'), findsOneWidget);
    expect(find.text('Sin nota'), findsWidgets);
  });
}

Future<void> _montarSemestre(WidgetTester tester, Size tamano) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => DatosAcademicosMock()),
      ],
      child: MaterialApp(
        theme: AppTheme.build(
          brightness: Brightness.light,
          seedColor: AppColors.primary,
        ),
        home: const SemestreView(numeroSemestre: 4),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
