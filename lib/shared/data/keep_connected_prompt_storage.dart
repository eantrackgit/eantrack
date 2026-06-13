import 'package:shared_preferences/shared_preferences.dart';

class KeepConnectedPromptStorage {
  const KeepConnectedPromptStorage();

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
