import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../shared/shared.dart';
import '../../data/onboarding_repository.dart';
import '../controllers/identifier_controller.dart';
import '../providers/onboarding_provider.dart';

class OnboardingProfileScreen extends ConsumerStatefulWidget {
  const OnboardingProfileScreen({
    super.key,
    this.mode = 'individual',
  });

  final String mode;

  @override
  ConsumerState<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState
    extends ConsumerState<OnboardingProfileScreen> {
  static const int _maxDescriptionLength = 200;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  late final IdentifierController _identifierController;
  bool _submitting = false;

  bool get _canSubmit =>
      !_submitting &&
      _nameCtrl.text.trim().isNotEmpty &&
      _identifierController.status == IdentifierStatus.available &&
      _identifierController.confirmedAvailable ==
          IdentifierController.normalize(_identifierController.textController.text);

  int get _descriptionLength => _descriptionCtrl.text.length;

  OnboardingRepository get _repository =>
      ref.read(onboardingRepositoryProvider);

  String get _photoProfileLocation => Uri(
        path: AppRoutes.photoProfile,
        queryParameters: {'mode': widget.mode},
      ).toString();

  @override
  void initState() {
    super.initState();
    _identifierController = IdentifierController(
      checkExists: ref.read(onboardingRepositoryProvider).identificadorExiste,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged(String value) {
    setState(() {});
    _identifierController.onNameChanged(value);
  }

  void _onDescriptionChanged(String _) {
    if (mounted) setState(() {});
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _identifierController.status != IdentifierStatus.available) {
      return;
    }

    setState(() => _submitting = true);

    final normalizedIdentifier =
        IdentifierController.normalize(_identifierController.textController.text);
    final nome = _nameCtrl.text.trim();
    final descricao = _descriptionCtrl.text.trim();

    try {
      final reservado = await _repository.reservarIdentificadorComCadastro(
        normalizedIdentifier,
        nome,
      );

      if (!mounted) return;

      if (!reservado) {
        await _identifierController.applyTakenStateFromConflict(normalizedIdentifier);
        if (!mounted) return;
        setState(() => _submitting = false);
        return;
      }

      await _repository.updateDescricao(descricao);
      if (!mounted) return;

      if (!mounted) return;
      setState(() => _submitting = false);
      context.go(_photoProfileLocation);
    } on AppException catch (e) {
      if (!mounted) return;
      if (e.message.contains('(23505)')) {
        await _identifierController.applyTakenStateFromConflict(normalizedIdentifier);
        if (!mounted) return;
        setState(() => _submitting = false);
        return;
      }
      setState(() => _submitting = false);
      await AppFeedback.showError(
        context,
        title: 'Erro ao avançar',
        message: e.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      await AppFeedback.showError(
        context,
        title: 'Erro ao avançar',
        message: 'Não foi possível concluir esta etapa agora.',
      );
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Informe o nome.';
    }
    return null;
  }

  // -------------------------------------------------------------------------
  // Helpers de UI do identificador
  // -------------------------------------------------------------------------

  Widget? _buildIdentifierSuffix() {
    switch (_identifierController.status) {
      case IdentifierStatus.typing:
      case IdentifierStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        );
      case IdentifierStatus.available:
        return const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 20,
        );
      case IdentifierStatus.tooShort:
      case IdentifierStatus.taken:
        return const Icon(
          Icons.error_outline,
          color: AppColors.error,
          size: 20,
        );
      case IdentifierStatus.error:
        return const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: 20,
        );
      case IdentifierStatus.idle:
        return null;
    }
  }

  Color _identifierMessageColor(EanTrackTheme et) {
    switch (_identifierController.status) {
      case IdentifierStatus.available:
        return AppColors.success;
      case IdentifierStatus.tooShort:
      case IdentifierStatus.taken:
      case IdentifierStatus.error:
        return AppColors.error;
      case IdentifierStatus.idle:
      case IdentifierStatus.typing:
      case IdentifierStatus.checking:
        return et.secondaryText;
    }
  }

  String _identifierSuggestionsTitle() {
    if (_identifierController.status == IdentifierStatus.tooShort) {
      return 'Sugestões para você';
    }
    if (_identifierController.status == IdentifierStatus.taken) {
      return 'Outras opções disponíveis';
    }
    return 'Sugestões disponíveis';
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  static const _fieldContentPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 15);

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    // Exceção intencional: TextFormField raw é usado nesta tela porque:
    // - O campo identificador exige border dinâmico por status (taken/available/error),
    //   não suportado por AppTextField.
    // - O campo descrição exige maxLines e buildCounter customizado,
    //   também não suportados por AppTextField.
    // Todos os tokens de cor e borda seguem EanTrackTheme e AppColors (semânticos).
    final fieldBorder = OutlineInputBorder(
      borderRadius: AppRadius.smAll,
      borderSide: BorderSide(color: et.inputBorder),
    );
    final fieldFocusedBorder = OutlineInputBorder(
      borderRadius: AppRadius.smAll,
      borderSide: BorderSide(color: et.inputBorderFocused, width: 1.5),
    );
    final fieldErrorBorder = OutlineInputBorder(
      borderRadius: AppRadius.smAll,
      borderSide: const BorderSide(color: AppColors.error),
    );
    final fieldFocusedErrorBorder = OutlineInputBorder(
      borderRadius: AppRadius.smAll,
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    );

