import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/utils/string_utils.dart';
import '../models/cnpj_model.dart';

/// Serviço responsável por persistir a agência no Supabase ao final do
/// onboarding de confirmação de dados.
class AgencyConfirmService {
  AgencyConfirmService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Insere a agência na tabela `agencies` e devolve o UUID gerado.
  ///
  /// Lança [AgencyAlreadyRegisteredException] quando o CNPJ já existe (código
  /// Postgres 23505) e [AgencyConfirmServiceException] para os demais erros.
  Future<String> saveAgency({
    required CnpjModel cnpjModel,
    required String nomeFantasia,
    required String telefoneContato,
    required String email,
    required String cep,
    required String logradouro,
    required String numero,
    required String municipio,
    required String uf,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const AgencyConfirmServiceException('Usuário não autenticado.');
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
          'Não foi possível identificar a agência salva.',
        );
      }
      return id;
    } on PostgrestException catch (e) {
      if (e.code == '23505') throw const AgencyAlreadyRegisteredException();
      throw const AgencyConfirmServiceException(
        'Erro ao salvar agência. Tente novamente.',
      );
    }
  }
}

/// Exceção base para falhas no fluxo de confirmação de agência.
class AgencyConfirmServiceException implements Exception {
  const AgencyConfirmServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Exceção emitida quando o CNPJ já está cadastrado (constraint 23505).
class AgencyAlreadyRegisteredException extends AgencyConfirmServiceException {
  const AgencyAlreadyRegisteredException()
      : super('Esta agência já está cadastrada em nossa plataforma.');
}
