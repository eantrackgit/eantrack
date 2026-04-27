part of 'menu_hub_sidebar.dart';

class _MenuHubFooter extends StatelessWidget {
  const _MenuHubFooter({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: et.divider),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: SizedBox(
            height: 46,
            child: ElevatedButton(
              onPressed: onSignOut,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: et.ctaForeground,
                elevation: 0,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
              ),
              child: Text(
                'Sair da conta',
                style: AppTextStyles.labelMedium.copyWith(
                  color: et.ctaForeground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: AppSpacing.md),
          child: AppVersionBadge(),
        ),
      ],
    );
  }
}
