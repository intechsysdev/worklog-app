import '../../sync/data/models/sync_models.dart';
import '../../sync/domain/queued_event.dart';
import '../data/models/enums.dart';
import '../data/models/today_dto.dart';

/// What the home tab shows.
enum HomeMode {
  /// Workday not started on a day with shift: "Inicio de jornada".
  start,

  /// Day without shift (absence, holiday, rest, unscheduled): "Sin turno hoy".
  noShift,

  /// Workday open: "Actividad en curso".
  active,

  /// Workday already closed today.
  closed,
}

/// Current activity as the UI needs it: the stopwatch runs from [runningSince].
class ActivityView {
  const ActivityView({
    required this.id,
    required this.activityTypeId,
    required this.name,
    required this.color,
    required this.startedAt,
    required this.paused,
    required this.baseWorkedSeconds,
    required this.requirements,
    this.timeClass,
    this.workOrderNumber,
    this.siteName,
    this.runningSince,
    this.pausedSince,
    this.geofence = GeofenceStatus.notApplicable,
    this.accuracy,
    this.optimistic = false,
  });

  /// From the server snapshot, taken at [serverTime].
  factory ActivityView.fromDto(CurrentActivityDto dto, DateTime serverTime) {
    final paused = dto.status == ActivityStatus.paused;
    return ActivityView(
      id: dto.id,
      activityTypeId: dto.activityTypeId,
      name: dto.name,
      color: dto.color,
      timeClass: dto.timeClass,
      workOrderNumber: dto.workOrderNumber,
      siteName: dto.siteName,
      startedAt: dto.startedAt,
      paused: paused,
      baseWorkedSeconds: dto.workedSeconds,
      runningSince: paused ? null : serverTime,
      pausedSince: dto.pausedSince,
      geofence: dto.startGeofence,
      accuracy: dto.startAccuracy,
      requirements: dto.requirements,
    );
  }

  final String id;
  final String activityTypeId;
  final String name;
  final String color;
  final TimeClass? timeClass;
  final String? workOrderNumber;
  final String? siteName;
  final DateTime startedAt;
  final bool paused;

  /// Worked seconds accumulated up to [runningSince] (or up to the pause).
  final int baseWorkedSeconds;
  final DateTime? runningSince;
  final DateTime? pausedSince;
  final GeofenceStatus geofence;
  final double? accuracy;
  final RequirementsDto requirements;

  /// Started on the phone and not yet confirmed by the server.
  final bool optimistic;

  /// `Almacén Norte · OT-1042`.
  String get place => [siteName, workOrderNumber].whereType<String>().join(' · ');

  Duration worked(DateTime now) {
    var seconds = baseWorkedSeconds;
    final since = runningSince;
    if (!paused && since != null && now.isAfter(since)) seconds += now.difference(since).inSeconds;
    return Duration(seconds: seconds);
  }

  ActivityView pause(DateTime at) =>
      _copy(paused: true, baseWorkedSeconds: worked(at).inSeconds, runningSince: null, pausedSince: at);

  ActivityView resume(DateTime at) => _copy(paused: false, runningSince: at, pausedSince: null);

  ActivityView _copy({
    required bool paused,
    int? baseWorkedSeconds,
    required DateTime? runningSince,
    required DateTime? pausedSince,
  }) => ActivityView(
    id: id,
    activityTypeId: activityTypeId,
    name: name,
    color: color,
    timeClass: timeClass,
    workOrderNumber: workOrderNumber,
    siteName: siteName,
    startedAt: startedAt,
    paused: paused,
    baseWorkedSeconds: baseWorkedSeconds ?? this.baseWorkedSeconds,
    runningSince: runningSince,
    pausedSince: pausedSince,
    geofence: geofence,
    accuracy: accuracy,
    requirements: requirements,
    optimistic: true,
  );
}

class WorkdayView {
  const WorkdayView({
    required this.id,
    required this.status,
    required this.startedAt,
    required this.summary,
    this.endedAt,
    this.startSiteName,
    this.startGeofence = GeofenceStatus.notApplicable,
    this.startAdjusted = false,
    this.current,
    this.optimistic = false,
  });

  final String id;
  final WorkdayStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String? startSiteName;
  final GeofenceStatus startGeofence;
  final bool startAdjusted;
  final DaySummaryDto summary;
  final ActivityView? current;
  final bool optimistic;

  bool get isOpen => status == WorkdayStatus.open;

  WorkdayView copyWith({
    WorkdayStatus? status,
    DateTime? endedAt,
    DaySummaryDto? summary,
    ActivityView? current,
    bool clearCurrent = false,
  }) => WorkdayView(
    id: id,
    status: status ?? this.status,
    startedAt: startedAt,
    endedAt: endedAt ?? this.endedAt,
    startSiteName: startSiteName,
    startGeofence: startGeofence,
    startAdjusted: startAdjusted,
    summary: summary ?? this.summary,
    current: clearCurrent ? null : (current ?? this.current),
    optimistic: true,
  );
}

