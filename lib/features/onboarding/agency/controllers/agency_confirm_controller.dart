import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cnpj_model.dart';
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
/// e o insert final da agência na tabela `public.agencies`.
class AgencyConfirmController extends ChangeNotifier {
  AgencyConfirmController({
    required this.cnpjModel,
    CepService? cepService,
  })  : _cepService = cepService ?? CepService(),
        _supabase = Supabase.instance.client {
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
  final SupabaseClient _supabase;

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

  bool get isSearchingCep => _isSearchingCep;
  String? get cepMessage => _cepMessage;
  AgencyConfirmSubmitState get submitState => _submitState;
  bool get isSubmitting => _submitState == AgencyConfirmSubmitState.loading;

  bool get canAdvance =>
      _isPhoneValid(phoneController.text) && _isEmailValid(emailController.text);

  String? get submitErrorMessage {
    switch (_submitState) {
      case AgencyConfirmSubmitState.errorAlreadyRegistered:
        return 'Esta agencia ja esta cadastrada em nossa plataforma.';
      case AgencyConfirmSubmitState.errorGeneric:
        return 'Erro ao salvar agencia. Tente novamente.';
      case AgencyConfirmSubmitState.idle:
      case AgencyConfirmSubmitState.loading:
      case AgencyConfirmSubmitState.success:
        return null;
    }
  }

  String? get phoneError {
    if (!_submitted) return null;
    if (_onlyDigits(phoneController.text).isEmpty) {
      return 'Informe o telefone de contato.';
    }
    if (!_isPhoneValid(phoneController.text)) {
      return 'Informe um telefone valido.';
    }
    return null;
  }

  String? get emailError {
    if (!_submitted) return null;
    if (emailController.text.trim().isEmpty) {
      return 'Informe o e-mail.';
    }
    if (!_isEmailValid(emailController.text)) {
      return 'Informe um e-mail valido.';
    }
    return null;
  }

  /// Consulta o CEP digitado e preenche os campos de endereço.
  ///
  /// Mantém o CEP digitado e limpa os demais campos quando a busca falha.
  Future<void> searchCep() async {
    final rawCep = _onlyDigits(cepController.text);
    _cepMessage = null;

    if (rawCep.length != 8) {
      _clearAddressFields();
      _cepMessage = 'CEP nao encontrado.';
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
      _cepMessage = 'CEP nao encontrado.';
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

  /// Valida o formulário e tenta salvar a agência no Supabase.
  ///
  /// Retorna `true` em sucesso e atualiza [submitState] para que a UI
  /// reaja a carregamento, sucesso e tipos de erro esperados.
  Future<bool> submit() async {
    _submitted = true;

    if (!canAdvance) {
      notifyListeners();
      return false;
    }

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      _submitState = AgencyConfirmSubmitState.errorGeneric;
      notifyListeners();
      return false;
    }

    _submitState = AgencyConfirmSubmitState.loading;
    notifyListeners();

    try {
      await _supabase.from('agencies').insert({
        'cnpj': _onlyDigits(cnpjModel.cnpj),
        'razao_social': cnpjModel.razaoSocial.trim(),
        'nome_fantasia': fantasyNameController.text.trim(),
        'porte': cnpjModel.porte?.trim() ?? '',
        'cnae_principal': cnpjModel.cnaePrincipal?.trim() ?? '',
        'cep': _onlyDigits(cepController.text),
        'logradouro': logradouroController.text.trim(),
        'numero': numeroController.text.trim(),
        'complemento': '',
        'municipio': municipioController.text.trim(),
        'uf': ufController.text.trim(),
        'email_contato': emailController.text.trim(),
        'telefone_contato': _onlyDigits(phoneController.text),
        'user_uuid': userId,
      });

      _submitState = AgencyConfirmSubmitState.success;
      notifyListeners();
      return true;
    } on PostgrestException catch (e) {
      _submitState = e.code == '23505'
          ? AgencyConfirmSubmitState.errorAlreadyRegistered
          : AgencyConfirmSubmitState.errorGeneric;
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
    return AgencyConfirmPayload(
      cnpjModel: cnpjModel,
      formData: AgencyConfirmFormData(
        nomeFantasia: fantasyNameController.text.trim(),
        telefoneContato: phoneController.text.trim(),
        email: emailController.text.trim(),
        cep: _onlyDigits(cepController.text),
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
    return _onlyDigits(value).length == 11;
  }

  bool _isEmailValid(String value) {
    final email = value.trim();
    if (email.isEmpty) return false;
    return RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-z]{2,}$', caseSensitive: false)
        .hasMatch(email);
  }

  String _onlyDigits(String value) {
    return value.replaceAll(RegExp(r'\D'), '');
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

/// Agrupa os dados fiscais e os dados editados no formulário após a confirmação.
class AgencyConfirmPayload {
  const AgencyConfirmPayload({
    required this.cnpjModel,
    required this.formData,
  });

  final CnpjModel cnpjModel;
  final AgencyConfirmFormData formData;
}

/// Estrutura com os dados complementares preenchidos na tela de confirmação.
class AgencyConfirmFormData {
  const AgencyConfirmFormData({
    required this.nomeFantasia,
    required this.telefoneContato,
    required this.email,
    required this.cep,
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.municipio,
    required this.uf,
  });

  final String nomeFantasia;
  final String telefoneContato;
  final String email;
  final String cep;
  final String logradouro;
  final String numero;
  final String bairro;
  final String municipio;
  final String uf;

  /// Serializa os dados complementares para envio entre etapas do fluxo.
  Map<String, dynamic> toJson() {
    return {
      'nome_fantasia': nomeFantasia,
      'telefone_contato': telefoneContato,
      'email': email,
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'bairro': bairro,
      'municipio': municipio,
      'uf': uf,
    };
  }
}
