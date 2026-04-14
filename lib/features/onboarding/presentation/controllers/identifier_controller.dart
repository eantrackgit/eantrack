import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/error/app_exception.dart';

enum IdentifierStatus {
  idle,
  typing,
  tooShort,
  checking,
  available,
  taken,
  error,
}

class IdentifierController {
  IdentifierController({
    required this.checkExists,
    required this.onStateChanged,
  });

  final Future<bool> Function(String identifier) checkExists;
  final VoidCallback onStateChanged;
  final TextEditingController textController = TextEditingController();

  IdentifierStatus _status = IdentifierStatus.idle;
  String? _message;
  List<String> _suggestions = const [];
  String? _confirmedAvailable;
  String _name = '';

  Timer? _debounce;
  int _requestId = 0;
  bool _disposed = false;

  static const int _minLength = 10;

  IdentifierStatus get status => _status;
  String? get message => _message;
  List<String> get suggestions => _suggestions;
  String? get confirmedAvailable => _confirmedAvailable;

  static String _stripAccents(String text) {
    const withAccent =
        '\u00E1\u00E0\u00E3\u00E2\u00E4\u00E9\u00E8\u00EA\u00EB\u00ED\u00EC\u00EE\u00EF'
        '\u00F3\u00F2\u00F5\u00F4\u00F6\u00FA\u00F9\u00FB\u00FC\u00E7\u00F1\u00C1\u00C0'
        '\u00C3\u00C2\u00C4\u00C9\u00C8\u00CA\u00CB\u00CD\u00CC\u00CE\u00CF\u00D3\u00D2'
        '\u00D5\u00D4\u00D6\u00DA\u00D9\u00DB\u00DC\u00C7\u00D1';
    const withoutAccent =
        'aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN';
    var result = text;
    for (var i = 0; i < withAccent.length; i++) {
      result = result.replaceAll(withAccent[i], withoutAccent[i]);
    }
    return result;
  }

  static String normalize(String input) {
    return _stripAccents(input.trim())
        .toLowerCase()
        .replaceAll('@', '')
        .replaceAll(RegExp(r'[^a-z0-9._-]'), '');
  }

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

  Future<void> applyTakenStateFromConflict(String normalizedIdentifier) async {
    final requestId = ++_requestId;
    final generatedSuggestions =
        await _generateSuggestions(normalizedIdentifier, requestId);
    if (_disposed || requestId != _requestId) return;
    if (normalize(textController.text) != normalizedIdentifier) return;

    _status = IdentifierStatus.taken;
    _message = 'Esse identificador n\u00E3o est\u00E1 dispon\u00EDvel.';
    _suggestions = generatedSuggestions;
    _confirmedAvailable = null;
    onStateChanged();
  }

  void dispose() {
    _disposed = true;
    _debounce?.cancel();
    textController.dispose();
  }

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
        _message = 'Esse identificador n\u00E3o est\u00E1 dispon\u00EDvel.';
        _suggestions = newSuggestions;
        _confirmedAvailable = null;
        onStateChanged();
        return;
      }

      _status = IdentifierStatus.available;
      _message = 'Identificador dispon\u00EDvel!';
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
      _message =
          'N\u00E3o foi poss\u00EDvel verificar o identificador agora.';
      _suggestions = const [];
      _confirmedAvailable = null;
      onStateChanged();
    }
  }

  void _setTooShortState(String normalized, {required int requestId}) {
    if (_disposed || requestId != _requestId) return;
    if (normalize(textController.text) != normalized) return;

    _status = IdentifierStatus.tooShort;
    _message = 'M\u00EDnimo de 10 caracteres.';
    _suggestions = _buildUncheckedSuggestions(normalized);
    _confirmedAvailable = null;
    onStateChanged();
  }

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

    Future<bool> tryAdd(String candidate) async {
      if (results.length >= 5) return true;

      final n = normalize(candidate);
      if (n.isEmpty) return false;
      if (!seen.add(n)) return false;
      if (_disposed || requestId != _requestId) return true;

      final exists = await checkExists(n);
      if (_disposed || requestId != _requestId) return true;
      if (!exists) {
        results.add(n);
      }

      return results.length >= 5;
    }

    for (final candidate in candidates) {
      if (await tryAdd(candidate)) break;
    }

    var suffix = 1;
    while (results.length < 5 && suffix <= 10) {
      if (await tryAdd(_composeIdentifier(base, suffix: '$suffix'))) break;
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

  String _normalizedNameToken(String value) {
    final parts = _normalizedNameParts(value);
    if (parts.isEmpty) return 'perfil';
    if (parts.length == 1) return parts.first;
    return '${parts.first}${parts.last}';
  }

  List<String> _normalizedNameParts(String value) {
    final normalized = _stripAccents(value.trim())
        .toLowerCase()
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
