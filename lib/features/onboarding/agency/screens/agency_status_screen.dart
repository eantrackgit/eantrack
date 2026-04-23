import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../controllers/agency_status_notifier.dart';

class AgencyStatusScreen extends ConsumerWidget {
  const AgencyStatusScreen({super.key, this.debugStatus});

  final AgencyDocumentStatus? debugStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final et = EanTrackTheme.of(context);
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

    return Scaffold(
      backgroundColor: et.scaffoldOuter,
      appBar: AppBar(
        backgroundColor: et.scaffoldOuter,
        foregroundColor: et.primaryText,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
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
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: data == null
                ? _InitialState(state: state, debugStatus: debugStatus)
                : _StatusContent(data: data, debugStatus: debugStatus),
          ),
        ),
      ),
    );
  }
}

class _StatusContent extends StatelessWidget {
  const _StatusContent({required this.data, required this.debugStatus});

  final AgencyStatusData data;
  final AgencyDocumentStatus? debugStatus;

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
          border: Border.all(color: et.ctaBackground.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Header(),
            const SizedBox(height: AppSpacing.md),
            _AgencyInfoCard(data: data),
            const SizedBox(height: AppSpacing.md),
            _DocumentStatusCard(data: data),
            const SizedBox(height: AppSpacing.md),
            _NextStepsCard(status: data.consolidatedDocumentStatus),
            const SizedBox(height: AppSpacing.md),
            _ActionButton(data: data, debugStatus: debugStatus),
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
            color: et.cardSurface,
            borderRadius: AppRadius.mdAll,
            border: Border.all(color: et.ctaBackground.withValues(alpha: 0.18)),
          ),
          child: Icon(Icons.business_rounded, size: 28, color: et.primaryText),
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
  const _AgencyInfoCard({required this.data});

  final AgencyStatusData data;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return _StatusSectionCard(
      title: 'AGÊNCIA',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(data.agencyLegalName, style: _cardBodyLargeStyle(et)),
          const SizedBox(height: AppSpacing.md),
          _InfoRow(
            label: 'ÚLTIMA ATUALIZAÇÃO',
            value: _formatDateTime(data.agencyUpdatedAt),
          ),
          const SizedBox(height: AppSpacing.md),
          _StatusInfoRow(status: data.statusAgency),
        ],
      ),
    );
  }
}

class _DocumentStatusCard extends StatelessWidget {
  const _DocumentStatusCard({required this.data});

  final AgencyStatusData data;

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
                Text(_documentTitle(data.documentType), style: _cardTitleStyle(et)),
                const SizedBox(height: AppSpacing.xs),
                Text(data.representativeName, style: _cardBodyStyle(et)),
                const SizedBox(height: AppSpacing.xs),
                Text(data.representativeEmail, style: _cardMutedStyle(et)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
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
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.balloonBackground,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.balloonBorder),
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
                    color: AppColors.balloonTitle,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(body, style: _supportTextStyle(et)),
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
      iconColor: AppColors.balloonIconAction,
      title: 'O que fazer?',
      body: _nextStepsText(status),
    );
  }
}

class _HelpCard extends StatelessWidget {
  const _HelpCard();

  @override
  Widget build(BuildContext context) {
    return const _BalloonCard(
      icon: Icons.lightbulb_rounded,
      iconColor: AppColors.balloonIconInfo,
      title: 'Dúvidas?',
      body: 'Entre em contato conosco: suporte@eantrack.com',
    );
  }
}

class _ActionButton extends ConsumerWidget {
  const _ActionButton({required this.data, required this.debugStatus});

  final AgencyStatusData data;
  final AgencyDocumentStatus? debugStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final et = EanTrackTheme.of(context);
    final status = data.consolidatedDocumentStatus;
    late final String ctaLabel;
    late final VoidCallback? ctaAction;

    if (status == AgencyDocumentStatus.approved) {
      ctaLabel = 'Continuar para configuração';
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
        ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
          child: AppButton.secondary(
            'Atualizar status da solicitação',
            onPressed: () =>
                ref.read(agencyStatusProvider(debugStatus).notifier).load(),
            leadingIcon: const Icon(Icons.sync),
          ),
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
        border: Border.all(color: et.ctaBackground.withValues(alpha: 0.18)),
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
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _cardLabelStyle(et)),
        const SizedBox(height: AppSpacing.xs),
        Text(value, style: _cardBodyStyle(et)),
      ],
    );
  }
}

class _StatusInfoRow extends StatelessWidget {
  const _StatusInfoRow({required this.status});

  final AgencyDocumentStatus status;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final color = _agencyStatusColor(status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('STATUS DA SOLICITAÇÃO', style: _cardLabelStyle(et)),
        const SizedBox(height: AppSpacing.xs),
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

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final h = local.hour.toString().padLeft(2, '0');
  final min = local.minute.toString().padLeft(2, '0');
  return '$d/$m/${local.year} $h:$min';
}

TextStyle _cardLabelStyle(EanTrackTheme et) =>
    AppTextStyles.labelSmall.copyWith(color: et.secondaryText);

TextStyle _cardTitleStyle(EanTrackTheme et) =>
    AppTextStyles.bodyMedium.copyWith(color: et.primaryText, fontWeight: FontWeight.w600);

TextStyle _cardBodyLargeStyle(EanTrackTheme et) =>
    AppTextStyles.bodyMedium.copyWith(color: et.primaryText);

TextStyle _cardBodyStyle(EanTrackTheme et) =>
    AppTextStyles.bodyMedium.copyWith(color: et.primaryText);

TextStyle _cardMutedStyle(EanTrackTheme et) =>
    AppTextStyles.bodyMedium.copyWith(color: et.secondaryText);

TextStyle _supportTextStyle(EanTrackTheme et) =>
    AppTextStyles.bodySmall.copyWith(color: et.primaryText);
