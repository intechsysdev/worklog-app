import '../../../core/format/formatters.dart';
import '../../sync/domain/queued_event.dart';
import '../../workday/data/models/timeline_dto.dart';
import '../../workday/domain/day_projection.dart';
import '../data/request_models.dart';

/// A recorded time the user can ask to correct.
class AdjustmentOption {
  const AdjustmentOption({required this.target, required this.label, this.activityRecordId, this.original});

  final AdjustmentTarget target;
  final String? activityRecordId;
  final String label;

  /// Time currently recorded.
  final DateTime? original;

  String get key => '${target.name}:${activityRecordId ?? ''}';
}

/// Data to open the adjustment form already filled (from Historial or a server rejection).
class AdjustmentPrefill {
  const AdjustmentPrefill({this.target, this.activityRecordId, this.proposed});

  final AdjustmentTarget? target;
  final String? activityRecordId;
  final DateTime? proposed;
}

/// Options of the adjustment form: start and end of the workday and of each activity.
///
/// The timeline of the API does not carry activity ids, so each activity entry is matched to
/// the `activity.start` event queued on this phone (same start, ±90 s) or to the current
/// activity. Activities registered from another device cannot be matched and are left out.
List<AdjustmentOption> adjustmentOptions({
  required WorkdayView? workday,
  required List<TimelineEntryDto> entries,
  required List<QueuedEvent> startedActivities,
}) {
  if (workday == null) return const [];
  final options = <AdjustmentOption>[
    AdjustmentOption(target: AdjustmentTarget.workdayStart, label: 'Inicio de jornada', original: workday.startedAt),
    if (workday.endedAt != null)
      AdjustmentOption(target: AdjustmentTarget.workdayEnd, label: 'Fin de jornada', original: workday.endedAt),
  ];

  String? idFor(TimelineEntryDto entry) {
    if (entry.running && workday.current != null) return workday.current!.id;
    for (final e in startedActivities) {
      final id = e.event.activityId;
      if (id != null && e.event.occurredAt.toUtc().difference(entry.start.toUtc()).inSeconds.abs() <= 90) return id;
    }
    final current = workday.current;
    if (current != null && current.startedAt.toUtc().difference(entry.start.toUtc()).inSeconds.abs() <= 90) {
      return current.id;
    }
    return null;
  }

  final activities = entries.where((e) => e.kind == 'activity').toList()..sort((a, b) => a.start.compareTo(b.start));
  final seen = <String>{};
  for (final entry in activities) {
    final id = idFor(entry);
    if (id == null || !seen.add(id)) continue;
    options.add(
      AdjustmentOption(
        target: AdjustmentTarget.activityStart,
        activityRecordId: id,
        label: 'Inicio · ${entry.title}',
        original: entry.start,
      ),
    );
    if (entry.end != null && !entry.running) {
      options.add(
        AdjustmentOption(
          target: AdjustmentTarget.activityEnd,
          activityRecordId: id,
          label: 'Fin · ${entry.title}',
          original: entry.end,
        ),
      );
    }
  }

  // The current activity, when the timeline is not available (offline).
  final current = workday.current;
  if (current != null && !seen.contains(current.id) && !current.optimistic) {
    options.add(
      AdjustmentOption(
        target: AdjustmentTarget.activityStart,
        activityRecordId: current.id,
        label: 'Inicio · ${current.name}',
        original: current.startedAt,
      ),
    );
  }
  return options;
}

/// Meta line of an option: `Registrado a las 07:03`.
String recordedLabel(AdjustmentOption option) =>
    option.original == null ? 'Sin hora registrada' : 'Registrado a las ${Fmt.time(option.original!)}';
