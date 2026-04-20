import 'package:flutter/material.dart';

import '../../../../shared/utils/string_utils.dart';
import '../models/agency_confirm_payload.dart';
import '../models/cnpj_model.dart';
import '../services/agency_confirm_service.dart';
import '../services/cep_service.dart';

/// Estados do envio final da agência para o Supabase.
enum AgencyConfirmSubmitState {
  idle,
  loading,
  success,
  errorAlreadyRegistered,
  errorGeneric,
}

/// Controller da tela de confirmação de dados da agência.
///
/// Gerencia pré-preenchimento dos campos, busca de CEP, validações do formulário
/// e o insert final da agência via [AgencyConfirmService].
class AgencyConfirmController extends ChangeNotifier {
  AgencyConfirmController({
    required this.cnpjModel,
    CepService? cepService,
    AgencyConfirmService? confirmService,
  })  : _cepService = cepService ?? CepService(),
        _confirmService = confirmService ?? AgencyConfirmService() {
    fantasyNameController.text = cnpjModel.displayName;
    phoneController.addListener(_onFormChanged);
    emailController.addListener(_onFormChanged);

    cepController.text = CnpjModel.formatCep(cnpjModel.cep);
    logradouroController.text = cnpjModel.logradouro;
    numeroController.text = cnpjModel.numero?.trim() ?? '';
    bairroController.text = cnpjModel.bairro;
    municipioController.text = cnpjModel.municipio;
    ufController.text = cnpjModel.uf;
  }

  final CnpjModel cnpjModel;
  final CepService _cepService;
  final AgencyConfirmService _confirmService;

  final TextEditingController fantasyNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cepController = TextEditingController();
  final TextEditingController logradouroController = TextEditingController();
  final TextEditingController numeroController = TextEditingController();
  final TextEditingController bairroController = TextEditingController();
  final TextEditingController municipioController = TextEditingController();
  final TextEditingController ufController = TextEditingController();

  bool _submitted = false;
  bool _isSearchingCep = false;
  String? _cepMessage;
  AgencyConfirmSubmitState _submitState = AgencyConfirmSubmitState.idle;
  String? _savedAgencyId;

  bool get isSearchingCep => _isSearchingCep;
  String? get cepMessage => _cepMessage;
  AgencyConfirmSubmitState get submitState => _submitState;
  bool get isSubmitting => _submitState == AgencyConfirmSubmitState.loading;
  String? get savedAgencyId => _savedAgencyId;

  bool get canAdvance =>
      _isPhoneValid(phoneController.text) && isValidEmail(emailController.text);

  String? get submitErrorMessage {
    switch (_submitState) {
      case AgencyConfirmSubmitState.errorAlreadyRegistered:
        return 'Esta agência já está cadastrada em nossa plataforma.';
      case AgencyConfirmSubmitState.errorGeneric:
        return 'Erro ao salvar agência. Tente novamente.';
      case AgencyConfirmSubmitState.idle:
      case AgencyConfirmSubmitState.loading:
      case AgencyConfirmSubmitState.success:
        return null;
    }
  }

  String? get phoneError {
    if (!_submitted) return null;
    if (onlyDigits(phoneController.text).isEmpty) {
      return 'Informe o telefone de contato.';
    }
    if (!_isPhoneValid(phoneController.text)) {
      return 'Informe um telefone válido.';
    }
    return null;
  }

