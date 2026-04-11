import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/shared.dart';
import '../providers/onboarding_provider.dart';

enum _Mode { individual, agency }

class ChooseModeScreen extends ConsumerStatefulWidget {
  const ChooseModeScreen({super.key});

  @override
  ConsumerState<ChooseModeScreen> createState() => _ChooseModeScreenState();
}

class _ChooseModeScreenState extends ConsumerState<ChooseModeScreen> {
  _Mode? _selected;
  bool _saving = false;

  Future<void> _continue() async {
    if (_selected == null || _saving) return;
    setState(() => _saving = true);

    final mode = _selected == _Mode.individual ? 'individual' : 'agency';
    final ok = await ref.read(onboardingNotifierProvider.notifier).saveMode(mode);

    if (!mounted) return;
    setState(() => _saving = false);

    if (!ok) {
      await AppFeedback.showError(
        context,
        title: 'Erro ao salvar',
        message: 'Nao foi possivel salvar a selecao. Tente novamente.',
      );
      return;
    }

    context.go(
      '${AppRoutes.onboardingIndividual}?mode=$mode',
    );
  }

  Future<void> _confirmBackToLogin() async {
    if (_saving) return;

    final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: ColoredBox(
                          color: AppColors.modalOverlayBase.withValues(
                            alpha: 0.52,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.xl,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryBackground,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: AppColors.alternate),
                              boxShadow: const [AppShadows.xl],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Icon(
                                  Icons.warning_amber_rounded,
                                  size: 36,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'Voltar agora?',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.headlineSmall.copyWith(
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Recomendamos selecionar um modo antes de voltar.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.secondaryText,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Se voce voltar agora, ira para o login e depois precisara fazer essa selecao novamente.',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.secondaryText,
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                AppButton.secondary(
                                  'Continuar nesta tela',
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                AppButton.primary(
                                  'Voltar para login',
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ) ??
        false;

    if (!mounted || !shouldLeave) return;
    await ref.read(authNotifierProvider.notifier).signOut();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Defina seu estilo operacional',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.secondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Essa configuracao ajuda o EANTrack a personalizar sua experiencia operacional.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _ModeCard(
                      icon: Icons.person,
                      title: 'Individual',
                      description:
                          'Execute pesquisas, auditorias e controle de validades de forma independente',
                      selected: _selected == _Mode.individual,
                      onTap: () => setState(() => _selected = _Mode.individual),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _ModeCard(
                      icon: Icons.business,
                      title: 'Agencia',
                      description:
                          'Gerencie equipes, lojas e operacoes completas',
                      selected: _selected == _Mode.agency,
                      onTap: () => setState(() => _selected = _Mode.agency),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: AppButton(
                            label: 'Voltar',
                            variant: AppButtonVariant.outlined,
                            leadingIcon: const Icon(
                              Icons.arrow_back_ios,
                              size: 14,
                              color: AppColors.secondary,
                            ),
                            onPressed: _saving ? null : _confirmBackToLogin,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppButton(
                            label: 'Continuar',
                            trailingIcon: _saving
                                ? null
                                : const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: AppColors.secondaryBackground,
                                  ),
                            isLoading: _saving,
                            onPressed:
                                (_selected == null || _saving) ? null : _continue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = selected
        ? AppColors.success.withValues(alpha: 0.05)
        : AppColors.secondaryBackground;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.success.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.hovered)) {
            return AppColors.primaryText.withValues(alpha: 0.03);
          }
          return null;
        }),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.success : AppColors.alternate,
              width: selected ? 2.0 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: selected ? 1 : 0,
                  child: const Icon(
                    Icons.check_circle,
                    size: 20,
                    color: AppColors.success,
                  ),
                ),
              ),
              Icon(
                icon,
                size: 64,
                color: selected ? AppColors.success : AppColors.secondaryText,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
