import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final agencyStatusRepositoryProvider = Provider<AgencyStatusRepository>(
  (_) => AgencyStatusRepository(),
);

class AgencyTermsAcceptance {
  const AgencyTermsAcceptance({
    required this.accepted,
    this.acceptedAt,
    this.version,
  });

  final bool accepted;
  final DateTime? acceptedAt;
  final String? version;

  Map<String, dynamic> toJson() {
    return {
      'terms_accepted': accepted,
      'terms_accepted_at': acceptedAt?.toIso8601String(),
      'terms_version': version,
    };
  }

  factory AgencyTermsAcceptance.fromJson(Map<String, dynamic> json) {
    return AgencyTermsAcceptance(
      accepted: _readBool(json['terms_accepted']),
      acceptedAt: _readDate(json['terms_accepted_at']),
      version: _readText(json['terms_version']),
    );
  }

  static bool _readBool(Object? value) {
    if (value is bool) return value;
    if (value == null) return false;

    return value.toString().trim().toLowerCase() == 'true';
  }

  static DateTime? _readDate(Object? value) {
    if (value is DateTime) return value.toLocal();
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static String? _readText(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }
}

class AgencyStatusRepository {
  AgencyStatusRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  static const currentTermsVersion = 'v1.0';

  final SupabaseClient _supabase;

  Future<Map<String, dynamic>> getAgencyStatusFull() async {
    try {
      final response = await _supabase.rpc('get_agency_status_full');

      if (response == null) {
        throw const AgencyStatusRepositoryException(
          'Nao foi possivel carregar o status da agencia.',
        );
      }

      if (response is Map<String, dynamic>) {
        return response;
      }

      if (response is Map) {
        return Map<String, dynamic>.from(response);
      }

      throw const AgencyStatusRepositoryException(
        'Nao foi possivel carregar o status da agencia.',
      );
    } on PostgrestException {
      throw const AgencyStatusRepositoryException(
        'Nao foi possivel carregar o status da agencia.',
      );
    }
  }

  Future<AgencyTermsAcceptance> fetchAgencyTerms(String agencyId) async {
    final userId = _currentUserId();

    try {
      final response = await _supabase
          .from('agencies')
          .select('terms_accepted, terms_accepted_at, terms_version')
          .eq('id', agencyId)
          .eq('user_uuid', userId)
          .maybeSingle();

      if (response == null) {
        throw const AgencyStatusRepositoryException(
          'Nao foi possivel localizar a agencia.',
        );
      }

      return AgencyTermsAcceptance.fromJson(response);
    } on PostgrestException {
      throw const AgencyStatusRepositoryException(
        'Nao foi possivel carregar o aceite dos termos.',
      );
    }
  }

  Future<AgencyTermsAcceptance> acceptAgencyTerms(
    String agencyId,
    String termsVersion,
  ) async {
    final userId = _currentUserId();
    final acceptedAt = DateTime.now().toUtc();

    try {
      final response = await _supabase
          .from('agencies')
          .update({
            'terms_accepted': true,
            'terms_accepted_at': acceptedAt.toIso8601String(),
            'terms_version': termsVersion,
          })
          .eq('id', agencyId)
          .eq('user_uuid', userId)
          .select('terms_accepted, terms_accepted_at, terms_version')
          .maybeSingle();

      if (response == null) {
        throw const AgencyStatusRepositoryException(
          'Nao foi possivel localizar a agencia para salvar o aceite.',
        );
      }

      return AgencyTermsAcceptance.fromJson(response);
    } on PostgrestException {
      throw const AgencyStatusRepositoryException(
        'Nao foi possivel registrar o aceite dos termos.',
      );
    }
  }

  String _currentUserId() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const AgencyStatusRepositoryException('Usuario nao autenticado.');
    }
    return userId;
  }
}

class AgencyStatusRepositoryException implements Exception {
  const AgencyStatusRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
