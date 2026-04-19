import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/shared.dart';
import '../controllers/agency_confirm_controller.dart';
import '../models/cnpj_model.dart';

/// Tela de confirmação e complementação dos dados da agência.
///
/// Exibe os dados fiscais vindos do CNPJ consultado, permite ajustes
/// complementares e dispara o salvamento final da agência.
class AgencyConfirmPage extends StatefulWidget {
  const AgencyConfirmPage({
    super.key,
    required this.cnpjModel,
  });

  final CnpjModel cnpjModel;

  @override
  State<AgencyConfirmPage> createState() => _AgencyConfirmPageState();
}

class _AgencyConfirmPageState extends State<AgencyConfirmPage> {
  static const String _placeholderNextRoute =
      '/onboarding/agency/representative';

  late final AgencyConfirmController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AgencyConfirmController(cnpjModel: widget.cnpjModel);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Tenta salvar a agência e, em caso de sucesso, avança para a próxima etapa.
  Future<void> _handleAdvance() async {
    final ok = await _controller.submit();
    if (!mounted || !ok) return;

    context.push(
      _placeholderNextRoute,
      extra: _controller.buildPayload(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final et = EanTrackTheme.of(context);
          final isActive =
              widget.cnpjModel.situacaoCadastral.trim().toUpperCase() == 'ATIVA';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.actionBlue.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
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
                'Essas informacoes serao usadas para validar sua conta.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall.copyWith(
                  color: et.secondaryText,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              _SectionCard(
                title: 'DADOS FISCAIS',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _EditableField(
                      label: 'Nome Fantasia',
                      controller: _controller.fantasyNameController,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ReadonlyField(
                      label: 'Razao Social',
                      value: widget.cnpjModel.razaoSocial,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _ReadonlyField(
                            label: 'CNPJ',
                            value: widget.cnpjModel.formattedCnpj,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Align(
                            alignment: Alignment.center,
                            child: _StatusCard(
                              label: 'Situacao Cadastral',
                              value: widget.cnpjModel.situacaoCadastral,
                              isActive: isActive,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isActive) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const AppErrorBox(
                        'Nao e possivel continuar com um CNPJ inativo.',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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
                          controller: _controller.phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _PhoneInputFormatter(),
                          ],
                          errorText: _controller.phoneError,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _EditableField(
                          label: 'E-mail',
                          controller: _controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _controller.emailError,
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
                          controller: _controller.phoneController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _PhoneInputFormatter(),
                          ],
                          errorText: _controller.phoneError,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _EditableField(
                          label: 'E-mail',
                          controller: _controller.emailController,
                          keyboardType: TextInputType.emailAddress,
                          errorText: _controller.emailError,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              const _SectionTitle('ENDERECO DA EMPRESA'),
              const SizedBox(height: AppSpacing.sm),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _EditableField(
                        label: 'CEP',
                        controller: _controller.cepController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => _controller.clearCepMessage(),
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
                        isLoading: _controller.isSearchingCep,
                        onPressed: _controller.isSearchingCep
                            ? null
                            : () => _controller.searchCep(),
                      ),
                    ),
                  ],
                ),
              ),
              if (_controller.cepMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                AppErrorBox(_controller.cepMessage!),
              ],
              const SizedBox(height: AppSpacing.sm),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _EditableField(
                      label: 'Logradouro',
                      controller: _controller.logradouroController,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 110,
                    child: _EditableField(
                      label: 'Numero',
                      controller: _controller.numeroController,
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
                      controller: _controller.bairroController,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 2,
                    child: _EditableField(
                      label: 'Municipio',
                      controller: _controller.municipioController,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 110,
                    child: _EditableField(
                      label: 'UF',
                      controller: _controller.ufController,
                      textCapitalization: TextCapitalization.characters,
                    ),
                  ),
                ],
              ),
              if (_controller.submitErrorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppErrorBox(_controller.submitErrorMessage!),
              ],
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: AppButton.secondary(
                      'Voltar',
                      onPressed: _controller.isSubmitting
                          ? null
                          : () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppButton.primary(
                      'Avancar',
                      isLoading: _controller.isSubmitting,
                      trailingIcon: _controller.isSubmitting
                          ? null
                          : const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                            ),
                      onPressed: (_controller.canAdvance &&
                              isActive &&
                              !_controller.isSubmitting)
                          ? _handleAdvance
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

/// Agrupa visualmente cada seção principal do formulário.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: et.surface.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: et.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitle(title),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
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
    this.errorText,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
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

/// Formata o telefone no padrão visual esperado pela tela.
class _PhoneInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length && i < 11; i++) {
      if (i == 0) buffer.write('(');
      if (i == 2) buffer.write(') ');
      if (i == 3) buffer.write(' ');
      if (i == 7) buffer.write('-');
      buffer.write(digits[i]);
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
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
