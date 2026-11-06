import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/formatters.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common.dart';
import '../../../core/widgets/form_fields.dart';
import '../../../core/widgets/selectable.dart';
import '../../sync/data/sync_providers.dart';
import '../../sync/domain/queued_event.dart';
import '../../workday/presentation/workday_providers.dart';
import '../data/request_models.dart';
import '../data/requests_api.dart';
import '../domain/adjustment_options.dart';
import '../domain/request_forms.dart';
import 'request_form_scaffold.dart';

final _startedActivitiesProvider = FutureProvider.autoDispose<List<QueuedEvent>>(
  (ref) => ref.watch(eventQueueStoreProvider).startedActivities(),
);

/// "Ajuste de registro": pick the recorded time to correct (from the timeline of the day) and
/// propose the right one.
class AdjustmentFormScreen extends ConsumerStatefulWidget {
  const AdjustmentFormScreen({super.key, this.prefill});

  final AdjustmentPrefill? prefill;

  @override
  ConsumerState<AdjustmentFormScreen> createState() => _AdjustmentFormScreenState();
}

class _AdjustmentFormScreenState extends ConsumerState<AdjustmentFormScreen> {
  final _reason = TextEditingController();
  String? _optionKey;
  HourMinute? _proposed;
  FormErrors _errors = const {};

  @override
  void initState() {
    super.initState();
    final p = widget.prefill;
    if (p?.target != null) _optionKey = '${p!.target!.name}:${p.activityRecordId ?? ''}';
    if (p?.proposed != null) _proposed = HourMinute.fromDateTime(p!.proposed!.toLocal());
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.wl;
    final day = ref.watch(dayViewProvider).value;
    final timeline = ref.watch(timelineProvider).value;
    final started = ref.watch(_startedActivitiesProvider).value ?? const [];
    final workday = day?.workday;
    final options = adjustmentOptions(
      workday: workday,
      entries: timeline?.entries ?? const [],
      startedActivities: started,
    );
    final selected = options.where((o) => o.key == _optionKey).firstOrNull;
    final date = Fmt.dateOnly(timeline?.workday?.date ?? day?.today.date) ?? DateTime.now();

    AdjustmentForm form() => AdjustmentForm(
      workdayId: workday == null || workday.optimistic ? null : workday.id,
      date: date,
      target: selected?.target,
      activityRecordId: selected?.activityRecordId,
      proposed: _proposed,
      original: selected?.original,
      reason: _reason.text,
    );

    return RequestFormScaffold(
      title: 'Ajuste de registro',
      intro: 'Elige la hora que quedó mal y escribe la correcta. Tu supervisor revisa el ajuste antes de aplicarlo.',
      onSubmit: () async {
        final f = form();
        final errors = f.validate();
        setState(() => _errors = errors);
        if (errors.isNotEmpty) return null;
        return ref
            .read(requestsApiProvider)
            .submitAdjustment(
              workdayId: f.workdayId!,
              target: f.target!,
              activityRecordId: f.activityRecordId,
              proposedValue: f.proposedValue,
              reason: _reason.text.trim(),
            );
      },
      children: [
        if (_errors['workday'] != null || workday == null || workday.optimistic)
          const InfoBanner(
            child: Text(
              'No hay una jornada de hoy confirmada por el servidor. Sincroniza primero o pide el ajuste a tu supervisor.',
            ),
          )
        else ...[
          const FieldLabel('¿Qué quieres corregir?'),
          const SizedBox(height: 8),
          for (final o in options) ...[
            SelectableCard(
              title: o.label,
              meta: recordedLabel(o),
              selected: o.key == _optionKey,
              selectedBackground: true,
              onTap: () => setState(() => _optionKey = o.key),
            ),
            const SizedBox(height: 8),
          ],
          if (_errors['target'] != null || _errors['activity'] != null)
            Text(_errors['target'] ?? _errors['activity']!, style: TextStyle(fontSize: 13, color: c.primaryDark)),
          const SizedBox(height: 8),
          PickerField(
            label: 'Hora correcta',
            value: _proposed?.label,
            placeholder: 'HH:mm',
            errorText: _errors['proposed'],
            onTap: () async {
              final picked = await pickTime(
                context,
                _proposed ??
                    (selected?.original == null ? null : HourMinute.fromDateTime(selected!.original!.toLocal())),
              );
              if (picked != null) setState(() => _proposed = picked);
            },
          ),
        ],
        const SizedBox(height: 16),
        AppTextArea(
          controller: _reason,
          label: 'Motivo',
          optional: false,
          hint: 'Ej.: Olvidé finalizar al salir del sitio.',
          errorText: _errors['reason'],
        ),
      ],
    );
  }
}

/// Builds the prefill of a server rejection (Pendiente de sincronizar).
AdjustmentPrefill prefillForRejected(QueuedEvent event) {
  final kind = event.event.kind;
  final target = switch (kind) {
    'workday.start' => AdjustmentTarget.workdayStart,
    'workday.close' => AdjustmentTarget.workdayEnd,
    'activity.start' => AdjustmentTarget.activityStart,
    'activity.finish' => AdjustmentTarget.activityEnd,
    _ => null,
  };
  return AdjustmentPrefill(
    target: target,
    activityRecordId: target != null && target.isActivity ? event.event.activityId : null,
    proposed: event.event.occurredAt,
  );
}
