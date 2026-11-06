import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/format/formatters.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/headers.dart';
import '../../auth/presentation/auth_controller.dart';
import 'onboarding_controller.dart';

/// "Tratamiento de datos". The CTA stays disabled until the checkbox is marked.
class PolicyScreen extends ConsumerStatefulWidget {
  const PolicyScreen({super.key, this.readOnly = false});

  /// Opened from the profile: shows the accepted version, nothing to accept.
  final bool readOnly;

  @override
  ConsumerState<PolicyScreen> createState() => _PolicyScreenState();
}

class _PolicyScreenState extends ConsumerState<PolicyScreen> {
  bool _checked = false;
  bool _busy = false;
  String? _error;

  static const _fallback = [
    'Ubicación, solo en jornada: al iniciar, cambiar y finalizar actividades, y cada 15 minutos mientras trabajas.',
    'Horas y actividades: para calcular tu jornada, horas extra y recargos.',
    'Fotos y firma del cliente: como evidencia del trabajo realizado.',
    'Tus derechos: conocer, actualizar y rectificar tus datos, y revocar la autorización (Ley 1581 de 2012).',
  ];

  static const _icons = [
    Icons.place_outlined,
    Icons.schedule_rounded,
    Icons.photo_camera_outlined,
    Icons.verified_user_outlined,
  ];

  @override
  void initState() {
    super.initState();
    if (ref.read(onboardingProvider).policy == null) {
      Future.microtask(() => ref.read(onboardingProvider.notifier).checkPolicy().catchError((_) {}));
    }
  }

  Future<void> _accept() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(onboardingProvider.notifier).acceptPolicy();
    } on ApiException catch (e) {
      setState(
        () => _error = e.isNetwork ? 'Necesitas conexión para aceptar la política. Inténtalo de nuevo.' : e.message,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openFullText(String? url) async {
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) showMessage(context, 'La política completa no está disponible en este momento.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final state = ref.watch(onboardingProvider);
    final policy = state.policy;
    final items = (policy?.summary.isNotEmpty ?? false) ? policy!.summary : _fallback;
    final version = policy?.version ?? '1.0';
    final effective = Fmt.dateOnly(policy?.effectiveFrom);
    final accepted = widget.readOnly && (policy?.accepted ?? state.policyAccepted);
    final checked = accepted || _checked;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BackHeader(
              title: 'Tratamiento de datos',
              onBack: widget.readOnly ? null : () => ref.read(authControllerProvider.notifier).signOut(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 12),
                children: [
                  Text(
                    'Antes de empezar, revisa qué datos registra WorkLog y para qué. Puedes leer la política completa cuando quieras desde tu perfil.',
                    style: TextStyle(fontSize: 15, height: 22 / 15, color: c.inkStrong),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++)
                          _PolicyItem(icon: _icons[i % _icons.length], text: items[i], last: i == items.length - 1),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: LinkButton(
                      label: 'Leer la política completa',
                      onPressed: () => _openFullText(policy?.fullTextUrl),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 0, kScreenPadding, 20),
              child: Column(
                children: [
                  _AcceptBox(
                    checked: checked,
                    enabled: !accepted,
                    subtitle: [
                      'Versión $version',
                      if (effective != null) 'vigente desde ${Fmt.shortDate(effective)} ${effective.year}',
                      if (accepted && policy?.acceptedAt != null)
                        'aceptada el ${Fmt.shortDate(policy!.acceptedAt!.toLocal())}',
                    ].join(' · '),
                    onChanged: (v) => setState(() => _checked = v),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    InfoBanner(icon: Icons.error_outline, child: Text(_error!)),
                  ],
                  const SizedBox(height: 14),
                  if (widget.readOnly)
                    SecondaryButton(label: 'Volver', onPressed: () => Navigator.of(context).maybePop())
                  else
                    PrimaryButton(label: 'Aceptar y continuar', loading: _busy, onPressed: _checked ? _accept : null),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PolicyItem extends StatelessWidget {
  const _PolicyItem({required this.icon, required this.text, required this.last});

  final IconData icon;
  final String text;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final split = text.indexOf(':');
    final title = split > 0 ? text.substring(0, split).trim() : text;
    var body = split > 0 ? text.substring(split + 1).trim() : '';
    if (body.isNotEmpty) body = body[0].toUpperCase() + body.substring(1);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: c.pinkSoft, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: c.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.ink),
                ),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(fontSize: 13, height: 18 / 13, color: c.inkMuted),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptBox extends StatelessWidget {
  const _AcceptBox({required this.checked, required this.enabled, required this.subtitle, required this.onChanged});

  final bool checked;
  final bool enabled;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Material(
      color: c.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.button),
        side: BorderSide(color: checked ? c.primary : c.borderInput),
      ),
      child: InkWell(
        customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.button)),
        onTap: enabled ? () => onChanged(!checked) : null,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: Checkbox(
                  value: checked,
                  onChanged: enabled ? (v) => onChanged(v ?? false) : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Leí y acepto la política de tratamiento de datos de INTECHSYS.',
                      style: TextStyle(fontSize: 14, height: 20 / 14, color: c.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: c.inkMuted)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
