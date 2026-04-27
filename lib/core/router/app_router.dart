import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_flow_state.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/password_recovery_link_expired_screen.dart';
import '../../features/auth/presentation/screens/recover_password_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/update_password_screen.dart';
import '../../features/flow/presentation/screens/flow_screen.dart';
import '../../features/hub/presentation/screens/hub_screen.dart';
import '../../features/onboarding/agency/screens/agency_cnpj_screen.dart';
import '../../features/onboarding/agency/screens/agency_confirm_screen.dart';
import '../../features/onboarding/agency/screens/agency_representative_screen.dart';
import '../../features/onboarding/agency/screens/agency_status_screen.dart';
import '../../features/onboarding/agency/models/agency_confirm_payload.dart';
import '../../features/onboarding/agency/models/cnpj_model.dart';
import '../../features/onboarding/presentation/screens/choose_mode_screen.dart';
import '../../features/onboarding/presentation/screens/company_data_screen.dart';
import '../../features/onboarding/presentation/screens/legal_representative_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_profile_screen.dart';
import '../../features/onboarding/presentation/screens/photo_profile_screen.dart';
import '../../features/regions/presentation/screens/region_list_screen.dart';
import '../../features/validity/presentation/screens/validity_list_screen.dart';
import '../../features/legal/presentation/screens/privacy_policy_screen.dart';
import '../../features/legal/presentation/screens/terms_of_use_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';
import '../../features/onboarding/agency/controllers/agency_status_notifier.dart';
import 'recovery_link_parser.dart';
import 'router_redirect_guard.dart';

Page<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage<void>(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
          child: child,
        );
      },
    );

bool _hasAgencyHubAccess(AgencyStatusData data) {
  return data.statusAgency == AgencyDocumentStatus.approved &&
      data.consolidatedDocumentStatus == AgencyDocumentStatus.approved &&
      data.termsAccepted;
}

