import 'package:eantrack/features/auth/data/password_recovery_cooldown_storage.dart';
import 'package:eantrack/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCooldownStorage implements CooldownStorage {
  final Map<String, int> intValues = <String, int>{};
  final Map<String, String> stringValues = <String, String>{};

  @override
  int? readInt(String key) => intValues[key];

  @override
  String? readString(String key) => stringValues[key];

  @override
  void writeInt(String key, int value) {
    intValues[key] = value;
  }

  @override
  void writeString(String key, String value) {
    stringValues[key] = value;
  }

  @override
  void remove(String key) {
    intValues.remove(key);
    stringValues.remove(key);
  }
}

void main() {
  test('restaura cooldown persistido de recuperacao enquanto ainda valido', () {
    final storage = _FakeCooldownStorage();
    final lockedUntil = DateTime.now().add(const Duration(minutes: 10));

    storage.writeInt(
      passwordRecoveryCooldownStorageKey,
      lockedUntil.millisecondsSinceEpoch,
    );

    final notifier = ResendCooldownNotifier(
      lockDuration: const Duration(minutes: 15),
      storage: storage,
      storageKey: passwordRecoveryCooldownStorageKey,
    );

    expect(notifier.state.isLocked, isTrue);
    expect(notifier.state.lockedUntil, isNotNull);
    expect(
      storage.readInt(passwordRecoveryCooldownStorageKey),
      lockedUntil.millisecondsSinceEpoch,
    );
  });

  test('limpa cooldown persistido quando o lockedUntil ja expirou', () {
    final storage = _FakeCooldownStorage();

    storage.writeInt(
      passwordRecoveryCooldownStorageKey,
      DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch,
    );

    final notifier = ResendCooldownNotifier(
      lockDuration: const Duration(minutes: 15),
      storage: storage,
      storageKey: passwordRecoveryCooldownStorageKey,
    );

    expect(notifier.state.isLocked, isFalse);
    expect(notifier.state.lockedUntil, isNull);
    expect(storage.readInt(passwordRecoveryCooldownStorageKey), isNull);
  });

  test('persiste lockedUntil ao iniciar cooldown de recuperacao', () {
    final storage = _FakeCooldownStorage();
    final notifier = ResendCooldownNotifier(
      lockDuration: const Duration(minutes: 15),
      storage: storage,
      storageKey: passwordRecoveryCooldownStorageKey,
    );

    notifier.onResendSuccess();

    expect(notifier.state.isLocked, isTrue);
    expect(storage.readInt(passwordRecoveryCooldownStorageKey), isNotNull);
  });
}
