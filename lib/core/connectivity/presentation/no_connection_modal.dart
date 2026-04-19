import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/shared.dart';
import '../connectivity_provider.dart';
import '../connectivity_state.dart';

Future<bool> ensureOnlineOrShowNoConnectionModal({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final status = await ref.read(connectivityProvider.notifier).checkConnection();
  if (status == ConnectionStatus.online) {
    return true;
  }
  if (!context.mounted) {
    return false;
  }
  return showNoConnectionModal(context: context, ref: ref);
}

Future<bool> showNoConnectionModal({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  final isOnline = await showDialog<bool>(
        context: context,
        builder: (_) => _NoConnectionModal(
          onRetry: () => ref.read(connectivityProvider.notifier).checkConnection(),
        ),
      ) ??
      false;

  return isOnline;
}

class _NoConnectionModal extends StatefulWidget {
  const _NoConnectionModal({required this.onRetry});

  final Future<ConnectionStatus> Function() onRetry;

  @override
  State<_NoConnectionModal> createState() => _NoConnectionModalState();
}

class _NoConnectionModalState extends State<_NoConnectionModal> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    if (_isRetrying) return;

    setState(() => _isRetrying = true);
    final status = await widget.onRetry();
    if (!mounted) return;

    if (status == ConnectionStatus.online) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() => _isRetrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: AppColors.actionBlue,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Sem Conexao',
              style: AppTextStyles.headlineSmall.copyWith(
                color: et.primaryText,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Verifique sua conexao com a internet e tente novamente',
              style: AppTextStyles.bodyMedium.copyWith(
                color: et.secondaryText,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (_isRetrying) ...[
              const SizedBox(height: AppSpacing.lg),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: AppSpacing.xl),
            AppButton.primary(
              'Tentar novamente',
              isLoading: _isRetrying,
              onPressed: _isRetrying ? null : _handleRetry,
            ),
          ],
        ),
      ),
    );
  }
}
