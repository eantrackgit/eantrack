import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/utils/string_utils.dart';
import '../models/cnpj_model.dart';

/// Serviço responsável por consultar dados de CNPJ na BrasilAPI
/// e validar duplicidade da agência no backend.
class CnpjService {
  CnpjService({
    SupabaseClient? supabaseClient,
  }) : _supabaseClient = supabaseClient ?? Supabase.instance.client;

  static const String _baseUrl = 'https://brasilapi.com.br/api/cnpj/v1';
  final SupabaseClient _supabaseClient;

  /// Consulta o CNPJ informado na BrasilAPI.
  ///
  /// Retorna um [CnpjModel] quando a empresa existe e está ativa.
  /// Lança exceções específicas para CNPJ não encontrado, inativo
  /// ou falhas de comunicação/interpretação da resposta.
  Future<CnpjModel> fetchCnpj(String cnpj) async {
    final normalizedCnpj = onlyDigits(cnpj);
    final client = http.Client();

    try {
      final response = await client.get(
        Uri.parse('$_baseUrl/$normalizedCnpj'),
        headers: const {'Accept': 'application/json'},
      );
      final body = response.body;

      if (response.statusCode == 404) {
        throw const CnpjNotFoundException();
      }

      if (response.statusCode != 200) {
        throw CnpjServiceException(
          'Falha ao consultar o CNPJ. Status ${response.statusCode}.',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const CnpjServiceException(
          'Resposta inválida ao consultar o CNPJ.',
        );
      }

      final model = CnpjModel.fromJson(decoded);
      final status = model.situacaoCadastral.trim().toUpperCase();

      if (status != 'ATIVA') {
        throw const CnpjInactiveException();
      }

      return model;
    } on http.ClientException {
      throw const CnpjServiceException(
        'Não foi possível consultar o CNPJ agora.',
      );
    } on FormatException {
      throw const CnpjServiceException(
        'Não foi possível interpretar a resposta da consulta.',
      );
    } finally {
      client.close();
    }
  }

  /// Verifica no backend se já existe uma agência cadastrada com este CNPJ.
  ///
  /// A RPC pode retornar bool, número, string, lista ou mapa, então o resultado
  /// é normalizado para um booleano com [_isTruthy].
  Future<bool> cnpjExistsAgency(String cnpj) async {
    final normalizedCnpj = onlyDigits(cnpj);
    try {
      final result = await _supabaseClient.rpc(
        'cnpj_exists_agency',
        params: {'p_cnpj': normalizedCnpj},
      );
      return _isTruthy(result);
    } on PostgrestException catch (e) {
      throw CnpjServiceException(
        'Erro ao verificar duplicidade do CNPJ. (${e.code})',
      );
    }
  }

  /// Normaliza diferentes formatos de retorno da RPC para um booleano.
  bool _isTruthy(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == 'true' ||
          normalized == 't' ||
          normalized == '1' ||
          normalized == 'yes' ||
          normalized == 'y' ||
          normalized == 'sim' ||
          normalized == 's';
    }

    if (value is Map) {
      for (final entryValue in value.values) {
        if (_isTruthy(entryValue)) return true;
      }
      return false;
    }

    if (value is Iterable) {
      for (final item in value) {
        if (_isTruthy(item)) return true;
      }
      return false;
    }

    return false;
  }
}

/// Exceção base para falhas relacionadas ao fluxo de consulta de CNPJ.
class CnpjServiceException implements Exception {
  const CnpjServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Indica que nenhum registro foi encontrado para o CNPJ consultado.
class CnpjNotFoundException extends CnpjServiceException {
  const CnpjNotFoundException()
      : super('Não encontramos uma empresa com este CNPJ.');
}

/// Indica que o CNPJ existe, porém não está com situação cadastral ativa.
class CnpjInactiveException extends CnpjServiceException {
  const CnpjInactiveException()
      : super('Este CNPJ está inativo na Receita Federal.');
}
