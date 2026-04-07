import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
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

    final mode = _selected == _Mode.individual ? 'individual' : 'agencia';
    final ok = await ref.read(onboardingNotifierProvider.notifier).saveMode(mode);

    if (!mounted) return;
    setState(() => _saving = false);

    if (!ok) {
      await AppFeedback.showError(
        context,
        title: 'Erro ao salvar',
        message: 'Não foi possível salvar a seleção. Tente novamente.',
      );
      return;
    }

    context.go(
      _selected == _Mode.individual
          ? AppRoutes.hub           // placeholder — individual onboarding
          : AppRoutes.onboardingCnpj,
    );
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
                      'Essa configuração ajuda o EANTrack a personalizar sua experiência operacional.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Cards
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
                      icon: Icons.groups,
                      title: 'Agência',
                      description:
                          'Gerencie equipes, lojas e operações completas',
                      selected: _selected == _Mode.agency,
                      onTap: () => setState(() => _selected = _Mode.agency),
                    ),
                    const SizedBox(height: AppSpacing.xl),

                    // Actions
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
                            onPressed:
                                _saving ? null : () => context.go(AppRoutes.login),
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
                                    color: AppColors.info,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.secondary : AppColors.primaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.secondary : AppColors.alternate,
            width: selected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: selected ? AppColors.info : AppColors.secondaryText,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                color: selected ? AppColors.info : AppColors.secondary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: AppTextStyles.bodySmall.copyWith(
                color: selected
                    ? AppColors.info.withValues(alpha: 0.8)
                    : AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
