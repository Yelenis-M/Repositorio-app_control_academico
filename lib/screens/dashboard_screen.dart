import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/datos_academicos_mock.dart';
import '../models/catedratico.dart';
import '../services/auth_service.dart';
import '../services/pdf_service.dart';
import '../services/perfil_service.dart';
import '../theme/theme_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import '../screens/academico/contacto_catedratico_view.dart';
import '../screens/academico/form_catedratico_view.dart';
import 'profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.onOpenSemester,
    this.onLogout,
  });

  final void Function(int semestre, bool bloqueado)? onOpenSemester;
  final VoidCallback? onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PerfilService _perfilService = PerfilService();
  final PdfService _pdfService = PdfService();

  int _indiceRuta = 0;
  int? _semestreSeleccionado;
  bool _generandoPdf = false;
  Timer? _saludoTimer;
  String _saludo = '';

  static const String _universidad = 'Universidad Panamericana';

  @override
  void initState() {
    super.initState();
    _saludo = _obtenerSaludo();
    _iniciarTimerSaludo();
  }

  @override
  void dispose() {
    _saludoTimer?.cancel();
    super.dispose();
  }

  void _iniciarTimerSaludo() {
    _saludoTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final nuevoSaludo = _obtenerSaludo();
      if (nuevoSaludo != _saludo && mounted) {
        setState(() => _saludo = nuevoSaludo);
      }
    });
  }

  String _obtenerSaludo() {
    final hora = DateTime.now().hour;
    if (hora >= 5 && hora < 12) {
      return 'Buenos días';
    } else if (hora >= 12 && hora < 18) {
      return 'Buenas tardes';
    } else {
      return 'Buenas noches';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final datos = context.watch<DatosAcademicosMock>();
    final usuario = datos.usuarioActual;
    final colorScheme = Theme.of(context).colorScheme;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    final nombreCompleto = (usuario?.nombre.trim().isNotEmpty ?? false)
        ? usuario!.nombre.trim()
        : 'Estudiante';
    final primerNombre = nombreCompleto.split(' ').first;
    final bytesFoto = _perfilService.decodificarFoto(usuario?.fotoBase64);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // BARRA SUPERIOR
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _abrirPerfil(context, datos),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.2),
                        backgroundImage:
                            bytesFoto != null ? MemoryImage(bytesFoto) : null,
                        child: bytesFoto == null
                            ? Icon(
                                Icons.person_rounded,
                                color: colorScheme.primary,
                                size: 24,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _abrirPerfil(context, datos),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$_saludo,',
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              primerNombre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: esOscuro
                          ? 'Cambiar a modo claro'
                          : 'Cambiar a modo oscuro',
                      icon: Icon(
                        esOscuro
                            ? Icons.light_mode_outlined
                            : Icons.dark_mode_outlined,
                      ),
                      onPressed: () {
                        themeProvider.setThemeMode(
                          esOscuro ? ThemeMode.light : ThemeMode.dark,
                        );
                      },
                    ),
                  ],
                ),
              ),
              // CONTENIDO DE LAS RUTAS
              Expanded(
                child: datos.cargando && datos.todosLosCursos.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : IndexedStack(
                        index: _indiceRuta,
                        children: [
                          _buildRutaInicio(colorScheme, datos),
                          _buildRutaResumenGlobal(colorScheme, datos),
                          const _RutaCatedraticos(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indiceRuta,
        onDestinationSelected: (index) {
          setState(() => _indiceRuta = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Resumen',
          ),
          NavigationDestination(
            icon: Icon(Icons.group_outlined),
            selectedIcon: Icon(Icons.group_rounded),
            label: 'Catedráticos',
          ),
        ],
      ),
    );
  }

  Widget _buildRutaInicio(ColorScheme colorScheme, DatosAcademicosMock datos) {
    final usuario = datos.usuarioActual;
    final carne = usuario?.carnet ?? '---';
    final carrera = (usuario?.carrera.trim().isNotEmpty ?? false)
        ? usuario!.carrera
        : 'Ingeniería en Sistemas';
    final totalSemestres = datos.totalSemestres;
    final semestreActual =
        datos.semestreMaximoHabilitado.clamp(1, totalSemestres);
    final semestreElegido =
        (_semestreSeleccionado ?? semestreActual).clamp(1, totalSemestres);
    final double progreso = (semestreActual / totalSemestres).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ID: $carne',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    carrera,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _universidad,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.school_outlined,
                        color: colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Progreso de la Carrera',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'Semestre $semestreActual / $totalSemestres',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progreso,
                      minHeight: 8,
                      backgroundColor:
                          colorScheme.primary.withValues(alpha: 0.15),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Gestión Académica',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Selecciona un semestre para consultar o registrar notas:',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: colorScheme.outline.withValues(alpha: 0.4),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: semestreElegido,
                        isExpanded: true,
                        items: List.generate(totalSemestres, (i) => i + 1)
                            .map(
                              (sem) => DropdownMenuItem(
                                value: sem,
                                child: Row(
                                  children: [
                                    Text('Semestre $sem'),
                                    if (datos.estaSemestreBloqueado(sem)) ...[
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.lock_outline,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _semestreSeleccionado = value);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Ver materias',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        final bloqueado =
                            datos.estaSemestreBloqueado(semestreElegido);
                        if (widget.onOpenSemester != null) {
                          widget.onOpenSemester!(semestreElegido, bloqueado);
                        } else {
                          Navigator.pushNamed(
                            context,
                            '/semestre',
                            arguments: {
                              'semestre': semestreElegido,
                              'bloqueado': bloqueado,
                            },
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRutaResumenGlobal(
    ColorScheme colorScheme,
    DatosAcademicosMock datos,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Resumen Global de la Carrera',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Estadísticas acumuladas de tu historial académico',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.trending_up_rounded,
                      color: colorScheme.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Promedio General Acumulado',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${datos.promedioGlobal.toStringAsFixed(2)} pts',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  title: 'Aprobados',
                  value: '${datos.cursosAprobados}',
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBox(
                  title: 'Reprobados',
                  value: '${datos.cursosReprobados}',
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  title: 'Total Cursos',
                  value: '${datos.totalCursosPensum}',
                  icon: Icons.menu_book_rounded,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBox(
                  title: 'Créditos Aprobados',
                  value:
                      '${datos.creditosAcumulados} / ${datos.totalCreditosPensum}',
                  icon: Icons.military_tech_outlined,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: 'Descargar PDF',
              icon: Icons.picture_as_pdf_rounded,
              isLoading: _generandoPdf,
              onPressed: _generandoPdf
                  ? null
                  : () => _generarReportePdfCarrera(context, datos),
            ),
          ),
        ],
      ),
    );
  }

  void _generarReportePdfCarrera(
    BuildContext context,
    DatosAcademicosMock datos,
  ) {
    final usuario = datos.usuarioActual;
    if (usuario == null) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Generar Reporte PDF'),
        content: const Text(
          'Se generará el documento PDF con tu vida académica completa, notas y prerrequisitos para guardar o compartir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() => _generandoPdf = true);
              try {
                await _pdfService.generarYMostrarVidaAcademica(
                  usuario,
                  cursosPrecargados: datos.todosLosCursos,
                  catedraticosPrecargados: datos.catedraticos,
                );
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      behavior: SnackBarBehavior.floating,
                      content: Text(
                        'No se pudo generar el reporte PDF. Intenta de nuevo.',
                      ),
                    ),
                  );
                }
              } finally {
                if (mounted) setState(() => _generandoPdf = false);
              }
            },
            child: const Text('Descargar / Compartir'),
          ),
        ],
      ),
    );
  }

  void _abrirPerfil(BuildContext context, DatosAcademicosMock datos) {
    final usuario = datos.usuarioActual;
    final semestreActual =
        datos.semestreMaximoHabilitado.clamp(1, datos.totalSemestres);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          nombreCompleto: usuario?.nombre ?? 'Estudiante',
          carne: usuario?.carnet ?? '---',
          carrera: (usuario?.carrera.trim().isNotEmpty ?? false)
              ? usuario!.carrera
              : 'Sin carrera asignada',
          universidad: _universidad,
          periodoActual: '$semestreActual.º Semestre',
          correo: usuario?.correo ?? '',
          onResetPassword: (correo) =>
              AuthService().enviarCorreoRecuperacion(correo),
          onLogout: widget.onLogout,
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA DE CATEDRÁTICOS
// ==========================================
class _RutaCatedraticos extends StatefulWidget {
  const _RutaCatedraticos();

  @override
  State<_RutaCatedraticos> createState() => _RutaCatedraticosState();
}

class _RutaCatedraticosState extends State<_RutaCatedraticos> {
  final TextEditingController _searchController = TextEditingController();
  String _filtroBusqueda = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _filtroBusqueda = _searchController.text.toLowerCase().trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final datos = context.watch<DatosAcademicosMock>();
    final todosCatedraticos = datos.catedraticos;

    final profesoresFiltrados = todosCatedraticos.where((cat) {
      return cat.nombre.toLowerCase().contains(_filtroBusqueda) ||
          cat.correo.toLowerCase().contains(_filtroBusqueda);
    }).toList();

    profesoresFiltrados.sort((a, b) => a.nombre.compareTo(b.nombre));

    final Map<String, List<Catedratico>> agrupados = {};
    for (var prof in profesoresFiltrados) {
      if (prof.nombre.isNotEmpty) {
        final letra = prof.nombre[0].toUpperCase();
        agrupados.putIfAbsent(letra, () => []).add(prof);
      }
    }

    final letrasOrdenadas = agrupados.keys.toList()..sort();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const FormCatedraticoView(),
            ),
          );
        },
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nuevo profesor'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Profesores',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              Text(
                '${todosCatedraticos.length} profesores',
                style: TextStyle(color: esquema.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar profesor...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: esquema.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 16),
          if (profesoresFiltrados.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 40),
              child: Center(
                child: Text(
                  'No se encontraron profesores',
                  style: TextStyle(color: esquema.onSurfaceVariant),
                ),
              ),
            )
          else
            for (final letra in letrasOrdenadas) ...[
              Text(
                letra,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: esquema.primary,
                ),
              ),
              const SizedBox(height: 8),
              ...agrupados[letra]!.map((profesor) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: profesor.color.withValues(alpha: 0.16),
                        child: Text(
                          letra,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: profesor.color,
                          ),
                        ),
                      ),
                      title: Text(
                        profesor.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        profesor.correo,
                        style: TextStyle(
                          fontSize: 13,
                          color: esquema.onSurfaceVariant,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.email_outlined,
                              color: esquema.primary,
                              size: 20,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ContactoCatedraticoView(
                                    catedraticoId: profesor.id,
                                  ),
                                ),
                              );
                            },
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 20),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ContactoCatedraticoView(
                              catedraticoId: profesor.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}