    final identifierStatus = _identifierController.status;
    final identifierBorderColor = identifierStatus == IdentifierStatus.taken ||
            identifierStatus == IdentifierStatus.tooShort ||
            identifierStatus == IdentifierStatus.error
        ? AppColors.error
        : et.inputBorder;
    final identifierFocusedBorderColor =
        identifierStatus == IdentifierStatus.available
            ? AppColors.success
            : identifierStatus == IdentifierStatus.taken ||
                    identifierStatus == IdentifierStatus.tooShort ||
                    identifierStatus == IdentifierStatus.error
                ? AppColors.error
                : et.inputBorderFocused;

    return AuthScaffold(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(et: et),
            const SizedBox(height: AppSpacing.lg),
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: et.surface,
                borderRadius: AppRadius.mdAll,
                border: Border.all(color: et.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Nome
                  Text(
                    'Digite seu nome*',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: et.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _nameCtrl,
                    onChanged: _onNameChanged,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: _validateName,
                    style: AppTextStyles.bodyMedium.copyWith(color: et.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Digite seu nome completo',
                      contentPadding: _fieldContentPadding,
                      filled: true,
                      fillColor: et.inputFill,
                      border: fieldBorder,
                      enabledBorder: fieldBorder,
                      focusedBorder: fieldFocusedBorder,
                      errorBorder: fieldErrorBorder,
                      focusedErrorBorder: fieldFocusedErrorBorder,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Descrição
                  Text(
                    'Descrição',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: et.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: _descriptionCtrl,
                    onChanged: _onDescriptionChanged,
                    maxLength: _maxDescriptionLength,
                    maxLines: 3,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: AppTextStyles.bodyMedium.copyWith(color: et.primaryText),
                    buildCounter: (
                      context, {
                      required int currentLength,
                      required bool isFocused,
                      required int? maxLength,
                    }) {
                      return const SizedBox.shrink();
                    },
                    decoration: InputDecoration(
                      hintText: 'Destaque sua experiência ou cargo',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      filled: true,
                      fillColor: et.inputFill,
                      alignLabelWithHint: true,
                      border: fieldBorder,
                      enabledBorder: fieldBorder,
                      focusedBorder: fieldFocusedBorder,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '$_descriptionLength/$_maxDescriptionLength',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: et.secondaryText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Identificador
                  Text(
                    'Identificador',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: et.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _identifierController.textController,
                    onChanged: _identifierController.onChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9._-]'),
                      ),
                      _LowerCaseTextFormatter(),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: AppTextStyles.bodyMedium.copyWith(color: et.primaryText),
                    decoration: InputDecoration(
                      hintText: 'Escolha seu identificador',
                      contentPadding: _fieldContentPadding,
                      prefixIcon: Icon(
                        Icons.alternate_email_rounded,
                        color: et.inputBorderFocused,
                        size: 22,
                      ),
                      suffixIcon: _buildIdentifierSuffix(),
                      filled: true,
                      fillColor: et.inputFill,
                      border: fieldBorder,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.smAll,
                        borderSide: BorderSide(color: identifierBorderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.smAll,
                        borderSide: BorderSide(
                          color: identifierFocusedBorderColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (_identifierController.message != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _identifierController.message!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _identifierMessageColor(et),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (_identifierController.suggestions.isNotEmpty)
                    _IdentifierSuggestions(
                      suggestions: _identifierController.suggestions,
                      title: _identifierSuggestionsTitle(),
                      onTap: _identifierController.applySuggestion,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: AppButton.secondary(
                      'Voltar',
                      leadingIcon: const Icon(Icons.arrow_back_ios, size: 14),
                      onPressed: _submitting
                          ? null
                          : () => context.go(AppRoutes.onboarding),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: AppButton.primary(
                      'Avançar',
                      trailingIcon: _submitting
                          ? null
                          : const Icon(Icons.arrow_forward_ios, size: 14),
                      isLoading: _submitting,
                      onPressed: _canSubmit ? _submit : null,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.et});
  final EanTrackTheme et;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: et.surface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(color: et.surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: et.inputBorderFocused.withValues(alpha: 0.10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.person, color: et.inputBorderFocused, size: 40),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Complete seu perfil para continuar',
          style: AppTextStyles.headlineSmall.copyWith(
            color: et.primaryText,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Leva menos de 1 minuto',
          style: AppTextStyles.bodySmall.copyWith(color: et.secondaryText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _IdentifierSuggestions extends StatelessWidget {
  const _IdentifierSuggestions({
    required this.suggestions,
    required this.title,
    required this.onTap,
  });

  final List<String> suggestions;
  final String title;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.xs),
        Text(
          title,
          style: AppTextStyles.bodySmall.copyWith(
            color: et.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: suggestions.map((s) {
            return InkWell(
              onTap: () => onTap(s),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: et.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: et.surfaceBorder),
                ),
                child: Text(
                  s,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: et.secondaryText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(growable: false),
        ),
      ],
    );
  }
}

class _LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final lower = newValue.text.toLowerCase();
    return TextEditingValue(
      text: lower,
      selection: TextSelection.collapsed(offset: lower.length),
    );
  }
}
