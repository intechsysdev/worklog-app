import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/selectable.dart';
import '../data/mock_state.dart';
import 'demo_controller.dart';

/// Strip shown on every screen of the demo APK.
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Column(
      children: [
        Material(
          color: c.warningDot,
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 22,
              width: double.infinity,
              child: Center(
                child: Text(
                  'Modo demostración · datos de prueba',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: c.ink),
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: MediaQuery.removePadding(context: context, removeTop: true, child: child),
        ),
      ],
    );
  }
}

/// "Modo demostración" card of the profile: scenarios, offline simulation and reset.
class DemoPanel extends ConsumerStatefulWidget {
  const DemoPanel({super.key});

  @override
  ConsumerState<DemoPanel> createState() => _DemoPanelState();
}

class _DemoPanelState extends ConsumerState<DemoPanel> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String message) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) showMessage(context, message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final status = ref.watch(demoControllerProvider);
    if (status == null) return const SizedBox.shrink();
    final controller = ref.read(demoControllerProvider.notifier);

    return AppCard(
      padding: const EdgeInsets.all(16),
      borderColor: c.warningDot,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel('Modo demostración', color: c.warningFg),
          const SizedBox(height: 6),
          Text(
            'Los datos viven en este teléfono. Elige un escenario para recorrer las pantallas; cambiarlo empieza el día de nuevo.',
            style: TextStyle(fontSize: 13, height: 18 / 13, color: c.inkStrong),
          ),
          const SizedBox(height: 12),
          for (final s in DemoScenario.values) ...[
            SelectableCard(
              title: s.label,
              meta: _detail(s),
              selected: status.scenario == s,
              selectedBackground: true,
              onTap: _busy || status.scenario == s
                  ? () {}
                  : () => _run(() => controller.setScenario(s), 'Escenario: ${s.label}.'),
            ),
            const SizedBox(height: 8),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Simular sin conexión', style: TextStyle(fontSize: 15, color: c.ink)),
            subtitle: Text(
              'Las acciones quedan en la cola de Pendiente de sincronizar.',
              style: TextStyle(fontSize: 12, color: c.inkMuted),
            ),
            value: status.offline,
            onChanged: _busy ? null : controller.setOffline,
          ),
          const SizedBox(height: 4),
          SecondaryButton(
            label: 'Reiniciar datos de demostración',
            icon: Icons.restart_alt_rounded,
            loading: _busy,
            foreground: c.primary,
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('¿Reiniciar los datos?'),
                  content: const Text(
                    'Se borran la jornada de hoy, la cola y las solicitudes nuevas, y vuelven los datos iniciales.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reiniciar')),
                  ],
                ),
              );
              if (confirmed == true) await _run(controller.reset, 'Datos de demostración reiniciados.');
            },
          ),
          TertiaryButton(label: 'Ver el aviso de fin de turno', onPressed: () => context.push(Routes.shiftEndNotice)),
        ],
      ),
    );
  }

  static String _detail(DemoScenario s) => switch (s) {
    DemoScenario.normal => 'Turno de hoy según la hora real, OT asignadas y catálogo.',
    DemoScenario.vacation => 'Novedad aprobada: el inicio de jornada queda bloqueado.',
    DemoScenario.kioskShared => 'Apps de trabajo bloqueadas hasta iniciar; sesión compartida.',
    DemoScenario.kioskAssigned => 'Apps de trabajo bloqueadas hasta iniciar; equipo propio.',
    DemoScenario.shiftEnd => 'Jornada abierta y cierre automático en 16 min (avisos de 15 y 5).',
  };
}
