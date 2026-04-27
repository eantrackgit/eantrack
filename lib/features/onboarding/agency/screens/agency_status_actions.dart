part of 'agency_status_screen.dart';

class _ActionSection extends ConsumerWidget {
  const _ActionSection({
    required this.data,
    required this.debugStatus,
    required this.isLoading,
    this.isDesktop = false,
  });

  final AgencyStatusData data;
  final AgencyDocumentStatus? debugStatus;
  final bool isLoading;
  final bool isDesktop;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final et = EanTrackTheme.of(context);
    final status = data.consolidatedDocumentStatus;
    final provider = agencyStatusProvider(debugStatus);
    late final String ctaLabel;
    late final VoidCallback? ctaAction;

    if (status == AgencyDocumentStatus.approved) {
      ctaLabel = 'Aceitar termos e começar';
      ctaAction = () {
        if (data.termsAccepted) {
          context.go(AppRoutes.hub);
          return;
        }
        _showTermsAcceptanceDialog(context);
      };
    } else if (status == AgencyDocumentStatus.rejected) {
      ctaLabel = 'Corrigir documentação';
      ctaAction = () => context.push(
            AppRoutes.onboardingAgencyRepresentative,
            extra: ref.read(provider).data,
          );
    } else {
      ctaLabel = 'Aguardando validação dos documentos.';
      ctaAction = null;
    }

    final ctaButton = _StatusCtaButton(
      label: ctaLabel,
      onPressed: ctaAction,
      backgroundColor: _ctaColor(status, et),
    );
    final secondaryButton = AppButton.secondary(
      'Atualizar status da solicitação',
      onPressed: isLoading
          ? null
          : () => ref.read(provider.notifier).refresh(),
      isLoading: isLoading,
      leadingIcon: const Icon(Icons.sync),
    );

    if (isDesktop) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: et.cardSurface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: et.surfaceBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(child: SizedBox(width: 320, child: secondaryButton)),
            const SizedBox(width: 16),
            Flexible(child: SizedBox(width: 360, child: ctaButton)),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ctaButton,
        const SizedBox(height: 8),
        secondaryButton,
      ],
    );
  }

  Future<void> _showTermsAcceptanceDialog(BuildContext context) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return _TermsAcceptanceDialog(debugStatus: debugStatus);
      },
    );

    if (accepted == true && context.mounted) {
      context.go(AppRoutes.hub);
    }
  }
}

class _DesktopActionCard extends StatelessWidget {
  const _DesktopActionCard({required this.data});

  final AgencyStatusData data;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final status = data.consolidatedDocumentStatus;

    return _StatusSectionCard(
      title: 'O que fazer?',
      titleIcon: Icons.assignment_turned_in_rounded,
      child: Text(
        _nextStepsText(status),
        style: AppTextStyles.bodySmall.copyWith(color: et.secondaryText),
      ),
    );
  }
}

class _StatusCtaButton extends StatelessWidget {
  const _StatusCtaButton({
    required this.label,
    required this.onPressed,
    required this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          disabledBackgroundColor: backgroundColor,
          foregroundColor: et.ctaForeground,
          disabledForegroundColor: et.ctaForeground,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleSmall.copyWith(color: et.ctaForeground),
        ),
      ),
    );
  }
}
