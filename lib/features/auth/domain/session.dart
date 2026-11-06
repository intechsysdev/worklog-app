import '../../../core/config/app_config.dart';

/// Signed-in user on this device: tokens of ONE (or the development token) and the chosen company.
class Session {
  const Session({
    required this.mode,
    required this.email,
    required this.accessToken,
    this.displayName,
    this.refreshToken,
    this.expiresAt,
    this.tenantId,
    this.tenantName,
  });

  factory Session.development(String email) =>
      Session(mode: AuthMode.development, email: email, accessToken: 'dev:$email');

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    mode: json['mode'] == 'one' ? AuthMode.one : AuthMode.development,
    email: json['email'] as String,
    accessToken: json['accessToken'] as String,
    displayName: json['displayName'] as String?,
    refreshToken: json['refreshToken'] as String?,
    expiresAt: json['expiresAt'] == null ? null : DateTime.parse(json['expiresAt'] as String),
    tenantId: json['tenantId'] as String?,
    tenantName: json['tenantName'] as String?,
  );

  final AuthMode mode;
  final String email;
  final String accessToken;
  final String? displayName;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? tenantId;
  final String? tenantName;

  bool get hasTenant => tenantId != null;

  /// Whether the access token expires within [margin] (only for ONE tokens).
  bool expiresSoon(DateTime now, {Duration margin = const Duration(seconds: 60)}) =>
      mode == AuthMode.one && expiresAt != null && expiresAt!.isBefore(now.add(margin));

  Session copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? displayName,
    String? tenantId,
    String? tenantName,
  }) => Session(
    mode: mode,
    email: email,
    accessToken: accessToken ?? this.accessToken,
    displayName: displayName ?? this.displayName,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
    tenantId: tenantId ?? this.tenantId,
    tenantName: tenantName ?? this.tenantName,
  );

  Map<String, dynamic> toJson() => {
    'mode': mode == AuthMode.one ? 'one' : 'development',
    'email': email,
    'accessToken': accessToken,
    'displayName': ?displayName,
    'refreshToken': ?refreshToken,
    'expiresAt': ?expiresAt?.toUtc().toIso8601String(),
    'tenantId': ?tenantId,
    'tenantName': ?tenantName,
  };
}

/// Tokens returned by ONE (`/auth/login`, `/auth/refresh`, `/sso/token`).
class OneTokens {
  const OneTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.fullName,
    this.email,
    this.tenantId,
  });

  factory OneTokens.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? Map<String, dynamic>.from(json['user'] as Map) : const <String, dynamic>{};
    return OneTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      fullName: user['fullName'] as String?,
      email: user['email'] as String?,
      tenantId: json['tenantId'] as String?,
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String? fullName;
  final String? email;

  /// Company chosen in the ONE portal during the SSO.
  final String? tenantId;
}
