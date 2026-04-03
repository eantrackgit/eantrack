import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';

/// Persiste estado do onboarding na tabela `user_flow_state`.
class OnboardingRepository {
  const OnboardingRepository(this._client);

  final SupabaseClient _client;

  /// Salva o modo operacional ('individual' ou 'agencia') no banco.
  Future<void> saveMode(String mode) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw const ServerException('Usuário não autenticado.');
      }

      await _client
          .from('user_flow_state')
          .update({'user_mode': mode})
          .eq('user_id', userId);
    } on PostgrestException catch (e) {
      throw ServerException(
        'Não foi possível salvar o modo de operação. (${e.code})',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException('Erro ao salvar configuração de onboarding.');
    }
  }
}
