import 'package:supabase_flutter/supabase_flutter.dart';

class UserSettingsRepository {
  UserSettingsRepository({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  static const Map<String, dynamic> defaultSettings = <String, dynamic>{};

  Future<void> ensureUserSettings(String userId) async {
    final normalizedUserId = _validateUserId(userId);

    await _supabase.from('user_settings').upsert(
      {
        'user_id': normalizedUserId,
        'settings': defaultSettings,
        'keep_connected': false,
      },
      onConflict: 'user_id',
      ignoreDuplicates: true,
      defaultToNull: false,
    );
  }

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

  Future<bool> getKeepConnected(String userId) async {
    final normalizedUserId = _validateUserId(userId);
    await ensureUserSettings(normalizedUserId);

    // keep_connected is only a boolean preference. Supabase Auth keeps owning
    // credentials, tokens, refresh tokens, and the authenticated session.
    final response = await _supabase
        .from('user_settings')
        .select('keep_connected')
        .eq('user_id', normalizedUserId)
        .maybeSingle();

    return response?['keep_connected'] == true;
  }

  Future<bool> upsertKeepConnected(String userId, bool value) async {
    final normalizedUserId = _validateUserId(userId);
    await ensureUserSettings(normalizedUserId);

    final response = await _supabase
        .from('user_settings')
        .update({'keep_connected': value})
        .eq('user_id', normalizedUserId)
        .select('keep_connected')
        .maybeSingle();

    return response?['keep_connected'] == true;
  }

  String _currentUserId() {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw const UserSettingsRepositoryException('Usuario nao autenticado.');
    }
    return userId;
  }

  String _validateUserId(String userId) {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) {
      throw const UserSettingsRepositoryException('Usuario nao autenticado.');
    }
    return normalizedUserId;
  }
}

class UserSettingsRepositoryException implements Exception {
  const UserSettingsRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
