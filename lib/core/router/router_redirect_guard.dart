import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_flow_state.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'app_routes.dart';
import 'recovery_link_parser.dart';

/// Bridges Riverpod auth state → GoRouter refresh + redirect.
///
/// Listens to [authFlowStateProvider] and notifies GoRouter whenever the
/// auth state changes. The [redirect] method maps the current [AuthFlowState]
/// to the appropriate route.
class RouterRedirectGuard extends ChangeNotifier {
  RouterRedirectGuard(Ref ref) : _ref = ref {
    ref.listen(authFlowStateProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authFlowState = _ref.read(authFlowStateProvider);
    final path = state.matchedLocation;

    if (RecoveryLinkParser.hasExpiredParams(state.uri)) {
      return path == AppRoutes.passwordRecoveryLinkExpired
          ? null
          : AppRoutes.passwordRecoveryLinkExpired;
    }

    // Splash and flow manage their own navigation — never redirect away.
    if (path == AppRoutes.splash) return null;
    if (path == AppRoutes.flow) return null;
    if (path == AppRoutes.passwordRecoveryLinkExpired) return null;

    final isGuestRoute = path == AppRoutes.login ||
        path == AppRoutes.register ||
        path == AppRoutes.recoverPassword;
    final isOnboardingRoute = path == AppRoutes.onboarding ||
        path == AppRoutes.onboardingIndividual ||
        path == AppRoutes.onboardingCnpj ||
        path == AppRoutes.onboardingAgency ||
        path == AppRoutes.onboardingLegalRep;
    final isAppRoute = path == AppRoutes.hub || path == AppRoutes.regions;

    // /email-verification is only valid while the notifier is in AuthEmailUnconfirmed.
    if (path == AppRoutes.emailVerification) {
      final authState = _ref.read(authNotifierProvider);
      if (authState is AuthEmailUnconfirmed) return null;
      return AppRoutes.flow;
    }

    if (path == AppRoutes.updatePassword &&
        authFlowState != AuthFlowState.recovery) {
      return AppRoutes.flow;
    }

    if (isGuestRoute && authFlowState != AuthFlowState.unauthenticated) {
      return AppRoutes.flow;
    }

    if (isOnboardingRoute &&
        authFlowState != AuthFlowState.onboardingRequired) {
      return AppRoutes.flow;
    }

    if (isAppRoute && authFlowState != AuthFlowState.authenticated) {
      return AppRoutes.flow;
    }

    return null;
  }
}
