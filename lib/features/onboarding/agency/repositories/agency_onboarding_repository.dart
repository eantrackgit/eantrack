import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final agencyOnboardingRepositoryProvider = Provider<AgencyOnboardingRepository>(
  (_) => AgencyOnboardingRepository(),
);

class AgencyOnboardingRepository {
  AgencyOnboardingRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  Future<void> deleteAgencyOnboardingById(String agencyId) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const AgencyOnboardingRepositoryException(
        'Usuario nao autenticado.',
      );
    }

    try {
      final deleted = await _supabase
          .from('agencies')
          .delete()
          .eq('id', agencyId)
          .eq('user_uuid', userId)
          .select('id')
          .maybeSingle();

      if (deleted == null) {
        throw const AgencyOnboardingRepositoryException(
          'Nao foi possivel localizar a agencia para reiniciar o cadastro.',
        );
      }
    } on PostgrestException {
      throw const AgencyOnboardingRepositoryException(
        'Nao foi possivel reiniciar o cadastro da agencia.',
      );
    }
  }
}

class AgencyOnboardingRepositoryException implements Exception {
  const AgencyOnboardingRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
