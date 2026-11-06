import '../data/models/sync_models.dart';
import 'queued_file.dart';

/// Server side of the synchronization. Implemented over HTTP by `WorkdayApi`.
abstract interface class SyncApi {
  /// `POST /me/workday/sync`.
  Future<SyncBatchResultDto> sync(List<SyncEventDto> events);

  /// `POST /me/workday/locations`. Returns how many points the server stored.
  Future<int> sendLocations(List<LocationInputDto> samples);

  /// `POST /me/workday/activities/{id}/evidences` (multipart, idempotent by clientId).
  Future<void> uploadEvidence(QueuedFile file);
}

/// Kind of network available right now.
enum NetworkKind {
  none,
  wifi,
  mobile,

  /// Ethernet, VPN or anything else that is not metered mobile data.
  other;

  bool get isOnline => this != NetworkKind.none;

  /// Unmetered networks, where files are uploaded without asking.
  bool get isUnmetered => this == NetworkKind.wifi || this == NetworkKind.other;
}
