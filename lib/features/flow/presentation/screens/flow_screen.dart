import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../features/auth/domain/auth_flow_state.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _decide(ref.read(authFlowStateProvider));
    });
  }

  void _decide(AuthFlowState flowState) {
    if (!mounted) return;

    switch (flowState) {
      case AuthFlowState.unauthenticated:
        context.go(AppRoutes.login);
        return;
      case AuthFlowState.recovery:
        context.go(AppRoutes.updatePassword);
        return;
      case AuthFlowState.onboardingRequired:
        _resolveOnboardingRoute(context);
        return;
      case AuthFlowState.authenticated:
        context.go(AppRoutes.hub);
        return;
    }
  }

  Future<void> _resolveOnboardingRoute(BuildContext context) async {
    try {
      final route = await Supabase.instance.client.rpc(
        'get_user_onboarding_route',
      ) as String?;

      if (!context.mounted) return;

      switch (route) {
        case 'hub':
          context.go(AppRoutes.hub);
          return;
        case 'onboarding/agency/status':
          context.go(AppRoutes.onboardingAgencyStatus);
          return;
        case 'onboarding/agency/representative':
          context.go(AppRoutes.onboardingAgencyRepresentative);
          return;
        case 'onboarding/agency/cnpj':
          context.go(AppRoutes.onboardingAgencyCnpj);
          return;
        case 'onboarding/individual/profile':
          context.go(AppRoutes.onboardingIndividualProfile);
          return;
        default:
          context.go(AppRoutes.onboarding);
          return;
      }
    } on Exception catch (e) {
      debugPrint('[FlowScreen] Erro ao resolver rota: $e');
      if (context.mounted) context.go(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthFlowState>(authFlowStateProvider, (_, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _decide(next));
    });

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
