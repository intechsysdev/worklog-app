import 'dart:async';

import '../../../core/clock/server_clock.dart';
import '../../../core/storage/kv_store.dart';
import 'models/activity_options_dto.dart';
import 'models/timeline_dto.dart';
import 'models/today_dto.dart';
import 'workday_api.dart';

/// Server state of the day, cached on the phone so the app opens and works without connection.
class TodayRepository {
  TodayRepository({required this._api, required this._kv, required this._clock, DateTime Function()? deviceNow})
    : _deviceNow = deviceNow ?? DateTime.now;

  final WorkdayApi _api;
  final KvStore _kv;
  final ServerClock _clock;
  final DateTime Function() _deviceNow;
  final _updates = StreamController<TodayDto>.broadcast();

  /// Every new `today` (from `/me/today`, from a command or from the sync answer).
  Stream<TodayDto> get updates => _updates.stream;

  Future<TodayDto?> cached() async {
    final offset = await _kv.get(KvKeys.clockOffsetMs);
    if (offset != null) _clock.offset = Duration(milliseconds: int.tryParse(offset) ?? 0);
    final json = await _kv.getJson(KvKeys.today);
    if (json == null) return null;
    try {
      return TodayDto.fromJson(json);
    } on Object {
      return null;
    }
  }

  Future<TodayDto> fetch() async {
    final sentAt = _deviceNow();
    final today = await _api.today();
    final receivedAt = _deviceNow();
    // Midpoint of the round trip: the server stamped the answer somewhere in between.
    final midpoint = sentAt.add(receivedAt.difference(sentAt) ~/ 2);
    await save(today, receivedAt: midpoint);
    return today;
  }

  /// Stores a `today` and re-measures the delta with the server clock.
  Future<void> save(TodayDto today, {DateTime? receivedAt}) async {
    _clock.sync(today.serverTime, receivedAt: receivedAt ?? _deviceNow());
    await _kv.set(KvKeys.clockOffsetMs, _clock.offset.inMilliseconds.toString());
    await _kv.setJson(KvKeys.today, today.toJson());
    if (!_updates.isClosed) _updates.add(today);
  }

  Future<ActivityOptionsDto?> cachedOptions() async {
    final json = await _kv.getJson(KvKeys.activityOptions);
    return json == null ? null : ActivityOptionsDto.fromJson(json);
  }

  Future<ActivityOptionsDto> fetchOptions() async {
    final options = await _api.activityOptions();
    await _kv.setJson(KvKeys.activityOptions, options.toJson());
    return options;
  }

  Future<TimelineDto?> cachedTimeline(String date) async {
    final json = await _kv.getJson('${KvKeys.timelinePrefix}$date');
    return json == null ? null : TimelineDto.fromJson(json);
  }

  Future<TimelineDto> fetchTimeline(String date) async {
    final timeline = await _api.timeline(date);
    await _kv.setJson('${KvKeys.timelinePrefix}$date', timeline.toJson());
    return timeline;
  }

  void dispose() => _updates.close();
}