/// The day as the phone believes it is: last server state plus the actions still in the queue.
class DayView {
  const DayView({required this.today, required this.workday, required this.pendingCount, this.stale = false});

  /// Last `today` received from the server (possibly cached).
  final TodayDto today;
  final WorkdayView? workday;
  final int pendingCount;

  /// The cached snapshot is from a previous day and the server could not be reached.
  final bool stale;

  HomeMode get mode {
    final w = workday;
    if (w != null) return w.isOpen ? HomeMode.active : HomeMode.closed;
    return today.plan.kind.isWorkingDay ? HomeMode.start : HomeMode.noShift;
  }

  ActivityView? get current => workday?.current;
}

/// Applies the pending queue on top of the server snapshot (optimistic UI). When the server
/// answers, its `today` becomes the new base and the confirmed events leave the queue, so the
/// projection converges to the server state.
abstract final class DayProjection {
  static DayView build(TodayDto today, List<QueuedEvent> queue, {bool stale = false}) {
    var workday = today.workday == null ? null : _fromDto(today.workday!, today.serverTime);
    final pending = queue.where((e) => e.isPending).toList()..sort((a, b) => a.seq.compareTo(b.seq));

    for (final queued in pending) {
      workday = apply(workday, queued, today);
    }
    return DayView(today: today, workday: workday, pendingCount: pending.length, stale: stale);
  }

  static WorkdayView? apply(WorkdayView? workday, QueuedEvent queued, TodayDto today) {
    final e = queued.event;
    final at = e.occurredAt.toUtc();
    switch (e.kind) {
      case SyncEventKind.workdayStart:
        if (workday != null) return workday;
        return WorkdayView(
          id: e.workdayId ?? queued.clientEventId,
          status: WorkdayStatus.open,
          startedAt: at,
          startSiteName: today.branchName,
          startGeofence: e.location == null ? GeofenceStatus.noLocation : GeofenceStatus.unknown,
          summary: const DaySummaryDto(),
          optimistic: true,
        );

      case SyncEventKind.activityStart:
        if (workday == null || !workday.isOpen) return workday;
        final meta = queued.meta;
        final activity = ActivityView(
          id: e.activityId ?? queued.clientEventId,
          activityTypeId: e.activityTypeId ?? '',
          name: meta.activityName ?? 'Actividad',
          color: meta.activityColor ?? '#AF1839',
          timeClass: _timeClass(meta.timeClass),
          workOrderNumber: meta.workOrderNumber,
          siteName: meta.siteName,
          startedAt: at,
          paused: false,
          baseWorkedSeconds: 0,
          runningSince: at,
          geofence: e.location == null ? GeofenceStatus.noLocation : GeofenceStatus.unknown,
          accuracy: e.location?.accuracy,
          requirements: RequirementsDto(
            photo: meta.requiresPhoto,
            signature: meta.requiresSignature,
            observationAlways: meta.observationAlways,
          ),
          optimistic: true,
        );
        return workday.copyWith(
          current: activity,
          summary: workday.summary.copyWith(activityCount: workday.summary.activityCount + 1),
        );

      case SyncEventKind.activityPause:
        final current = workday?.current;
        if (current == null || current.id != e.activityId || current.paused) return workday;
        return workday!.copyWith(current: current.pause(at));

      case SyncEventKind.activityResume:
        final current = workday?.current;
        if (current == null || current.id != e.activityId || !current.paused) return workday;
        return workday!.copyWith(current: current.resume(at));

      case SyncEventKind.activityFinish:
        final current = workday?.current;
        if (current == null || current.id != e.activityId) return workday;
        return workday!.copyWith(clearCurrent: true);

      case SyncEventKind.workdayClose:
        if (workday == null || !workday.isOpen) return workday;
        return workday.copyWith(status: WorkdayStatus.closed, endedAt: at, clearCurrent: true);
    }
    return workday;
  }

  static WorkdayView _fromDto(WorkdayDto dto, DateTime serverTime) => WorkdayView(
    id: dto.id,
    status: dto.status,
    startedAt: dto.startedAt,
    endedAt: dto.endedAt,
    startSiteName: dto.startSiteName,
    startGeofence: dto.startGeofence,
    startAdjusted: dto.startAdjusted,
    summary: dto.summary,
    current: dto.current == null ? null : ActivityView.fromDto(dto.current!, serverTime),
  );

  static TimeClass? _timeClass(String? wire) => switch (wire) {
    'Productive' => TimeClass.productive,
    'PaidNonProductive' => TimeClass.paidNonProductive,
    'Unproductive' => TimeClass.unproductive,
    _ => null,
  };
}
