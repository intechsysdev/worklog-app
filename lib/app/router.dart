import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/alerts/presentation/previews.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/tenant_screen.dart';
import '../features/onboarding/presentation/onboarding_controller.dart';
import '../features/onboarding/presentation/permissions_screen.dart';
import '../features/onboarding/presentation/policy_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/requests/domain/adjustment_options.dart';
import '../features/requests/presentation/adjustment_form_screen.dart';
import '../features/requests/presentation/overtime_form_screen.dart';
import '../features/requests/presentation/requests_screen.dart';
import '../features/requests/presentation/shift_change_form_screen.dart';
import '../features/sync/presentation/pending_sync_screen.dart';
import '../features/week/presentation/week_screen.dart';
import '../features/workday/presentation/close_workday_screen.dart';
import '../features/workday/presentation/finish_activity_screen.dart';
import '../features/workday/presentation/history_screen.dart';
import '../features/workday/presentation/home_screen.dart';
import '../features/workday/presentation/select_activity_screen.dart';
import 'routes.dart';
import 'work_session_scope.dart';

/// Re-evaluates the redirects when the session or the onboarding change.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (_, _) => notifyListeners());
    ref.listen(onboardingProvider, (_, _) => notifyListeners());
  }
}

/// Where the user must be, given the session and the onboarding, or null to stay.
String? gateRedirect(AuthState auth, OnboardingState onboarding, String location) {
  String? goTo(String target) => location == target ? null : target;

  if (auth is AuthLoading) return goTo(Routes.splash);
  if (auth is SignedOut) return goTo(Routes.login);
  if (auth is PendingTenant) return goTo(Routes.tenants);
  final signedIn = auth as SignedIn;
  if (signedIn.needsTenant) return goTo(Routes.tenants);
  if (signedIn.session.mustChangePassword) return goTo(Routes.changePassword);
  if (!onboarding.loaded) return goTo(Routes.splash);
  if (!onboarding.policyAccepted) return goTo(Routes.policy);
  if (!onboarding.deviceReviewed) return goTo(Routes.permissions);
  const gates = {Routes.splash, Routes.login, Routes.tenants, Routes.changePassword, Routes.policy, Routes.permissions};
  return gates.contains(location) ? Routes.home : null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  Page<void> page(Widget child) => NoTransitionPage<void>(child: child);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) =>
        gateRedirect(ref.read(authControllerProvider), ref.read(onboardingProvider), state.matchedLocation),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const _Splash()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.tenants, builder: (_, _) => const TenantScreen()),
      GoRoute(path: Routes.changePassword, builder: (_, _) => const ChangePasswordScreen()),
      GoRoute(path: Routes.policy, builder: (_, _) => const PolicyScreen()),
      GoRoute(path: Routes.permissions, builder: (_, _) => const PermissionsScreen()),
      ShellRoute(
        builder: (context, state, child) => WorkSessionScope(child: child),
        routes: [
          GoRoute(path: Routes.home, pageBuilder: (_, _) => page(const HomeScreen())),
          GoRoute(path: Routes.history, pageBuilder: (_, _) => page(const HistoryScreen())),
          GoRoute(path: Routes.selectActivity, builder: (_, _) => const SelectActivityScreen()),
          GoRoute(path: Routes.finishActivity, builder: (_, _) => const FinishActivityScreen()),
          GoRoute(path: Routes.closeWorkday, builder: (_, _) => const CloseWorkdayScreen()),
          GoRoute(path: Routes.pending, builder: (_, _) => const PendingSyncScreen()),
          GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen()),
          GoRoute(path: Routes.policyView, builder: (_, _) => const PolicyScreen(readOnly: true)),
          GoRoute(path: Routes.deviceReview, builder: (_, _) => const PermissionsScreen(fromProfile: true)),
          GoRoute(path: Routes.week, pageBuilder: (_, _) => page(const WeekScreen())),
          GoRoute(path: Routes.requests, builder: (_, _) => const RequestsScreen()),
          GoRoute(
            path: Routes.adjustmentRequest,
            builder: (_, state) => AdjustmentFormScreen(prefill: state.extra as AdjustmentPrefill?),
          ),
          GoRoute(path: Routes.overtimeRequest, builder: (_, _) => const OvertimeFormScreen()),
          GoRoute(path: Routes.shiftChangeRequest, builder: (_, _) => const ShiftChangeFormScreen()),
          GoRoute(path: Routes.kiosk, builder: (_, _) => const KioskPreviewScreen()),
          GoRoute(path: Routes.shiftEndNotice, builder: (_, _) => const ShiftEndPreviewScreen()),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}
