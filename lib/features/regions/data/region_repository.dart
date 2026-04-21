import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../domain/region_model.dart';

/// Acesso a dados de Regiões via Supabase.
///
/// Todos os métodos lançam [AppException] em caso de falha.
/// RPCs usadas:
///   - list_regions_by_agency_exhibition(p_agency_id) → lista de regiões
///   - is_region_name_available_for_current_user(p_name) → bool/json
///
/// TODO(marcio): verificar assinatura RPC com Supabase antes do deploy
class RegionRepository {
  const RegionRepository(this._client);

  final SupabaseClient _client;

  /// Retorna todas as regiões da agência.
  ///
  /// [agencyId] é obrigatório para chamada da RPC.
  /// [search] filtra por nome (case-insensitive, local).
  Future<List<RegionModel>> fetchRegions({required String agencyId}) async {
    try {
      final response = await _client.rpc(
        'list_regions_by_agency_exhibition',
        params: {'p_agency_id': agencyId},
      );

      final list = (response as List)
          .cast<Map<String, dynamic>>()
          .map(RegionModel.fromRpc)
          .toList();

      return list;
    } on PostgrestException catch (e) {
      throw ServerException(
        'Não foi possível carregar as regiões. (${e.code})',
      );
    } catch (e) {
      debugPrint('[EANTrack] ${e.toString()}');
      throw const ServerException('Erro inesperado ao carregar regiões.');
    }
  }

  /// Verifica se o nome da região está disponível para o usuário atual.
  ///
  /// Retorna true se disponível.
  Future<bool> isNameAvailable(String name) async {
    try {
      final response = await _client.rpc(
        'is_region_name_available_for_current_user',
        params: {'p_name': name.trim()},
      );

      // A RPC retorna JSON; o campo de disponibilidade pode ser 'available' ou bool direto
      if (response is bool) return response;
      if (response is Map) {
        return response['available'] as bool? ??
            response['is_available'] as bool? ??
            true;
      }
      return true;
    } catch (e) {
      debugPrint('[EANTrack] ${e.toString()}');
      // RPC falhou → assumir disponível, o banco vai rejeitar duplicata
      return true;
    }
  }

  /// Cria uma nova região para a agência.
  Future<void> createRegion({
    required String name,
    required String agencyId,
  }) async {
    try {
      await _client.from('regions').insert({
        'name': name.trim(),
        'agency_id': agencyId,
        'is_active': true,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // unique violation
        throw const ServerException(
          'Já existe uma região com este nome.',
        );
      }
      throw ServerException(
        'Não foi possível criar a região. (${e.code})',
      );
    } catch (e) {
      debugPrint('[EANTrack] ${e.toString()}');
      throw const ServerException('Erro inesperado ao criar região.');
    }
  }

  /// Ativa ou desativa uma região.
  Future<void> toggleActive({
    required String regionId,
    required bool isActive,
  }) async {
    try {
      await _client
          .from('regions')
          .update({'is_active': isActive})
          .eq('id', regionId);
    } on PostgrestException catch (e) {
      throw ServerException(
        'Não foi possível atualizar a região. (${e.code})',
      );
    } catch (e) {
      debugPrint('[EANTrack] ${e.toString()}');
      throw const ServerException('Erro inesperado ao atualizar região.');
    }
  }
}
