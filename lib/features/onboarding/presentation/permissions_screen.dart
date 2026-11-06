import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../data/device_info.dart';
import '../data/device_permissions.dart';
import 'onboarding_controller.dart';

/// "Revisión del dispositivo". The MobiControl integration (group, serial, configuration sent
/// by the MDM) is not read yet; this screen checks the OS permissions.
class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key, this.fromProfile = false});

  final bool fromProfile;

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> with WidgetsBindingObserver {
  Map<DevicePermission, bool>? _status;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from the system settings.
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final status = await ref.read(devicePermissionsProvider).check();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _recheck() async {
    setState(() => _checking = true);
    final status = await ref.read(devicePermissionsProvider).requestMissing();
    if (mounted) {
      setState(() {
        _status = status;
        _checking = false;
      });
    }
  }

  Future<void> _continue() async {
    if (widget.fromProfile) {
      await Navigator.of(context).maybePop();
      return;
    }
    await ref.read(onboardingProvider.notifier).markDeviceReviewed();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final device = ref.watch(deviceInfoProvider).value;
    final status = _status;
    final missing = status == null
        ? const <DevicePermission>[]
        : [
            for (final p in DevicePermission.values)
              if (status[p] != true) p,
          ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(
              title: 'Revisión del dispositivo',
              onBack: widget.fromProfile ? null : () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 12),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: c.successBg, shape: BoxShape.circle),
                          child: Icon(Icons.phone_android_rounded, size: 20, color: c.successFg),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Administrado por SOTI MobiControl',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${device?.model ?? 'Dispositivo'} · ${device?.os ?? ''}\nGrupo y serie: llegan con la integración de MobiControl',
                                style: TextStyle(fontSize: 13, height: 18 / 13, color: c.inkMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'La política de tu dispositivo concede estos permisos. Si alguno falla, soporte TI lo corrige desde MobiControl; no tienes que cambiar nada en el teléfono.',
                    style: TextStyle(fontSize: 14, height: 20 / 14, color: c.inkStrong),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        for (final p in DevicePermission.values)
                          _PermissionRow(title: p.title, why: p.why, granted: status?[p]),
                        const _PermissionRow(
                          title: 'Configuración de la app',
                          why: 'Servidor y usuario enviados por MobiControl',
                          granted: null,
                          pendingLabel: 'No disponible',
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  if (missing.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: c.warningBg,
                        borderRadius: BorderRadius.circular(AppRadii.button),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              style: TextStyle(fontSize: 14, height: 20 / 14, color: c.warningInk),
                              children: [
                                TextSpan(
                                  text: missing.map((p) => p.title).join(', '),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text: missing.length == 1
                                      ? ' no está activo en este dispositivo. Avisa a soporte TI para que lo active desde MobiControl.'
                                      : ' no están activos en este dispositivo. Avisa a soporte TI para que los active desde MobiControl.',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          SecondaryButton(
                            label: 'Volver a revisar',
                            expand: false,
                            height: 44,
                            fontSize: 14,
                            loading: _checking,
                            foreground: c.warningInk,
                            borderColor: c.warningFg,
                            onPressed: _recheck,
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 0, kScreenPadding, 20),
              child: PrimaryButton(label: widget.fromProfile ? 'Listo' : 'Continuar', onPressed: _continue),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.title,
    required this.why,
    required this.granted,
    this.pendingLabel,
    this.last = false,
  });

  final String title;
  final String why;

  /// Null while checking (or not applicable yet).
  final bool? granted;
  final String? pendingLabel;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final (label, bg, fg) = switch (granted) {
      true => ('Por política', c.successBg, c.successFg),
      false => ('Falta', c.warningBg, c.warningFg),
      null => (pendingLabel ?? '…', c.surfaceMuted, c.inkStrong),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink),
                ),
                const SizedBox(height: 2),
                Text(why, style: TextStyle(fontSize: 12, color: c.inkMuted)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          StatusChip(
            label: label,
            background: bg,
            foreground: fg,
            fontSize: 12,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
        ],
      ),
    );
  }
}
