import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/clock/server_clock.dart';
import '../features/alerts/data/alert_notifier.dart';
import '../features/alerts/domain/alert_schedule.dart';
import '../features/alerts/presentation/shift_end_notice.dart';
import '../features/sync/data/sync_providers.dart';
import '../features/sync/presentation/sync_controller.dart';
import '../features/tracking/data/service_location_tracker.dart';
import '../features/tracking/domain/location_tracker.dart';
import '../features/tracking/domain/tracker_status.dart';
import '../features/workday/domain/day_projection.dart';
import '../features/workday/presentation/workday_providers.dart';

/// Lives while the user is inside the app (after the onboarding):
/// - runs the location tracker (foreground service on Android) while the workday is open and
///   keeps its notification in step with the current activity;
/// - reschedules the local alerts (inactivity, pause, shift end) with every new state;
/// - shows the shift end notice when a warning is reached with the app open;
/// - on resume, refreshes `today` and retries the queue.
class WorkSessionScope extends ConsumerStatefulWidget {
  const WorkSessionScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WorkSessionScope> createState() => _WorkSessionScopeState();
}

class _WorkSessionScopeState extends ConsumerState<WorkSessionScope> {
  late final AppLifecycleListener _lifecycle;
  late final LocationTracker _tracker;
  late final AlertNotifier _alerts;
  StreamSubscription<TrackerEvent>? _trackerEvents;
  Timer? _noticeTimer;
  String? _lastStatus;
  String? _lastAlerts;

  /// When the user was left without an open activity (for the inactivity alert).
  DateTime? _idleSince;
  String? _previousActivity;

  /// Warnings already shown, per workday: `workdayId:minutes`.
  final Set<String> _shown = {};
  bool _noticeOpen = false;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    _tracker = ref.read(locationTrackerProvider);
    _alerts = ref.read(alertNotifierProvider);
    _trackerEvents = _tracker.events.listen(_onTrackerEvent);
    ref.listenManual(dayViewProvider, (_, next) => _onDay(next.value), fireImmediately: true);
    _noticeTimer = Timer.periodic(const Duration(seconds: 20), (_) => _checkNotice());
    // First pass of the queue left from a previous session.
    Future.microtask(() => ref.read(syncControllerProvider.notifier).run());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _noticeTimer?.cancel();
    _trackerEvents?.cancel();
    unawaited(_tracker.stop());
    unawaited(_alerts.cancelAll());
    super.dispose();
  }

  void _onResume() {
    unawaited(ref.read(todayControllerProvider.notifier).refresh());
    unawaited(ref.read(syncControllerProvider.notifier).run());
    _checkNotice();
  }

  void _onTrackerEvent(TrackerEvent event) {
    if (!mounted) return;
    switch (event.type) {
      case TrackerEventType.samplesStored:
        unawaited(ref.read(syncServiceProvider).syncLocations().catchError((_) => 0));
      case TrackerEventType.eventQueued:
        final sync = ref.read(syncControllerProvider.notifier);
        unawaited(sync.reload().then((_) => sync.run()));
      case TrackerEventType.openRoute:
        if (event.route != null) GoRouter.of(context).push(event.route!);
    }
  }

  void _onDay(DayView? day) {
    if (day == null) return;
    final open = day.mode == HomeMode.active;

    // Tracker and its notification.
    if (!open) {
      _lastStatus = null;
      if (_tracker.isRunning) unawaited(_tracker.stop());
    } else {
      final status = TrackerStatus.fromDay(day);
      final encoded = status.encode();
      if (encoded != _lastStatus || !_tracker.isRunning) {
        final first = _lastStatus == null;
        _lastStatus = encoded;
        unawaited(first ? _tracker.start(status) : _tracker.update(status));
      }
    }

    // Inactivity is counted from the moment the activity disappeared.
    final currentId = day.current?.id;
    if (currentId == null && (_previousActivity != null || _idleSince == null)) {
      _idleSince = _previousActivity != null || (day.workday?.summary.activityCount ?? 0) > 0
          ? ref.read(serverClockProvider).now()
          : day.workday?.startedAt;
    }
    if (currentId != null) _idleSince = null;
    _previousActivity = currentId;

    final alerts = AlertPlanner.plan(day: day, now: ref.read(serverClockProvider).now(), idleSince: _idleSince);
    final key = alerts.map((a) => '${a.id}@${a.at.toIso8601String()}').join(',');
    if (key != _lastAlerts) {
      _lastAlerts = key;
      unawaited(alerts.isEmpty ? _alerts.cancelAll() : _alerts.reschedule(alerts));
    }
    _checkNotice();
  }

  /// Shows the shift end notice once per warning while the app is in front.
  void _checkNotice() {
    if (!mounted || _noticeOpen) return;
    final day = ref.read(dayViewProvider).value;
    if (day == null) return;
    final minutes = AlertPlanner.dueShiftWarning(day: day, now: ref.read(serverClockProvider).now());
    if (minutes == null || minutes == 0) return;
    final key = '${day.workday!.id}:$minutes';
    if (!_shown.add(key)) return;
    _noticeOpen = true;
    unawaited(ShiftEndNoticeSheet.show(context, minutes: minutes).whenComplete(() => _noticeOpen = false));
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
