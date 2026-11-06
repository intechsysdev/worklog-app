import 'dart:async';

import '../../../core/location/location_service.dart';
import '../../sync/domain/queue_stores.dart';
import '../domain/location_tracker.dart';
import '../domain/tracker_status.dart';

/// Sampling with a timer while the app is in memory (iOS, desktop, tests).
class TimerLocationTracker implements LocationTracker {
  TimerLocationTracker(this._location, this._samples);

  final LocationService _location;
  final LocationSampleStore _samples;
  final _events = StreamController<TrackerEvent>.broadcast();
  Timer? _timer;
  int? _minutes;

  @override
  bool get isRunning => _timer != null;

  @override
  Stream<TrackerEvent> get events => _events.stream;

  @override
  Future<void> start(TrackerStatus status) async {
    if (_timer != null && _minutes == status.samplingMinutes) return;
    _timer?.cancel();
    _minutes = status.samplingMinutes;
    _timer = Timer.periodic(Duration(minutes: status.samplingMinutes), (_) async {
      final fix = await _location.current();
      if (fix == null) return;
      await _samples.add(fix.toInput());
      if (!_events.isClosed) _events.add(const TrackerEvent(TrackerEventType.samplesStored));
    });
  }

  @override
  Future<void> update(TrackerStatus status) => start(status);

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _minutes = null;
  }

  void dispose() {
    _timer?.cancel();
    _events.close();
  }
}
