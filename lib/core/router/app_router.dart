import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/password_recovery_link_expired_screen.dart';
import '../../features/auth/presentation/screens/recover_password_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/update_password_screen.dart';
import '../../features/flow/presentation/screens/flow_page.dart';
import '../../features/hub/presentation/screens/hub_screen.dart';
import '../../features/onboarding/agency/pages/agency_cnpj_page.dart';
import '../../features/onboarding/agency/pages/agency_confirm_page.dart';
import '../../features/onboarding/agency/pages/agency_representative_page.dart';
import '../../features/onboarding/agency/models/agency_confirm_payload.dart';
import '../../features/onboarding/agency/models/cnpj_model.dart';
import '../../features/onboarding/presentation/screens/choose_mode_screen.dart';
import '../../features/onboarding/presentation/screens/company_data_screen.dart';
import '../../features/onboarding/presentation/screens/legal_representative_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_profile_screen.dart';
import '../../features/onboarding/presentation/screens/photo_profile_screen.dart';
import '../../features/regions/presentation/screens/region_list_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';
import 'recovery_link_parser.dart';
import 'router_redirect_guard.dart';

CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
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
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final guard = RouterRedirectGuard(ref);
  ref.read(authRecoveryContextProvider);
  final recoveryErrorLocation = RecoveryLinkParser.initialErrorLocation();

  return GoRouter(
    debugLogDiagnostics: false,
    refreshListenable: guard,
    redirect: guard.redirect,
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
        pageBuilder: (_, state) => _fadePage(state, const SplashScreen()),
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

          return _fadePage(
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
        pageBuilder: (_, state) => _fadePage(state, const RegisterScreen()),
      ),
      GoRoute(
        path: AppRoutes.emailVerification,
        pageBuilder: (_, state) =>
            _fadePage(state, const EmailVerificationScreen()),
      ),
      GoRoute(
        path: AppRoutes.recoverPassword,
        pageBuilder: (_, state) =>
            _fadePage(state, const RecoverPasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.updatePassword,
        pageBuilder: (_, state) =>
            _fadePage(state, const UpdatePasswordScreen()),
      ),
      GoRoute(
        path: AppRoutes.passwordRecoveryLinkExpired,
        pageBuilder: (_, state) => _fadePage(
          state,
          const PasswordRecoveryLinkExpiredScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.hub,
        pageBuilder: (_, state) => _fadePage(state, const HubScreen()),
      ),
      GoRoute(
        path: AppRoutes.flow,
        pageBuilder: (_, state) => _fadePage(state, const FlowPage()),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, state) => _fadePage(state, const ChooseModeScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingIndividual,
        pageBuilder: (_, state) => _fadePage(
          state,
          OnboardingProfileScreen(
            mode: state.uri.queryParameters['mode'] ?? 'individual',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.photoProfile,
        pageBuilder: (_, state) => _fadePage(
          state,
          PagPhotoProfile(
            mode: state.uri.queryParameters['mode'] ?? 'individual',
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboardingCnpj,
        pageBuilder: (_, state) => _fadePage(state, const AgencyCnpjPage()),
      ),
      GoRoute(
        path: AppRoutes.onboardingAgency,
        pageBuilder: (_, state) =>
            _fadePage(state, const CompanyDataScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingLegalRep,
        pageBuilder: (_, state) =>
            _fadePage(state, const LegalRepresentativeScreen()),
      ),
      GoRoute(
        path: '/onboarding/agency/confirm',
        pageBuilder: (_, state) {
          final cnpjModel = state.extra;
          if (cnpjModel is! CnpjModel) {
            return _fadePage(state, const AgencyCnpjPage());
          }

          return _fadePage(
            state,
            AgencyConfirmPage(cnpjModel: cnpjModel),
          );
        },
      ),
      GoRoute(
        path: '/onboarding/agency/representative',
        pageBuilder: (_, state) {
          final payload = state.extra;
          if (payload is! AgencyConfirmPayload) {
            return _fadePage(state, const AgencyCnpjPage());
          }

          return _fadePage(
            state,
            AgencyRepresentativePage(
              key: ValueKey(payload.agencyId),
              payload: payload,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.regions,
        pageBuilder: (_, state) => _fadePage(state, const RegionListScreen()),
      ),
      GoRoute(
        path: AppRoutes.termsOfUse,
        pageBuilder: (_, state) =>
            _fadePage(state, const _PlaceholderScreen(title: 'Termos de Uso')),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        pageBuilder: (_, state) => _fadePage(
          state,
          const _PlaceholderScreen(title: 'Politica de Privacidade'),
        ),
      ),
    ],
  );
});

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text('$title - em construcao')),
    );
  }
}