  String? get emailError {
    if (!_submitted) return null;
    if (emailController.text.trim().isEmpty) {
      return 'Informe o e-mail.';
    }
    if (!isValidEmail(emailController.text)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  /// Consulta o CEP digitado e preenche os campos de endereço.
  ///
  /// Mantém o CEP digitado e limpa os demais campos quando a busca falha.
  Future<void> searchCep() async {
    final rawCep = onlyDigits(cepController.text);
    _cepMessage = null;

    if (rawCep.length != 8) {
      _clearAddressFields();
      _cepMessage = 'CEP não encontrado.';
      notifyListeners();
      return;
    }

    _isSearchingCep = true;
    notifyListeners();

    try {
      final result = await _cepService.fetchCep(rawCep);
      cepController.text = CnpjModel.formatCep(result.cep);
      logradouroController.text = result.logradouro.toUpperCase();
      bairroController.text = result.bairro.toUpperCase();
      municipioController.text = result.municipio.toUpperCase();
      ufController.text = result.uf.toUpperCase();
      _cepMessage = null;
      notifyListeners();
    } on CepNotFoundException {
      _clearAddressFields();
      _cepMessage = 'CEP não encontrado.';
      notifyListeners();
    } on CepServiceException {
      _clearAddressFields();
      _cepMessage = 'Erro ao consultar CEP. Tente novamente.';
      notifyListeners();
    } catch (_) {
      _clearAddressFields();
      _cepMessage = 'Erro ao consultar CEP. Tente novamente.';
      notifyListeners();
    } finally {
      _isSearchingCep = false;
      notifyListeners();
    }
  }

  /// Remove a mensagem exibida após uma tentativa de busca de CEP.
  void clearCepMessage() {
    if (_cepMessage == null) return;
    _cepMessage = null;
    notifyListeners();
  }

  /// Valida o formulário e tenta salvar a agência.
  ///
  /// Retorna `true` em sucesso e atualiza [submitState] para que a UI
  /// reaja a carregamento, sucesso e tipos de erro esperados.
  Future<bool> submit() async {
    _submitted = true;

    if (!canAdvance) {
      notifyListeners();
      return false;
    }

    _submitState = AgencyConfirmSubmitState.loading;
    notifyListeners();

    try {
      _savedAgencyId = await _confirmService.saveAgency(
        cnpjModel: cnpjModel,
        nomeFantasia: fantasyNameController.text.trim(),
        telefoneContato: phoneController.text.trim(),
        email: emailController.text.trim(),
        cep: cepController.text.trim(),
        logradouro: logradouroController.text.trim(),
        numero: numeroController.text.trim(),
        municipio: municipioController.text.trim(),
        uf: ufController.text.trim(),
      );

      _submitState = AgencyConfirmSubmitState.success;
      notifyListeners();
      return true;
    } on AgencyAlreadyRegisteredException {
      _submitState = AgencyConfirmSubmitState.errorAlreadyRegistered;
      notifyListeners();
      return false;
    } on AgencyConfirmServiceException {
      _submitState = AgencyConfirmSubmitState.errorGeneric;
      notifyListeners();
      return false;
    } catch (_) {
      _submitState = AgencyConfirmSubmitState.errorGeneric;
      notifyListeners();
      return false;
    }
  }

  /// Monta o payload que segue para a próxima etapa do onboarding.
  AgencyConfirmPayload buildPayload() {
    final agencyId = _savedAgencyId;
    if (agencyId == null || agencyId.isEmpty) {
      throw StateError('Agency ID não disponível para a próxima etapa.');
    }

    return AgencyConfirmPayload(
      agencyId: agencyId,
      cnpjModel: cnpjModel,
      formData: AgencyConfirmFormData(
        nomeFantasia: fantasyNameController.text.trim(),
        telefoneContato: phoneController.text.trim(),
        email: emailController.text.trim(),
        cep: onlyDigits(cepController.text),
        logradouro: logradouroController.text.trim(),
        numero: numeroController.text.trim(),
        bairro: bairroController.text.trim(),
        municipio: municipioController.text.trim(),
        uf: ufController.text.trim(),
      ),
    );
  }

  void _onFormChanged() {
    if (_submitState == AgencyConfirmSubmitState.errorAlreadyRegistered ||
        _submitState == AgencyConfirmSubmitState.errorGeneric) {
      _submitState = AgencyConfirmSubmitState.idle;
    }
    notifyListeners();
  }

  void _clearAddressFields() {
    logradouroController.text = '';
    bairroController.text = '';
    municipioController.text = '';
    ufController.text = '';
  }

  bool _isPhoneValid(String value) {
    return onlyDigits(value).length == 11;
  }

  @override
  void dispose() {
    phoneController.removeListener(_onFormChanged);
    emailController.removeListener(_onFormChanged);
    fantasyNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    cepController.dispose();
    logradouroController.dispose();
    numeroController.dispose();
    bairroController.dispose();
    municipioController.dispose();
    ufController.dispose();
    super.dispose();
  }
}
