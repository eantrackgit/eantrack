import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../shared/shared.dart';

/// Serviço de consulta de CEP via ViaCEP usado na confirmação da agência.
class CepService {
  CepService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  /// Busca o CEP informado no ViaCEP e retorna o endereço normalizado.
  ///
  /// Lança [CepNotFoundException] quando o CEP não existe e
  /// [CepServiceException] quando ocorre falha de rede ou parsing.
  Future<CepAddress> fetchCep(String cep) async {
    final normalizedCep = onlyDigits(cep);

    try {
      final response = await _client.get(
        Uri.parse('https://viacep.com.br/ws/$normalizedCep/json/'),
        headers: const {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        throw const CepNotFoundException();
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw const CepServiceException(
          'Erro ao consultar CEP. Tente novamente.',
        );
      }

      if (decoded['erro'] == true) {
        throw const CepNotFoundException();
      }

      return CepAddress(
        cep: onlyDigits(decoded['cep']?.toString() ?? normalizedCep),
        logradouro: decoded['logradouro']?.toString().trim() ?? '',
        bairro: decoded['bairro']?.toString().trim() ?? '',
        municipio: decoded['localidade']?.toString().trim() ?? '',
        uf: decoded['uf']?.toString().trim() ?? '',
      );
    } on CepNotFoundException {
      rethrow;
    } on http.ClientException {
      throw const CepServiceException(
        'Erro ao consultar CEP. Tente novamente.',
      );
    } on FormatException {
      throw const CepServiceException(
        'Erro ao consultar CEP. Tente novamente.',
      );
    }
  }
}

/// Estrutura simples com os campos de endereço devolvidos pelo ViaCEP.
class CepAddress {
  const CepAddress({
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.municipio,
    required this.uf,
  });

  final String cep;
  final String logradouro;
  final String bairro;
  final String municipio;
  final String uf;
}

/// Exceção base para erros de consulta de CEP.
class CepServiceException implements Exception {
  const CepServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Exceção emitida quando o ViaCEP informa que o CEP não existe.
class CepNotFoundException extends CepServiceException {
  const CepNotFoundException() : super('CEP não encontrado.');
}
