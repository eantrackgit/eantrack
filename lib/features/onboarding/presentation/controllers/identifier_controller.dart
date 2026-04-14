import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/error/app_exception.dart';

/// Status do identificador durante o preenchimento e validação assíncrona.
enum IdentifierStatus {
  idle,
  typing,
  tooShort,
  checking,
  available,
  taken,
  error,
}

/// Gerencia toda a lógica de identificador: normalização, debounce, verificação
/// assíncrona de disponibilidade e geração de sugestões.
///
/// Não é um widget — é uma classe Dart pura que notifica a tela via [onStateChanged].
/// Instanciar em [initState] e descartar em [dispose].
class IdentifierController {
  IdentifierController({
    required this.checkExists,
    required this.onStateChanged,
  });

  /// Callback para verificar se um identificador já existe no backend.
  final Future<bool> Function(String identifier) checkExists;

  /// Chamado sempre que o estado interno muda — normalmente `() => setState(() {})`.
  final VoidCallback onStateChanged;

  /// Controller do campo de texto do identificador.
  /// Deve ser passado como `controller:` ao `TextFormField` da tela.
  final TextEditingController textController = TextEditingController();

  // -------------------------------------------------------------------------
  // Estado interno
  // -------------------------------------------------------------------------

  IdentifierStatus _status = IdentifierStatus.idle;
  String? _message;
  List<String> _suggestions = const [];
  String? _confirmedAvailable;
  String _name = '';

  Timer? _debounce;
  int _requestId = 0;
  bool _disposed = false;

  static const int _minLength = 10;

  // -------------------------------------------------------------------------
  // Getters públicos (somente leitura)
  // -------------------------------------------------------------------------

  IdentifierStatus get status => _status;
  String? get message => _message;
  List<String> get suggestions => _suggestions;
  String? get confirmedAvailable => _confirmedAvailable;

  // -------------------------------------------------------------------------
  // Normalização — método estático público para uso externo (ex: _canSubmit)
  // -------------------------------------------------------------------------

  static String normalize(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('@', '');
    return normalized.replaceAll(RegExp(r'[^a-z0-9._-]'), '');
  }

  // -------------------------------------------------------------------------
  // Ações públicas chamadas pela tela
  // -------------------------------------------------------------------------

  /// Atualiza o nome do perfil usado para gerar sugestões de identificador.
  /// Chamar do `onChanged` do campo nome.
  void onNameChanged(String name) {
    _name = name;

    final normalized = normalize(textController.text);
    if (_status == IdentifierStatus.taken) {
      _scheduleValidation(forceRefreshSuggestions: true);
      return;
    }
    if (_status == IdentifierStatus.tooShort &&
        normalized.isNotEmpty &&
        normalized.length < _minLength) {
      _suggestions = _buildUncheckedSuggestions(normalized);
      onStateChanged();
    }
  }

