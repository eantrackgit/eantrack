abstract class CooldownStorage {
  int? readInt(String key);
  String? readString(String key);
  void writeInt(String key, int value);
  void writeString(String key, String value);
  void remove(String key);
}
