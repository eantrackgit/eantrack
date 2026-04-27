import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../auth/domain/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/shared.dart';
import '../controllers/agency_confirm_controller.dart';
import '../controllers/agency_representative_controller.dart';
import '../services/agency_confirm_service.dart';
import '../models/agency_confirm_payload.dart';
import '../models/agency_representative_model.dart';
import '../controllers/agency_status_notifier.dart';
import '../widgets/attachment_drop_area.dart';

/// Tela de cadastro do representante legal da agência.
class AgencyRepresentativeScreen extends ConsumerWidget {
  const AgencyRepresentativeScreen({
    super.key,
    this.payload,
    this.prefillData,
  });

  final AgencyConfirmPayload? payload;
  final AgencyStatusData? prefillData;

  Future<void> _handleAdvance(
    BuildContext context,
    AgencyRepresentativeNotifier notifier,
  ) async {
    final ok = await notifier.submit();
    if (!context.mounted || !ok) return;

    context.pushReplacement(AppRoutes.onboardingAgencyStatus);
  }

  Future<void> _handleDocumentTypeSelection(
    BuildContext context,
    AgencyRepresentativeNotifier notifier,
    AgencyRepresentativeState state,
    AgencyRepresentativeDocumentType type,
  ) async {
    final hasAttachedFiles = state.frontFile != null ||
        state.backFile != null ||
        state.attachmentFile != null;

    if (!hasAttachedFiles || state.selectedDocumentType == type) {
      notifier.selectDocumentType(type);
      return;
    }

    final shouldChange = await showDialog<bool>(
          context: context,
          builder: (context) => const _ChangeDocumentTypeDialog(),
        ) ??
        false;

    if (!shouldChange || !context.mounted) return;
    notifier.selectDocumentType(type);
  }