String? _redirect(Ref ref, BuildContext context, GoRouterState state) {
  final authFlowState = ref.read(authFlowStateProvider);
  final authState = ref.read(authNotifierProvider);
  final path = state.matchedLocation;

  if (RecoveryLinkParser.hasExpiredParams(state.uri) ||
      RecoveryLinkParser.hasExpiredParams(Uri.base)) {
    return path == AppRoutes.passwordRecoveryLinkExpired
        ? null
        : AppRoutes.passwordRecoveryLinkExpired;
  }

  if (path == AppRoutes.splash) return null;
  if (path == AppRoutes.flow) return null;
  if (path == AppRoutes.passwordRecoveryLinkExpired) return null;

  final isGuestRoute = path == AppRoutes.login ||
      path == AppRoutes.register ||
      path == AppRoutes.recoverPassword;
  final isAgencyStatusRoute = path == AppRoutes.onboardingAgencyStatus;
  final isOnboardingRoute = path == AppRoutes.onboarding ||
      path == AppRoutes.onboardingOperationalStyle ||
      path == AppRoutes.onboardingIndividual ||
      path == AppRoutes.onboardingIndividualProfile ||
      path == AppRoutes.photoProfile ||
      path == AppRoutes.onboardingCnpj ||
      path == AppRoutes.onboardingAgency ||
      path == AppRoutes.onboardingLegalRep ||
      path == AppRoutes.onboardingAgencyCnpj ||
      path == AppRoutes.onboardingAgencyConfirm ||
      path == AppRoutes.onboardingAgencyRepresentative ||
      isAgencyStatusRoute;
  final isAppRoute = AppRoutes.protectedRoutes.contains(path);
  final agencyStatusProviderInstance = agencyStatusProvider(null);
  final agencyData = ref.read(agencyStatusProviderInstance).data;
  final isAgencyUser = authState is AuthAuthenticated &&
      authState.flowState?.normalizedUserMode == 'agency';

  if ((isAppRoute || isAgencyStatusRoute) &&
      isAgencyUser &&
      ref.read(agencyStatusProviderInstance).status ==
          AgencyStatusLoading.idle) {
    Future.microtask(() {
      final status = ref.read(agencyStatusProviderInstance).status;
      if (status == AgencyStatusLoading.idle) {
        ref.read(agencyStatusProviderInstance.notifier).load();
      }
    });
  }

  if (path == AppRoutes.emailVerification) {
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

  if (isAgencyStatusRoute &&
      (authFlowState == AuthFlowState.onboardingRequired ||
          authFlowState == AuthFlowState.authenticated)) {
    return null;
  }

  // Permite que agência com documentação rejeitada acesse a tela de correção,
  // mesmo quando authFlowState já é authenticated (após aceite de termos).
  if (path == AppRoutes.onboardingAgencyRepresentative &&
      isAgencyUser &&
      agencyData?.consolidatedDocumentStatus == AgencyDocumentStatus.rejected &&
      (authFlowState == AuthFlowState.authenticated ||
          authFlowState == AuthFlowState.onboardingRequired)) {
    return null;
  }

  if (isOnboardingRoute &&
      authFlowState != AuthFlowState.onboardingRequired) {
    return AppRoutes.flow;
  }

  if (isAppRoute && authFlowState != AuthFlowState.authenticated) {
    if (isAgencyUser && agencyData != null) {
      return _hasAgencyHubAccess(agencyData)
          ? null
          : AppRoutes.onboardingAgencyStatus;
    }

    if (authFlowState == AuthFlowState.onboardingRequired) {
      return isAgencyUser ? AppRoutes.onboardingAgencyStatus : AppRoutes.flow;
    }

    return AppRoutes.flow;
  }

  if (isAppRoute &&
      isAgencyUser &&
      agencyData != null &&
      !_hasAgencyHubAccess(agencyData)) {
    return AppRoutes.onboardingAgencyStatus;
  }

  return null;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final guard = RouterRedirectGuard(ref);
  ref.read(authRecoveryContextProvider);
  final agencyStatusProviderInstance = agencyStatusProvider(null);
  ref.listen(agencyStatusProviderInstance, (_, __) => guard.notifyListeners());
  ref.listen(authFlowStateProvider, (_, next) {
    final authState = ref.read(authNotifierProvider);
    final isAgencyUser = authState is AuthAuthenticated &&
        authState.flowState?.normalizedUserMode == 'agency';
    if (isAgencyUser &&
        (next == AuthFlowState.authenticated ||
            next == AuthFlowState.onboardingRequired)) {
      ref.read(agencyStatusProviderInstance.notifier).refresh();
    }
  });
  final recoveryErrorLocation = RecoveryLinkParser.initialErrorLocation();

  return GoRouter(
    debugLogDiagnostics: false,
    refreshListenable: guard,
    redirect: (context, state) => _redirect(ref, context, state),
    initialLocation: recoveryErrorLocation ?? AppRoutes.splash,
    overridePlatformDefaultLocation: recoveryErrorLocation != null,
    onException: (_, state, router) {
      // Recovery links with expired/invalid tokens land here when GoRouter
      // fails to parse the URL fragment. Check both the router URI and the raw
      // browser URL to catch all fragment-encoding variants.
      if (RecoveryLinkParser.hasExpiredParams(state.uri) ||
          RecoveryLinkParser.hasExpiredParams(Uri.base)) {
        router.go(AppRoutes.passwordRecoveryLinkExpired);
        return;
      }
      if (state.uri.toString() == AppRoutes.login) return;
      router.go(AppRoutes.login);
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, state) => _fade(state, const SplashScreen()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, state) {
          final recoveryFromQuery =
              state.uri.queryParameters['recovery'] == 'email-sent';
          final notice = state.extra is LoginScreenNotice
              ? state.extra! as LoginScreenNotice
              : recoveryFromQuery
                  ? LoginScreenNotice.recoveryEmailSent
                  : null;

          return _fade(
            state,
            LoginScreen(
              notice: notice,
              consumeRecoveryQueryParam: recoveryFromQuery,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (_, state) => _fade(state, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        pageBuilder: (_, state) => _fade(state, const EmailVerificationScreen()),
      ),
      GoRoute(
        path: AppRoutes.recoverPassword,
        pageBuilder: (_, state) => _fade(state, const RecoverPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.updatePassword,
        pageBuilder: (_, state) => _fade(state, const UpdatePasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.passwordRecoveryLinkExpired,
        pageBuilder: (_, state) => _fade(state, const PasswordRecoveryLinkExpiredScreen()),
      ),
      GoRoute(
        path: AppRoutes.hub,
        pageBuilder: (_, state) => _fade(state, const HubScreen()),
      ),
      GoRoute(
        path: AppRoutes.flow,
        pageBuilder: (_, state) => _fade(state, const FlowScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, state) => _fade(state, const ChooseModeScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingOperationalStyle,
        pageBuilder: (_, state) => _fade(state, const ChooseModeScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingIndividual,
        pageBuilder: (_, state) => _fade(
          state,
          OnboardingProfileScreen(
            mode: state.uri.queryParameters['mode'] ?? 'individual',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingIndividualProfile,
        pageBuilder: (_, state) => _fade(
          state,
          OnboardingProfileScreen(
            mode: state.uri.queryParameters['mode'] ?? 'individual',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.photoProfile,
        pageBuilder: (_, state) => _fade(
          state,
          PagPhotoProfile(
            mode: state.uri.queryParameters['mode'] ?? 'individual',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingCnpj,
        pageBuilder: (_, state) => _fade(state, const AgencyCnpjScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingAgencyCnpj,
        pageBuilder: (_, state) => _fade(state, const AgencyCnpjScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingAgency,
        pageBuilder: (_, state) => _fade(state, const CompanyDataScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingLegalRep,
        pageBuilder: (_, state) => _fade(state, const LegalRepresentativeScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingAgencyConfirm,
        pageBuilder: (_, state) {
          final cnpjModel = state.extra;
          if (cnpjModel is! CnpjModel) {
            return _fade(state, const AgencyCnpjScreen());
          }

          return _fade(
            state,
            AgencyConfirmScreen(cnpjModel: cnpjModel),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboardingAgencyRepresentative,
        pageBuilder: (_, state) {
          final extra = state.extra;
          final payload = extra is AgencyConfirmPayload ? extra : null;
          final prefillData = extra is AgencyStatusData ? extra : null;

          return _fade(
            state,
            AgencyRepresentativeScreen(
              key: ValueKey(payload?.agencyId ?? prefillData?.agencyLegalName),
              payload: payload,
              prefillData: prefillData,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboardingAgencyStatus,
        pageBuilder: (_, state) {
          final debugStatus = state.extra is AgencyDocumentStatus
              ? state.extra! as AgencyDocumentStatus
              : null;

          return _fade(
            state,
            AgencyStatusScreen(debugStatus: debugStatus),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.validity,
        pageBuilder: (_, state) => _fade(state, const ValidityListScreen()),
      ),
      GoRoute(
        path: AppRoutes.regions,
        pageBuilder: (_, state) => _fade(state, const RegionListScreen()),
      ),
      GoRoute(
        path: AppRoutes.termsOfUse,
        pageBuilder: (_, state) => _fade(state, const TermsOfUseScreen()),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        pageBuilder: (_, state) => _fade(state, const PrivacyPolicyScreen()),
      ),
    ],
  );
});
