import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/sync/domain/sync_ports.dart';

NetworkKind networkKindOf(List<ConnectivityResult> results) {
  if (results.contains(ConnectivityResult.wifi)) return NetworkKind.wifi;
  if (results.contains(ConnectivityResult.ethernet) || results.contains(ConnectivityResult.vpn)) {
    return NetworkKind.other;
  }
  if (results.contains(ConnectivityResult.mobile)) return NetworkKind.mobile;
  if (results.contains(ConnectivityResult.other)) return NetworkKind.other;
  return NetworkKind.none;
}

/// Network as reported by the OS. "Online" here means a network interface is up; whether the
/// server answers is learned when the sync runs.
abstract interface class ConnectivityService {
  Future<NetworkKind> current();
  Stream<NetworkKind> changes();
}

class PlusConnectivityService implements ConnectivityService {
  final _connectivity = Connectivity();

  @override
  Future<NetworkKind> current() async {
    try {
      return networkKindOf(await _connectivity.checkConnectivity());
    } on Exception {
      return NetworkKind.none;
    }
  }

  @override
  Stream<NetworkKind> changes() => _connectivity.onConnectivityChanged.map(networkKindOf).distinct();
}

final connectivityServiceProvider = Provider<ConnectivityService>((ref) => PlusConnectivityService());

final networkProvider = StreamProvider<NetworkKind>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield await service.current();
  yield* service.changes();
});
