import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/error/app_exception.dart';
import '../../data/auth_repository.dart';
import '../../data/password_history_service.dart';
import '../../data/password_recovery_cooldown_storage.dart';
import '../../domain/auth_flow_state.dart';
import '../../domain/auth_state.dart';

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

final supabaseClientProvider = Provider<SupabaseClient>(
  (_) => Supabase.instance.client,
);

final passwordHistoryServiceProvider = Provider<PasswordHistoryService>(
  (ref) => PasswordHistoryService(ref.read(supabaseClientProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    client: ref.read(supabaseClientProvider),
    passwordHistoryService: ref.read(passwordHistoryServiceProvider),
  ),
);

final passwordRecoveryCooldownStorageProvider = Provider<CooldownStorage>(
  (_) => createCooldownStorage(),
);

/// Raw Supabase auth stream — User? (null = not logged in).
final authRecoveryContextProvider =
    StateNotifierProvider<AuthRecoveryContextNotifier, bool>((ref) {
  return AuthRecoveryContextNotifier(
    ref.read(supabaseClientProvider),
  );
});

final authUserStreamProvider = StreamProvider<User?>((ref) {
  return ref.read(authRepositoryProvider).authStateStream;
});

final authFlowStateProvider = Provider<AuthFlowState>((ref) {
  final isRecovery = ref.watch(authRecoveryContextProvider);
  final authState = ref.watch(authNotifierProvider);
  final authUser = ref.watch(authUserStreamProvider).valueOrNull;
  final hasSession = isRecovery || authUser != null;

  if (isRecovery) {
    return AuthFlowState.recovery;
  }
  if (authState is AuthAuthenticated) {
    return _hasIndividualHubAccess(authState)
        ? AuthFlowState.authenticated
        : AuthFlowState.onboardingRequired;
  }
  if (!hasSession) {
    return AuthFlowState.unauthenticated;
  }
  return AuthFlowState.onboardingRequired;
});

bool _hasIndividualHubAccess(AuthAuthenticated authState) {
  final flowState = authState.flowState;
  return flowState?.normalizedUserMode == 'individual' &&
      flowState?.hasProfile == true;
}

// ---------------------------------------------------------------------------
// Auth notifier
// ---------------------------------------------------------------------------

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final notifier = AuthNotifier(ref.read(authRepositoryProvider));

  // Escuta mudanças externas de auth (OAuth callback, sessão restaurada).
  // Quando um novo usuário aparece no stream sem que o notifier saiba,
  // busca o flowState e transita para AuthAuthenticated.
  ref.listen<AsyncValue<User?>>(authUserStreamProvider, (prev, next) {
    next.whenData((user) {
      if (user != null && !notifier.isAuthenticated) {
        final isRecovery = ref.read(authRecoveryContextProvider);
        if (!isRecovery) {
          notifier.onExternalAuthChange(user);
        }
      } else if (user == null &&
          notifier.shouldHandleExternalSignOut) {
        notifier.onSignedOut();
      }
    });
  });

  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthInitial());

  final AuthRepository _repo;

  bool get isAuthenticated => state is AuthAuthenticated;

  bool get shouldHandleExternalSignOut =>
      state is! AuthUnauthenticated &&
      state is! AuthInitial &&
      state is! AuthEmailUnconfirmed;

  // --- Sign in ---

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading('Entrando...');
    try {
      await _repo.signIn(email: email, password: password);
      final user = _repo.currentUser!;
      final flowState = await _repo.getUserFlowState(user.id);
      state = AuthAuthenticated(user: user, flowState: flowState);
    } on EmailNotConfirmedException {
      state = AuthEmailUnconfirmed(email: email);
    } on AppException catch (e) {
      state = AuthError(e.message);
    }
  }

  // --- Sign up ---

  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading('Criando sua conta...');
    try {
      await _repo.signUp(email: email, password: password);
      state = AuthEmailUnconfirmed(email: email);
    } on AppException catch (e) {
      state = AuthError(e.message);
    }
  }

  // --- Sign out ---

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthUnauthenticated();
  }

  // --- Password reset ---

  /// Sends a password-reset email. Throws [AppException] on failure.
  /// Does NOT mutate state — caller (screen) owns loading/error via AsyncAction.
  Future<void> resetPassword(String email) async {
    await _repo.resetPassword(email);
  }

  // --- Email verification ---

  /// Returns true if the user's email is confirmed on Supabase.
  /// Does NOT sign in — caller must open a password modal to re-authenticate.
  Future<bool> checkEmailConfirmed() async {
    if (state is! AuthEmailUnconfirmed) return false;
    return _repo.isEmailConfirmed();
  }

  /// Called from the password modal after email confirmation.
  /// Signs in with the user-provided password and transitions to AuthAuthenticated.
  Future<void> signInAfterConfirmation({
    required String email,
    required String password,
  }) async {
    await _repo.signIn(email: email, password: password);
    final user = _repo.currentUser;
    if (user != null) {
      final flowState = await _repo.getUserFlowState(user.id);
      state = AuthAuthenticated(user: user, flowState: flowState);
    }
  }

  Future<bool> resendVerificationEmail() async {
    final current = state;
    if (current is! AuthEmailUnconfirmed) return false;

    try {
      await _repo.resendVerificationEmail(current.email);
      return true;
    } on AppException {
      return false;
    }
  }

  // --- Google Sign-In ---

  /// Inicia o fluxo OAuth com Google.
  ///
  /// Na Web, o browser redireciona para o Google e volta ao app.
  /// A transição de estado para [AuthAuthenticated] é tratada por
  /// [onExternalAuthChange], chamado pelo listener do stream.
  Future<void> signInWithGoogle() async {
    state = const AuthLoading('Entrando com Google...');
    try {
      await _repo.signInWithGoogle();
      // Na web: o browser vai para o Google. O estado será atualizado
      // pelo stream listener quando o OAuth callback retornar.
    } on AppException catch (e) {
      state = AuthError(e.message);
    }
  }

  // --- Handlers de mudanças externas (OAuth, restauração de sessão) ---

  /// Chamado quando o stream detecta um novo usuário autenticado
  /// sem ação explícita do notifier (ex: OAuth callback, deep link).
  Future<void> onExternalAuthChange(User user) async {
    state = const AuthLoading('Verificando...');
    final flowState = await _repo.getUserFlowState(user.id);
    state = AuthAuthenticated(user: user, flowState: flowState);
  }

  /// Chamado quando o stream detecta que o usuário saiu externamente.
  void onSignedOut() {
    state = const AuthUnauthenticated();
  }

  // --- Utilities ---

  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}

