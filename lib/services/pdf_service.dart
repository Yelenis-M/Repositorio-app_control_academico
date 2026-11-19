import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/usuario_model.dart';
import '../models/curso.dart';
import 'notas_service.dart';
import 'catedraticos_service.dart';

typedef MapaSemestres = Map<int, List<Curso>>;

class PdfService {
  final NotasService _notasService = NotasService();
  final CatedraticosService _catedraticosService = CatedraticosService();

  Future<void> generarYMostrarVidaAcademica(UsuarioModel usuario) async {
    final pdf = pw.Document();

    final resumenGlobal = await _notasService.obtenerResumenGlobal(
      usuario.carnet,
      usuario.carreraId,
    );

    // Mapa id -> nombre de catedráticos por si el curso solo tiene catedraticoId
    final listaCatedraticos =
        await _catedraticosService.obtenerCatedraticos(usuario.carnet);
    final Map<String, String> mapaNombresCat = {
      for (var cat in listaCatedraticos) cat.id: cat.nombre,
    };

    final MapaSemestres cursosPorSemestre = {};
    for (int s = 1; s <= 11; s++) {
      final lista = await _notasService.obtenerCursosPorSemestre(
        usuario.carnet,
        usuario.carreraId,
        s,
      );
      if (lista.isNotEmpty) {
        cursosPorSemestre[s] = lista;
      }
    }

    final etiquetaPensum =
        usuario.carreraId == 'sistemas_2026' ? 'Pénsum 2026' : 'Pénsum 2024';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => _construirEncabezado(usuario, etiquetaPensum),
        footer: (context) => _construirPieDePagina(context),
        build: (context) => [
          pw.SizedBox(height: 10),
          _construirCajaResumenGlobal(resumenGlobal),
          pw.SizedBox(height: 14),
          for (var entrada in cursosPorSemestre.entries) ...[
            _construirBloqueSemestre(entrada.key, entrada.value, mapaNombresCat),
            pw.SizedBox(height: 12),
          ],
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Vida_Academica_${usuario.carnet}.pdf',
    );
  }

  pw.Widget _construirEncabezado(UsuarioModel usuario, String etiquetaPensum) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'VIDA ACADÉMICA CON PRERREQUISITOS',
                  style: pw.TextStyle(
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.Text(
                  'Ingeniería y Ciencias Aplicadas',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  '${usuario.carrera} ($etiquetaPensum)',
                  style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'UNIVERSIDAD PANAMERICANA',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.indigo900,
                  ),
                ),
                pw.Text(
                  '"Sabiduría ante todo; adquiere sabiduría"',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.indigo50,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Estudiante: ${usuario.carnet} - ${usuario.nombre}',
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Ingreso: ${usuario.anioIngreso}',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),
        ),
        pw.Divider(color: PdfColors.indigo900, thickness: 1),
      ],
    );
  }

  pw.Widget _construirCajaResumenGlobal(Map<String, dynamic> resumen) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.indigo200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _itemResumen('Promedio Global', '${resumen['promedioGlobal']} pts'),
          _itemResumen('Créditos Acumulados', '${resumen['creditosAcumulados']}'),
          _itemResumen('Cursos Aprobados', '${resumen['aprobados']}'),
          _itemResumen('Cursos Reprobados', '${resumen['reprobados']}'),
          _itemResumen('Total Pénsum', '${resumen['totalCursosPensum']}'),
        ],
      ),
    );
  }

  pw.Widget _itemResumen(String titulo, String valor) {
    return pw.Column(
      children: [
        pw.Text(titulo, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
        pw.SizedBox(height: 2),
        pw.Text(
          valor,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo900,
          ),
        ),
      ],
    );
  }

  pw.Widget _construirBloqueSemestre(
    int semestre,
    List<Curso> cursos,
    Map<String, String> mapaNombresCat,
  ) {
    int aprobados = 0;
    int creditosSem = 0;
    double suma = 0;
    int evaluados = 0;

    for (var c in cursos) {
      if (c.calificacion != null) {
        evaluados++;
        suma += c.calificacion!;
        if (c.aprobado) {
          aprobados++;
          creditosSem += c.creditos;
        }
      }
    }

    final promSem = evaluados > 0 ? (suma / evaluados).toStringAsFixed(2) : '0.00';

    final filas = cursos.map((c) {
      final textoNota = c.calificacion != null ? c.calificacion!.toStringAsFixed(0) : '-';
      final textoEstado = c.calificacion == null
          ? 'PENDIENTE'
          : (c.aprobado ? 'APROBADO' : 'REPROBADO');

      String textoCatedratico = '-';
      if (c.catedraticoNombre != null && c.catedraticoNombre!.isNotEmpty) {
        textoCatedratico = c.catedraticoNombre!;
      } else if (c.catedraticoId != null && mapaNombresCat.containsKey(c.catedraticoId)) {
        textoCatedratico = mapaNombresCat[c.catedraticoId]!;
      }

      return [
        c.id,
        c.nombre,
        '${c.creditos}',
        textoNota,
        textoEstado,
        textoCatedratico,
        c.prerequisitosNombresLimpios,
      ];
    }).toList();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          color: PdfColors.indigo900,
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ISTI SEMESTRAL $semestre',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Promedio Semestre: $promSem | Aprobados: $aprobados/${cursos.length} | Créditos: $creditosSem',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 8),
              ),
            ],
          ),
        ),
        pw.TableHelper.fromTextArray(
          headers: const [
            'CÓDIGO',
            'CURSO',
            'CRÉD.',
            'NOTA',
            'ESTADO',
            'CATEDRÁTICO',
            'PRERREQUISITOS',
          ],
          data: filas,
          headerStyle: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.indigo900,
          ),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellStyle: const pw.TextStyle(fontSize: 7),
          cellPadding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: {
            0: const pw.FixedColumnWidth(46),
            1: const pw.FlexColumnWidth(2.3),
            2: const pw.FixedColumnWidth(30),
            3: const pw.FixedColumnWidth(30),
            4: const pw.FixedColumnWidth(52),
            5: const pw.FlexColumnWidth(1.5),
            6: const pw.FlexColumnWidth(2.2),
          },
        ),
      ],
    );
  }

  pw.Widget _construirPieDePagina(pw.Context context) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      margin: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Página ${context.pageNumber} de ${context.pagesCount}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
      ),
    );
  }
}