  /// Reagir ao texto digitado no campo identificador.
  /// Chamar do `onChanged` do `TextFormField`.
  void onChanged(String rawValue) {
    final normalized = normalize(rawValue);
    if (rawValue != normalized) {
      textController.value = TextEditingValue(
        text: normalized,
        selection: TextSelection.collapsed(offset: normalized.length),
      );
    }

    _debounce?.cancel();
    _requestId++;
    _confirmedAvailable = null;

    if (_disposed) return;

    if (normalized.isEmpty) {
      _status = IdentifierStatus.idle;
      _message = null;
      _suggestions = const [];
      _confirmedAvailable = null;
      onStateChanged();
      return;
    }

    if (normalized.length < _minLength) {
      _status = IdentifierStatus.typing;
      _message = 'Analisando identificador...';
      _suggestions = const [];
      _confirmedAvailable = null;
      onStateChanged();

      final requestId = _requestId;
      _debounce = Timer(
        const Duration(milliseconds: 350),
        () => _setTooShortState(normalized, requestId: requestId),
      );
      return;
    }

    _status = IdentifierStatus.checking;
    _message = 'Verificando disponibilidade...';
    _suggestions = const [];
    _confirmedAvailable = null;
    onStateChanged();

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _validate(
        normalized,
        requestId: _requestId,
        refreshSuggestions: true,
      ),
    );
  }

  /// Aplicar uma sugestão clicada pelo usuário.
  Future<void> applySuggestion(String suggestion) async {
    final normalized = normalize(suggestion);
    textController.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
    _debounce?.cancel();
    final requestId = ++_requestId;
    _confirmedAvailable = null;
    _status = IdentifierStatus.checking;
    _message = 'Verificando disponibilidade...';
    _suggestions = const [];
    onStateChanged();
    await _validate(normalized, requestId: requestId, refreshSuggestions: false);
  }

  /// Resolver um conflito de identificador detectado durante o submit.
  /// A tela é responsável por resetar o flag `_submitting` após o await.
  Future<void> applyTakenStateFromConflict(String normalizedIdentifier) async {
    final requestId = ++_requestId;
    final generatedSuggestions =
        await _generateSuggestions(normalizedIdentifier, requestId);
    if (_disposed || requestId != _requestId) return;
    if (normalize(textController.text) != normalizedIdentifier) return;

    _status = IdentifierStatus.taken;
    _message = 'Esse identificador não está disponível.';
    _suggestions = generatedSuggestions;
    _confirmedAvailable = null;
    onStateChanged();
  }

  // -------------------------------------------------------------------------
  // Ciclo de vida
  // -------------------------------------------------------------------------

  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    textController.dispose();
  }

  // -------------------------------------------------------------------------
  // Lógica interna
  // -------------------------------------------------------------------------

  void _scheduleValidation({bool forceRefreshSuggestions = false}) {
    final normalized = normalize(textController.text);
    if (normalized.length < _minLength) return;

    _debounce?.cancel();
    _requestId++;

    _status = IdentifierStatus.checking;
    _message = 'Verificando disponibilidade...';
    _suggestions = const [];
    _confirmedAvailable = null;
    onStateChanged();

    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _validate(
        normalized,
        requestId: _requestId,
        refreshSuggestions: forceRefreshSuggestions,
      ),
    );
  }

  Future<void> _validate(
    String normalized, {
    required int requestId,
    required bool refreshSuggestions,
  }) async {
    try {
      final exists = await checkExists(normalized);
      if (_disposed || requestId != _requestId) return;
      if (normalize(textController.text) != normalized) return;

      if (exists) {
        final newSuggestions = refreshSuggestions
            ? await _generateSuggestions(normalized, requestId)
            : _suggestions;

        if (_disposed || requestId != _requestId) return;

        _status = IdentifierStatus.taken;
        _message = 'Esse identificador não está disponível.';
        _suggestions = newSuggestions;
        _confirmedAvailable = null;
        onStateChanged();
        return;
      }

      _status = IdentifierStatus.available;
      _message = 'Identificador disponível!';
      _suggestions = const [];
      _confirmedAvailable = normalized;
      onStateChanged();
    } on AppException catch (e) {
      if (_disposed || requestId != _requestId) return;
      _status = IdentifierStatus.error;
      _message = e.message;
      _suggestions = const [];
      _confirmedAvailable = null;
      onStateChanged();
    } catch (_) {
      if (_disposed || requestId != _requestId) return;
      _status = IdentifierStatus.error;
      _message = 'Não foi possível verificar o identificador agora.';
      _suggestions = const [];
      _confirmedAvailable = null;
      onStateChanged();
    }
  }

  void _setTooShortState(String normalized, {required int requestId}) {
    if (_disposed || requestId != _requestId) return;
    if (normalize(textController.text) != normalized) return;

    _status = IdentifierStatus.tooShort;
    _message = 'Identificador não disponível.';
    _suggestions = _buildUncheckedSuggestions(normalized);
    _confirmedAvailable = null;
    onStateChanged();
  }

  // -------------------------------------------------------------------------
  // Geração de sugestões
  // -------------------------------------------------------------------------

  List<String> _buildUncheckedSuggestions(String identifier) {
    final seen = <String>{normalize(identifier)};
    final results = <String>[];

    for (final candidate in _buildSuggestionCandidates(identifier)) {
      final n = normalize(candidate);
      if (n.isEmpty) continue;
      if (!seen.add(n)) continue;
      results.add(n);
      if (results.length >= 5) break;
    }

    return results.take(5).toList(growable: false);
  }

  Future<List<String>> _generateSuggestions(
    String identifier,
    int requestId,
  ) async {
    final normalizedIdentifier = normalize(identifier);
    final base = normalizedIdentifier.replaceAll(RegExp(r'[._-]+'), '');
    final candidates = _buildSuggestionCandidates(normalizedIdentifier);

    final results = <String>[];
    final seen = <String>{normalizedIdentifier};

    Future<void> tryAdd(String candidate) async {
      final n = normalize(candidate);
      if (n.isEmpty) return;
      if (!seen.add(n)) return;
      if (_disposed || requestId != _requestId) return;

      final exists = await checkExists(n);
      if (_disposed || requestId != _requestId) return;
      if (!exists) results.add(n);
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
    final parts = _normalizedNameParts(_name);
    if (parts.isEmpty) return const [];

    final first = parts.first;
    final last = parts.length > 1 ? parts.last : '';
    final fl = last.isNotEmpty ? '$first$last' : first;

    return <String>[
      fl,
      if (last.isNotEmpty) '$first.$last',
      if (last.isNotEmpty) '${first}_$last',
      '${fl}1',
      '$fl.oficial',
      '$fl.pro',
    ];
  }

  List<String> _buildIdentifierDrivenCandidates(String identifier) {
    final n = normalize(identifier);
    final base = n.replaceAll(RegExp(r'[._-]+'), '');
    final seed = base.isNotEmpty ? base : _normalizedNameToken(_name);

    return <String>[
      _composeIdentifier(seed, suffix: 'oficial'),
      _composeIdentifier(seed, suffix: 'pro'),
      _composeIdentifier(seed, suffix: 'gestao'),
      _composeIdentifier(seed, suffix: 'negocios'),
      _composeIdentifier(seed, suffix: 'hub'),
      _composeIdentifier(seed, suffix: 'central'),
    ];
  }

  // -------------------------------------------------------------------------
  // Helpers de normalização de nome
  // -------------------------------------------------------------------------

  String _normalizedNameToken(String value) {
    final parts = _normalizedNameParts(value);
    if (parts.isEmpty) return 'perfil';
    if (parts.length == 1) return parts.first;
    return '${parts.first}${parts.last}';
  }

  List<String> _normalizedNameParts(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '');

    return normalized
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList(growable: false);
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
        .map((part) => normalize(part))
        .where((part) => part.isNotEmpty)
        .join(separator);

    if (compact.length >= _minLength) return compact;
    return '${compact}01';
  }
}
