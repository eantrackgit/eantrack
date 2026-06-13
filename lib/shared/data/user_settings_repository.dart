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

  // keep_connected is treated in the app as the "remember me" preference: it
  // does not extend or alter tokens/refresh tokens and does not replace
  // Supabase Auth. It only controls the local saved-account UX and the
  // local cache/logout behavior. It is the only preference persisted in
  // Supabase for this feature, kept light so user_settings stays cheap at
  // 100k+ users. Never store email, display name, avatar, tokens, or any
  // UX/device metadata here — that all belongs to local storage.

  /// Single indexed read, no writes. Missing row falls back to `false`,
  /// matching the column default.
  Future<bool> getKeepConnected(String userId) async {
    final normalizedUserId = _validateUserId(userId);

    final response = await _supabase
        .from('user_settings')
        .select('keep_connected')
        .eq('user_id', normalizedUserId)
        .maybeSingle();

    return response?['keep_connected'] == true;
  }

  /// Reads the current value and writes only if it actually changes, so
  /// re-saving the same preference never hits the database.
  Future<bool> setKeepConnectedIfChanged(String userId, bool value) async {
    final normalizedUserId = _validateUserId(userId);
    final current = await getKeepConnected(normalizedUserId);
    if (current == value) return current;
    return upsertKeepConnected(normalizedUserId, value);
  }

  /// Single upsert touching only `keep_connected`. On conflict, `settings`
  /// and `created_at` are left untouched; `updated_at` is handled by the
  /// existing trigger.
  Future<bool> upsertKeepConnected(String userId, bool value) async {
    final normalizedUserId = _validateUserId(userId);

    final response = await _supabase
        .from('user_settings')
        .upsert(
          {'user_id': normalizedUserId, 'keep_connected': value},
          onConflict: 'user_id',
          defaultToNull: false,
        )
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
