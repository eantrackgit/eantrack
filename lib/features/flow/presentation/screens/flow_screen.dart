import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../features/auth/domain/auth_state.dart';
import '../../../../features/auth/domain/auth_flow_state.dart';
import '../../../../features/auth/domain/user_flow_state.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/shared.dart';

/// Tela transitória central de decisão do fluxo de auth.
/// Lê [AuthFlowState] e encaminha automaticamente o usuário.
class FlowScreen extends ConsumerStatefulWidget {
  const FlowScreen({super.key});

  @override
  ConsumerState<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends ConsumerState<FlowScreen> {
  ProviderSubscription<AuthFlowState>? _authFlowSubscription;
  Timer? _safetyTimer;
  static const Duration _safetyTimeout = Duration(seconds: 8);

  bool _isNavigating = false;
  bool _isResolvingOnboardingRoute = false;

  @override
  void initState() {
    super.initState();
    _authFlowSubscription = ref.listenManual<AuthFlowState>(
      authFlowStateProvider,
      (_, next) => _scheduleDecision(next),
    );
    _safetyTimer = Timer(_safetyTimeout, () {
      if (!mounted || _isNavigating) return;
      _isNavigating = true;
      context.go(AppRoutes.login);
    });
    _scheduleDecision(ref.read(authFlowStateProvider));
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _authFlowSubscription?.close();
    super.dispose();
  }

  void _scheduleDecision(AuthFlowState flowState) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _decide(flowState);
    });
  }

  void _go(String route) {
    if (!mounted || _isNavigating) return;
    _isNavigating = true;
    context.go(route);
    // Se o router redirecionar de volta para /flow, a instância permanece
    // montada. Nesse caso, resetar e re-tentar com o estado atual.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _isNavigating = false;
      _isResolvingOnboardingRoute = false;
      _scheduleDecision(ref.read(authFlowStateProvider));
    });
  }

  void _decide(AuthFlowState flowState) {
    if (!mounted || _isNavigating) return;

    switch (flowState) {
      case AuthFlowState.unauthenticated:
        _go(AppRoutes.login);
        return;
      case AuthFlowState.recovery:
        _go(AppRoutes.updatePassword);
        return;
      case AuthFlowState.onboardingRequired:
        _resolveOnboardingRouteFromState();
        return;
      case AuthFlowState.authenticated:
        _go(AppRoutes.hub);
        return;
    }
  }

  String _routeFromUserFlowState(UserFlowState? flowState) {
    if (flowState == null) return AppRoutes.onboarding;

    if (flowState.isOnboardingComplete) {
      return AppRoutes.hub;
    }

    switch (flowState.normalizedUserMode) {
      case null:
        return AppRoutes.onboarding;
      case 'individual':
        return flowState.hasProfile
            ? AppRoutes.hub
            : AppRoutes.onboardingIndividualProfile;
      case 'agency':
        final agencyId = flowState.agencyId?.trim();
        if (agencyId == null || agencyId.isEmpty) {
          return AppRoutes.onboardingAgencyCnpj;
        }

        final agencyStatus = flowState.agencyStatus?.trim().toLowerCase();
        if (agencyStatus == 'aprovada' || agencyStatus == 'approved') {
          return AppRoutes.hub;
        }

        if (flowState.hasLegalRepresentative == true) {
          return AppRoutes.onboardingAgencyStatus;
        }

        return AppRoutes.onboardingAgencyRepresentative;
      default:
        return AppRoutes.onboarding;
    }
  }

  Future<void> _resolveOnboardingRouteFromState() async {
    if (_isResolvingOnboardingRoute || _isNavigating) return;
    _isResolvingOnboardingRoute = true;

    try {
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        _go(_routeFromUserFlowState(authState.flowState));
        return;
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _go(AppRoutes.login);
        return;
      }

      final flowState = await ref
          .read(authRepositoryProvider)
          .getUserFlowState(user.id)
          .timeout(const Duration(seconds: 8), onTimeout: () => null);

      if (!mounted || _isNavigating) return;
      _go(_routeFromUserFlowState(flowState));
    } on Exception catch (e) {
      debugPrint('[FlowScreen] Erro ao resolver fluxo: $e');
      if (mounted && !_isNavigating) {
        _go(AppRoutes.onboarding);
      }
    } finally {
      if (mounted) {
        _isResolvingOnboardingRoute = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Scaffold(
      backgroundColor: et.scaffoldOuter,
      body: Center(
        child: Lottie.asset(
          'assets/animations/flow_loading.json',
          width: 180,
          repeat: true,
          animate: true,
        ),
      ),
    );
  }
}
