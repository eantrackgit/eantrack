import 'package:shared_preferences/shared_preferences.dart';

const keepConnectedSavedEmailStorageKey = 'eantrack_keep_connected_email';

class KeepConnectedPromptStorage {
  const KeepConnectedPromptStorage();

  // savedLoginEmail is a local cache for the saved-account UX only — never a
  // credential, and never the source of truth (Supabase user_settings is).
  Future<String?> loadSavedLoginEmail() async {
    final preferences = await SharedPreferences.getInstance();
    final email = preferences.getString(keepConnectedSavedEmailStorageKey)
        ?.trim()
        .toLowerCase();
    if (email == null || email.isEmpty) return null;

    // Corrupted/invalid local cache must not break the saved-account UX.
    if (!email.contains('@')) {
      await clearSavedLoginEmail();
      return null;
    }
    return email;
  }

  Future<void> saveSavedLoginEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      await clearSavedLoginEmail();
      return;
    }

    final preferences = await SharedPreferences.getInstance();
    // This is a local UX hint only. Supabase keeps credentials and tokens; the
    // database still stores only the keep_connected boolean.
    await preferences.setString(
      keepConnectedSavedEmailStorageKey,
      normalizedEmail,
    );
  }

  Future<void> clearSavedLoginEmail() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(keepConnectedSavedEmailStorageKey);
  }

  // The prompt-answered flag is controlled purely by userId, locally, so the
  // "Manter conectado?" dialog is not re-shown on every F5/restart.
  Future<bool> wasPromptAnswered(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_keyFor(userId)) ?? false;
  }

  Future<void> markPromptAnswered(String userId) async {
    final preferences = await SharedPreferences.getInstance();
    // The local flag is scoped by user id and stores only that the prompt was
    // answered on this device; credentials and personal data stay out of it.
    await preferences.setBool(_keyFor(userId), true);
  }

  String _keyFor(String userId) =>
      'keep_connected_prompt_answered_${userId.trim()}';
}
