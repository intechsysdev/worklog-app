import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes.dart';
import '../../../core/clock/server_clock.dart';
import '../../../core/format/formatters.dart';
import '../../../core/location/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/dashed_box.dart';
import '../../../core/widgets/headers.dart';
import '../data/models/activity_options_dto.dart';
import '../data/models/enums.dart';
import '../domain/day_projection.dart';
import 'signature_screen.dart';
import 'widgets/workday_widgets.dart';
import 'workday_commands.dart';
import 'workday_providers.dart';

/// Photo, signature and observation required to finish an activity.
class FinishRequirements {
  const FinishRequirements({required this.photo, required this.signature, required this.observation});

  /// Requirements of the activity (server snapshot or catalog) combined with the outcome.
  factory FinishRequirements.of(ActivityView activity, CatalogOptionDto? catalog, OutcomeDto outcome) =>
      FinishRequirements(
        photo: activity.requirements.photo || (catalog?.requiresPhoto ?? false),
        signature: activity.requirements.signature || (catalog?.requiresSignature ?? false),
        observation:
            outcome.requiresObservation ||
            activity.requirements.observationAlways ||
            catalog?.observation == ObservationPolicy.always,
      );

  final bool photo;
  final bool signature;
  final bool observation;
}

/// "Finalizar actividad".
class FinishActivityScreen extends ConsumerStatefulWidget {
  const FinishActivityScreen({super.key});

  @override
  ConsumerState<FinishActivityScreen> createState() => _FinishActivityScreenState();
}

class _FinishActivityScreenState extends ConsumerState<FinishActivityScreen> {
  final _observation = TextEditingController();
  final _photos = <CapturedPhoto>[];
  ActivityOutcome _outcome = ActivityOutcome.completed;
  Uint8List? _signature;
  DateTime? _signedAt;
  LocationFix? _location;
  bool _locating = true;
  bool _submitted = false;
  bool _busy = false;

  /// Kept while saving: the optimistic state drops the activity as soon as it is queued.
  ActivityView? _activity;

  @override
  void initState() {
    super.initState();
    _captureLocation();
  }

  @override
  void dispose() {
    _observation.dispose();
    super.dispose();
  }

  Future<void> _captureLocation() async {
    final fix = await ref.read(locationServiceProvider).current();
    if (mounted) {
      setState(() {
        _location = fix;
        _locating = false;
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 75,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) return;
      setState(() => _photos.add(CapturedPhoto(path: file.path, capturedAt: ref.read(serverClockProvider).now())));
    } on Exception {
      if (mounted) showMessage(context, 'No se pudo abrir la cámara. Revisa el permiso de cámara.');
    }
  }

  Future<void> _sign() async {
    final bytes = await SignatureScreen.open(context);
    if (bytes != null && mounted) {
      setState(() {
        _signature = bytes;
        _signedAt = ref.read(serverClockProvider).now();
      });
    }
  }

  Future<void> _confirm(ActivityView activity, OutcomeDto outcome, FinishRequirements requirements) async {
    setState(() => _submitted = true);
    if (_missing(requirements).isNotEmpty) return;

    setState(() => _busy = true);
    try {
      final handle = await ref
          .read(workdayCommandsProvider)
          .finishActivity(
            activity: activity,
            outcome: _outcome,
            outcomeLabel: outcome.label,
            observation: _observation.text,
            photos: List.of(_photos),
            signaturePng: _signature,
            signedAt: _signedAt,
            location: _location,
          );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      context.go(Routes.history);
      await reportCommand(messenger, handle, accepted: 'Actividad finalizada.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> _missing(FinishRequirements r) => [
    if (r.observation && _observation.text.trim().isEmpty) 'observación',
    if (r.photo && _photos.isEmpty) 'foto',
    if (r.signature && _signature == null) 'firma del cliente',
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final activity = _busy ? _activity : ref.watch(dayViewProvider).value?.current;
    _activity = activity;
    final options = ref.watch(activityOptionsProvider).value;

    if (activity == null) {
      return const Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              BackHeader(title: 'Finalizar actividad'),
              Expanded(child: StateMessage(message: 'No tienes una actividad en curso.')),
            ],
          ),
        ),
      );
    }