  Future<void> _handleBack(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (context.canPop()) {
      context.pop();
      return;
    }

    final payloadAgencyId = payload?.agencyId.trim();
    var agencyId = payloadAgencyId == null || payloadAgencyId.isEmpty
        ? null
        : payloadAgencyId;

    if (agencyId == null) {
      final authState = ref.read(authNotifierProvider);
      if (authState is AuthAuthenticated) {
        final flowAgencyId = authState.flowState?.agencyId?.trim();
        if (flowAgencyId != null && flowAgencyId.isNotEmpty) {
          agencyId = flowAgencyId;
        }
      }
    }

    if (agencyId == null || agencyId.isEmpty) {
      context.go(AppRoutes.onboardingAgencyCnpj);
      return;
    }

    try {
      final recoveryData = await AgencyConfirmService().fetchAgencyForEdit(
        agencyId,
      );
      if (!context.mounted) return;

      AgencyConfirmNotifier.seedRecovery(recoveryData);
      context.go(
        AppRoutes.onboardingAgencyConfirm,
        extra: recoveryData.cnpjModel,
      );
    } on AgencyConfirmServiceException catch (e) {
      if (!context.mounted) return;
      await AppFeedback.showError(
        context,
        title: 'Falha ao voltar',
        message: e.message,
      );
    } catch (_) {
      if (!context.mounted) return;
      await AppFeedback.showError(
        context,
        title: 'Falha ao voltar',
        message: 'Nao foi possivel carregar os dados da agencia.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(agencyRepresentativeProvider(payload));
    final notifier = ref.read(agencyRepresentativeProvider(payload).notifier);
    final et = EanTrackTheme.of(context);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (prefillData != null) {
        notifier.prefill(prefillData!);
      }
    });

    return AuthScaffold(
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
                Icons.badge_rounded,
                size: 42,
                color: AppColors.secondary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Cadastre o representante legal',
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineSmall.copyWith(
              color: et.primaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Esses dados serão usados para validar a responsabilidade legal da agência.',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: et.secondaryText,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SectionCard(
            title: 'DADOS PESSOAIS E CARGO',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AppTextField(
                  label: 'Nome Completo',
                  hintText: 'Ex: João da Silva',
                  controller: notifier.fullNameController,
                  errorText: state.fullNameError,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.sm),
                _AppTextField(
                  label: 'CPF',
                  hintText: '000.000.000-00',
                  controller: notifier.cpfController,
                  focusNode: notifier.cpfFocusNode,
                  keyboardType: TextInputType.number,
                  errorText: state.cpfError,
                  onEditingComplete: notifier.onCpfEditingComplete,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CpfInputFormatter(),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _RoleDropdown(
                  value: state.selectedRole,
                  errorText: state.roleError,
                  onChanged: notifier.updateRole,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'CONTATO',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AppTextField(
                  label: 'Telefone do representante',
                  hintText: '(11) 9 9999-9999',
                  controller: notifier.phoneController,
                  keyboardType: TextInputType.phone,
                  errorText: state.phoneError,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    const PhoneInputFormatter(),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                _AppTextField(
                  label: 'E-mail',
                  hintText: 'joao.silva@suaempresa.com.br',
                  controller: notifier.emailController,
                  keyboardType: TextInputType.emailAddress,
                  errorText: state.emailError,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'DOCUMENTO COM FOTO',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _DocumentTypeSelector(
                  selectedType: state.selectedDocumentType,
                  onSelected: (type) => _handleDocumentTypeSelection(
                    context,
                    notifier,
                    state,
                    type,
                  ),
                ),
                if (state.documentTypeError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.documentTypeError!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
                if (state.selectedDocumentType != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  ..._buildAttachmentFields(notifier, state),
                ],
                if (state.documentsError != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    state.documentsError!,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            AppErrorBox(state.errorMessage!),
          ],
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: AppButton.secondary(
                  'Voltar',
                  onPressed: state.isSubmitting
                      ? null
                      : () => _handleBack(context, ref),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton.primary(
                  'Avançar',
                  isLoading: state.isSubmitting,
                  trailingIcon: state.isSubmitting
                      ? null
                      : const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                  onPressed: (state.canAdvance && !state.isSubmitting)
                      ? () => _handleAdvance(context, notifier)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAttachmentFields(
    AgencyRepresentativeNotifier notifier,
    AgencyRepresentativeState state,
  ) {
    final type = state.selectedDocumentType;
    if (type == null) return const <Widget>[];

    if (type.requiresFrontAndBack) {
      return [
        AttachmentDropArea(
          label: 'FRENTE',
          file: state.frontFile,
          copyText: 'JPG, PNG ou PDF • max. 5MB',
          acceptsPdfOnly: false,
          onAttach: () =>
              notifier.pickFile(AgencyRepresentativeAttachmentSlot.front),
          onDroppedFile: (file) => notifier.receiveDroppedFile(
            AgencyRepresentativeAttachmentSlot.front,
            file,
          ),
          onRemove: () =>
              notifier.removeFile(AgencyRepresentativeAttachmentSlot.front),
        ),
        const SizedBox(height: AppSpacing.sm),
        AttachmentDropArea(
          label: 'VERSO',
          file: state.backFile,
          copyText: 'JPG, PNG ou PDF • max. 5MB',
          acceptsPdfOnly: false,
          onAttach: () =>
              notifier.pickFile(AgencyRepresentativeAttachmentSlot.back),
          onDroppedFile: (file) => notifier.receiveDroppedFile(
            AgencyRepresentativeAttachmentSlot.back,
            file,
          ),
          onRemove: () =>
              notifier.removeFile(AgencyRepresentativeAttachmentSlot.back),
        ),
      ];
    }

    return [
      AttachmentDropArea(
        label: 'ANEXO',
        file: state.attachmentFile,
        copyText: 'PDF • max. 5MB',
        acceptsPdfOnly: true,
        onAttach: () =>
            notifier.pickFile(AgencyRepresentativeAttachmentSlot.attachment),
        onDroppedFile: (file) => notifier.receiveDroppedFile(
          AgencyRepresentativeAttachmentSlot.attachment,
          file,
        ),
        onRemove: () =>
            notifier.removeFile(AgencyRepresentativeAttachmentSlot.attachment),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Form widgets
// ---------------------------------------------------------------------------

class _AppTextField extends StatelessWidget {
  const _AppTextField({
    required this.label,
    required this.controller,
    this.hintText,
    this.errorText,
    this.focusNode,
    this.onEditingComplete,
    this.keyboardType,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? hintText;
  final String? errorText;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onEditingComplete: onEditingComplete,
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

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.value,
    required this.onChanged,
    this.errorText,
  });

  final String? value;
  final ValueChanged<String?> onChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final dropdownTextStyle = AppTextStyles.bodyMedium.copyWith(
      color: et.primaryText,
    );
    final dropdownHintStyle = AppTextStyles.bodyMedium.copyWith(
      color: et.secondaryText.withValues(alpha: 0.72),
    );

    return DropdownButtonFormField<String>(
      key: ValueKey(value),
      value: value,
      style: dropdownTextStyle,
      hint: Text(
        'Selecione o cargo',
        style: dropdownHintStyle,
      ),
      decoration: InputDecoration(
        labelText: 'Cargo',
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
      items: AgencyRepresentativeNotifier.roles
          .map(
            (role) => DropdownMenuItem<String>(
              value: role,
              child: Text(role, style: dropdownTextStyle),
            ),
          )
          .toList(growable: false),
      onChanged: onChanged,
    );
  }
}

class _DocumentTypeSelector extends StatelessWidget {
  const _DocumentTypeSelector({
    required this.selectedType,
    required this.onSelected,
  });

  final AgencyRepresentativeDocumentType? selectedType;
  final ValueChanged<AgencyRepresentativeDocumentType> onSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;
        final children = AgencyRepresentativeDocumentType.values
            .map(
              (type) => isCompact
                  ? _DocumentChoiceButton(
                      type: type,
                      isSelected: selectedType == type,
                      onPressed: () => onSelected(type),
                    )
                  : Expanded(
                      child: _DocumentChoiceButton(
                        type: type,
                        isSelected: selectedType == type,
                        onPressed: () => onSelected(type),
                      ),
                    ),
            )
            .toList(growable: false);

        if (isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              children[0],
              const SizedBox(height: AppSpacing.sm),
              children[1],
              const SizedBox(height: AppSpacing.sm),
              children[2],
            ],
          );
        }

        return Row(
          children: [
            children[0],
            const SizedBox(width: AppSpacing.sm),
            children[1],
            const SizedBox(width: AppSpacing.sm),
            children[2],
          ],
        );
      },
    );
  }
}

class _DocumentChoiceButton extends StatelessWidget {
  const _DocumentChoiceButton({
    required this.type,
    required this.isSelected,
    required this.onPressed,
  });

  final AgencyRepresentativeDocumentType type;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final borderColor = isSelected ? AppColors.actionBlue : et.surfaceBorder;
    final backgroundColor = isSelected
        ? AppColors.actionBlue.withValues(alpha: 0.08)
        : et.surface;

    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: isSelected ? AppColors.actionBlue : et.primaryText,
          side: BorderSide(color: borderColor, width: isSelected ? 1.5 : 1),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        ),
        child: Text(
          type.label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.actionBlue : et.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog de confirmação de troca de tipo de documento
// ---------------------------------------------------------------------------

/// Dialog exibido quando o usuário tenta trocar o tipo de documento com
/// arquivos já anexados. Pergunta se deseja descartar os anexos atuais.
class _ChangeDocumentTypeDialog extends StatelessWidget {
  const _ChangeDocumentTypeDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 40,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.error,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Trocar tipo de documento',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Os arquivos anexados serão removidos. Deseja continuar?',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.actionBlue,
                    side: const BorderSide(color: AppColors.actionBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.smAll,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Continuar anexando'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppRadius.smAll,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Trocar e remover'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Formatters locais
// ---------------------------------------------------------------------------

class _CpfInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length && i < 11; i++) {
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
