import 'package:flutter/material.dart';

import '../../../../shared/shared.dart';

/// Saída segura exibida em /flow quando a autenticação não pôde ser
/// confirmada dentro do tempo seguro (erro ou timeout).
///
/// Garante que o usuário nunca fique preso numa rota protegida sem mensagem
/// e sem ação: sempre há um caminho de volta ao login e uma opção de tentar
/// novamente.
class AuthFallbackScreen extends StatelessWidget {
  const AuthFallbackScreen({
    super.key,
    required this.isRetrying,
    required this.onRetry,
    required this.onBackToLogin,
  });

  final bool isRetrying;
  final VoidCallback onRetry;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return AuthScaffold(
      showLogo: true,
      title: 'Não foi possível confirmar sua sessão',
      subtitle: 'Não conseguimos validar sua autenticação neste momento. '
          'Você pode tentar novamente ou voltar para o login.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: et.surface,
              borderRadius: BorderRadius.circular(AppSpacing.md),
              border: Border.all(color: et.surfaceBorder),
            ),
            child: Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: et.inputFill,
                  border: Border.all(color: et.inputBorder),
                ),
                child: Icon(
                  Icons.lock_clock_outlined,
                  size: 32,
                  color: et.secondaryText,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.primary(
            'Voltar para login',
            onPressed: isRetrying ? null : onBackToLogin,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.outlined(
            'Tentar novamente',
            isLoading: isRetrying,
            onPressed: isRetrying ? null : onRetry,
          ),
        ],
      ),
    );
  }
}
