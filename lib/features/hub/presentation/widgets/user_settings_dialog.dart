import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/shared.dart';

Future<void> showUserSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const UserSettingsDialog(),
  );
}

class UserSettingsDialog extends ConsumerStatefulWidget {
  const UserSettingsDialog({super.key});

  @override
  ConsumerState<UserSettingsDialog> createState() => _UserSettingsDialogState();
}

class _UserSettingsDialogState extends ConsumerState<UserSettingsDialog> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      // forceRefresh: Preferencias deve sempre refletir o valor atual do
      // banco ao abrir, mesmo que o boot/login já tenha carregado este
      // userId nesta sessão.
      ref.read(keepConnectedControllerProvider.notifier).load(forceRefresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(userThemeControllerProvider, (previous, next) {
      if (next.error == null || previous?.error == next.error) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
        ),
      );
      ref.read(userThemeControllerProvider.notifier).clearError();
    });
    ref.listen(keepConnectedControllerProvider, (previous, next) {
      if (next.error == null || previous?.error == next.error) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(next.error!),
          backgroundColor: AppColors.error,
        ),
      );
      ref.read(keepConnectedControllerProvider.notifier).clearError();
    });

    final et = EanTrackTheme.of(context);
    final selectedMode = ref.watch(themeModeProvider);
    final themeState = ref.watch(userThemeControllerProvider);
    final keepConnectedState = ref.watch(keepConnectedControllerProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: et.cardSurface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: et.surfaceBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.modalOverlayBase.withValues(alpha: 0.24),
                blurRadius: 28,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Configura\u00e7\u00f5es',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: et.primaryText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: et.secondaryText,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Apar\u00eancia',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: et.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _ThemeOptionTile(
                  icon: Icons.light_mode_outlined,
                  label: 'Claro',
                  selected: selectedMode == ThemeMode.light,
                  enabled: !themeState.isSaving,
                  onTap: () {
                    ref
                        .read(userThemeControllerProvider.notifier)
                        .setTheme(ThemeMode.light);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                _ThemeOptionTile(
                  icon: Icons.dark_mode_outlined,
                  label: 'Escuro',
                  selected: selectedMode == ThemeMode.dark,
                  enabled: !themeState.isSaving,
                  onTap: () {
                    ref
                        .read(userThemeControllerProvider.notifier)
                        .setTheme(ThemeMode.dark);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Sess\u00e3o',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: et.secondaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _KeepConnectedTile(
                  value: keepConnectedState.keepConnected,
                  isLoading: keepConnectedState.isLoading,
                  isSaving: keepConnectedState.isSaving,
                  onChanged: (value) {
                    ref
                        .read(keepConnectedControllerProvider.notifier)
                        .setKeepConnected(value);
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Fechar',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: et.accentLink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeepConnectedTile extends StatelessWidget {
  const _KeepConnectedTile({
    required this.value,
    required this.isLoading,
    required this.isSaving,
    required this.onChanged,
  });

  final bool value;
  final bool isLoading;
  final bool isSaving;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final isBusy = isLoading || isSaving;

    return Container(
      constraints: const BoxConstraints(minHeight: 74),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: et.surface,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: et.inputBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lock_clock_outlined,
            size: 20,
            color: et.secondaryText,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Lembrar-me',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: et.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Lembre esta conta neste dispositivo para facilitar o '
                  'pr\u00f3ximo acesso.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: et.secondaryText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: et.ctaBackground,
              ),
            )
          else
            Switch.adaptive(
              value: value,
              onChanged: isSaving ? null : onChanged,
            ),
        ],
      ),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.icon,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final borderColor = selected ? et.inputBorderFocused : et.inputBorder;
    final foregroundColor = selected ? et.primaryText : et.secondaryText;

    return Material(
      color: selected ? et.surface : Colors.transparent,
      borderRadius: AppRadius.smAll,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: AppRadius.smAll,
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smAll,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: foregroundColor),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: foregroundColor,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: selected ? et.inputBorderFocused : et.secondaryText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
