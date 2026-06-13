import 'package:shared_preferences/shared_preferences.dart';

const keepConnectedSavedEmailStorageKey = 'eantrack_keep_connected_email';

class KeepConnectedPromptStorage {
  const KeepConnectedPromptStorage();

  Future<String?> loadSavedLoginEmail() async {
    final preferences = await SharedPreferences.getInstance();
    final email = preferences.getString(keepConnectedSavedEmailStorageKey)
        ?.trim()
        .toLowerCase();
    return email == null || email.isEmpty ? null : email;
  }

  Future<void> saveSavedLoginEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) {
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
