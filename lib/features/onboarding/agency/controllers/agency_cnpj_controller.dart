import 'package:flutter/material.dart';

import '../services/cnpj_service.dart';
import '../models/cnpj_model.dart';

/// Estados possíveis da busca de CNPJ na etapa inicial do onboarding.
enum CnpjState {
  initial,
  loading,
  success,
  errorInvalid,
  errorNotFound,
  errorInactive,
  errorAlreadyRegistered,
  errorGeneric,
}

/// Controller da tela de consulta de CNPJ da agência.
///
/// Faz validação local do documento, consulta a BrasilAPI e verifica
/// duplicidade da agência antes de liberar o avanço para a próxima etapa.
class AgencyCnpjController extends ChangeNotifier {
  AgencyCnpjController({
    CnpjService? service,
  }) : _service = service ?? CnpjService();

  final CnpjService _service;

  final TextEditingController textController = TextEditingController();

  CnpjState _state = CnpjState.initial;
  CnpjModel? _cnpjModel;

  CnpjState get state => _state;
  CnpjModel? get cnpjModel => _cnpjModel;

  bool get canAdvance => _state == CnpjState.success && _cnpjModel != null;

  String? get errorMessage {
    switch (_state) {
      case CnpjState.errorInvalid:
        return 'CNPJ inv\u00E1lido. Verifique os n\u00FAmeros e tente novamente.';
      case CnpjState.errorNotFound:
        return 'N\u00E3o encontramos uma empresa com este CNPJ.';
      case CnpjState.errorInactive:
        return 'Este CNPJ est\u00E1 inativo na Receita Federal.';
      case CnpjState.errorAlreadyRegistered:
        return 'Este CNPJ j\u00E1 est\u00E1 cadastrado em nossa plataforma.';
      case CnpjState.errorGeneric:
        return 'Erro ao consultar CNPJ. Tente novamente.';
      case CnpjState.initial:
      case CnpjState.loading:
      case CnpjState.success:
        return null;
    }
  }

  /// Limpa estado e resultado anteriores quando o usuário altera o campo.
  void onChanged(String _) {
    if (_state == CnpjState.initial) return;

    _state = CnpjState.initial;
    _cnpjModel = null;
    notifyListeners();
  }

  /// Executa o fluxo completo de validação e consulta do CNPJ informado.
  ///
  /// Atualiza [state] para refletir carregamento, sucesso ou tipos de erro
  /// esperados pelo fluxo de onboarding.
  Future<void> consultCnpj() async {
    final rawCnpj = onlyDigits(textController.text);

    if (!_isValidCnpj(rawCnpj)) {
      _state = CnpjState.errorInvalid;
      _cnpjModel = null;
      notifyListeners();
      return;
    }

    _state = CnpjState.loading;
    _cnpjModel = null;
    notifyListeners();

    try {
      final result = await _service.fetchCnpj(rawCnpj);
      final alreadyRegistered = await _service.cnpjExistsAgency(rawCnpj);

      if (alreadyRegistered) {
        _state = CnpjState.errorAlreadyRegistered;
        _cnpjModel = null;
        notifyListeners();
        return;
      }

      _cnpjModel = result;
      _state = CnpjState.success;
      notifyListeners();
    } on CnpjNotFoundException {
      _state = CnpjState.errorNotFound;
      _cnpjModel = null;
      notifyListeners();
    } on CnpjInactiveException {
      _state = CnpjState.errorInactive;
      _cnpjModel = null;
      notifyListeners();
    } on CnpjServiceException {
      _state = CnpjState.errorGeneric;
      _cnpjModel = null;
      notifyListeners();
    } catch (_) {
      _state = CnpjState.errorGeneric;
      _cnpjModel = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  /// Remove qualquer máscara e mantém apenas os dígitos do valor recebido.
  static String onlyDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
  }

  /// Valida estrutura, repetição de dígitos e verificadores do CNPJ.
  bool _isValidCnpj(String value) {
    if (value.length != 14) return false;
    if (RegExp(r'^(\d)\1{13}$').hasMatch(value)) return false;

    final numbers = value.split('').map(int.parse).toList(growable: false);
    final firstDigit = _calculateDigit(numbers, const [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2]);
    final secondDigit = _calculateDigit(
      numbers,
      const [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2],
    );

    return numbers[12] == firstDigit && numbers[13] == secondDigit;
  }

  /// Calcula um dígito verificador do CNPJ a partir dos pesos informados.
  int _calculateDigit(List<int> numbers, List<int> weights) {
    var sum = 0;
    for (var i = 0; i < weights.length; i++) {
      sum += numbers[i] * weights[i];
    }

    final remainder = sum % 11;
    return remainder < 2 ? 0 : 11 - remainder;
  }
}