class AuthRecoveryContextNotifier extends StateNotifier<bool> {
  AuthRecoveryContextNotifier(this._client) : super(false) {
    _subscription = _client.auth.onAuthStateChange.listen(_onAuthStateChange);
  }

  final SupabaseClient _client;
  late final StreamSubscription<dynamic> _subscription;

  void _onAuthStateChange(dynamic data) {
    final event = data.event as AuthChangeEvent;

    if (event == AuthChangeEvent.passwordRecovery) {
      state = true;
      return;
    }

    if (event == AuthChangeEvent.signedOut) {
      state = false;
      return;
    }

    if (event == AuthChangeEvent.initialSession && data.session == null) {
      state = false;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Resend cooldown providers (rate limiting)
// ---------------------------------------------------------------------------

/// Shared resend cooldown state model.
///
/// Email verification keeps this state only in memory.
/// Password recovery optionally restores/persists `lockedUntil` externally.
final emailCooldownProvider = StateNotifierProvider.autoDispose<
    ResendCooldownNotifier, ResendCooldownState>(
  (_) => ResendCooldownNotifier(
    lockDuration: const Duration(minutes: 5),
    maxAttempts: 3,
  ),
);

final passwordRecoveryCooldownProvider = StateNotifierProvider.autoDispose<
    ResendCooldownNotifier, ResendCooldownState>(
  (ref) => ResendCooldownNotifier(
    lockDuration: const Duration(minutes: 15),
    storage: ref.read(passwordRecoveryCooldownStorageProvider),
    storageKey: passwordRecoveryCooldownStorageKey,
    storageEmailKey: passwordRecoveryCooldownEmailStorageKey,
  ),
);

const passwordRecoveryCooldownStorageKey =
    'auth.password_recovery.locked_until_ms';
const passwordRecoveryCooldownEmailStorageKey =
    'auth.password_recovery.email';

class ResendCooldownState {
  const ResendCooldownState({
    required this.lockDuration,
    this.attempts = 0,
    this.maxAttempts,
    this.lockedUntil,
    this.email,
  });

  final int attempts;
  final int? maxAttempts;
  final DateTime? lockedUntil;
  final Duration lockDuration;
  final String? email;

  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  bool get hasStoredLock => lockedUntil != null;

  Duration get remainingLock {
    if (!isLocked) return Duration.zero;
    return lockedUntil!.difference(DateTime.now());
  }

  bool get hasReachedAttemptLimit {
    final limit = maxAttempts;
    return limit != null && attempts >= limit;
  }
}

class ResendCooldownNotifier extends StateNotifier<ResendCooldownState> {
  ResendCooldownNotifier({
    required Duration lockDuration,
    int? maxAttempts,
    CooldownStorage? storage,
    String? storageKey,
    String? storageEmailKey,
  }) : _lockDuration = lockDuration,
       _maxAttempts = maxAttempts,
       _storage = storage,
       _storageKey = storageKey,
       _storageEmailKey = storageEmailKey,
       super(
         ResendCooldownState(
           lockDuration: lockDuration,
           maxAttempts: maxAttempts,
         ),
       ) {
    restorePersistedLock();
  }

  final CooldownStorage? _storage;
  final String? _storageKey;
  final String? _storageEmailKey;

  final Duration _lockDuration;
  final int? _maxAttempts;

  void restorePersistedLock() {
    final key = _storageKey;
    final storage = _storage;
    if (key == null || storage == null) return;

    final milliseconds = storage.readInt(key);
    final email = _readStoredEmail();
    if (milliseconds == null) {
      _clearStoredEmail();
      return;
    }

    final lockedUntil = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    if (!DateTime.now().isBefore(lockedUntil)) {
      storage.remove(key);
      _clearStoredEmail();
      if (state.lockedUntil != null) {
        state = ResendCooldownState(
          lockDuration: _lockDuration,
          maxAttempts: _maxAttempts,
        );
      }
      return;
    }

    state = ResendCooldownState(
      attempts: state.attempts,
      maxAttempts: _maxAttempts,
      lockDuration: _lockDuration,
      lockedUntil: lockedUntil,
      email: email,
    );
  }

  void onResendSuccess({String? email}) {
    final lockedUntil = DateTime.now().add(_lockDuration);
    final key = _storageKey;
    final normalizedEmail = email?.trim();

    if (key != null) {
      _storage?.writeInt(key, lockedUntil.millisecondsSinceEpoch);
    }
    if (normalizedEmail != null && normalizedEmail.isNotEmpty) {
      final emailKey = _storageEmailKey;
      if (emailKey != null) {
        _storage?.writeString(emailKey, normalizedEmail);
      }
    } else {
      _clearStoredEmail();
    }

    state = ResendCooldownState(
      attempts: state.attempts + 1,
      maxAttempts: _maxAttempts,
      lockDuration: _lockDuration,
      lockedUntil: lockedUntil,
      email: normalizedEmail ?? state.email,
    );
  }

  void clearExpiredLockIfNeeded() {
    if (state.lockedUntil == null || state.isLocked) return;
    reset();
  }

  void reset() {
    final key = _storageKey;
    if (key != null) {
      _storage?.remove(key);
    }
    _clearStoredEmail();

    state = ResendCooldownState(
      lockDuration: _lockDuration,
      maxAttempts: _maxAttempts,
    );
  }

  String? _readStoredEmail() {
    final emailKey = _storageEmailKey;
    if (emailKey == null) return null;
    final email = _storage?.readString(emailKey)?.trim();
    if (email == null || email.isEmpty) return null;
    return email;
  }

  void _clearStoredEmail() {
    final emailKey = _storageEmailKey;
    if (emailKey != null) {
      _storage?.remove(emailKey);
    }
  }
}
