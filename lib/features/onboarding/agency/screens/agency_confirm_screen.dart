import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../controllers/agency_confirm_controller.dart';
import '../controllers/agency_onboarding_notifier.dart';
import '../models/cnpj_model.dart';

/// Tela de confirmação e complementação dos dados da agência.
///
/// Exibe os dados fiscais vindos do CNPJ consultado, permite ajustes
/// complementares e dispara o salvamento final da agência.
class AgencyConfirmScreen extends ConsumerWidget {
  const AgencyConfirmScreen({
    super.key,
    required this.cnpjModel,
  });

  final CnpjModel cnpjModel;

  /// Tenta salvar a agência e, em caso de sucesso, avança para a próxima etapa.
  Future<void> _handleAdvance(
    BuildContext context,
    AgencyConfirmNotifier notifier,
  ) async {
    final ok = await notifier.submit();
    if (!context.mounted || !ok) return;

    context.push(
      AppRoutes.onboardingAgencyRepresentative,
      extra: notifier.buildPayload(),
    );
  }

  Future<void> _handleBack(
    BuildContext context,
    WidgetRef ref,
    AgencyConfirmState state,
  ) async {
    final agencyId = state.savedAgencyId?.trim();
    if (agencyId == null || agencyId.isEmpty) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.onboardingAgencyCnpj);
      }
      return;
    }

    final shouldReset = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return Material(
              color: Colors.transparent,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(
                              color: AppColors.modalOverlayBase.withValues(
                                alpha: 0.52,
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    AppColors.modalOverlayMid.withValues(
                                      alpha: 0.92,
                                    ),
                                    AppColors.modalOverlayBase.withValues(
                                      alpha: 0.84,
                                    ),
                                    AppColors.modalOverlayGlow.withValues(
                                      alpha: 0.18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
                          child: Builder(
                            builder: (ctx) {
                              final det = EanTrackTheme.of(ctx);
                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: det.cardSurface,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: AppColors.warning.withValues(
                                      alpha: 0.16,
                                    ),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.modalOverlayBase
                                          .withValues(alpha: 0.28),
                                      blurRadius: 32,
                                      offset: const Offset(0, 18),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Center(
                                      child: Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppColors.warning.withValues(
                                            alpha: 0.10,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 34,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      'Reiniciar cadastro?',
                                      textAlign: TextAlign.center,
                                      style:
                                          AppTextStyles.headlineSmall.copyWith(
                                        color: det.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      'Alterar o CNPJ reiniciara o cadastro da agencia. Os dados ja preenchidos serao descartados.',
                                      textAlign: TextAlign.center,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: det.secondaryText,
                                        height: 1.45,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                    AppButton.secondary(
                                      'Cancelar',
                                      onPressed: () => Navigator.of(
                                        dialogContext,
                                      ).pop(false),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    AppButton.primary(
                                      'Reiniciar cadastro',
                                      onPressed: () => Navigator.of(
                                        dialogContext,
                                      ).pop(true),
                                    ),
                                  ],
                                ),
                              );
                            },
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

    if (!shouldReset || !context.mounted) return;

    final ok = await ref
        .read(agencyOnboardingNotifierProvider.notifier)
        .resetAgencyOnboarding(agencyId);

    if (!context.mounted) return;

    if (!ok) {
      final message = ref.read(agencyOnboardingNotifierProvider).error ??
          'Nao foi possivel reiniciar o cadastro da agencia.';
      await AppFeedback.showError(
        context,
        title: 'Falha ao reiniciar',
        message: message,
      );
      return;
    }

    ref.invalidate(agencyConfirmProvider(cnpjModel));
    ref.read(agencyOnboardingNotifierProvider.notifier).clearState();
    context.go(AppRoutes.onboardingAgencyCnpj);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agencyConfirmProvider(cnpjModel));
    final resetState = ref.watch(agencyOnboardingNotifierProvider);
    final notifier = ref.read(agencyConfirmProvider(cnpjModel).notifier);
    final et = EanTrackTheme.of(context);
    final isActive = cnpjModel.situacaoCadastral.trim().toUpperCase() == 'ATIVA';
    final cnpjTextStyle = AppTextStyles.bodyMedium.copyWith(color: et.primaryText);
    final cnpjTextPainter = TextPainter(
      text: TextSpan(
        text: cnpjModel.formattedCnpj,
        style: cnpjTextStyle,
      ),
      maxLines: 1,
      textDirection: Directionality.of(context),
    )..layout();
    final cnpjFieldWidth = cnpjTextPainter.width + 84;
    final sectionDecoration = BoxDecoration(
      color: et.surface.withValues(alpha: 0.55),
      borderRadius: AppRadius.mdAll,
      border: Border.all(color: et.surfaceBorder),
    );

    return AuthScaffold(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Breakpoints.isDesktop(context) ? 640 : 480,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.actionBlue.withValues(alpha: 0.08),
                    borderRadius: AppRadius.mdAll,
                    border: Border.all(
                      color: AppColors.actionBlue.withValues(alpha: 0.16),
                    ),
                  ),
                  child: const Icon(
                    Icons.business_rounded,
                    size: 44,
                    color: AppColors.secondary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Confirme os dados da empresa',
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineSmall.copyWith(
                  color: et.primaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Essas informações serão usadas para validar sua conta.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: et.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SectionCard(
                title: 'DADOS FISCAIS',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _EditableField(
                      label: 'Nome Fantasia',
                      controller: notifier.fantasyNameController,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ReadonlyField(
                      label: 'Razão Social',
                      value: cnpjModel.razaoSocial,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        const statusWidth = 118.0;
                        final availableWidth =
                            constraints.maxWidth - statusWidth - AppSpacing.sm;
                        final cnpjWidth =
                            cnpjFieldWidth < availableWidth
                                ? cnpjFieldWidth
                                : availableWidth;

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: cnpjWidth,
                              child: _ReadonlyField(
                                label: 'CNPJ',
                                value: cnpjModel.formattedCnpj,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            SizedBox(
                              width: statusWidth,
                              child: Align(
                                alignment: Alignment.center,
                                child: _StatusCard(
                                  label: 'Situação Cadastral',
                                  value: cnpjModel.situacaoCadastral,
                                  isActive: isActive,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    if (!isActive) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const AppErrorBox(
                        'Não é possível continuar com um CNPJ inativo.',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: sectionDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionTitle('CONTATO DA EMPRESA'),
                    const SizedBox(height: AppSpacing.sm),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth < 380) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _EditableField(
                                label: 'Telefone de Contato',
                                hintText: '(11) 9 9999-9999',
                                controller: notifier.phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  const PhoneInputFormatter(),
                                ],
                                errorText: state.phoneError,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _EditableField(
                                label: 'E-mail',
                                hintText: 'contato@suaempresa.com.br',
                                controller: notifier.emailController,
                                keyboardType: TextInputType.emailAddress,
                                errorText: state.emailError,
                              ),
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _EditableField(
                                label: 'Telefone de Contato',
                                hintText: '(11) 9 9999-9999',
                                controller: notifier.phoneController,
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  const PhoneInputFormatter(),
                                ],
                                errorText: state.phoneError,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: _EditableField(
                                label: 'E-mail',
                                hintText: 'contato@suaempresa.com.br',
                                controller: notifier.emailController,
                                keyboardType: TextInputType.emailAddress,
                                errorText: state.emailError,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: sectionDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const _SectionTitle('ENDEREÇO DA EMPRESA'),
                    const SizedBox(height: AppSpacing.sm),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _EditableField(
                              label: 'CEP',
                              hintText: '00000-000',
                              controller: notifier.cepController,
                              keyboardType: TextInputType.number,
                              onChanged: (_) => notifier.clearCepMessage(),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                _CepInputFormatter(),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          SizedBox(
                            width: 110,
                            child: _SearchCepButton(
                              isLoading: state.isSearchingCep,
                              onPressed:
                                  state.isSearchingCep ? null : notifier.searchCep,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (state.cepMessage != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppErrorBox(state.cepMessage!),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _EditableField(
                            label: 'Logradouro',
                            hintText: 'Av. Paulista',
                            controller: notifier.logradouroController,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: 110,
                          child: _EditableField(
                            label: 'Número',
                            hintText: '1000',
                            controller: notifier.numeroController,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _EditableField(
                            label: 'Bairro',
                            hintText: 'Centro',
                            controller: notifier.bairroController,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: _EditableField(
                            label: 'Município',
                            hintText: 'São Paulo',
                            controller: notifier.municipioController,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        SizedBox(
                          width: 110,
                          child: _EditableField(
                            label: 'UF',
                            hintText: 'SP',
                            controller: notifier.ufController,
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (state.submitErrorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppErrorBox(state.submitErrorMessage!),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      'Voltar',
                      onPressed: (state.isSubmitting || resetState.isLoading)
                          ? null
                          : () => _handleBack(context, ref, state),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton.primary(
                      'Avançar',
                      isLoading: state.isSubmitting,
                      trailingIcon: state.isSubmitting
                          ? null
                          : const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onPressed:
                          (state.canAdvance && isActive && !state.isSubmitting)
                              ? () => _handleAdvance(context, notifier)
                              : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Título visual reutilizado nas seções da página.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Text(
      value,
      style: AppTextStyles.labelMedium.copyWith(
        color: et.primaryText,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

/// Campo somente leitura usado para dados fiscais não editáveis.
class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return TextFormField(
      initialValue: value,
      readOnly: true,
      style: AppTextStyles.bodyMedium.copyWith(color: et.primaryText),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: et.inputFillDisabled,
        suffixIcon: const Icon(Icons.lock_rounded, size: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorder),
        ),
      ),
    );
  }
}

/// Campo editável reutilizado na composição do formulário.
class _EditableField extends StatelessWidget {
  const _EditableField({
    required this.label,
    required this.controller,
    this.hintText,
    this.errorText,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      style: AppTextStyles.bodyMedium.copyWith(color: et.primaryText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: et.secondaryText.withValues(alpha: 0.72),
        ),
        errorText: errorText,
        filled: true,
        fillColor: et.inputFill,
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorderFocused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }
}

/// Apresenta a situação cadastral da empresa em formato de título + chip.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.label,
    required this.value,
    required this.isActive,
  });

  final String label;
  final String value;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.error;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.secondaryText,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.28)),
          ),
          child: Text(
            value,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Botão de busca de CEP alinhado ao campo de CEP na mesma linha.
class _SearchCepButton extends StatelessWidget {
  const _SearchCepButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.actionBlue,
          disabledBackgroundColor: AppColors.actionBlue,
          foregroundColor: AppColors.secondaryBackground,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          minimumSize: const Size(110, 0),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.secondaryBackground,
                ),
              )
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 16,
                    color: AppColors.secondaryBackground,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text('Buscar'),
                ],
              ),
      ),
    );
  }
}

/// Formata o CEP no padrão `00000-000`.
class _CepInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length && i < 8; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
