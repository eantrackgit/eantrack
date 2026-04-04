import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/domain/auth_flow_state.dart';
import '../../features/auth/domain/auth_state.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/email_verification_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/recover_password_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/update_password_screen.dart';
import '../../features/flow/presentation/screens/flow_page.dart';
import '../../features/hub/presentation/screens/hub_screen.dart';
import '../../features/onboarding/presentation/screens/choose_mode_screen.dart';
import '../../features/onboarding/presentation/screens/cnpj_screen.dart';
import '../../features/onboarding/presentation/screens/company_data_screen.dart';
import '../../features/onboarding/presentation/screens/individual_placeholder_screen.dart';
import '../../features/onboarding/presentation/screens/legal_representative_screen.dart';
import '../../features/regions/presentation/screens/region_list_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import 'app_routes.dart';

// ---------------------------------------------------------------------------
// Page transition helper — fade + subtle upward slide
// ---------------------------------------------------------------------------

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
  final notifier = _RouterNotifier(ref);
  ref.read(authRecoveryContextProvider);

  return GoRouter(
    debugLogDiagnostics: false,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    initialLocation: AppRoutes.splash,
    routes: [
      // --- Splash ---
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (_, state) => _fadePage(state, const SplashScreen()),
      ),

      // --- Auth (public) ---
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (_, state) => _fadePage(state, const LoginScreen()),
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

      // --- Hub (protected) ---
      GoRoute(
        path: AppRoutes.hub,
        pageBuilder: (_, state) => _fadePage(state, const HubScreen()),
      ),
      // FlowPage: transitória, decide destino pós email-confirmado.
      GoRoute(
        path: AppRoutes.flow,
        pageBuilder: (_, state) => _fadePage(state, const FlowPage()),
      ),

      // --- Onboarding ---
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (_, state) =>
            _fadePage(state, const ChooseModeScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingIndividual,
        pageBuilder: (_, state) =>
            _fadePage(state, const IndividualPlaceholderScreen()),
      ),
      GoRoute(
        path: AppRoutes.onboardingCnpj,
        pageBuilder: (_, state) => _fadePage(state, const CnpjScreen()),
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

      // --- Hub modules ---
      GoRoute(
        path: AppRoutes.regions,
        pageBuilder: (_, state) =>
            _fadePage(state, const RegionListScreen()),
      ),

      // --- Legal (placeholder) ---
      GoRoute(
        path: AppRoutes.termsOfUse,
        pageBuilder: (_, state) =>
            _fadePage(state, const _PlaceholderScreen(title: 'Termos de Uso')),
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        pageBuilder: (_, state) => _fadePage(
            state,
            const _PlaceholderScreen(
                title: 'Politica de Privacidade')),
      ),

      GoRoute(
        path: AppRoutes.noConnection,
        pageBuilder: (_, state) =>
            _fadePage(state, const _PlaceholderScreen(title: 'Sem Conexao')),
      ),
    ],
  );
});

/// Bridges Riverpod auth state -> GoRouter refresh + redirect.
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authFlowStateProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authFlowState = _ref.read(authFlowStateProvider);
    final path = state.matchedLocation;

    // Splash manages its own navigation — never redirect away from it.
    if (path == AppRoutes.splash) return null;
    if (path == AppRoutes.flow) return null;

    final isGuestRoute = path == AppRoutes.login ||
        path == AppRoutes.register ||
        path == AppRoutes.recoverPassword;
    final isOnboardingRoute = path == AppRoutes.onboarding ||
        path == AppRoutes.onboardingIndividual ||
        path == AppRoutes.onboardingCnpj ||
        path == AppRoutes.onboardingAgency ||
        path == AppRoutes.onboardingLegalRep ||
        path == AppRoutes.onboardingOperationalStyle ||
        path == AppRoutes.onboardingStatus;
    final isAppRoute = path == AppRoutes.hub ||
        path == AppRoutes.home ||
        path == AppRoutes.search ||
        path == AppRoutes.regions ||
        path == AppRoutes.cities ||
        path == AppRoutes.pdvs ||
        path == AppRoutes.registerPdv ||
        path == AppRoutes.networks ||
        path == AppRoutes.categories ||
        path == AppRoutes.subcategories ||
        path == AppRoutes.industries ||
        path == AppRoutes.registerIndustry ||
        path == AppRoutes.productMix;

    // /email-verification só é válida quando o notifier está em AuthEmailUnconfirmed.
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
