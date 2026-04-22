import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/shared.dart';
import '../models/cnpj_model.dart';
import '../services/cnpj_service.dart';

const _agencyCnpjUnset = Object();
const _kCnpjInvalido =
    'CNPJ inválido. Verifique os números e tente novamente.';
const _kCnpjNaoEncontrado = 'Não encontramos uma empresa com este CNPJ.';
const _kCnpjInativo = 'Este CNPJ está inativo na Receita Federal.';
const _kCnpjDuplicado = 'Este CNPJ já está cadastrado em nossa plataforma.';
const _kCnpjErroGenerico = 'Erro ao consultar CNPJ. Tente novamente.';

enum AgencyCnpjStatus {
  idle,
  loading,
  invalid,
  notFound,
  inactive,
  duplicate,
  genericError,
  success,
}

class AgencyCnpjState {
  const AgencyCnpjState({
    this.status = AgencyCnpjStatus.idle,
    this.cnpj = '',
    this.isLoading = false,
    this.error,
    this.cnpjData,
  });

  final AgencyCnpjStatus status;
  final String cnpj;
  final bool isLoading;
  final String? error;
  final CnpjModel? cnpjData;

  CnpjModel? get cnpjModel => cnpjData;

  bool get canAdvance =>
      status == AgencyCnpjStatus.success && cnpjData != null;

  String? get errorMessage => error;

  AgencyCnpjState copyWith({
    AgencyCnpjStatus? status,
    String? cnpj,
    bool? isLoading,
    Object? error = _agencyCnpjUnset,
    Object? cnpjData = _agencyCnpjUnset,
  }) {
    return AgencyCnpjState(
      status: status ?? this.status,
      cnpj: cnpj ?? this.cnpj,
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _agencyCnpjUnset) ? this.error : error as String?,
      cnpjData: identical(cnpjData, _agencyCnpjUnset)
          ? this.cnpjData
          : cnpjData as CnpjModel?,
    );
  }
}

final agencyCnpjProvider =
    StateNotifierProvider.autoDispose<AgencyCnpjNotifier, AgencyCnpjState>(
      (ref) {
        final cnpjController = TextEditingController();
        final focusNode = FocusNode();

        ref.onDispose(() {
          cnpjController.dispose();
          focusNode.dispose();
        });

        return AgencyCnpjNotifier(cnpjController, focusNode);
      },
    );

class AgencyCnpjNotifier extends StateNotifier<AgencyCnpjState> {
  AgencyCnpjNotifier(
    this._cnpjController,
    this._focusNode, {
    CnpjService? service,
  })  : _service = service ?? CnpjService(),
        super(const AgencyCnpjState());

  final CnpjService _service;
  final TextEditingController _cnpjController;
  final FocusNode _focusNode;

  TextEditingController get textController => _cnpjController;
  FocusNode get focusNode => _focusNode;

  void onChanged(String value) {
    if (state.status == AgencyCnpjStatus.idle && state.cnpj == value) {
      return;
    }

    state = state.copyWith(
      status: AgencyCnpjStatus.idle,
      cnpj: value,
      isLoading: false,
      error: null,
      cnpjData: null,
    );
  }

  Future<void> consultCnpj() async {
    final rawCnpj = onlyDigits(_cnpjController.text);

    if (!isValidCnpj(rawCnpj)) {
      state = state.copyWith(
        status: AgencyCnpjStatus.invalid,
        cnpj: _cnpjController.text,
        isLoading: false,
        error: _kCnpjInvalido,
        cnpjData: null,
      );
      return;
    }

    state = state.copyWith(
      status: AgencyCnpjStatus.loading,
      cnpj: _cnpjController.text,
      isLoading: true,
      error: null,
      cnpjData: null,
    );

    try {
      final result = await _service.fetchCnpj(rawCnpj);
      final alreadyRegistered = await _service.cnpjExistsAgency(rawCnpj);

      if (alreadyRegistered) {
        state = state.copyWith(
          status: AgencyCnpjStatus.duplicate,
          isLoading: false,
          error: _kCnpjDuplicado,
          cnpjData: null,
        );
        return;
      }

      state = state.copyWith(
        status: AgencyCnpjStatus.success,
        isLoading: false,
        error: null,
        cnpjData: result,
      );
    } on CnpjNotFoundException {
      state = state.copyWith(
        status: AgencyCnpjStatus.notFound,
        isLoading: false,
        error: _kCnpjNaoEncontrado,
        cnpjData: null,
      );
    } on CnpjInactiveException {
      state = state.copyWith(
        status: AgencyCnpjStatus.inactive,
        isLoading: false,
        error: _kCnpjInativo,
        cnpjData: null,
      );
    } on CnpjServiceException {
      state = state.copyWith(
        status: AgencyCnpjStatus.genericError,
        isLoading: false,
        error: _kCnpjErroGenerico,
        cnpjData: null,
      );
    } catch (_) {
      state = state.copyWith(
        status: AgencyCnpjStatus.genericError,
        isLoading: false,
        error: _kCnpjErroGenerico,
        cnpjData: null,
      );
    }
  }
}
