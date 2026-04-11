import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';

/// Persiste o estado inicial do onboarding na tabela `tab_cadastroauxiliar`.
class OnboardingRepository {
  const OnboardingRepository(this._client);

  final SupabaseClient _client;

  String _normalizeIdentifier(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('@', '');
    return normalized.replaceAll(RegExp(r'[^a-z0-9._-]'), '');
  }

  bool _searchContainsIdentifier(dynamic response, String normalized) {
    if (response is! List) return false;

    for (final item in response) {
      if (item is Map && item['identificador'] == normalized) {
        return true;
      }
    }

    return false;
  }

  /// Salva o tipo de usuario ('individual' ou 'agency') no banco.
  Future<void> saveMode(String mode) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const ServerException('Usuário não autenticado.');
      }

      await _client.from('tab_cadastroauxiliar').insert({
        'user_id': userId,
        'typeuser': mode,
      });
    } on PostgrestException catch (e) {
      throw ServerException(
        'Não foi possível salvar o modo de operação. (${e.code})',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException('Erro ao salvar a configuração de onboarding.');
    }
  }

  Future<bool> identificadorExiste(String identificador) async {
    final normalized = _normalizeIdentifier(identificador);
    try {
      final response = await _client.rpc(
        'identifier_exists',
        params: {'p_identificador': normalized},
      );
      final exists = response as bool? ?? false;
      if (exists) return true;

      try {
        final fallback = await _client
            .from('user_identifiers')
            .select('identificador')
            .eq('identificador', normalized)
            .limit(1);

        if (fallback.isNotEmpty) return true;
         } on PostgrestException {
          // Mantem fallback adicional abaixo quando a tabela nao puder ser lida.
         }

      try {
        final searchFallback = await _client.rpc(
          'search_users_by_identifier',
          params: {
            'p_query': normalized,
            'p_limit': 1,
          },
        );

        return _searchContainsIdentifier(searchFallback, normalized);
      } on PostgrestException {
        return false;
      }
    } on PostgrestException catch (e) {
      throw ServerException(
        'Não foi possível verificar o identificador. (${e.code})',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException(
        'Erro ao verificar a disponibilidade do identificador.',
      );
    }
  }

  Future<bool> reservarIdentificadorComCadastro(
    String identificador,
    String nome,
  ) async {
    try {
      final response = await _client.rpc(
        'reservar_identificador_com_cadastro',
        params: {
          'p_identificador': identificador,
          'p_nome': nome,
        },
      );
      return response as bool? ?? false;
    } on PostgrestException catch (e) {
      throw ServerException(
        'Não foi possível concluir o cadastro complementar. (${e.code})',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException(
        'Erro ao concluir o cadastro complementar.',
      );
    }
  }

  Future<void> updateDescricao(String descricao) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const ServerException('Usuário não autenticado.');
      }

      await _client
          .from('tab_cadastroauxiliar')
          .update({
            'descricao': descricao.trim().isEmpty ? null : descricao.trim(),
          })
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(
        'Não foi possível salvar a descrição. (${e.code})',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException('Erro ao salvar a descrição.');
    }
  }
}
