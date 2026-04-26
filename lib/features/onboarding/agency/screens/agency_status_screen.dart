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
        backgroundColor: et.scaffoldOuter,
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
            Expanded(child: content),
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
            const _Header(),
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
  const _Header();

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
          child: Text(
            'Status da Agência',
            style: AppTextStyles.titleLarge.copyWith(
              color: et.primaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
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
    final et = EanTrackTheme.of(context);
    final descriptor = _StatusDescriptor.from(data.consolidatedDocumentStatus);

    return _StatusSectionCard(
      title: 'STATUS DO DOCUMENTO',
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
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
                const SizedBox(height: AppSpacing.sm),
                if (isLoading)
                  const AppSkeleton(height: 14, width: 120)
                else
                  Text(
                    data.representativeName.toUpperCase(),
                    style: _cardBodyStyle(et).copyWith(fontWeight: FontWeight.w500),
                  ),
                const SizedBox(height: AppSpacing.xs),
                if (isLoading)
                  const AppSkeleton(height: 14, width: 160)
                else
                  Text(data.representativeEmail, style: _cardMutedStyle(et)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (isLoading)
            const AppSkeleton(height: 36, width: 110, radius: 8)
          else
            Container(
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
                    _documentStatusText(data.consolidatedDocumentStatus),
                    style: _cardBodyStyle(et).copyWith(color: descriptor.color),
                  ),
                ],
              ),
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

class _ActionButton extends ConsumerWidget {
  const _ActionButton({
    required this.data,
    required this.debugStatus,
    required this.isLoading,
  });

  final AgencyStatusData data;
  final AgencyDocumentStatus? debugStatus;
  final bool isLoading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final et = EanTrackTheme.of(context);
    final status = data.consolidatedDocumentStatus;
    late final String ctaLabel;
    late final VoidCallback? ctaAction;

    if (status == AgencyDocumentStatus.approved) {
      ctaLabel = 'Iniciar configuração da agência';
      ctaAction = () => context.go(AppRoutes.hub);
    } else if (status == AgencyDocumentStatus.rejected) {
      ctaLabel = 'Corrigir documentação';
      ctaAction = () => context.push(
            AppRoutes.onboardingAgencyRepresentative,
            extra: ref.read(agencyStatusProvider(debugStatus)).data,
          );
    } else {
      ctaLabel = 'Aguardando validação dos documentos.';
      ctaAction = null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusCtaButton(
          label: ctaLabel,
          onPressed: ctaAction,
          backgroundColor: _ctaColor(status, et),
        ),
        const SizedBox(height: 8),
        AppButton.secondary(
          'Atualizar status da solicitação',
          onPressed: isLoading
              ? null
              : () => ref
                  .read(agencyStatusProvider(debugStatus).notifier)
                  .refresh(),
          isLoading: isLoading,
          leadingIcon: const Icon(Icons.sync),
        ),
      ],
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

class _StatusSectionCard extends StatelessWidget {
  const _StatusSectionCard({required this.child, this.title});

  final Widget child;
  final String? title;

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
            Text(title!, style: _cardLabelStyle(et)),
            const SizedBox(height: AppSpacing.sm),
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
