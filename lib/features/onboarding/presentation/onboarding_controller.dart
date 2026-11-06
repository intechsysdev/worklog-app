import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/storage/kv_store.dart';
import '../../profile/data/models/profile_models.dart';
import '../../profile/data/profile_api.dart';

/// Steps between login and the home screen: data policy and device review.
class OnboardingState {
  const OnboardingState({this.loaded = false, this.policyAccepted = false, this.deviceReviewed = false, this.policy});

  final bool loaded;
  final bool policyAccepted;
  final bool deviceReviewed;

  /// Current policy (null until downloaded).
  final PrivacyPolicyDto? policy;

  OnboardingState copyWith({bool? loaded, bool? policyAccepted, bool? deviceReviewed, PrivacyPolicyDto? policy}) =>
      OnboardingState(
        loaded: loaded ?? this.loaded,
        policyAccepted: policyAccepted ?? this.policyAccepted,
        deviceReviewed: deviceReviewed ?? this.deviceReviewed,
        policy: policy ?? this.policy,
      );
}

class OnboardingController extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    unawaited(_load());
    return const OnboardingState();
  }

  KvStore get _kv => ref.read(kvStoreProvider);

  Future<void> _load() async {
    final accepted = await _kv.get(KvKeys.policyAcceptedVersion);
    final reviewed = await _kv.getBool(KvKeys.deviceReviewed);
    if (!ref.mounted) return;
    state = state.copyWith(loaded: true, policyAccepted: accepted != null, deviceReviewed: reviewed);
  }

  /// Downloads the current policy. A new version forces the acceptance again; without
  /// connection the cached acceptance is kept.
  Future<void> checkPolicy() async {
    try {
      final policy = await ref.read(profileApiProvider).privacyPolicy();
      await _kv.set(KvKeys.policyAcceptedVersion, policy.accepted ? policy.version : null);
      if (!ref.mounted) return;
      state = state.copyWith(loaded: true, policy: policy, policyAccepted: policy.accepted);
    } on ApiException catch (e) {
      if (!e.isTransient) rethrow;
      if (!state.loaded) await _load();
    }
  }

  Future<void> acceptPolicy() async {
    var policy = state.policy;
    if (policy == null) {
      policy = await ref.read(profileApiProvider).privacyPolicy();
      if (!ref.mounted) return;
      state = state.copyWith(policy: policy);
    }
    await ref.read(profileApiProvider).acceptPolicy(policy.version);
    await _kv.set(KvKeys.policyAcceptedVersion, policy.version);
    if (!ref.mounted) return;
    state = state.copyWith(policyAccepted: true);
    unawaited(checkPolicy());
  }

  Future<void> markDeviceReviewed() async {
    await _kv.setBool(KvKeys.deviceReviewed, true);
    state = state.copyWith(deviceReviewed: true);
  }

  /// After signing out.
  void reset() => state = const OnboardingState(loaded: true);
}

final onboardingProvider = NotifierProvider<OnboardingController, OnboardingState>(OnboardingController.new);
