import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../../core/config/app_config.dart';
import '../domain/session.dart';
import 'one_auth_api.dart';

/// PKCE verifier and its S256 challenge.
class Pkce {
  Pkce._(this.verifier, this.challenge);

  factory Pkce.generate([Random? random]) {
    final rnd = random ?? Random.secure();
    final bytes = List<int>.generate(48, (_) => rnd.nextInt(256));
    final verifier = _base64Url(bytes);
    return Pkce._(verifier, challengeFor(verifier));
  }

  static String challengeFor(String verifier) => _base64Url(sha256.convert(ascii.encode(verifier)).bytes);

  static String _base64Url(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

  final String verifier;
  final String challenge;
}

class SsoCancelledException implements Exception {
  const SsoCancelledException();
}

/// "Ingresar con la cuenta de la empresa": SSO of INTECHSYS ONE with PKCE in the system browser.
///
/// Opens `{ONE_PORTAL_URL}/autorizar?client_id=worklog&redirect_uri=…&code_challenge=…`, the portal
/// answers on the app redirect (`com.intechsys.worklog://sso/callback?code=…&state=…&tenant=…`) and
/// the code is exchanged in `POST {ONE_URL}/api/v1/sso/token`. The redirect must be registered in
/// ONE for the `worklog` app.
class SsoService {
  SsoService(this._config, this._api);

  final AppConfig _config;
  final OneAuthApi _api;

  Uri authorizeUri(Pkce pkce, String state) => Uri.parse('${_config.onePortalUrl}/autorizar').replace(
    queryParameters: {
      'client_id': _config.oneClientId,
      'redirect_uri': _config.ssoRedirectUri,
      'response_type': 'code',
      'code_challenge': pkce.challenge,
      'code_challenge_method': 'S256',
      'state': state,
    },
  );

  Future<OneTokens> signIn() async {
    // Demo: there is no portal to open; the company account is the demo user.
    if (_config.isMock) return _api.login('andres.mora@intechsys.co', 'demo');
    final pkce = Pkce.generate();
    final state = Pkce.generate().verifier.substring(0, 24);

    final String result;
    try {
      result = await FlutterWebAuth2.authenticate(
        url: authorizeUri(pkce, state).toString(),
        callbackUrlScheme: _config.ssoCallbackScheme,
      );
    } on Exception catch (e) {
      if (e.toString().contains('CANCELED')) throw const SsoCancelledException();
      rethrow;
    }

    final callback = Uri.parse(result);
    final code = callback.queryParameters['code'];
    if (code == null || callback.queryParameters['state'] != state) {
      throw const FormatException('La respuesta del inicio de sesión no es válida.');
    }

    final tokens = await _api.exchangeSsoCode(
      clientId: _config.oneClientId,
      code: code,
      codeVerifier: pkce.verifier,
      redirectUri: _config.ssoRedirectUri,
    );
    final tenant = callback.queryParameters['tenant'];
    return tokens.tenantId != null || tenant == null
        ? tokens
        : OneTokens(
            accessToken: tokens.accessToken,
            refreshToken: tokens.refreshToken,
            expiresAt: tokens.expiresAt,
            fullName: tokens.fullName,
            email: tokens.email,
            tenantId: tenant,
          );
  }
}
