import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../controllers/agency_cnpj_controller.dart';
import '../presentation/widgets/cnpj_not_found_dialog.dart';

/// Primeira tela do onboarding de agência.
///
/// Recebe o CNPJ, apresenta feedback visual de consulta e, em caso de sucesso,
/// encaminha o usuário para a etapa de confirmação dos dados fiscais.
class AgencyCnpjScreen extends ConsumerWidget {
  const AgencyCnpjScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(agencyCnpjProvider.notifier);

    ref.listen<AgencyCnpjState>(agencyCnpjProvider, (previous, next) {
      if (previous?.status == AgencyCnpjStatus.notFound ||
          next.status != AgencyCnpjStatus.notFound) {
        return;
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;

        showDialog<void>(
          context: context,
          builder: (dialogContext) => CnpjNotFoundDialog(
            onSearchAgain: () {
              notifier.textController.clear();
              notifier.onChanged('');
            },
            onContinue: () => context.go(AppRoutes.onboardingAgency),
          ),
        );
      });
    });

    final state = ref.watch(agencyCnpjProvider);
    final et = EanTrackTheme.of(context);

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.search_rounded,
            size: 56,
            color: AppColors.actionBlue,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Informe o CNPJ da empresa',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              color: et.primaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Usaremos esse dado para localizar a empresa e validar o cadastro da agência.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: et.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _CnpjField(
            controller: notifier.textController,
            focusNode: notifier.focusNode,
            enabled: state.status != AgencyCnpjStatus.loading,
            onChanged: notifier.onChanged,
          ),
          if (state.errorMessage != null &&
              state.status != AgencyCnpjStatus.notFound) ...[
            const SizedBox(height: AppSpacing.sm),
            AppErrorBox(state.errorMessage!),
          ],
          if (state.cnpjModel != null) ...[
            const SizedBox(height: AppSpacing.md),
            _CompanyPreviewCard(
              razaoSocial: state.cnpjModel!.razaoSocial,
              nomeFantasia: state.cnpjModel!.nomeFantasia,
              situacao: state.cnpjModel!.situacaoCadastral,
              endereco: state.cnpjModel!.fullAddress,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppButton.action(
            'Consultar CNPJ',
            isLoading: state.status == AgencyCnpjStatus.loading,
            onPressed: state.status == AgencyCnpjStatus.loading
                ? null
                : notifier.consultCnpj,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  'Voltar',
                  onPressed: () => context.pop(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton.primary(
                  'Avançar',
                  onPressed: state.canAdvance
                      ? () => context.push(
                            AppRoutes.onboardingAgencyConfirm,
                            extra: state.cnpjModel,
                          )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Campo de entrada de CNPJ com máscara local da própria etapa.
class _CnpjField extends StatelessWidget {
  const _CnpjField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        const _CnpjInputFormatter(),
      ],
      style: AppTextStyles.bodyMedium.copyWith(color: et.primaryText),
      decoration: InputDecoration(
        labelText: 'CNPJ',
        hintText: '00.000.000/0000-00',
        filled: true,
        fillColor: enabled ? et.inputFill : et.inputFillDisabled,
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorderFocused, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorder),
        ),
      ),
    );
  }
}

/// Card de resumo exibido após uma consulta de CNPJ bem-sucedida.
class _CompanyPreviewCard extends StatelessWidget {
  const _CompanyPreviewCard({
    required this.razaoSocial,
    required this.nomeFantasia,
    required this.situacao,
    required this.endereco,
  });

  final String razaoSocial;
  final String nomeFantasia;
  final String situacao;
  final String endereco;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: AppRadius.smAll,
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            razaoSocial,
            style: AppTextStyles.titleSmall.copyWith(color: et.primaryText),
          ),
          if (nomeFantasia.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              nomeFantasia,
              style: AppTextStyles.bodySmall.copyWith(color: et.secondaryText),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Situação: $situacao',
            style: AppTextStyles.bodySmall.copyWith(color: et.primaryText),
          ),
          if (endereco.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              endereco,
              style: AppTextStyles.bodySmall.copyWith(color: et.secondaryText),
            ),
          ],
        ],
      ),
    );
  }
}

/// Formata a digitação do CNPJ para o padrão visual esperado na tela.
class _CnpjInputFormatter extends TextInputFormatter {
  const _CnpjInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length && i < 14; i++) {
      if (i == 2 || i == 5) buffer.write('.');
      if (i == 8) buffer.write('/');
      if (i == 12) buffer.write('-');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
