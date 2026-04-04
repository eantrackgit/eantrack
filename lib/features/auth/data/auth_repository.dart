import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../shared/utils/password_validator.dart';
import '../domain/user_flow_state.dart';

class AuthRepository {
  const AuthRepository(this._client);

  final SupabaseClient _client;

  // ---------------------------------------------------------------------------
  // Auth state
  // ---------------------------------------------------------------------------

  Stream<User?> get authStateStream =>
      _client.auth.onAuthStateChange.map((e) => e.session?.user);

  User? get currentUser => _client.auth.currentUser;

  // ---------------------------------------------------------------------------
  // Sign in
  // ---------------------------------------------------------------------------

  /// Returns normally on success.
  /// Throws [EmailNotConfirmedException] if email not yet confirmed.
  /// Throws [AuthAppException] for invalid credentials or other auth errors.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user == null) {
        throw const AuthAppException('Credenciais inválidas.');
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('confirm') ||
          e.message.toLowerCase().contains('not confirmed')) {
        throw const EmailNotConfirmedException();
      }
      throw AuthAppException(_mapAuthError(e.message));
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AuthAppException('Erro ao realizar login. Tente novamente.');
    }
  }

  // ---------------------------------------------------------------------------
  // Sign up
  // ---------------------------------------------------------------------------

  /// Creates a new account.
  /// Validates password strength, checks email uniqueness via RPC,
  /// creates Supabase Auth user, and stores email hash.
  ///
  /// Throws [WeakPasswordException], [EmailAlreadyInUseException], or [AuthAppException].
  Future<void> signUp({
    required String email,
    required String password,
  }) async {
    _validatePassword(password);

    final normalized = email.trim().toLowerCase();
    final hash = _sha256(normalized);

    // Check for duplicate email via RPC (privacy-preserving hash lookup)
    try {
      final exists = await _client.rpc(
            'email_code_exists',
            params: {'p_hash': hash},
          ) as bool? ??
          false;

      if (exists) throw const EmailAlreadyInUseException();
    } on EmailAlreadyInUseException {
      rethrow;
    } catch (_) {
      // RPC failure is non-fatal for the duplicate check; proceed with signup
      // Supabase will catch true duplicates at the auth level
    }

    try {
      final response = await _client.auth.signUp(
        email: normalized,
        password: password,
      );

      if (response.user == null) {
        throw const AuthAppException('Erro ao criar conta. Tente novamente.');
      }

      // Store email hash for future duplicate checks
      await _client.rpc('insert_email_code', params: {
        'p_hash': hash,
        'p_user_id': response.user!.id,
      });
    } on AuthException catch (e) {
      throw AuthAppException(_mapAuthError(e.message));
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AuthAppException('Erro ao criar conta. Tente novamente.');
    }
  }

  // ---------------------------------------------------------------------------
  // Sign out
  // ---------------------------------------------------------------------------

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {
      // Swallow — user is considered signed out locally regardless
    }
  }

  // ---------------------------------------------------------------------------
  // Password reset
  // ---------------------------------------------------------------------------

  Future<void> resetPassword(String email) async {
    if (email.trim().isEmpty) {
      throw const AuthAppException(
          'Informe o e-mail para redefinir sua senha.');
    }
    try {
      await _client.auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: AppConfig.passwordResetRedirectUrl,
      );
    } on AuthException catch (e) {
      throw AuthAppException(_mapAuthError(e.message));
    }
  }

  // ---------------------------------------------------------------------------
  // Email verification
  // ---------------------------------------------------------------------------

  /// Checks if the current user's email has been confirmed.
  /// Uses refreshSession + currentUser to avoid signInWithPassword rate limits.
  Future<bool> isEmailConfirmed() async {
    try {
      final response = await _client.auth.getUser();
      return response.user?.emailConfirmedAt != null;
    } catch (_) {
      return false;
    }
  }

  /// Resends the verification email.
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email.trim(),
      );
    } on AuthException catch (e) {
      throw AuthAppException(_mapAuthError(e.message));
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw AuthAppException(_mapAuthError(e.message));
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException(
        'Erro ao atualizar senha. Tente novamente.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Email availability (used by register screen debounce)
  // ---------------------------------------------------------------------------

  /// Returns true if the email is not yet registered.
  /// Uses the same SHA-256 hash + RPC as signUp.
  /// Fails silently (returns true) if RPC is unavailable — signUp handles real duplicates.
  Future<bool> checkEmailAvailable(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    final hash = _sha256(normalized);
    try {
      final exists = await _client.rpc(
            'email_code_exists',
            params: {'p_hash': hash},
          ) as bool? ??
          false;
      return !exists;
    } catch (_) {
      return true;
    }
  }

  // ---------------------------------------------------------------------------
  // User flow state
  // ---------------------------------------------------------------------------

  Future<UserFlowState?> getUserFlowState(String userId) async {
    try {
      final data = await _client
          .from('user_flow_state')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (data == null) return null;
      return UserFlowState.fromJson(data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Google OAuth
  // ---------------------------------------------------------------------------

  /// Inicia o fluxo OAuth com Google.
  ///
  /// Na Web: redireciona para a página do Google e volta ao app via URL de retorno.
  /// No mobile: abre um browser customizado (deep link `io.supabase.flutter://login-callback`).
  ///
  /// A atualização de estado (AuthAuthenticated) é tratada pelo listener
  /// do stream de auth no [authNotifierProvider].
  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback',
      );
    } on AuthException catch (e) {
      throw AuthAppException(_mapAuthError(e.message));
    } catch (e) {
      if (e is AppException) rethrow;
      throw const AuthAppException(
        'Não foi possível entrar com Google. Tente novamente.',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Valida força da senha usando [PasswordValidator].
  /// Lança [WeakPasswordException] se alguma regra for violada.
  void _validatePassword(String password) {
    if (!PasswordValidator.hasMinLength(password)) {
      throw const WeakPasswordException(
          'A senha deve ter pelo menos 8 caracteres.');
    }
    if (!PasswordValidator.hasUppercase(password)) {
      throw const WeakPasswordException(
          'A senha deve conter uma letra maiúscula.');
    }
    if (!PasswordValidator.hasLowercase(password)) {
      throw const WeakPasswordException(
          'A senha deve conter uma letra minúscula.');
    }
    if (!PasswordValidator.hasNumber(password)) {
      throw const WeakPasswordException('A senha deve conter um número.');
    }
    if (!PasswordValidator.hasSymbol(password)) {
      throw const WeakPasswordException(
          'A senha deve conter um símbolo (ex: @, #, \$, %).');
    }
  }

  String _sha256(String input) {
    final bytes = utf8.encode(input);
    return sha256.convert(bytes).toString();
  }

  String _mapAuthError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login credentials') ||
        m.contains('invalid_credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (m.contains('email not confirmed')) {
      return 'E-mail não confirmado. Verifique sua caixa de entrada.';
    }
    if (m.contains('user already registered') ||
        m.contains('already registered')) {
      return 'Este e-mail já está em uso.';
    }
    if (m.contains('rate limit') || m.contains('too many')) {
      return 'Muitas tentativas. Aguarde antes de tentar novamente.';
    }
    if (m.contains('network') || m.contains('timeout')) {
      return 'Falha de conexão. Verifique sua internet.';
    }
    return 'Erro de autenticação. Tente novamente.';
  }
}
