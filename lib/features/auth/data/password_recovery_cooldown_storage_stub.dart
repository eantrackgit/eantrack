import 'password_recovery_cooldown_storage_base.dart';

class _MemoryCooldownStorage implements CooldownStorage {
  final Map<String, int> _storage = <String, int>{};
  final Map<String, String> _stringStorage = <String, String>{};

  @override
  int? readInt(String key) => _storage[key];

  @override
  String? readString(String key) => _stringStorage[key];

  @override
  void remove(String key) {
    _storage.remove(key);
    _stringStorage.remove(key);
  }

  @override
  void writeInt(String key, int value) {
    _storage[key] = value;
  }

  @override
  void writeString(String key, String value) {
    _stringStorage[key] = value;
  }
}

CooldownStorage createCooldownStorageImpl() => _MemoryCooldownStorage();
