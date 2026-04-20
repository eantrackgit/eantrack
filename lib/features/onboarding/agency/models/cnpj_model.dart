import '../../../../shared/utils/string_utils.dart';

/// Modelo de dados da empresa retornado pela BrasilAPI e reutilizado
/// ao longo do onboarding de agências.
///
/// A classe centraliza normalização básica, serialização e algumas
/// representações derivadas usadas na UI, como CNPJ e CEP formatados.
class CnpjModel {
  const CnpjModel({
    required this.cnpj,
    required this.razaoSocial,
    required this.nomeFantasia,
    required this.situacaoCadastral,
    this.porte,
    this.cnaePrincipal,
    this.numero,
    required this.cep,
    required this.logradouro,
    required this.bairro,
    required this.municipio,
    required this.uf,
  });

  final String cnpj;
  final String razaoSocial;
  final String nomeFantasia;
  final String situacaoCadastral;
  final String? porte;
  final String? cnaePrincipal;
  final String? numero;
  final String cep;
  final String logradouro;
  final String bairro;
  final String municipio;
  final String uf;

  String get formattedCnpj => formatCnpj(cnpj);

  String get displayName =>
      nomeFantasia.trim().isNotEmpty ? nomeFantasia : razaoSocial;

  String get fullAddress {
    final parts = <String>[
      if (cep.trim().isNotEmpty) formatCep(cep),
      if (logradouro.trim().isNotEmpty) logradouro.trim(),
      if (bairro.trim().isNotEmpty) bairro.trim(),
      if (municipio.trim().isNotEmpty) municipio.trim(),
      if (uf.trim().isNotEmpty) uf.trim(),
    ];
    return parts.join(' - ');
  }

  /// Cria o modelo a partir do payload bruto retornado pela BrasilAPI.
  factory CnpjModel.fromJson(Map<String, dynamic> json) {
    return CnpjModel(
      cnpj: onlyDigits(json['cnpj']?.toString() ?? ''),
      razaoSocial: json['razao_social']?.toString().trim() ?? '',
      nomeFantasia: json['nome_fantasia']?.toString().trim() ?? '',
      situacaoCadastral:
          (json['descricao_situacao_cadastral'] ??
                  json['situacao_cadastral'] ??
                  '')
              .toString()
              .trim(),
      porte: json['porte']?.toString().trim(),
      cnaePrincipal: json['cnae_fiscal_descricao']?.toString().trim(),
      numero: json['numero']?.toString().trim(),
      cep: onlyDigits(json['cep']?.toString() ?? ''),
      logradouro: json['logradouro']?.toString().trim() ?? '',
      bairro: json['bairro']?.toString().trim() ?? '',
      municipio: json['municipio']?.toString().trim() ?? '',
      uf: json['uf']?.toString().trim() ?? '',
    );
  }

  /// Serializa os dados atuais para um mapa simples.
  Map<String, dynamic> toJson() {
    return {
      'cnpj': cnpj,
      'razao_social': razaoSocial,
      'nome_fantasia': nomeFantasia,
      'situacao_cadastral': situacaoCadastral,
      'porte': porte,
      'cnae_principal': cnaePrincipal,
      'numero': numero,
      'cep': cep,
      'logradouro': logradouro,
      'bairro': bairro,
      'municipio': municipio,
      'uf': uf,
    };
  }

  /// Formata um CNPJ de 14 dígitos no padrão `00.000.000/0000-00`.
  static String formatCnpj(String value) {
    final digits = onlyDigits(value);
    if (digits.length != 14) return digits;

    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.'
        '${digits.substring(5, 8)}/${digits.substring(8, 12)}-'
        '${digits.substring(12, 14)}';
  }

  /// Formata um CEP de 8 dígitos no padrão `00000-000`.
  static String formatCep(String value) {
    final digits = onlyDigits(value);
    if (digits.length != 8) return digits;
    return '${digits.substring(0, 5)}-${digits.substring(5, 8)}';
  }
}
