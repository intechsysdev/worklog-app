import '../data/models/sync_models.dart';

/// State of an event in the local queue.
enum QueueStatus {
  /// Saved on the phone, not yet confirmed by the server.
  pending,

  /// Applied by the server as sent.
  accepted,

  /// Applied by the server with a correction (for example, start moved to the window opening).
  adjusted,

  /// Rejected by the server. It is not sent again.
  rejected;

  static QueueStatus parse(String value) =>
      QueueStatus.values.firstWhere((s) => s.name == value, orElse: () => pending);
}

/// Display data saved with each event, so the UI can show the activity and build the optimistic
/// state without the server.
class EventMeta {
  const EventMeta({
    this.activityName,
    this.activityColor,
    this.timeClass,
    this.workOrderNumber,
    this.siteName,
    this.requiresPhoto = false,
    this.requiresSignature = false,
    this.observationAlways = false,
    this.outcomeLabel,
  });

  factory EventMeta.fromJson(Map<String, dynamic> json) => EventMeta(
    activityName: json['activityName'] as String?,
    activityColor: json['activityColor'] as String?,
    timeClass: json['timeClass'] as String?,
    workOrderNumber: json['workOrderNumber'] as String?,
    siteName: json['siteName'] as String?,
    requiresPhoto: json['requiresPhoto'] as bool? ?? false,
    requiresSignature: json['requiresSignature'] as bool? ?? false,
    observationAlways: json['observationAlways'] as bool? ?? false,
    outcomeLabel: json['outcomeLabel'] as String?,
  );

  final String? activityName;
  final String? activityColor;

  /// Wire value of the category time class (`Productive`…).
  final String? timeClass;
  final String? workOrderNumber;
  final String? siteName;
  final bool requiresPhoto;
  final bool requiresSignature;
  final bool observationAlways;
  final String? outcomeLabel;

  Map<String, dynamic> toJson() => {
    'activityName': ?activityName,
    'activityColor': ?activityColor,
    'timeClass': ?timeClass,
    'workOrderNumber': ?workOrderNumber,
    'siteName': ?siteName,
    if (requiresPhoto) 'requiresPhoto': true,
    if (requiresSignature) 'requiresSignature': true,
    if (observationAlways) 'observationAlways': true,
    'outcomeLabel': ?outcomeLabel,
  };
}

class QueuedEvent {
  const QueuedEvent({
    required this.seq,
    required this.event,
    required this.meta,
    required this.status,
    required this.createdAt,
    this.code,
    this.message,
    this.resultId,
    this.attempts = 0,
    this.syncedAt,
  });

  /// Local order: the order in which the user did things.
  final int seq;
  final SyncEventDto event;
  final EventMeta meta;
  final QueueStatus status;
  final String? code;
  final String? message;
  final String? resultId;
  final int attempts;
  final DateTime createdAt;
  final DateTime? syncedAt;

  String get clientEventId => event.clientEventId;
  bool get isPending => status == QueueStatus.pending;

  /// Spanish title for the queue list.
  String get title => switch (event.kind) {
    SyncEventKind.workdayStart => 'Inicio de jornada',
    SyncEventKind.workdayClose => 'Cierre de jornada',
    SyncEventKind.activityStart => 'Iniciar actividad',
    SyncEventKind.activityPause => 'Pausa',
    SyncEventKind.activityResume => 'Reanudar',
    SyncEventKind.activityFinish => 'Finalizar actividad',
    _ => event.kind,
  };

  /// Second line: activity and work order, or outcome and accuracy.
  String get subtitle {
    final accuracy = event.location == null ? null : 'ubicación ${event.location!.accuracy.round()} m';
    final activity = [meta.activityName, meta.workOrderNumber].whereType<String>().join(' · ');
    switch (event.kind) {
      case SyncEventKind.activityFinish:
        return [meta.outcomeLabel, accuracy].whereType<String>().join(' · ');
      case SyncEventKind.workdayStart:
      case SyncEventKind.workdayClose:
        return accuracy ?? 'Sin ubicación';
      default:
        return activity.isEmpty ? (accuracy ?? '') : activity;
    }
  }
}
