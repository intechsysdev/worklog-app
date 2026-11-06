import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/clock/server_clock.dart';
import '../../../core/format/formatters.dart';
import '../../../core/network/api_exception.dart';
import '../../sync/data/sync_providers.dart';
import '../../sync/presentation/sync_controller.dart';
import '../data/models/activity_options_dto.dart';
import '../data/models/timeline_dto.dart';
import '../data/models/today_dto.dart';
import '../domain/day_projection.dart';

/// Last server state of the day: the cache first (works offline), then `/me/today`.
class TodayController extends AsyncNotifier<TodayDto> {
  @override
  Future<TodayDto> build() async {
    final repository = ref.watch(todayRepositoryProvider);
    final subscription = repository.updates.listen((today) => state = AsyncData(today));
    ref.onDispose(subscription.cancel);

    final cached = await repository.cached();
    if (cached != null) {
      unawaited(refresh());
      return cached;
    }
    return repository.fetch();
  }

  /// Asks the server again. Without connection the cached state stays.
  Future<void> refresh() async {
    try {
      await ref.read(todayRepositoryProvider).fetch();
    } on ApiException catch (e) {
      if (!e.isTransient && state.value == null && ref.mounted) state = AsyncError(e, StackTrace.current);
    }
  }
}

final todayControllerProvider = AsyncNotifierProvider<TodayController, TodayDto>(TodayController.new);

/// The day as shown: server snapshot plus the pending queue (optimistic UI).
final dayViewProvider = Provider<AsyncValue<DayView>>((ref) {
  final today = ref.watch(todayControllerProvider);
  final pending = ref.watch(syncControllerProvider.select((s) => s.pendingEvents));
  final clock = ref.watch(serverClockProvider);
  return today.whenData((t) {
    final localDate = Fmt.isoDate(clock.now().toLocal());
    final stale = t.date != localDate && localDate.compareTo(t.date) > 0;
    return DayProjection.build(stale ? t.carriedTo(localDate) : t, pending, stale: stale);
  });
});

/// Assigned work orders, catalog and outcomes. Cached for offline use.
class ActivityOptionsController extends AsyncNotifier<ActivityOptionsDto> {
  @override
  Future<ActivityOptionsDto> build() async {
    final repository = ref.watch(todayRepositoryProvider);
    final cached = await repository.cachedOptions();
    if (cached != null) {
      unawaited(refresh());
      return cached;
    }
    return repository.fetchOptions();
  }

  Future<void> refresh() async {
    try {
      final options = await ref.read(todayRepositoryProvider).fetchOptions();
      if (ref.mounted) state = AsyncData(options);
    } on ApiException {
      // Keep the cached catalog.
    }
  }
}

final activityOptionsProvider = AsyncNotifierProvider<ActivityOptionsController, ActivityOptionsDto>(
  ActivityOptionsController.new,
);

/// Timeline of today. Falls back to the cached copy without connection.
final timelineProvider = FutureProvider.autoDispose<TimelineDto?>((ref) async {
  final today = ref.watch(todayControllerProvider).value;
  final date = today?.date ?? Fmt.isoDate(ref.read(serverClockProvider).now().toLocal());
  final repository = ref.watch(todayRepositoryProvider);
  try {
    return await repository.fetchTimeline(date);
  } on ApiException catch (e) {
    if (!e.isTransient) rethrow;
    return repository.cachedTimeline(date);
  }
});
