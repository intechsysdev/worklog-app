import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Device clock corrected with the delta to the server, measured on each `/me/today`.
///
/// The app shows (and stamps events with) the server time, so a phone with a wrong clock does not
/// register the workday at a wrong hour. The delta survives restarts through [offset] persisted
/// by the caller, so it keeps working without connection.
class ServerClock {
  ServerClock({DateTime Function()? deviceNow, this.offset = Duration.zero}) : _deviceNow = deviceNow ?? DateTime.now;

  final DateTime Function() _deviceNow;

  /// Server time minus device time.
  Duration offset;

  /// Current server time, in UTC.
  DateTime now() => _deviceNow().toUtc().add(offset);

  /// Updates the delta with a server timestamp received just now.
  void sync(DateTime serverTime, {DateTime? receivedAt}) {
    final device = (receivedAt ?? _deviceNow()).toUtc();
    offset = serverTime.toUtc().difference(device);
  }
}

final serverClockProvider = Provider<ServerClock>((ref) => ServerClock());

/// Ticks every second with the server time, for clocks and stopwatches.
final serverTickerProvider = StreamProvider.autoDispose<DateTime>((ref) {
  final clock = ref.watch(serverClockProvider);
  return Stream<DateTime>.periodic(const Duration(seconds: 1), (_) => clock.now());
});