    final outcomes = (options?.outcomes.isNotEmpty ?? false) ? options!.outcomes : OutcomeDto.defaults;
    final outcome = outcomes.firstWhere((o) => o.outcome == _outcome, orElse: () => outcomes.first);
    final requirements = FinishRequirements.of(activity, options?.catalogFor(activity.activityTypeId), outcome);
    final missing = _submitted ? _missing(requirements) : const <String>[];
    final now = ref.watch(serverTickerProvider).value ?? ref.read(serverClockProvider).now();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const BackHeader(title: 'Finalizar actividad'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(kScreenPadding, 4, kScreenPadding, 16),
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.ink),
                        ),
                        if (activity.place.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(activity.place, style: TextStyle(fontSize: 13, color: c.inkMuted)),
                        ],
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: c.divider)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Expanded(
                                child: Text(
                                  '${Fmt.time(activity.startedAt)} → ${Fmt.time(now)}',
                                  style: TextStyle(fontSize: 14, color: c.inkStrong),
                                ),
                              ),
                              Text(
                                Fmt.duration(activity.worked(now)),
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: c.ink),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Semantics(
                    header: true,
                    child: Text(
                      'Resultado',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < outcomes.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        Expanded(
                          child: _OutcomeButton(
                            label: outcomes[i].label,
                            selected: outcomes[i].outcome == _outcome,
                            onTap: () => setState(() => _outcome = outcomes[i].outcome),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppTextArea(
                    controller: _observation,
                    label: 'Observación',
                    optional: !requirements.observation,
                    hint: 'Ej.: Equipo instalado y probado con el cliente.',
                    errorText: missing.contains('observación')
                        ? 'Escribe la observación: es obligatoria con este resultado.'
                        : null,
                    onChanged: (_) {
                      if (_submitted) setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      text: 'Evidencia',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.ink),
                      children: [
                        if (requirements.photo || requirements.signature)
                          TextSpan(
                            text:
                                ' · obligatoria: ${[if (requirements.photo) 'foto', if (requirements.signature) 'firma'].join(' y ')}',
                            style: TextStyle(fontWeight: FontWeight.w400, color: c.primaryDark),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _EvidenceButton(
                          icon: Icons.photo_camera_outlined,
                          label: _photos.isEmpty ? 'Tomar foto' : 'Otra foto (${_photos.length})',
                          error: missing.contains('foto'),
                          onTap: _takePhoto,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _EvidenceButton(
                          icon: _signature == null ? Icons.draw_outlined : Icons.check_circle_outline,
                          label: _signature == null ? 'Firma del cliente' : 'Firma tomada',
                          error: missing.contains('firma del cliente'),
                          onTap: _sign,
                        ),
                      ),
                    ],
                  ),
                  if (_photos.isNotEmpty || _signature != null) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 64,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          for (var i = 0; i < _photos.length; i++)
                            _Thumb(
                              image: Image.file(File(_photos[i].path), fit: BoxFit.cover, cacheWidth: 128),
                              label: 'Foto ${i + 1}',
                              onRemove: () => setState(() => _photos.removeAt(i)),
                            ),
                          if (_signature != null)
                            _Thumb(
                              image: Image.memory(_signature!, fit: BoxFit.contain),
                              label: 'Firma',
                              onRemove: () => setState(() => _signature = null),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  LocationLine(
                    busy: _locating,
                    ok: _location != null,
                    text: _locating
                        ? 'Obteniendo ubicación…'
                        : _location == null
                        ? 'Sin ubicación: el GPS no respondió. Puedes finalizar igual.'
                        : 'Ubicación capturada · precisión ${Fmt.meters(_location!.accuracy)} · ${Fmt.time(_location!.capturedAt)}',
                  ),
                  if (missing.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    InfoBanner(icon: Icons.error_outline, child: Text('Para finalizar falta: ${missing.join(', ')}.')),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kScreenPadding, 0, kScreenPadding, 16),
              child: PrimaryButton(
                label: 'Confirmar y finalizar',
                icon: Icons.check_rounded,
                loading: _busy,
                onPressed: () => _confirm(activity, outcome, requirements),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeButton extends StatelessWidget {
  const _OutcomeButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.pinkSoft : c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: selected ? c.primary : c.borderInput, width: selected ? 2 : 1),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? c.primaryDark : c.inkStrong,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EvidenceButton extends StatelessWidget {
  const _EvidenceButton({required this.icon, required this.label, required this.onTap, this.error = false});

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return DashedBorderBox(
      color: error ? c.primaryDark : c.iconSubtle,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: 84,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: c.inkStrong),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.inkStrong),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.image, required this.label, required this.onRemove});

  final Widget image;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 64,
              height: 64,
              color: c.surface,
              child: Semantics(label: label, image: true, child: image),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Semantics(
              button: true,
              label: 'Quitar $label',
              child: InkWell(
                onTap: onRemove,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: c.ink.withValues(alpha: 0.7), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
