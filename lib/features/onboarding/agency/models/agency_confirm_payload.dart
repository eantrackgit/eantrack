import 'cnpj_model.dart';

/// Agrupa os dados da agência que precisam seguir para a etapa seguinte.
/// Combina o `agencyId` persistido, o retorno fiscal do CNPJ e os ajustes
/// feitos na tela de confirmação antes do cadastro do representante legal.
class AgencyConfirmPayload {
  const AgencyConfirmPayload({
    required this.agencyId,
    required this.cnpjModel,
    required this.formData,
    this.legalRepresentativeId,
  });

  /// Identificador da agência salvo antes da etapa do representante legal.
  final String agencyId;

  /// Identificador do representante existente, usado em fluxos de correcao.
  final String? legalRepresentativeId;

  /// Dados fiscais retornados pela consulta de CNPJ.
  final CnpjModel cnpjModel;

  /// Dados editáveis confirmados pelo usuário na etapa anterior.
  final AgencyConfirmFormData formData;

  factory AgencyConfirmPayload.fromJson(Map<String, dynamic> json) {
    return AgencyConfirmPayload(
      agencyId: json['agency_id']?.toString() ?? '',
      legalRepresentativeId: json['legal_representative_id']?.toString(),
      cnpjModel: CnpjModel.fromJson(
        json['cnpj_model'] as Map<String, dynamic>,
      ),
      formData: AgencyConfirmFormData.fromJson(
        json['form_data'] as Map<String, dynamic>,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'agency_id': agencyId,
      'legal_representative_id': legalRepresentativeId,
      'cnpj_model': cnpjModel.toJson(),
      'form_data': formData.toJson(),
    };
  }
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

  /// Nome fantasia confirmado para a agência.
  final String nomeFantasia;

  /// Telefone principal de contato da agência.
  final String telefoneContato;

  /// E-mail institucional informado no formulário.
  final String email;

  /// CEP utilizado para buscar e confirmar o endereço.
  final String cep;

  /// Logradouro principal da agência.
  final String logradouro;

  /// Número do endereço informado manualmente.
  final String numero;

  /// Bairro correspondente ao endereço da agência.
  final String bairro;

  /// Município da agência.
  final String municipio;

  /// Unidade federativa da agência.
  final String uf;

  factory AgencyConfirmFormData.fromJson(Map<String, dynamic> json) {
    return AgencyConfirmFormData(
      nomeFantasia: json['nome_fantasia']?.toString() ?? '',
      telefoneContato: json['telefone_contato']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      cep: json['cep']?.toString() ?? '',
      logradouro: json['logradouro']?.toString() ?? '',
      numero: json['numero']?.toString() ?? '',
      bairro: json['bairro']?.toString() ?? '',
      municipio: json['municipio']?.toString() ?? '',
      uf: json['uf']?.toString() ?? '',
    );
  }

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
