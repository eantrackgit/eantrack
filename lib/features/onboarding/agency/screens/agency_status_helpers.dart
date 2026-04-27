part of 'agency_status_screen.dart';

class _BalloonCard extends StatelessWidget {
  const _BalloonCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    this.highlightedText,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;
  final String? highlightedText;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: et.surface.withValues(alpha: 0.72),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: et.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: _supportTextStyle(et).copyWith(
                    color: et.primaryText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (highlightedText == null)
                  Text(body, style: _supportTextStyle(et))
                else
                  RichText(
                    text: TextSpan(
                      style: _supportTextStyle(et),
                      children: [
                        TextSpan(text: body),
                        TextSpan(
                          text: highlightedText,
                          style: _supportTextStyle(et).copyWith(
                            color: AppColors.actionBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NextStepsCard extends StatelessWidget {
  const _NextStepsCard({required this.status});

  final AgencyDocumentStatus status;

  @override
  Widget build(BuildContext context) {
    return _BalloonCard(
      icon: Icons.assignment_turned_in_rounded,
      iconColor: AppColors.actionBlue,
      title: 'O que fazer?',
      body: _nextStepsText(status),
    );
  }
}

class _RejectionReasonCard extends StatelessWidget {
  const _RejectionReasonCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return _BalloonCard(
      icon: Icons.report_problem_rounded,
      iconColor: AppColors.error,
      title: 'Motivo da rejeição',
      body: reason,
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return const _BalloonCard(
      icon: Icons.lightbulb_rounded,
      iconColor: AppColors.success,
      title: 'Dúvidas?',
      body: 'Entre em contato conosco ',
      highlightedText: 'suporte@eantrack.com',
    );
  }
}

class _FooterText extends StatelessWidget {
  const _FooterText();

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 13, color: et.secondaryText),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Seus dados estão protegidos e são utilizados apenas para validação da responsabilidade legal da agência.',
              style: AppTextStyles.bodySmall.copyWith(color: et.secondaryText),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSectionCard extends StatelessWidget {
  const _StatusSectionCard({required this.child, this.title, this.titleIcon});

  final Widget child;
  final String? title;
  final IconData? titleIcon;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: et.cardSurface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: et.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, size: 18, color: AppColors.actionBlue),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  title!,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: et.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.valueChild});

  final String label;
  final String value;
  final Widget? valueChild;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _cardLabelStyle(et)),
        const SizedBox(height: AppSpacing.xs),
        valueChild ?? Text(value, style: _cardBodyStyle(et)),
      ],
    );
  }
}

class _StatusInfoRow extends StatelessWidget {
  const _StatusInfoRow({required this.status, required this.isLoading});

  final AgencyDocumentStatus status;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final color = _agencyStatusColor(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STATUS DA SOLICITAÇÃO', style: _cardLabelStyle(et)),
        const SizedBox(height: AppSpacing.xs),
        if (isLoading)
          const AppSkeleton(height: 28, width: 110, radius: 8)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_agencyStatusIcon(status), size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  _agencyStatusLabel(status),
                  style: AppTextStyles.bodySmall.copyWith(color: color),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AppBarLoadingIndicator extends StatelessWidget {
  const _AppBarLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ),
    );
  }
}
