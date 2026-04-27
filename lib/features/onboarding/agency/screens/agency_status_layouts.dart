part of 'agency_status_screen.dart';

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
            _ActionSection(
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

class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout({
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
        padding: const EdgeInsets.fromLTRB(32, 12, 48, 20),
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
                        child: _DocumentStatusCard(
                          data: data,
                          isLoading: isLoading,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_shouldShowRejectionReason(data)) ...[
                  const SizedBox(height: AppSpacing.md),
                  _RejectionReasonCard(reason: data.rejectionReason!),
                ],
                const SizedBox(height: AppSpacing.md),
                _DesktopActionCard(data: data),
                const SizedBox(height: AppSpacing.md),
                _ActionSection(
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
  _Header({this.showSubtitle = false, this.trailing});

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
            border: Border.all(
              color: AppColors.actionBlue.withValues(alpha: 0.22),
            ),
          ),
          child: const Icon(
            Icons.business_rounded,
            size: 28,
            color: AppColors.actionBlue,
          ),
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
                  style: AppTextStyles.bodySmall.copyWith(
                    color: et.secondaryText,
                  ),
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
