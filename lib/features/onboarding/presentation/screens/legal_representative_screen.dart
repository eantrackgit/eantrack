import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/shared.dart';

class LegalRepresentativeScreen extends ConsumerStatefulWidget {
  const LegalRepresentativeScreen({super.key});

  @override
  ConsumerState<LegalRepresentativeScreen> createState() =>
      _LegalRepresentativeScreenState();
}

class _LegalRepresentativeScreenState
    extends ConsumerState<LegalRepresentativeScreen>
    with FormStateMixin<LegalRepresentativeScreen> {
  final _cpfCtrl = TextEditingController();
  final _rgCtrl = TextEditingController();
  final _birthCtrl = TextEditingController();
  final _orgCtrl = TextEditingController();
  bool _termsAccepted = false;

  @override
  void dispose() {
    _cpfCtrl.dispose();
    _rgCtrl.dispose();
    _birthCtrl.dispose();
    _orgCtrl.dispose();
    super.dispose();
  }

  void _onAdvance() {
    if (!validateAndSubmit()) return;
    if (!_termsAccepted) {
      setState(() {});
      return;
    }
    debugPrint('[ONBOARDING] Legal rep saved, advancing to hub');
    context.go(AppRoutes.hub);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Representante Legal',
      subtitle: 'Preencha os dados do responsável legal pela agência.',
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(
              controller: _cpfCtrl,
              label: 'CPF',
              hint: '000.000.000-00',
              formatter: _CpfInputFormatter(),
              validator: (v) => requiredValidator(v, 'o CPF'),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _rgCtrl,
              label: 'RG',
              hint: '00.000.000-0',
              validator: (v) => requiredValidator(v, 'o RG'),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _birthCtrl,
              label: 'Data de Nascimento',
              hint: 'DD/MM/AAAA',
              keyboardType: TextInputType.datetime,
              formatter: _DateInputFormatter(),
              validator: (v) => requiredValidator(v, 'a data de nascimento'),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              controller: _orgCtrl,
              label: 'Órgão Expedidor do RG',
              hint: 'Ex: SSP/MG',
              validator: (v) => requiredValidator(v, 'o órgão expedidor'),
            ),
            const SizedBox(height: AppSpacing.lg),
            const _DocumentUploadPlaceholder(),
            const SizedBox(height: AppSpacing.lg),
            _TermsCheckbox(
              accepted: _termsAccepted,
              hasError: submitted && !_termsAccepted,
              onChanged: (v) => setState(() => _termsAccepted = v ?? false),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(
                    'Voltar',
                    onPressed: () async {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (!context.mounted) return;
                      context.go(AppRoutes.login);
                    },
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppButton.primary(
                    'Finalizar',
                    onPressed: _onAdvance,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    String? hint,
    TextInputType? keyboardType,
    TextInputFormatter? formatter,
  }) {
    final et = EanTrackTheme.of(context);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: formatter != null ? [formatter] : null,
      style: AppTextStyles.bodyMedium.copyWith(color: et.primaryText),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: et.inputFill,
        border: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorderFocused, width: 1.5),
        ),
      ),
    );
  }
}

class _DocumentUploadPlaceholder extends StatelessWidget {
  const _DocumentUploadPlaceholder();

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: et.surface,
        borderRadius: AppRadius.smAll,
        border: Border.all(color: et.surfaceBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.upload_file_outlined, color: et.secondaryText),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload de documentos',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: et.primaryText,
                  ),
                ),
                Text(
                  'RG, CPF, Contrato Social — disponível em breve.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: et.secondaryText,
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

class _TermsCheckbox extends StatelessWidget {
  const _TermsCheckbox({
    required this.accepted,
    required this.hasError,
    required this.onChanged,
  });

  final bool accepted;
  final bool hasError;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

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
                activeColor: et.ctaBackground,
                checkColor: et.ctaForeground,
                side: BorderSide(
                  color: hasError ? AppColors.error : et.surfaceBorder,
                ),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Declaro que sou o representante legal desta empresa e que as informações fornecidas são verdadeiras.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: et.primaryText,
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

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _DateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 8; i++) {
      if (i == 2 || i == 4) buffer.write('/');
      buffer.write(digits[i]);
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
