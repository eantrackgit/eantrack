import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../shared/theme/app_colors.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/auth_scaffold.dart';

class CnpjScreen extends StatefulWidget {
  const CnpjScreen({super.key});

  @override
  State<CnpjScreen> createState() => _CnpjScreenState();
}

class _CnpjScreenState extends State<CnpjScreen> {
  final _controller = TextEditingController();
  bool _submitted = false;
  bool _accepted = false;
  _CnpjStatus _status = _CnpjStatus.idle;
  String? _statusMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validateCnpj() {
    if (!_submitted) return null;
    final raw = _controller.text.replaceAll(RegExp(r'[^\d]'), '');
    if (raw.isEmpty) return 'Informe o CNPJ.';
    if (raw.length != 14) return 'CNPJ inválido. Use o formato XX.XXX.XXX/XXXX-XX.';
    return null;
  }

  Future<void> _consultar() async {
    final raw = _controller.text.replaceAll(RegExp(r'[^\d]'), '');
    if (raw.length != 14) {
      setState(() {
        _submitted = true;
        _status = _CnpjStatus.error;
        _statusMessage = 'CNPJ inválido. Verifique e tente novamente.';
      });
      return;
    }

    setState(() => _status = _CnpjStatus.loading);

    // Placeholder — integração real em tarefa futura
    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _status = _CnpjStatus.success;
      _statusMessage = 'CNPJ encontrado. Verifique os dados na próxima etapa.';
    });
  }

  void _onAdvance() {
    setState(() => _submitted = true);
    final cnpjError = _validateCnpj();
    if (cnpjError != null) return;
    if (!_accepted) return;
    if (_status != _CnpjStatus.success) return;

    context.go(AppRoutes.onboardingAgency);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Dados da Agência',
      subtitle: 'Informe o CNPJ da sua empresa para iniciar o cadastro.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CnpjField(
            controller: _controller,
            errorText: _submitted ? _validateCnpj() : null,
            onChanged: (_) => setState(() => _statusMessage = null),
          ),
          const SizedBox(height: AppSpacing.sm),
          AppButton.action(
            'Consultar CNPJ',
            leadingIcon: const Icon(Icons.search, size: 18, color: AppColors.info),
            isLoading: _status == _CnpjStatus.loading,
            onPressed: _status == _CnpjStatus.loading ? null : _consultar,
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _StatusMessage(message: _statusMessage!, status: _status),
          ],
          const SizedBox(height: AppSpacing.md),
          _AcceptCheckbox(
            accepted: _accepted,
            hasError: _submitted && !_accepted,
            onChanged: (v) => setState(() => _accepted = v ?? false),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  '← Voltar',
                  onPressed: () => context.go(AppRoutes.onboarding),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton.primary(
                  'Avançar →',
                  onPressed: _status == _CnpjStatus.loading ? null : _onAdvance,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Widgets privados
// ---------------------------------------------------------------------------

class _CnpjField extends StatelessWidget {
  const _CnpjField({
    required this.controller,
    required this.onChanged,
    this.errorText,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        _CnpjInputFormatter(),
      ],
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: 'CNPJ',
        hintText: 'XX.XXX.XXX/XXXX-XX',
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: AppRadius.smAll),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: const BorderSide(color: AppColors.secondary, width: 1.5),
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, required this.status});
  final String message;
  final _CnpjStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      _CnpjStatus.success => AppColors.success,
      _CnpjStatus.error => AppColors.error,
      _ => AppColors.secondaryText,
    };

    final icon = switch (status) {
      _CnpjStatus.success => Icons.check_circle_outline,
      _CnpjStatus.error => Icons.error_outline,
      _ => Icons.info_outline,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: AppRadius.smAll,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptCheckbox extends StatelessWidget {
  const _AcceptCheckbox({
    required this.accepted,
    required this.hasError,
    required this.onChanged,
  });

  final bool accepted;
  final bool hasError;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: accepted,
                activeColor: AppColors.secondary,
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Confirmo que os dados do CNPJ correspondem à minha empresa e aceito os termos de cadastro.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 32),
            child: Text(
              'Aceite os termos para continuar.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

enum _CnpjStatus { idle, loading, success, error }

/// Formata input como XX.XXX.XXX/XXXX-XX
class _CnpjInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 14; i++) {
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
