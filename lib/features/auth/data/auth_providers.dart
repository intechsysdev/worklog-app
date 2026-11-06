import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/http_clients.dart';
import 'auth_repository.dart';
import 'one_auth_api.dart';
import 'session_store.dart';
import 'sso_service.dart';

final sessionStoreProvider = Provider<SessionStore>((ref) => SecureSessionStore());

final oneAuthApiProvider = Provider<OneAuthApi>((ref) => OneAuthApi(ref.watch(oneDioProvider)));

final ssoServiceProvider = Provider<SsoService>(
  (ref) => SsoService(ref.watch(appConfigProvider), ref.watch(oneAuthApiProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final repository = AuthRepository(
    store: ref.watch(sessionStoreProvider),
    oneApi: ref.watch(oneAuthApiProvider),
    sso: ref.watch(ssoServiceProvider),
  );
  ref.onDispose(repository.dispose);
  return repository;
});
