import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../hub/presentation/widgets/menu_hub_sidebar.dart';
import '../../../../shared/shared.dart';
import '../controllers/agency_status_notifier.dart';

class AgencyStatusScreen extends ConsumerWidget {
  const AgencyStatusScreen({super.key, this.debugStatus});

  final AgencyDocumentStatus? debugStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final et = EanTrackTheme.of(context);
    final isDesktop = Breakpoints.isDesktop(context);
    final provider = agencyStatusProvider(debugStatus);
    final state = ref.watch(provider);
    final isLoading = state.status == AgencyStatusLoading.loading;
    final data = state.data;

    if (state.status == AgencyStatusLoading.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        ref.read(provider.notifier).load();
      });
    }

    final content = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: data == null
              ? _InitialState(state: state, debugStatus: debugStatus)
              : _StatusContent(
                  data: data,
                  debugStatus: debugStatus,
                  isLoading: isLoading,
                ),
        ),
      ),
    );

    if (isDesktop) {
      return Scaffold(
        backgroundColor: et.sidebarSurface,
        body: Row(
          children: [
            MenuHubSidebar(
              userName: '',
              userRole: '',
              agencyName: data?.agencyLegalName ?? '',
              agencyHandle: '',
              agencyStatus: data?.consolidatedDocumentStatus ??
                  AgencyDocumentStatus.pending,
              onSignOut: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
                if (!context.mounted) return;
                context.go(AppRoutes.login);
              },
            ),
            Expanded(
              child: data == null
                  ? content
                  : _DesktopStatusContent(
                      data: data,
                      debugStatus: debugStatus,
                      isLoading: isLoading,
                    ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: et.scaffoldOuter,
      appBar: AppBar(
        backgroundColor: et.scaffoldOuter,
        foregroundColor: et.primaryText,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.secondaryBackground,
          ),
          onPressed: () async {
            await ref.read(authNotifierProvider.notifier).signOut();
            if (!context.mounted) return;
            context.go(AppRoutes.login);
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.xs),
            child: isLoading
                ? const _AppBarLoadingIndicator()
                : IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => ref.read(provider.notifier).refresh(),
                  ),
          ),
        ],
      ),
      body: content,
    );
  }
}

class _StatusContent extends StatelessWidget {
  const _StatusContent({
    required this.data,
    required this.debugStatus,
    required this.isLoading,
  });

  final AgencyStatusData data;
  final AgencyDocumentStatus? debugStatus;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: et.cardSurface,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: et.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(),
            const SizedBox(height: AppSpacing.md),
            _AgencyInfoCard(data: data, isLoading: isLoading),
            const SizedBox(height: AppSpacing.md),
            _DocumentStatusCard(data: data, isLoading: isLoading),
            if (_shouldShowRejectionReason(data)) ...[
              const SizedBox(height: AppSpacing.md),
              _RejectionReasonCard(reason: data.rejectionReason!),
            ],
            const SizedBox(height: AppSpacing.md),
            _NextStepsCard(status: data.consolidatedDocumentStatus),
            const SizedBox(height: AppSpacing.md),
            _ActionButton(
              data: data,
              debugStatus: debugStatus,
              isLoading: isLoading,
            ),
            const SizedBox(height: AppSpacing.md),
            const _HelpCard(),
          ],
        ),
      ),
    );
  }
}

class _DesktopStatusContent extends ConsumerWidget {
  const _DesktopStatusContent({
    required this.data,
    required this.debugStatus,
    required this.isLoading,
  });

