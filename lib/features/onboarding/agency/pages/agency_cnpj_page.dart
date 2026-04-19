import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart' as spacing_tokens;
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_error_box.dart';
import '../../../../shared/widgets/auth_scaffold.dart';
import '../controllers/agency_cnpj_controller.dart';

/// Primeira tela do onboarding de agência.
///
/// Recebe o CNPJ, apresenta feedback visual de consulta e, em caso de sucesso,
/// encaminha o usuário para a etapa de confirmação dos dados fiscais.
class AgencyCnpjPage extends StatefulWidget {
  const AgencyCnpjPage({super.key});

  @override
  State<AgencyCnpjPage> createState() => _AgencyCnpjPageState();
}

class _AgencyCnpjPageState extends State<AgencyCnpjPage> {
  late final AgencyCnpjController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AgencyCnpjController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final et = EanTrackTheme.of(context);

          return Column(
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
                'Usaremos esse dado para localizar a empresa e validar o cadastro da ag\u00EAncia.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: et.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              _CnpjField(
                controller: _controller.textController,
                enabled: _controller.state != CnpjState.loading,
                onChanged: _controller.onChanged,
              ),
              if (_controller.errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                AppErrorBox(_controller.errorMessage!),
              ],
              if (_controller.cnpjModel != null) ...[
                const SizedBox(height: AppSpacing.md),
                _CompanyPreviewCard(
                  razaoSocial: _controller.cnpjModel!.razaoSocial,
                  nomeFantasia: _controller.cnpjModel!.nomeFantasia,
                  situacao: _controller.cnpjModel!.situacaoCadastral,
                  endereco: _controller.cnpjModel!.fullAddress,
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton.action(
                'Consultar CNPJ',
                isLoading: _controller.state == CnpjState.loading,
                onPressed: _controller.state == CnpjState.loading
                    ? null
                    : _controller.consultCnpj,
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
                      'Avan\u00E7ar',
                      onPressed: _controller.canAdvance
                          ? () => context.push(
                                '/onboarding/agency/confirm',
                                extra: _controller.cnpjModel,
                              )
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Campo de entrada de CNPJ com máscara local da própria etapa.
class _CnpjField extends StatelessWidget {
  const _CnpjField({
    required this.controller,
    required this.enabled,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _CnpjInputFormatter(),
      ],
      style: AppTextStyles.bodyMedium.copyWith(color: et.primaryText),
      decoration: InputDecoration(
        labelText: 'CNPJ',
        hintText: '00.000.000/0000-00',
        filled: true,
        fillColor: enabled ? et.inputFill : et.inputFillDisabled,
        enabledBorder: OutlineInputBorder(
          borderRadius: spacing_tokens.AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: spacing_tokens.AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorderFocused, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: spacing_tokens.AppRadius.smAll,
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
        borderRadius: spacing_tokens.AppRadius.smAll,
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
            const SizedBox(height: AppSpacing.xxs),
            Text(
              nomeFantasia,
              style: AppTextStyles.bodySmall.copyWith(color: et.secondaryText),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Situa\u00E7\u00E3o: $situacao',
            style: AppTextStyles.bodySmall.copyWith(color: et.primaryText),
          ),
          if (endereco.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xxs),
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

/// Alias local de espaçamentos para manter consistência visual nesta página.
abstract final class AppSpacing {
  static const double xxs = spacing_tokens.AppSpacing.xs;
  static const double xs = spacing_tokens.AppSpacing.xs;
  static const double sm = spacing_tokens.AppSpacing.sm;
  static const double md = spacing_tokens.AppSpacing.md;
  static const double lg = spacing_tokens.AppSpacing.lg;
  static const double xl = spacing_tokens.AppSpacing.xl;
}
