import 'package:supabase_flutter/supabase_flutter.dart';

class UserSettingsRepository {
  UserSettingsRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  static const Map<String, dynamic> defaultSettings = <String, dynamic>{};

  Future<Map<String, dynamic>> loadSettings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return Map<String, dynamic>.from(defaultSettings);
    }

    final response = await _supabase
        .from('user_settings')
        .select('settings')
        .eq('user_id', userId)
        .maybeSingle();

    final settings = response?['settings'];
    if (settings is Map<String, dynamic>) {
      return Map<String, dynamic>.from(settings);
    }
    if (settings is Map) {
      return Map<String, dynamic>.from(settings);
    }

    return Map<String, dynamic>.from(defaultSettings);
  }

  Future<Map<String, dynamic>> upsertSettings(
    Map<String, dynamic> settings,
  ) async {
    final userId = _currentUserId();
    final currentSettings = await loadSettings();
    final nextSettings = <String, dynamic>{
      ...currentSettings,
      ...settings,
    };

    final response = await _supabase
        .from('user_settings')
        .upsert(
          {
            'user_id': userId,
            'settings': nextSettings,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          },
          onConflict: 'user_id',
        )
        .select('settings')
        .maybeSingle();

    final savedSettings = response?['settings'];
    if (savedSettings is Map<String, dynamic>) {
      return Map<String, dynamic>.from(savedSettings);
    }
    if (savedSettings is Map) {
      return Map<String, dynamic>.from(savedSettings);
    }

    return nextSettings;
  }

  String _currentUserId() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const UserSettingsRepositoryException('Usuario nao autenticado.');
    }
    return userId;
  }
}

class UserSettingsRepositoryException implements Exception {
  const UserSettingsRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
