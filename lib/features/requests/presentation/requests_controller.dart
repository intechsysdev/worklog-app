import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/request_models.dart';
import '../data/requests_api.dart';

/// "Mis solicitudes": every request of the user (online).
class RequestsController extends AsyncNotifier<List<RequestDto>> {
  @override
  Future<List<RequestDto>> build() => ref.watch(requestsApiProvider).list();

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(requestsApiProvider).list());
  }

  bool get hasPending => state.value?.any((r) => r.status == RequestStatus.pending) ?? false;

  /// Asks the server again and returns the requests that were pending and are now resolved (the
  /// supervisor approved or rejected them from the panel). Without connection nothing changes.
  Future<List<RequestDto>> refreshResolved() async {
    final pending = {
      for (final r in state.value ?? const <RequestDto>[])
        if (r.status == RequestStatus.pending) r.id,
    };
    try {
      final list = await ref.read(requestsApiProvider).list();
      if (!ref.mounted) return const [];
      state = AsyncData(list);
      return list.where((r) => pending.contains(r.id) && r.status.isResolved).toList();
    } on ApiException {
      return const [];
    }
  }

  Future<void> cancel(String id) async {
    final updated = await ref.read(requestsApiProvider).cancel(id);
    final current = state.value ?? const [];
    state = AsyncData([for (final r in current) r.id == id ? updated : r]);
  }

  /// A request just sent: shown at the top without waiting for a reload.
  void added(RequestDto request) {
    final current = state.value;
    if (current != null) state = AsyncData([request, ...current.where((r) => r.id != request.id)]);
  }
}

final requestsControllerProvider = AsyncNotifierProvider<RequestsController, List<RequestDto>>(RequestsController.new);

/// Tabs of "Mis solicitudes".
enum RequestsTab { all, pending, resolved }

List<RequestDto> filterRequests(List<RequestDto> all, RequestsTab tab) => switch (tab) {
  RequestsTab.all => all,
  RequestsTab.pending => all.where((r) => r.status == RequestStatus.pending).toList(),
  RequestsTab.resolved => all.where((r) => r.status.isResolved).toList(),
};
