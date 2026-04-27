part of 'agency_status_screen.dart';

class _TermsAcceptanceDialog extends ConsumerStatefulWidget {
  const _TermsAcceptanceDialog({required this.debugStatus});

  final AgencyDocumentStatus? debugStatus;

  @override
  ConsumerState<_TermsAcceptanceDialog> createState() =>
      _TermsAcceptanceDialogState();
}

class _TermsAcceptanceDialogState extends ConsumerState<_TermsAcceptanceDialog> {
  bool _accepted = false;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final size = MediaQuery.sizeOf(context);
    final isDesktop = Breakpoints.isDesktop(context);
    final dialogMaxWidth = isDesktop ? 640.0 : size.width - AppSpacing.xl;
    final termsHeight = isDesktop ? 280.0 : 220.0;
    final provider = agencyStatusProvider(widget.debugStatus);
    final isSaving = ref.watch(
      provider.select((state) => state.isAcceptingTerms),
    );
    final error = ref.watch(provider.select((state) => state.error));

    return Dialog(
      backgroundColor: et.cardSurface,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogMaxWidth,
          maxHeight: size.height - (AppSpacing.lg * 2),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Aceite dos termos',
                style: AppTextStyles.titleLarge.copyWith(
                  color: et.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Para configurar a agência, é necessário aceitar os Termos de Uso e a Política de Privacidade.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: et.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _TermsScrollableText(et: et, termsHeight: termsHeight),
              const SizedBox(height: AppSpacing.md),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: et.surface,
                  borderRadius: AppRadius.smAll,
                  border: Border.all(color: et.surfaceBorder),
                ),
                child: CheckboxListTile(
                  value: _accepted,
                  activeColor: AppColors.success,
                  checkColor: et.ctaForeground,
                  onChanged: isSaving
                      ? null
                      : (value) {
                          setState(() => _accepted = value ?? false);
                        },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  title: Text(
                    'Li e aceito os Termos de Uso e a Política de Privacidade',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: et.primaryText,
                    ),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              _TermsActions(
                accepted: _accepted,
                isSaving: isSaving,
                onAccept: () => _acceptAndContinue(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptAndContinue(BuildContext context) async {
    final provider = agencyStatusProvider(widget.debugStatus);
    final ok = await ref.read(provider.notifier).acceptTermsAndContinue();
    if (!context.mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    final message = ref.read(provider).error ??
        'Não foi possível registrar o aceite dos termos.';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TermsScrollableText extends StatelessWidget {
  const _TermsScrollableText({required this.et, required this.termsHeight});

  final EanTrackTheme et;
  final double termsHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: termsHeight,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: et.surface,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: et.surfaceBorder),
      ),
      child: Scrollbar(
        child: SingleChildScrollView(
          child: Text(
            'Ao continuar, declaro que li e aceito os Termos de Uso '
            'e a Política de Privacidade do EANTrack.\n\n'
            'Confirmo que sou responsável pelas informações da '
            'agência, representante legal e documentos enviados, '
            'autorizando o EANTrack a utilizar esses dados para '
            'validação, segurança, operação da conta e cumprimento '
            'das obrigações da plataforma.\n\n'
            'Estou ciente de que, após a liberação da agência e '
            'início da configuração/uso do ambiente, poderão ser '
            'aplicadas cobranças conforme o plano contratado, '
            'condições comerciais vigentes e recursos habilitados '
            'na conta.\n\n'
            'Também entendo que o uso da plataforma está sujeito '
            'às regras operacionais, políticas de acesso, '
            'suspensão, cancelamento e tratamento de dados '
            'descritas nos documentos legais do EANTrack.',
            style: AppTextStyles.bodyMedium.copyWith(color: et.primaryText),
          ),
        ),
      ),
    );
  }
}

class _TermsActions extends StatelessWidget {
  const _TermsActions({
    required this.accepted,
    required this.isSaving,
    required this.onAccept,
  });

  final bool accepted;
  final bool isSaving;
  final VoidCallback onAccept;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackButtons = constraints.maxWidth < 420;
        final cancelButton = AppButton.secondary(
          'Cancelar',
          onPressed: isSaving ? null : () => Navigator.of(context).pop(false),
        );
        final acceptButton = AppButton.primary(
          'Aceitar e continuar',
          onPressed: accepted && !isSaving ? onAccept : null,
          isLoading: isSaving,
        );

        if (stackButtons) {
          return Column(
            children: [
              acceptButton,
              const SizedBox(height: AppSpacing.sm),
              cancelButton,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cancelButton),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: acceptButton),
          ],
        );
      },
    );
  }
}