  final AgencyStatusData data;
  final AgencyDocumentStatus? debugStatus;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          32,
          12,
          48,
          20,
        ),
        child: Align(
          alignment: const Alignment(-0.10, -1),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1280),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  showSubtitle: true,
                  trailing: const _ThemeToggleButton(),
                ),
                const SizedBox(height: AppSpacing.md),
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _AgencyInfoCard(data: data, isLoading: isLoading),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 2,
                        child: _DocumentStatusCard(data: data, isLoading: isLoading),
                      ),
                    ],
                  ),
                ),
                if (_shouldShowRejectionReason(data)) ...[
                  const SizedBox(height: AppSpacing.md),
                  _RejectionReasonCard(reason: data.rejectionReason!),
                ],
                const SizedBox(height: AppSpacing.md),
                _DesktopActionCard(
                  data: data,
                ),
                const SizedBox(height: AppSpacing.md),
                _ActionButton(
                  data: data,
                  debugStatus: debugStatus,
                  isLoading: isLoading,
                  isDesktop: true,
                ),
                const SizedBox(height: AppSpacing.md),
                const _HelpCard(),
                const SizedBox(height: AppSpacing.lg),
                const _FooterText(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InitialState extends StatelessWidget {
  const _InitialState({required this.state, required this.debugStatus});

  final AgencyStatusState state;
  final AgencyDocumentStatus? debugStatus;

  @override
  Widget build(BuildContext context) {
    if (state.status == AgencyStatusLoading.error) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppErrorBox(state.error ?? ''),
            const SizedBox(height: AppSpacing.md),
            Consumer(
              builder: (context, ref, _) {
                return AppButton.primary(
                  'Tentar novamente',
                  onPressed: () => ref
                      .read(agencyStatusProvider(debugStatus).notifier)
                      .refresh(),
                );
              },
            ),
          ],
        ),
      );
    }
    return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
  }
}

class _Header extends StatelessWidget {
  // ignore: prefer_const_constructors_in_immutables
  _Header({
    this.showSubtitle = false,
    this.trailing,
  });

  final bool showSubtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.actionBlue.withValues(alpha: 0.10),
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: AppColors.actionBlue.withValues(alpha: 0.22)),
          ),
          child: const Icon(Icons.business_rounded, size: 28, color: AppColors.actionBlue),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Status da Agência',
                style: AppTextStyles.titleLarge.copyWith(
                  color: et.primaryText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showSubtitle) ...[
                const SizedBox(height: 2),
                Text(
                  'Acompanhe o status da sua solicitação e dos documentos enviados.',
                  style: AppTextStyles.bodySmall.copyWith(color: et.secondaryText),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    );
  }
}

class _AgencyInfoCard extends StatelessWidget {
  const _AgencyInfoCard({required this.data, required this.isLoading});

  final AgencyStatusData data;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return _StatusSectionCard(
      title: 'Dados da agência',
      titleIcon: Icons.people_alt_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoRow(
            label: 'AGÊNCIA',
            value: data.agencyLegalName,
            valueChild:
                isLoading ? const AppSkeleton(height: 16, width: 200) : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            label: 'ÚLTIMA ATUALIZAÇÃO',
            value: _formatDateTime(data.agencyUpdatedAt),
            valueChild:
                isLoading ? const AppSkeleton(height: 14, width: 140) : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _StatusInfoRow(status: data.statusAgency, isLoading: isLoading),
        ],
      ),
    );
  }
}

class _DocumentStatusCard extends StatelessWidget {
  const _DocumentStatusCard({required this.data, required this.isLoading});

  final AgencyStatusData data;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final descriptor = _StatusDescriptor.from(data.consolidatedDocumentStatus);

