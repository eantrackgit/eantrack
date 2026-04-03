import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../features/auth/domain/auth_state.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

/// Tela transitória pós-confirmação de e-mail.
/// Lê o estado do usuário e decide para onde ir — nunca permanece visível.
class FlowPage extends ConsumerStatefulWidget {
  const FlowPage({super.key});

  @override
  ConsumerState<FlowPage> createState() => _FlowPageState();
}

class _FlowPageState extends ConsumerState<FlowPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _decide());
  }

  void _decide() {
    if (!mounted) return;
    final authState = ref.read(authNotifierProvider);

    if (authState is! AuthAuthenticated) {
      context.go(AppRoutes.login);
      return;
    }

    final flowState = authState.flowState;

    // Mode not yet chosen — always start at mode selection.
    if (flowState == null || flowState.userMode == null) {
      context.go(AppRoutes.onboarding);
      return;
    }

    if (!flowState.isOnboardingComplete) {
      // Mode defined but onboarding incomplete — resume at correct step.
      context.go(
        flowState.userMode == 'agencia'
            ? AppRoutes.onboardingCnpj
            : AppRoutes.onboardingIndividual,
      );
      return;
    }

    // Onboarding complete — enter the app.
    context.go(AppRoutes.hub);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E27),
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
