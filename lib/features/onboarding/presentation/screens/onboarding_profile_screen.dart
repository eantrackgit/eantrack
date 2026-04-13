import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/app_exception.dart';
import '../../../../core/router/app_routes.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../shared/shared.dart';
import '../../data/onboarding_repository.dart';
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

enum _IdentifierStatus {
  idle,
  typing,
  tooShort,
  checking,
  available,
  taken,
  error,
}

class _OnboardingProfileScreenState
    extends ConsumerState<OnboardingProfileScreen> {
  static const int _minIdentifierLength = 10;
  static const int _maxDescriptionLength = 200;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _identifierCtrl = TextEditingController();

  Timer? _identifierDebounce;
  int _identifierRequestId = 0;
  bool _submitting = false;
  _IdentifierStatus _identifierStatus = _IdentifierStatus.idle;
  String? _identifierMessage;
  List<String> _identifierSuggestions = const [];
  String? _confirmedAvailableIdentifier;

  bool get _isAgency => widget.mode == 'agency';

  bool get _canSubmit =>
      !_submitting &&
      _nameCtrl.text.trim().isNotEmpty &&
      _identifierStatus == _IdentifierStatus.available &&
      _confirmedAvailableIdentifier == _normalizeIdentifier(_identifierCtrl.text);

  int get _descriptionLength => _descriptionCtrl.text.length;

  OnboardingRepository get _repository =>
      ref.read(onboardingRepositoryProvider);

  @override
  void dispose() {
    _identifierDebounce?.cancel();
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _identifierCtrl.dispose();
    super.dispose();
  }

  String _normalizeIdentifier(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('@', '');
    return normalized.replaceAll(RegExp(r'[^a-z0-9._-]'), '');
  }

  void _onNameChanged(String _) {
    if (mounted) setState(() {});
    final normalized = _normalizeIdentifier(_identifierCtrl.text);
    if (_identifierStatus == _IdentifierStatus.taken) {
      _scheduleIdentifierValidation(forceRefreshSuggestions: true);
      return;
    }
    if (_identifierStatus == _IdentifierStatus.tooShort &&
        normalized.isNotEmpty &&
        normalized.length < _minIdentifierLength) {
      setState(() {
        _identifierSuggestions = _buildUncheckedSuggestions(normalized);
      });
    }
  }

  void _onDescriptionChanged(String _) {
    if (mounted) setState(() {});
  }

  void _onIdentifierChanged(String rawValue) {
    final normalized = _normalizeIdentifier(rawValue);
    if (rawValue != normalized) {
      _identifierCtrl.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }

    _identifierDebounce?.cancel();
    _identifierRequestId++;
    _confirmedAvailableIdentifier = null;

    if (!mounted) return;

    if (normalized.isEmpty) {
      setState(() {
        _identifierStatus = _IdentifierStatus.idle;
        _identifierMessage = null;
        _identifierSuggestions = const [];
        _confirmedAvailableIdentifier = null;
      });
      return;
    }

    if (normalized.length < _minIdentifierLength) {
      setState(() {
        _identifierStatus = _IdentifierStatus.typing;
        _identifierMessage = 'Analisando identificador...';
        _identifierSuggestions = const [];
        _confirmedAvailableIdentifier = null;
      });

      final requestId = _identifierRequestId;
      _identifierDebounce = Timer(
        const Duration(milliseconds: 350),
        () => _setTooShortState(
          normalized,
          requestId: requestId,
        ),
      );
      return;
    }

    setState(() {
      _identifierStatus = _IdentifierStatus.checking;
      _identifierMessage = 'Verificando disponibilidade...';
      _identifierSuggestions = const [];
      _confirmedAvailableIdentifier = null;
    });

    _identifierDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _validateIdentifier(
        normalized,
        requestId: _identifierRequestId,
        refreshSuggestions: true,
      ),
    );
  }

  void _scheduleIdentifierValidation({bool forceRefreshSuggestions = false}) {
    final normalized = _normalizeIdentifier(_identifierCtrl.text);
    if (normalized.length < _minIdentifierLength) return;

    _identifierDebounce?.cancel();
    _identifierRequestId++;

    setState(() {
      _identifierStatus = _IdentifierStatus.checking;
      _identifierMessage = 'Verificando disponibilidade...';
      _identifierSuggestions = const [];
      _confirmedAvailableIdentifier = null;
    });

    _identifierDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _validateIdentifier(
        normalized,
        requestId: _identifierRequestId,
        refreshSuggestions: forceRefreshSuggestions,
      ),
    );
  }

  Future<void> _validateIdentifier(
    String normalized, {
    required int requestId,
    required bool refreshSuggestions,
  }) async {
    try {
      final identifierExists = await _repository.identificadorExiste(normalized);
      if (!mounted || requestId != _identifierRequestId) return;
      if (_normalizeIdentifier(_identifierCtrl.text) != normalized) return;

      if (identifierExists) {
        final suggestions = refreshSuggestions
            ? await _generateSuggestions(normalized, requestId)
            : _identifierSuggestions;

        if (!mounted || requestId != _identifierRequestId) return;

        setState(() {
          _identifierStatus = _IdentifierStatus.taken;
          _identifierMessage = 'Esse identificador não está disponível.';
          _identifierSuggestions = suggestions;
          _confirmedAvailableIdentifier = null;
        });
        return;
      }

      setState(() {
        _identifierStatus = _IdentifierStatus.available;
        _identifierMessage = 'Identificador disponível!';
        _identifierSuggestions = const [];
        _confirmedAvailableIdentifier = normalized;
      });
    } on AppException catch (e) {
      if (!mounted || requestId != _identifierRequestId) return;
      setState(() {
        _identifierStatus = _IdentifierStatus.error;
        _identifierMessage = e.message;
        _identifierSuggestions = const [];
        _confirmedAvailableIdentifier = null;
      });
    } catch (_) {
      if (!mounted || requestId != _identifierRequestId) return;
      setState(() {
        _identifierStatus = _IdentifierStatus.error;
        _identifierMessage = 'Não foi possível verificar o identificador agora.';
        _identifierSuggestions = const [];
        _confirmedAvailableIdentifier = null;
      });
    }
  }

  void _setTooShortState(
    String normalized, {
    required int requestId,
  }) {
    if (!mounted || requestId != _identifierRequestId) return;
    if (_normalizeIdentifier(_identifierCtrl.text) != normalized) return;

    setState(() {
      _identifierStatus = _IdentifierStatus.tooShort;
      _identifierMessage = 'Identificador não disponível.';
      _identifierSuggestions = _buildUncheckedSuggestions(normalized);
      _confirmedAvailableIdentifier = null;
    });
  }

  List<String> _buildSuggestionCandidates(String identifier) {
    final nameCandidates = _buildNameDrivenCandidates();
    if (nameCandidates.isNotEmpty) {
      return <String>[
        ...nameCandidates,
        ..._buildIdentifierDrivenCandidates(identifier),
      ];
    }

    return _buildIdentifierDrivenCandidates(identifier);
  }

  List<String> _buildNameDrivenCandidates() {
    final parts = _normalizedNameParts(_nameCtrl.text);
    if (parts.isEmpty) return const [];

    final first = parts.first;
    final last = parts.length > 1 ? parts.last : '';
    final fl = last.isNotEmpty ? '$first$last' : first;

    return <String>[
      fl,                                     // joaosilva
      if (last.isNotEmpty) '$first.$last',    // joao.silva
      if (last.isNotEmpty) '${first}_$last',  // joao_silva
      '${fl}1',                               // joaosilva1
      '$fl.oficial',                          // joaosilva.oficial
      '$fl.pro',                              // joaosilva.pro
    ];
  }

  List<String> _buildIdentifierDrivenCandidates(String identifier) {
    final normalizedIdentifier = _normalizeIdentifier(identifier);
    final base = normalizedIdentifier.replaceAll(RegExp(r'[._-]+'), '');
    final seed = base.isNotEmpty ? base : _normalizedNameToken(_nameCtrl.text);

    return <String>[
      _composeIdentifier(seed, suffix: 'oficial'),
      _composeIdentifier(seed, suffix: 'pro'),
      _composeIdentifier(seed, suffix: 'gestao'),
      _composeIdentifier(seed, suffix: 'negocios'),
      _composeIdentifier(seed, suffix: 'hub'),
      _composeIdentifier(seed, suffix: 'central'),
    ];
  }

  List<String> _buildUncheckedSuggestions(String identifier) {
    final seen = <String>{_normalizeIdentifier(identifier)};
    final results = <String>[];

    for (final candidate in _buildSuggestionCandidates(identifier)) {
      final normalized = _normalizeIdentifier(candidate);
      if (normalized.isEmpty) continue;
      if (!seen.add(normalized)) continue;
      results.add(normalized);
      if (results.length >= 5) break;
    }

    return results.take(5).toList(growable: false);
  }

  Future<List<String>> _generateSuggestions(
    String identifier,
    int requestId,
  ) async {
    final normalizedIdentifier = _normalizeIdentifier(identifier);
    final base = normalizedIdentifier.replaceAll(RegExp(r'[._-]+'), '');
    final candidates = _buildSuggestionCandidates(normalizedIdentifier);

    final results = <String>[];
    final seen = <String>{normalizedIdentifier};

    Future<void> tryAdd(String candidate) async {
      final normalized = _normalizeIdentifier(candidate);
      if (normalized.isEmpty) return;
      if (!seen.add(normalized)) return;
      if (!mounted || requestId != _identifierRequestId) return;

      final exists = await _repository.identificadorExiste(normalized);
      if (!mounted || requestId != _identifierRequestId) return;
      if (!exists) results.add(normalized);
    }

    for (final candidate in candidates) {
      if (results.length >= 5) break;
      await tryAdd(candidate);
    }

    var suffix = 1;
    while (results.length < 5 && suffix <= 10) {
      await tryAdd(_composeIdentifier(base, suffix: '$suffix'));
      suffix++;
    }

    return results.take(5).toList(growable: false);
  }

  String _normalizedNameToken(String value) {
    final parts = _normalizedNameParts(value);
    if (parts.isEmpty) return 'perfil';
    if (parts.length == 1) return parts.first;
    return '${parts.first}${parts.last}';
  }

  List<String> _normalizedNameParts(String value) {
    final normalizedValue = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        ;

    final parts = normalizedValue
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);

    return parts;
  }

  String _composeIdentifier(
    String base, {
    String? prefix,
    String? suffix,
    String separator = '',
  }) {
    final pieces = <String>[
      if (prefix != null && prefix.isNotEmpty) prefix,
      base,
      if (suffix != null && suffix.isNotEmpty) suffix,
    ];

    final compact = pieces
        .map((part) => _normalizeIdentifier(part))
        .where((part) => part.isNotEmpty)
        .join(separator);

    if (compact.length >= _minIdentifierLength) return compact;
    return '${compact}01';
  }

  Future<void> _applySuggestion(String suggestion) async {
    final normalized = _normalizeIdentifier(suggestion);
    _identifierCtrl.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
    _identifierDebounce?.cancel();
    final requestId = ++_identifierRequestId;
    _confirmedAvailableIdentifier = null;
    setState(() {
      _identifierStatus = _IdentifierStatus.checking;
      _identifierMessage = 'Verificando disponibilidade...';
      _identifierSuggestions = const [];
    });
    await _validateIdentifier(
      normalized,
      requestId: requestId,
      refreshSuggestions: false,
    );
  }

  Future<void> _applyTakenStateFromConflict(String normalizedIdentifier) async {
    final requestId = ++_identifierRequestId;
    final suggestions = await _generateSuggestions(normalizedIdentifier, requestId);
    if (!mounted || requestId != _identifierRequestId) return;
    if (_normalizeIdentifier(_identifierCtrl.text) != normalizedIdentifier) return;

    setState(() {
      _identifierStatus = _IdentifierStatus.taken;
      _identifierMessage = 'Esse identificador não está disponível.';
      _identifierSuggestions = suggestions;
      _confirmedAvailableIdentifier = null;
      _submitting = false;
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _identifierStatus != _IdentifierStatus.available) return;

    setState(() => _submitting = true);

    final normalizedIdentifier = _normalizeIdentifier(_identifierCtrl.text);
    final nome = _nameCtrl.text.trim();
    final descricao = _descriptionCtrl.text.trim();

    try {
      final reservado = await _repository.reservarIdentificadorComCadastro(
        normalizedIdentifier,
        nome,
      );

      if (!mounted) return;

      if (!reservado) {
        await _applyTakenStateFromConflict(normalizedIdentifier);
        return;
      }

      await _repository.updateDescricao(descricao);
      if (!mounted) return;

      if (_isAgency) {
        setState(() => _submitting = false);
        context.go(AppRoutes.onboardingCnpj);
        return;
      }

      final user = ref.read(authRepositoryProvider).currentUser;
      if (user != null) {
        await ref.read(authNotifierProvider.notifier).onExternalAuthChange(user);
      }

      if (!mounted) return;
      setState(() => _submitting = false);
      context.go(AppRoutes.hub);
    } on AppException catch (e) {
      if (!mounted) return;
      if (e.message.contains('(23505)')) {
        await _applyTakenStateFromConflict(normalizedIdentifier);
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

  Widget? _buildIdentifierSuffix() {
    switch (_identifierStatus) {
      case _IdentifierStatus.typing:
      case _IdentifierStatus.checking:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2),
          ),
        );
      case _IdentifierStatus.available:
        return const Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 20,
        );
      case _IdentifierStatus.tooShort:
      case _IdentifierStatus.taken:
        return const Icon(
          Icons.error_outline,
          color: AppColors.error,
          size: 20,
        );
      case _IdentifierStatus.error:
        return const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.warning,
          size: 20,
        );
      case _IdentifierStatus.idle:
        return null;
    }
  }

  Color _identifierMessageColor(EanTrackTheme et) {
    switch (_identifierStatus) {
      case _IdentifierStatus.available:
        return AppColors.success;
      case _IdentifierStatus.tooShort:
      case _IdentifierStatus.taken:
      case _IdentifierStatus.error:
        return AppColors.error;
      case _IdentifierStatus.idle:
      case _IdentifierStatus.typing:
      case _IdentifierStatus.checking:
        return et.secondaryText;
    }
  }

  String _identifierSuggestionsTitle() {
    if (_identifierStatus == _IdentifierStatus.tooShort) {
      return 'Sugestões para você';
    }

    if (_identifierStatus == _IdentifierStatus.taken) {
      return 'Outras opções disponíveis';
    }

    return 'Sugestões disponíveis';
  }

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

    return AuthScaffold(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: et.surface,
                  borderRadius: AppRadius.mdAll,
                  border: Border.all(
                    color: et.surfaceBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: et.inputBorderFocused.withValues(alpha: 0.10),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person,
                  color: et.inputBorderFocused,
                  size: 40,
                ),
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
              style: AppTextStyles.bodySmall.copyWith(
                color: et.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: et.primaryText,
                    ),
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
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: et.primaryText,
                    ),
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
                  Text(
                    'Identificador',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: et.primaryText,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  TextFormField(
                    controller: _identifierCtrl,
                    onChanged: _onIdentifierChanged,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9._-]'),
                      ),
                      _LowerCaseTextFormatter(),
                    ],
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: et.primaryText,
                    ),
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
                        borderSide: BorderSide(
                          color: _identifierStatus == _IdentifierStatus.taken ||
                                  _identifierStatus ==
                                      _IdentifierStatus.tooShort ||
                                  _identifierStatus == _IdentifierStatus.error
                              ? AppColors.error
                              : et.inputBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.smAll,
                        borderSide: BorderSide(
                          color: _identifierStatus == _IdentifierStatus.available
                              ? AppColors.success
                              : _identifierStatus ==
                                          _IdentifierStatus.taken ||
                                      _identifierStatus ==
                                          _IdentifierStatus.tooShort ||
                                      _identifierStatus ==
                                          _IdentifierStatus.error
                                  ? AppColors.error
                                  : et.inputBorderFocused,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  if (_identifierMessage != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _identifierMessage!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: _identifierMessageColor(et),
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (_identifierSuggestions.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      _identifierSuggestionsTitle(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: et.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: _identifierSuggestions.map((suggestion) {
                        return InkWell(
                          onTap: () => _applySuggestion(suggestion),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: et.surface,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: et.surfaceBorder),
                            ),
                            child: Text(
                              suggestion,
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
                      leadingIcon: const Icon(
                        Icons.arrow_back_ios,
                        size: 14,
                      ),
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
                          : const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                            ),
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
