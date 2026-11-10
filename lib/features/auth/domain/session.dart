import '../../../core/config/app_config.dart';

/// Signed-in user on this device: tokens of WorkLog or ONE (or the development token) and the company.
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
    this.mustChangePassword = false,
  });

  factory Session.development(String email) =>
      Session(mode: AuthMode.development, email: email, accessToken: 'dev:$email');

  factory Session.fromJson(Map<String, dynamic> json) => Session(
    mode: switch (json['mode']) {
      'one' => AuthMode.one,
      'worklog' => AuthMode.worklog,
      _ => AuthMode.development,
    },
    email: json['email'] as String,
    accessToken: json['accessToken'] as String,
    displayName: json['displayName'] as String?,
    refreshToken: json['refreshToken'] as String?,
    expiresAt: json['expiresAt'] == null ? null : DateTime.parse(json['expiresAt'] as String),
    tenantId: json['tenantId'] as String?,
    tenantName: json['tenantName'] as String?,
    mustChangePassword: json['mustChangePassword'] == true,
  );

  final AuthMode mode;
  final String email;
  final String accessToken;
  final String? displayName;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? tenantId;
  final String? tenantName;

  /// The password is temporary (given by an administrator): the app asks to change it first.
  final bool mustChangePassword;

  bool get hasTenant => tenantId != null;

  /// Whether the session renews its token (WorkLog and ONE; the development token never expires).
  bool get canRefresh => mode != AuthMode.development && refreshToken != null;

  /// Whether the access token expires within [margin].
  bool expiresSoon(DateTime now, {Duration margin = const Duration(seconds: 60)}) =>
      canRefresh && expiresAt != null && expiresAt!.isBefore(now.add(margin));

  Session copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? displayName,
    String? tenantId,
    String? tenantName,
    bool? mustChangePassword,
  }) => Session(
    mode: mode,
    email: email,
    accessToken: accessToken ?? this.accessToken,
    displayName: displayName ?? this.displayName,
    refreshToken: refreshToken ?? this.refreshToken,
    expiresAt: expiresAt ?? this.expiresAt,
    tenantId: tenantId ?? this.tenantId,
    tenantName: tenantName ?? this.tenantName,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
  );

  Map<String, dynamic> toJson() => {
    'mode': mode.name,
    'email': email,
    'accessToken': accessToken,
    'displayName': ?displayName,
    'refreshToken': ?refreshToken,
    'expiresAt': ?expiresAt?.toUtc().toIso8601String(),
    'tenantId': ?tenantId,
    'tenantName': ?tenantName,
    'mustChangePassword': mustChangePassword,
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

/// Session issued by the WorkLog API (`/mobile-auth/login`, `/mobile-auth/refresh`).
class WorklogTokens {
  const WorklogTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.mustChangePassword,
    required this.fullName,
    required this.email,
    required this.tenantId,
    required this.tenantName,
  });

  factory WorklogTokens.fromJson(Map<String, dynamic> json) {
    final user = Map<String, dynamic>.from(json['user'] as Map);
    return WorklogTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      mustChangePassword: json['mustChangePassword'] == true,
      fullName: user['fullName'] as String,
      email: user['email'] as String,
      tenantId: json['tenantId'] as String,
      tenantName: json['tenantName'] as String,
    );
  }

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final bool mustChangePassword;
  final String fullName;
  final String email;
  final String tenantId;
  final String tenantName;
}

/// A company where the same email and password work: the user picks one and signs in again.
class WorklogTenantOption {
  const WorklogTenantOption({required this.tenantId, required this.name});

  final String tenantId;
  final String name;
}

/// Result of the WorkLog login: the session, or the companies to choose from.
class WorklogLogin {
  const WorklogLogin({this.tokens, this.tenants = const []});

  final WorklogTokens? tokens;
  final List<WorklogTenantOption> tenants;
}
