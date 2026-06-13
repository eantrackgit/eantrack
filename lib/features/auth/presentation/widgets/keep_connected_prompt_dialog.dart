import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';

import '../../../../shared/shared.dart';

Future<bool> showKeepConnectedPromptDialog({
  required BuildContext context,
  required String userId,
  required String? loginEmail,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => KeepConnectedPromptDialog(
      userId: userId,
      loginEmail: loginEmail,
    ),
  );

  return result ?? false;
}

class KeepConnectedPromptDialog extends ConsumerWidget {
  const KeepConnectedPromptDialog({
    super.key,
    required this.userId,
    required this.loginEmail,
  });

  final String userId;
  final String? loginEmail;

  Future<void> _answer(
    BuildContext context,
    WidgetRef ref,
    bool keepConnected,
  ) async {
    final saved = await ref
        .read(keepConnectedControllerProvider.notifier)
        .answerPrompt(
          userId,
          keepConnected,
          loginEmail: loginEmail,
        );

    if (!context.mounted) return;
    if (saved) {
      Navigator.of(context).pop(true);
      return;
    }

    final message = ref.read(keepConnectedControllerProvider).error ??
        'Nao foi possivel salvar a preferencia.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final et = EanTrackTheme.of(context);
    final state = ref.watch(keepConnectedControllerProvider);
    final isSaving = state.isSaving;

    return PopScope(
      canPop: false,
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.lg),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: et.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: et.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: AppColors.modalOverlayBase.withValues(alpha: 0.24),
                  blurRadius: 32,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Lottie.asset(
                      'assets/animations/keep_connected.json',
                      width: 148,
                      height: 148,
                      fit: BoxFit.contain,
                      repeat: true,
                      animate: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Manter conectado?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: et.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Voc\u00ea deseja manter sua sess\u00e3o ativa neste '
                    'dispositivo para acessar o EANTrack mais rapidamente nas '
                    'pr\u00f3ximas vezes?',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: et.secondaryText,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stackButtons = constraints.maxWidth < 360;
                      final primary = AppButton(
                        label: 'Sim, manter conectado',
                        isLoading: isSaving,
                        onPressed: isSaving
                            ? null
                            : () => _answer(context, ref, true),
                      );
                      final secondary = AppButton(
                        label: 'Agora n\u00e3o',
                        variant: AppButtonVariant.outlined,
                        onPressed: isSaving
                            ? null
                            : () => _answer(context, ref, false),
                      );

                      if (stackButtons) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            primary,
                            const SizedBox(height: AppSpacing.sm),
                            secondary,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: secondary),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: primary),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
