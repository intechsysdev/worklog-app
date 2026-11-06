import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/request_models.dart';
import '../data/requests_api.dart';

/// "Mis solicitudes": every request of the user (online).
class RequestsController extends AsyncNotifier<List<RequestDto>> {
  @override
  Future<List<RequestDto>> build() => ref.watch(requestsApiProvider).list();

  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(requestsApiProvider).list());
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
