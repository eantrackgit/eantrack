import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import '../../../../core/error/app_exception.dart';
import '../../data/auth_repository.dart';
import '../../data/password_history_service.dart';
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

/// Placeholder for a future dedicated onboarding source.
/// For now, it derives the current completion status from [AuthAuthenticated].
final authOnboardingCompleteProvider = Provider<bool>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthAuthenticated) {
    return authState.flowState?.isOnboardingComplete ?? false;
  }
  return false;
});

final authFlowStateProvider = Provider<AuthFlowState>((ref) {
  final isRecovery = ref.watch(authRecoveryContextProvider);
  final authUser = ref.watch(authUserStreamProvider).valueOrNull;
  final hasSession = isRecovery ||
      authUser != null;

  if (isRecovery) {
    return AuthFlowState.recovery;
  }
  if (!hasSession) {
    return AuthFlowState.unauthenticated;
  }
  if (!ref.watch(authOnboardingCompleteProvider)) {
    return AuthFlowState.onboardingRequired;
  }
  return AuthFlowState.authenticated;
});

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
      if (user != null && notifier.state is! AuthAuthenticated) {
    final isRecovery = ref.read(authRecoveryContextProvider);
    if (!isRecovery) {
      notifier.onExternalAuthChange(user);
    }
      } else if (user == null &&
          notifier.state is! AuthUnauthenticated &&
          notifier.state is! AuthInitial &&
          notifier.state is! AuthEmailUnconfirmed) {
        notifier.onSignedOut();
      }
    });
  });

  return notifier;
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthInitial());

  final AuthRepository _repo;

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

    switch (event) {
      case AuthChangeEvent.passwordRecovery:
        state = true;
        break;
      case AuthChangeEvent.signedIn:
        break;
      case AuthChangeEvent.signedOut:
      case AuthChangeEvent.userDeleted:
        state = false;
        break;
      case AuthChangeEvent.initialSession:
        if (data.session == null) {
          state = false;
        }
        break;
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.mfaChallengeVerified:
        break;
      default:
        break;
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Email cooldown provider (resend rate limiting)
// ---------------------------------------------------------------------------

/// Tracks resend attempts and cooldown for email verification.
/// Kept in memory only — resets on app restart (matches FlutterFlow behavior).
final emailCooldownProvider = StateNotifierProvider.autoDispose<
    EmailCooldownNotifier, EmailCooldownState>(
  (_) => EmailCooldownNotifier(),
);

class EmailCooldownState {
  const EmailCooldownState({
    this.attempts = 0,
    this.lockedUntil,
  });

  final int attempts;
  final DateTime? lockedUntil;

  bool get isLocked {
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  Duration get remainingLock {
    if (!isLocked) return Duration.zero;
    return lockedUntil!.difference(DateTime.now());
  }

  static const int maxAttempts = 3;
  static const Duration lockDuration = Duration(minutes: 5);
}

class EmailCooldownNotifier extends StateNotifier<EmailCooldownState> {
  EmailCooldownNotifier() : super(const EmailCooldownState());

  /// Called after a successful resend. Increments attempt count
  /// and locks if max attempts reached.
  void onResendSuccess() {
    final next = state.attempts + 1;
    final lock = DateTime.now().add(EmailCooldownState.lockDuration);
    state = EmailCooldownState(attempts: next, lockedUntil: lock);
  }

  void reset() => state = const EmailCooldownState();
}
