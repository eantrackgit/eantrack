import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/shared.dart';
import '../models/agency_confirm_payload.dart';
import '../models/cnpj_model.dart';
import '../services/agency_confirm_service.dart';
import '../services/cep_service.dart';

const _agencyConfirmUnset = Object();

class AgencyConfirmState {
  const AgencyConfirmState({
    this.submitted = false,
    this.isSearchingCep = false,
    this.cepMessage,
    this.isLoading = false,
    this.error,
    this.isConfirmed = false,
    this.savedAgencyId,
    this.phoneText = '',
    this.emailText = '',
  });

  final bool submitted;
  final bool isSearchingCep;
  final String? cepMessage;
  final bool isLoading;
  final String? error;
  final bool isConfirmed;
  final String? savedAgencyId;
  final String phoneText;
  final String emailText;

  bool get isSubmitting => isLoading;

  bool get canAdvance =>
      _isPhoneValid(phoneText) && isValidEmail(emailText);

  String? get submitErrorMessage => error;

  String? get phoneError {
    if (!submitted) return null;
    if (onlyDigits(phoneText).isEmpty) {
      return 'Informe o telefone de contato.';
    }
    if (!_isPhoneValid(phoneText)) {
      return 'Informe um telefone válido.';
    }
    return null;
  }

  String? get emailError {
    if (!submitted) return null;
    if (emailText.trim().isEmpty) {
      return 'Informe o e-mail.';
    }
    if (!isValidEmail(emailText)) {
      return 'Informe um e-mail válido.';
    }
    return null;
  }

  AgencyConfirmState copyWith({
    bool? submitted,
    bool? isSearchingCep,
    Object? cepMessage = _agencyConfirmUnset,
    bool? isLoading,
    Object? error = _agencyConfirmUnset,
    bool? isConfirmed,
    Object? savedAgencyId = _agencyConfirmUnset,
    String? phoneText,
    String? emailText,
  }) {
    return AgencyConfirmState(
      submitted: submitted ?? this.submitted,
      isSearchingCep: isSearchingCep ?? this.isSearchingCep,
      cepMessage: identical(cepMessage, _agencyConfirmUnset)
          ? this.cepMessage
          : cepMessage as String?,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _agencyConfirmUnset) ? this.error : error as String?,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      savedAgencyId: identical(savedAgencyId, _agencyConfirmUnset)
          ? this.savedAgencyId
          : savedAgencyId as String?,
      phoneText: phoneText ?? this.phoneText,
      emailText: emailText ?? this.emailText,
    );
  }

  static bool _isPhoneValid(String value) => onlyDigits(value).length == 11;
}

final agencyConfirmProvider = StateNotifierProvider.autoDispose.family<
    AgencyConfirmNotifier, AgencyConfirmState, CnpjModel>(
  (ref, cnpjModel) => AgencyConfirmNotifier(cnpjModel: cnpjModel),
);

class AgencyConfirmNotifier extends StateNotifier<AgencyConfirmState> {
  AgencyConfirmNotifier({
    required this.cnpjModel,
    CepService? cepService,
    AgencyConfirmService? confirmService,
  })  : _cepService = cepService ?? CepService(),
        _confirmService = confirmService ?? AgencyConfirmService(),
        super(const AgencyConfirmState()) {
    fantasyNameController.text = cnpjModel.displayName;
    phoneController.addListener(_onFormChanged);
    emailController.addListener(_onFormChanged);

    cepController.text = CnpjModel.formatCep(cnpjModel.cep);
    logradouroController.text = cnpjModel.logradouro;
    numeroController.text = cnpjModel.numero?.trim() ?? '';
    bairroController.text = cnpjModel.bairro;
    municipioController.text = cnpjModel.municipio;
    ufController.text = cnpjModel.uf;

    _syncFormState();
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

  Future<void> searchCep() async {
    final rawCep = onlyDigits(cepController.text);
    state = state.copyWith(cepMessage: null);

    if (rawCep.length != 8) {
      _clearAddressFields();
      state = state.copyWith(cepMessage: 'CEP não encontrado.');
      return;
    }

    state = state.copyWith(isSearchingCep: true);

    try {
      final result = await _cepService.fetchCep(rawCep);
      cepController.text = CnpjModel.formatCep(result.cep);
      logradouroController.text = result.logradouro.toUpperCase();
      bairroController.text = result.bairro.toUpperCase();
      municipioController.text = result.municipio.toUpperCase();
      ufController.text = result.uf.toUpperCase();
      state = state.copyWith(cepMessage: null);
    } on CepNotFoundException {
      _clearAddressFields();
      state = state.copyWith(cepMessage: 'CEP não encontrado.');
    } on CepServiceException {
      _clearAddressFields();
      state = state.copyWith(
        cepMessage: 'Erro ao consultar CEP. Tente novamente.',
      );
    } catch (_) {
      _clearAddressFields();
      state = state.copyWith(
        cepMessage: 'Erro ao consultar CEP. Tente novamente.',
      );
    } finally {
      state = state.copyWith(isSearchingCep: false);
    }
  }

  void clearCepMessage() {
    if (state.cepMessage == null) return;
    state = state.copyWith(cepMessage: null);
  }

  Future<bool> submit() async {
    state = state.copyWith(submitted: true);

    if (!state.canAdvance) {
      return false;
    }

    state = state.copyWith(
      isLoading: true,
      error: null,
      isConfirmed: false,
    );

    try {
      final agencyId = await _confirmService.saveAgency(
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

      state = state.copyWith(
        isLoading: false,
        error: null,
        isConfirmed: true,
        savedAgencyId: agencyId,
      );
      return true;
    } on AgencyAlreadyRegisteredException {
      state = state.copyWith(
        isLoading: false,
        error: 'Esta agência já está cadastrada.',
        isConfirmed: false,
      );
      return false;
    } on AgencyConfirmServiceException {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao salvar agência.',
        isConfirmed: false,
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao salvar agência.',
        isConfirmed: false,
      );
      return false;
    }
  }

  AgencyConfirmPayload buildPayload() {
    final agencyId = state.savedAgencyId;
    if (agencyId == null || agencyId.isEmpty) {
      throw StateError('Agency ID não disponível.');
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
    state = state.copyWith(
      error: null,
      phoneText: phoneController.text,
      emailText: emailController.text,
    );
  }

  void _syncFormState() {
    state = state.copyWith(
      phoneText: phoneController.text,
      emailText: emailController.text,
    );
  }

  void _clearAddressFields() {
    logradouroController.text = '';
    bairroController.text = '';
    municipioController.text = '';
    ufController.text = '';
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
