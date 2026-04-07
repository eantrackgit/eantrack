import 'password_recovery_cooldown_storage_base.dart';
import 'password_recovery_cooldown_storage_stub.dart'
    if (dart.library.html) 'password_recovery_cooldown_storage_web.dart';

export 'password_recovery_cooldown_storage_base.dart';

CooldownStorage createCooldownStorage() => createCooldownStorageImpl();