    return _StatusSectionCard(
      title: 'STATUS DO DOCUMENTO',
      titleIcon: Icons.description_outlined,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final useHorizontalLayout = constraints.maxWidth >= 420;
          final representativeDetails = _DocumentRepresentativeDetails(
            data: data,
            isLoading: isLoading,
          );
          final statusBadge = isLoading
              ? const AppSkeleton(height: 36, width: 110, radius: 8)
              : _DocumentStatusBadge(
                  descriptor: descriptor,
                  label: _documentStatusText(data.consolidatedDocumentStatus),
                );

          if (!useHorizontalLayout) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                representativeDetails,
                const SizedBox(height: AppSpacing.md),
                statusBadge,
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: representativeDetails),
              const SizedBox(width: AppSpacing.md),
              Align(
                alignment: Alignment.topRight,
                child: statusBadge,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DocumentRepresentativeDetails extends StatelessWidget {
  const _DocumentRepresentativeDetails({
    required this.data,
    required this.isLoading,
  });

  final AgencyStatusData data;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final name = data.representativeName.trim();
    final role = data.representativeRole?.trim();
    final email = data.representativeEmail.trim();
    final phone = _formatRepresentativePhone(data.representativePhone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isLoading)
          const AppSkeleton(height: 22, width: 130, radius: 6)
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.actionBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: AppColors.actionBlue.withValues(alpha: 0.22),
              ),
            ),
            child: Text(
              _documentTitle(data.documentType),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.actionBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        if (isLoading) ...[
          const AppSkeleton(height: 16, width: 150),
          const SizedBox(height: AppSpacing.xs),
          const AppSkeleton(height: 13, width: 110),
          const SizedBox(height: AppSpacing.xs),
          const AppSkeleton(height: 13, width: 170),
          const SizedBox(height: AppSpacing.xs),
          const AppSkeleton(height: 13, width: 130),
        ] else ...[
          if (name.isNotEmpty) ...[
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _cardBodyStyle(et).copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (role != null && role.isNotEmpty) ...[
            Text(
              role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(color: et.secondaryText),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (email.isNotEmpty) ...[
            Text(
              email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _cardMutedStyle(et),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          if (phone != null)
            Text(
              phone,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _cardMutedStyle(et),
            ),
        ],
      ],
    );
  }
}

class _DocumentStatusBadge extends StatelessWidget {
  const _DocumentStatusBadge({
    required this.descriptor,
    required this.label,
  });

  final _StatusDescriptor descriptor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: descriptor.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(descriptor.icon, color: descriptor.color, size: 22),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: _cardBodyStyle(et).copyWith(color: descriptor.color),
          ),
        ],
      ),
    );
  }
}

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

class _ActionButton extends ConsumerWidget {
  const _ActionButton({
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
            Flexible(
              child: SizedBox(
                width: 320,
                child: secondaryButton,
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: SizedBox(
                width: 360,
                child: ctaButton,
              ),
            ),
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

  Future<void> _showTermsAcceptanceDialog(
    BuildContext context,
  ) async {
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

// ---------------------------------------------------------------------------
// Desktop action card — "O que fazer?"
// ---------------------------------------------------------------------------

class _DesktopActionCard extends StatelessWidget {
  const _DesktopActionCard({
    required this.data,
  });

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
              Container(
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
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: et.primaryText,
                      ),
                    ),
                  ),
                ),
              ),
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final stackButtons = constraints.maxWidth < 420;
                  final cancelButton = AppButton.secondary(
                    'Cancelar',
                    onPressed: isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                  );
                  final acceptButton = AppButton.primary(
                    'Aceitar e continuar',
                    onPressed: _accepted && !isSaving
                        ? () => _acceptAndContinue(context)
                        : null,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _acceptAndContinue(
    BuildContext context,
  ) async {
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
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueChild,
  });

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

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _StatusDescriptor {
  const _StatusDescriptor({
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  factory _StatusDescriptor.from(AgencyDocumentStatus status) {
    switch (status) {
      case AgencyDocumentStatus.approved:
        return const _StatusDescriptor(
          label: 'Aprovada',
          color: AppColors.success,
          icon: Icons.check_circle,
        );
      case AgencyDocumentStatus.rejected:
        return const _StatusDescriptor(
          label: 'Rejeitada',
          color: AppColors.error,
          icon: Icons.warning_sharp,
        );
      case AgencyDocumentStatus.pending:
        return const _StatusDescriptor(
          label: 'Aguardando',
          color: AppColors.warning,
          icon: Icons.hourglass_bottom,
        );
    }
  }
}

Color _agencyStatusColor(AgencyDocumentStatus status) => switch (status) {
      AgencyDocumentStatus.approved => AppColors.success,
      AgencyDocumentStatus.pending => AppColors.warning,
      AgencyDocumentStatus.rejected => AppColors.error,
    };

IconData _agencyStatusIcon(AgencyDocumentStatus status) => switch (status) {
      AgencyDocumentStatus.approved => Icons.check_circle,
      AgencyDocumentStatus.pending => Icons.hourglass_bottom,
      AgencyDocumentStatus.rejected => Icons.cancel,
    };

String _agencyStatusLabel(AgencyDocumentStatus status) => switch (status) {
      AgencyDocumentStatus.approved => 'Aprovada',
      AgencyDocumentStatus.pending => 'Aguardando',
      AgencyDocumentStatus.rejected => 'Rejeitada',
    };

Color _ctaColor(AgencyDocumentStatus status, EanTrackTheme et) => switch (status) {
      AgencyDocumentStatus.approved => AppColors.success,
      AgencyDocumentStatus.rejected => AppColors.error,
      AgencyDocumentStatus.pending => et.secondaryText.withValues(alpha: 0.3),
    };

String _documentTitle(String documentType) {
  final normalized = documentType.trim();
  return normalized.isEmpty ? 'Documento' : normalized;
}

String? _formatRepresentativePhone(String? value) {
  final text = value?.trim();
  if (text == null || text.isEmpty) return null;

  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 3)} '
        '${digits.substring(3, 7)}-${digits.substring(7)}';
  }

  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-'
        '${digits.substring(6)}';
  }

