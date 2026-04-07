abstract class CooldownStorage {
  int? readInt(String key);
  void writeInt(String key, int value);
  void remove(String key);
}
