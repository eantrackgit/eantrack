import 'password_recovery_cooldown_storage_base.dart';

class _MemoryCooldownStorage implements CooldownStorage {
  final Map<String, int> _storage = <String, int>{};

  @override
  int? readInt(String key) => _storage[key];

  @override
  void remove(String key) => _storage.remove(key);

  @override
  void writeInt(String key, int value) {
    _storage[key] = value;
  }
}

CooldownStorage createCooldownStorageImpl() => _MemoryCooldownStorage();
