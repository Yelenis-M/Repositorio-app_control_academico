import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/datos_academicos_mock.dart';
import '../../widgets/app_background.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'editar_catedratico_view.dart';

/// Perfil de contacto del catedrático: ícono, nombre, correo, teléfono y horario.
class ContactoCatedraticoView extends StatelessWidget {
  const ContactoCatedraticoView({
    super.key,
    required this.catedraticoId,
    this.soloLectura=false,
  });

  final String catedraticoId;
  final bool soloLectura;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final catedratico = context.watch<DatosAcademicosMock>().buscarCatedratico(
          catedraticoId,
        );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Contacto'),
      ),
      body: AppBackground(
        child: catedratico == null
            ? const Center(child: Text('No se encontró el catedrático.'))
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  AppCard(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 46,
                          backgroundColor:
                              catedratico.color.withValues(alpha: 0.16),
                          child: Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: catedratico.color,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          catedratico.nombre,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      children: [
                        _FilaContacto(
                          icono: Icons.email_outlined,
                          etiqueta: 'Correo',
                          valor: _texto(catedratico.correo, 'Sin correo'),
                        ),
                        const Divider(height: 22),
                        _FilaContacto(
                          icono: Icons.phone_outlined,
                          etiqueta: 'Teléfono',
                          valor: _texto(catedratico.telefono, 'Sin teléfono'),
                        ),
                        const Divider(height: 22),
                        _FilaContacto(
                          icono: Icons.schedule_outlined,
                          etiqueta: 'Horario',
                          valor: _texto(catedratico.horarioOficina, 'Sin horario especificado'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: 'Editar',
                    icon: Icons.edit_outlined,
                    width: double.infinity,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditarCatedraticoView(
                            catedraticoId: catedratico.id,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El ícono usa el color elegido para este catedrático.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: esquema.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _texto(String valor, String vacio) {
    final limpio = valor.trim();
    return limpio.isEmpty ? vacio : limpio;
  }
}

class _FilaContacto extends StatelessWidget {
  const _FilaContacto({
    required this.icono,
    required this.etiqueta,
    required this.valor,
  });

  final IconData icono;
  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: esquema.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: esquema.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }
}