  return text;
}

String _documentStatusText(AgencyDocumentStatus status) => switch (status) {
      AgencyDocumentStatus.approved => 'Aprovado',
      AgencyDocumentStatus.rejected => 'Rejeitado',
      AgencyDocumentStatus.pending => 'Aguardando',
    };

String _nextStepsText(AgencyDocumentStatus status) => switch (status) {
      AgencyDocumentStatus.approved =>
        'Seu documento foi aprovado com sucesso. Sua agência está liberada para continuar.',
      AgencyDocumentStatus.rejected =>
        'Seu documento foi rejeitado. Você precisa enviar uma nova versão com foto legível para continuar o processo de aprovação.',
      AgencyDocumentStatus.pending =>
        'Recebemos seu documento e ele está em análise. Assim que a verificação for concluída, você será notificado.',
    };

bool _shouldShowRejectionReason(AgencyStatusData data) {
  return data.consolidatedDocumentStatus == AgencyDocumentStatus.rejected &&
      data.rejectionReason?.trim().isNotEmpty == true;
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d/$m/${local.year} $h:$min';
}

TextStyle _cardLabelStyle(EanTrackTheme et) =>
    AppTextStyles.labelSmall.copyWith(
      color: et.secondaryText,
      fontWeight: FontWeight.w600,
    );

TextStyle _cardBodyStyle(EanTrackTheme et) =>
    AppTextStyles.bodyMedium.copyWith(color: et.primaryText);

TextStyle _cardMutedStyle(EanTrackTheme et) =>
    AppTextStyles.bodyMedium.copyWith(color: et.secondaryText);

TextStyle _supportTextStyle(EanTrackTheme et) =>
    AppTextStyles.bodySmall.copyWith(color: et.secondaryText);

// ---------------------------------------------------------------------------
// Theme toggle
// ---------------------------------------------------------------------------

class _ThemeToggleButton extends ConsumerWidget {
  const _ThemeToggleButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final isDark = mode == ThemeMode.dark;
    final et = EanTrackTheme.of(context);

    return Tooltip(
      message: isDark ? 'Modo claro' : 'Modo escuro',
      child: Material(
        color: et.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            ref.read(themeModeProvider.notifier).state =
                isDark ? ThemeMode.light : ThemeMode.dark;
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                key: ValueKey(isDark),
                size: 20,
                color: et.secondaryText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
