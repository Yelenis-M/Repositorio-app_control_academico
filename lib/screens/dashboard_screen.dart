import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../widgets/app_background.dart';
import '../widgets/app_button.dart';
import '../widgets/app_card.dart';
import 'profile/profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.onOpenSemester,
    this.onLogout,
  });

  /// Callback para abrir SemestreScreen(numeroSemestre, esBloqueado)
  final void Function(int semestre, bool bloqueado)? onOpenSemester;
  final VoidCallback? onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _indiceRuta = 0;
  int _semestreSeleccionado = 4;

  // Timer para actualizar el saludo
  Timer? _saludoTimer;
  String _saludo = '';

  // Datos de ejemplo (Gerson los inyectará desde usuario_model.dart)
  final String _primerNombre = 'Yelenis';
  final String _nombreCompleto = 'Yelenis Andrea Marroquín López';
  final String _carne = '000150079';
  final String _carrera = 'Ingeniería en Sistemas';
  final String _universidad = 'Universidad Panamericana';
  final String _correo = '000150079@upana.edu.gt';
  final int _semestreActual = 4;
  final int _totalSemestres = 10;
  final String? _fotoPerfilUrl = null;

  @override
  void initState() {
    super.initState();
    _saludo = _obtenerSaludo(); // calcular al iniciar
    _iniciarTimerSaludo();
  }
  @override
  void dispose() {
    _saludoTimer?.cancel();
    super.dispose();
  }

  /// Inicia un timer que revisa cada minuto si el saludo debe cambiar.
  void _iniciarTimerSaludo() {
    _saludoTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      final nuevoSaludo = _obtenerSaludo();
      if (nuevoSaludo != _saludo && mounted) {
        setState(() => _saludo = nuevoSaludo);
      }
    });
  }

  /// Calcula el saludo según la hora actual.
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
    final colorScheme = Theme.of(context).colorScheme;
    final esOscuro = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // ==========================================
              // BARRA SUPERIOR (Avatar + Saludo + Sol/Luna)
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _abrirPerfil(context),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.2),
                        backgroundImage: _fotoPerfilUrl != null
                            ? NetworkImage(_fotoPerfilUrl)
                            : null,
                        child: _fotoPerfilUrl == null
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
                        onTap: () => _abrirPerfil(context),
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
                              _primerNombre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botón de Sol / Luna para alternar tema rápido
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

              // ==========================================
              // CONTENIDO SEGÚN LA RUTA SELECCIONADA
              // ==========================================
              Expanded(
                child: IndexedStack(
                  index: _indiceRuta,
                  children: [
                    _buildRutaInicio(colorScheme),
                    _buildRutaResumenGlobal(colorScheme),
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
            label: 'Resumen Global',
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RUTA 1: INICIO Y GESTIÓN POR SEMESTRE
  // ==========================================
  Widget _buildRutaInicio(ColorScheme colorScheme) {
    final double progreso = _semestreActual / _totalSemestres;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tarjeta central de Identidad (ID y Carrera centrados)
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
                      'ID: $_carne',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _carrera,
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

          // Progreso de la Carrera
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
                        'Semestre $_semestreActual / $_totalSemestres',
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

          // Gestión Académica por Semestre
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
                        value: _semestreSeleccionado,
                        isExpanded: true,
                        items: List.generate(_totalSemestres, (i) => i + 1)
                            .map(
                              (sem) => DropdownMenuItem(
                                value: sem,
                                child: Row(
                                  children: [
                                    Text('Semestre $sem'),
                                    if (sem > _semestreActual) ...[
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
                  AppButton(
                    text: 'Ver materias del semestre',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () {
                      final bloqueado =
                          _semestreSeleccionado > _semestreActual;
                      if (widget.onOpenSemester != null) {
                        widget.onOpenSemester!(
                          _semestreSeleccionado,
                          bloqueado,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            content: Text(
                              bloqueado
                                  ? 'Semestre $_semestreSeleccionado (Solo lectura)'
                                  : 'Abriendo Semestre $_semestreSeleccionado',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // RUTA 2: RESUMEN GLOBAL DE LA CARRERA
  // ==========================================
  Widget _buildRutaResumenGlobal(ColorScheme colorScheme) {
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
          Text(
            'Estadísticas acumuladas de tu historial académico',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),

          // Tarjeta destacada: Promedio General
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Promedio General Acumulado',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '85.40 pts',
                          style: TextStyle(
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

          // Fila de Aprobados y Reprobados (sin altura rígida para evitar overflow)
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  title: 'Aprobados',
                  value: '20',
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBox(
                  title: 'Reprobados',
                  value: '2',
                  icon: Icons.cancel_outlined,
                  color: Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Fila de Total Cursos y Créditos Aprobados
          Row(
            children: [
              Expanded(
                child: _MetricBox(
                  title: 'Total Cursos',
                  value: '48',
                  icon: Icons.menu_book_rounded,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricBox(
                  title: 'Créditos Aprobados',
                  value: '95 / 220',
                  icon: Icons.military_tech_outlined,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _abrirPerfil(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          nombreCompleto: _nombreCompleto,
          carne: _carne,
          carrera: _carrera,
          universidad: _universidad,
          periodoActual: '$_semestreActual.º Semestre',
          correo: _correo,
          fotoUrl: _fotoPerfilUrl,
          onLogout: widget.onLogout,
        ),
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