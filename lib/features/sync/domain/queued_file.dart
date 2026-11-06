import '../../workday/data/models/enums.dart';

enum FileStatus {
  pending,
  uploaded,

  /// The server refused the file (size, type) or the activity never reached the server.
  failed;

  static FileStatus parse(String value) => FileStatus.values.firstWhere((s) => s.name == value, orElse: () => pending);
}

/// Photo or signature waiting to be uploaded (by default only on wifi).
class QueuedFile {
  const QueuedFile({
    required this.clientId,
    required this.activityId,
    required this.kind,
    required this.path,
    required this.contentType,
    required this.sizeBytes,
    required this.capturedAt,
    required this.label,
    required this.status,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  /// Idempotency key of the upload.
  final String clientId;
  final String activityId;
  final EvidenceKind kind;
  final String path;
  final String contentType;
  final int sizeBytes;
  final DateTime capturedAt;

  /// `Foto 1 de 2`, `Firma del cliente`.
  final String label;
  final FileStatus status;
  final int attempts;
  final String? lastError;
  final DateTime createdAt;
}
