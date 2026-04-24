import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/shared.dart';
import '../models/cnpj_model.dart';

class AgencyEditRecoveryData {
  const AgencyEditRecoveryData({
    required this.agencyId,
    required this.cnpjModel,
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

  final String agencyId;
  final CnpjModel cnpjModel;
  final String nomeFantasia;
  final String telefoneContato;
  final String email;
  final String cep;
  final String logradouro;
  final String numero;
  final String bairro;
  final String municipio;
  final String uf;
}

/// Servico responsavel por persistir a agencia no Supabase ao final do
/// onboarding de confirmacao de dados.
class AgencyConfirmService {
  AgencyConfirmService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Insere a agencia na tabela `agencies` e devolve o UUID gerado.
  ///
  /// Lanca [AgencyAlreadyRegisteredException] quando o CNPJ ja existe (codigo
  /// Postgres 23505) e [AgencyConfirmServiceException] para os demais erros.
  Future<String> saveAgency({
    required CnpjModel cnpjModel,
    required String nomeFantasia,
    required String telefoneContato,
    required String email,
    required String cep,
    required String logradouro,
    required String numero,
    required String bairro,
    required String municipio,
    required String uf,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const AgencyConfirmServiceException('Usuario nao autenticado.');
    }

    try {
      final inserted = await _supabase
          .from('agencies')
          .insert({
            'cnpj': onlyDigits(cnpjModel.cnpj),
            'razao_social': cnpjModel.razaoSocial.trim(),
            'nome_fantasia': nomeFantasia.trim(),
            'porte': cnpjModel.porte?.trim() ?? '',
            'cnae_principal': cnpjModel.cnaePrincipal?.trim() ?? '',
            'cep': onlyDigits(cep),
            'logradouro': logradouro.trim(),
            'numero': numero.trim(),
            'bairro': bairro.trim(),
            'complemento': '',
            'municipio': municipio.trim(),
            'uf': uf.trim(),
            'email_contato': email.trim(),
            'telefone_contato': onlyDigits(telefoneContato),
            'user_uuid': userId,
          })
          .select('id')
          .single();

      final id = inserted['id']?.toString();
      if (id == null || id.isEmpty) {
        throw const AgencyConfirmServiceException(
          'Nao foi possivel identificar a agencia salva.',
        );
      }
      return id;
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const AgencyAlreadyRegisteredException();
      throw const AgencyConfirmServiceException(
        'Erro ao salvar agencia. Tente novamente.',
      );
    }
  }

  Future<void> updateAgency({
    required String agencyId,
    required String nomeFantasia,
    required String telefoneContato,
    required String email,
    required String cep,
    required String logradouro,
    required String numero,
    required String bairro,
    required String municipio,
    required String uf,
  }) async {
    try {
      await _supabase
          .from('agencies')
          .update({
            'nome_fantasia': nomeFantasia.trim(),
            'email_contato': email.trim(),
            'telefone_contato': onlyDigits(telefoneContato),
            'cep': onlyDigits(cep),
            'logradouro': logradouro.trim(),
            'numero': numero.trim(),
            'bairro': bairro.trim(),
            'municipio': municipio.trim(),
            'uf': uf.trim(),
          })
          .eq('id', agencyId);
    } on PostgrestException {
      throw const AgencyConfirmServiceException('Erro ao atualizar agencia.');
    }
  }

  Future<AgencyEditRecoveryData> fetchAgencyForEdit(String agencyId) async {
    try {
      final response = await _supabase
          .from('agencies')
          .select()
          .eq('id', agencyId)
          .single();

      final cnpj = onlyDigits(response['cnpj']?.toString() ?? '');
      final razaoSocial = response['razao_social']?.toString().trim() ?? '';
      final nomeFantasia = response['nome_fantasia']?.toString().trim() ?? '';
      final porte = response['porte']?.toString().trim();
      final cnaePrincipal = response['cnae_principal']?.toString().trim();
      final cep = onlyDigits(response['cep']?.toString() ?? '');
      final logradouro = response['logradouro']?.toString().trim() ?? '';
      final numero = response['numero']?.toString().trim() ?? '';
      final bairro = response['bairro']?.toString().trim() ?? '';
      final municipio = response['municipio']?.toString().trim() ?? '';
      final uf = response['uf']?.toString().trim() ?? '';
      final email = response['email_contato']?.toString().trim() ?? '';
      final telefoneContato =
          response['telefone_contato']?.toString().trim() ?? '';

      return AgencyEditRecoveryData(
        agencyId: response['id']?.toString() ?? agencyId,
        cnpjModel: CnpjModel(
          cnpj: cnpj,
          razaoSocial: razaoSocial,
          nomeFantasia: nomeFantasia,
          situacaoCadastral: 'ATIVA',
          porte: porte,
          cnaePrincipal: cnaePrincipal,
          numero: numero,
          cep: cep,
          logradouro: logradouro,
          bairro: bairro,
          municipio: municipio,
          uf: uf,
        ),
        nomeFantasia: nomeFantasia,
        telefoneContato: telefoneContato,
        email: email,
        cep: cep,
        logradouro: logradouro,
        numero: numero,
        bairro: bairro,
        municipio: municipio,
        uf: uf,
      );
    } on PostgrestException {
      throw const AgencyConfirmServiceException(
        'Erro ao carregar dados da agencia.',
      );
    }
  }
}

/// Excecao base para falhas no fluxo de confirmacao de agencia.
class AgencyConfirmServiceException implements Exception {
  const AgencyConfirmServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Excecao emitida quando o CNPJ ja esta cadastrado (constraint 23505).
class AgencyAlreadyRegisteredException extends AgencyConfirmServiceException {
  const AgencyAlreadyRegisteredException()
      : super('Esta agencia ja esta cadastrada em nossa plataforma.');
}
