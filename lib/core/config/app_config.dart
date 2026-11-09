import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How the user signs in.
enum AuthMode {
  /// Local API in Development mode: only an email is asked and the token is `dev:<email>`.
  development,

  /// INTECHSYS ONE: email and password (or SSO PKCE) against ONE.
  one,
}

/// Build-time configuration, passed with `--dart-define`.
///
/// Without defines the app targets production (WorkLog API and INTECHSYS ONE). For the local API:
///
/// ```
/// flutter run --dart-define=AUTH_MODE=development --dart-define=WORKLOG_API_URL=http://10.0.2.2:5290
/// ```
class AppConfig {
  const AppConfig({
    required this.authMode,
    required this.worklogApiUrl,
    required this.oneUrl,
    required this.onePortalUrl,
    required this.oneClientId,
    required this.ssoRedirectUri,
    required this.appVersion,
    this.isMock = false,
  });

  factory AppConfig.fromEnvironment() {
    const mode = String.fromEnvironment('AUTH_MODE', defaultValue: 'one');
    const api = String.fromEnvironment('WORKLOG_API_URL', defaultValue: _prodWorklogApi);
    const one = String.fromEnvironment('ONE_URL', defaultValue: _prodOneApi);
    const portal = String.fromEnvironment('ONE_PORTAL_URL', defaultValue: _prodOnePortal);
    const clientId = String.fromEnvironment('ONE_CLIENT_ID', defaultValue: 'worklog');
    const redirect = String.fromEnvironment('ONE_REDIRECT_URI', defaultValue: 'com.intechsys.worklog://sso/callback');
    const data = String.fromEnvironment('DATA_MODE');
    if (data.toLowerCase() == 'mock') {
      // Demo APK: everything is answered on the phone (MockHttpAdapter); any email and password.
      return const AppConfig(
        authMode: AuthMode.one,
        worklogApiUrl: 'https://demo.worklog.local',
        oneUrl: 'https://demo.one.local',
        onePortalUrl: 'https://demo.one.local',
        oneClientId: clientId,
        ssoRedirectUri: redirect,
        appVersion: '1.0.0',
        isMock: true,
      );
    }
    return AppConfig(
      authMode: mode.toLowerCase() == 'one' ? AuthMode.one : AuthMode.development,
      worklogApiUrl: _trimSlash(api),
      oneUrl: _trimSlash(one),
      onePortalUrl: _trimSlash(portal.isEmpty ? one : portal),
      oneClientId: clientId,
      ssoRedirectUri: redirect,
      appVersion: '1.0.0',
    );
  }

  final AuthMode authMode;

  /// Base URL of the WorkLog API (without `/api/v1`).
  final String worklogApiUrl;

  /// Base URL of the ONE API (login, refresh, SSO token).
  final String oneUrl;

  /// Base URL of the ONE portal, which hosts the `/autorizar` page of the SSO.
  final String onePortalUrl;

  /// App slug registered in ONE (`client_id` of the SSO).
  final String oneClientId;

  /// Redirect of the SSO. Must be registered in ONE for the `worklog` app.
  final String ssoRedirectUri;

  final String appVersion;

  /// `--dart-define=DATA_MODE=mock`: demo data on the phone, no server.
  final bool isMock;

  bool get isDevelopment => authMode == AuthMode.development;

  /// Custom scheme of [ssoRedirectUri], used to catch the redirect on the device.
  String get ssoCallbackScheme => Uri.parse(ssoRedirectUri).scheme;

  // Production: the same hosts as worklog-front/.env.production.
  static const _prodWorklogApi = 'https://app-worklog-api-prd-djdwfecheudhg9de.centralus-01.azurewebsites.net';
  static const _prodOneApi = 'https://app-intechsysone-api-prd-bxehhkf8dgcwbve9.centralus-01.azurewebsites.net';
  static const _prodOnePortal = 'https://intechsysone.com';

  static String _trimSlash(String value) => value.endsWith('/') ? value.substring(0, value.length - 1) : value;
}

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());
