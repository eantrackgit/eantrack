import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../features/auth/domain/auth_flow_state.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/shared.dart';

/// Tela transitória central de decisão do fluxo de auth.
/// Lê [AuthFlowState] e encaminha automaticamente o usuário.
class FlowPage extends ConsumerStatefulWidget {
  const FlowPage({super.key});

  @override
  ConsumerState<FlowPage> createState() => _FlowPageState();
}

class _FlowPageState extends ConsumerState<FlowPage> {
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
        context.go(AppRoutes.onboarding);
        return;
      case AuthFlowState.authenticated:
        context.go(AppRoutes.hub);
        return;
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
