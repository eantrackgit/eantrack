import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import '../../../shared/utils/password_validator.dart';
import '../domain/user_flow_state.dart';
import 'password_history_service.dart';

class AuthRepository {
  const AuthRepository({
    required SupabaseClient client,
    required PasswordHistoryService passwordHistoryService,
  })  : _client = client,
        _passwordHistoryService = passwordHistoryService;

  final SupabaseClient _client;
  final PasswordHistoryService _passwordHistoryService;

  Stream<User?> get authStateStream =>
      _client.auth.onAuthStateChange.map((e) => e.session?.user);

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user == null) {
        throw const AuthAppException('Credenciais invalidas.');
      }
    } on AuthException catch (e) {
      if (_isEmailNotConfirmedError(e.message)) {
        throw const EmailNotConfirmedException();
      }
      throw AuthAppException(_mapAuthError(e.message));
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthAppException(
        _mapUnexpectedAuthError(
          e,
          fallbackMessage: 'Erro ao realizar login. Tente novamente.',
        ),
      );
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    _validatePassword(password);
    final normalizedEmail = email.trim().toLowerCase();
    final emailHash = _sha256(normalizedEmail);

    try {
      if (await _emailExists(emailHash)) {
        throw const EmailAlreadyInUseException();
      }
    } on EmailAlreadyInUseException {
      rethrow;
    } catch (_) {}

    try {
      final response = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
      );
      if (response.user == null) {
        throw const AuthAppException('Erro ao criar conta. Tente novamente.');
      }
      await _client.rpc('insert_email_code', params: {
        'p_hash': emailHash,
        'p_user_id': response.user!.id,
      });
    } on AuthException catch (e) {
      throw AuthAppException(_mapAuthError(e.message));
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthAppException(
        _mapUnexpectedAuthError(
          e,
          fallbackMessage: 'Erro ao criar conta. Tente novamente.',
        ),
      );
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (_) {}
  }

  Future<void> resetPassword(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw const AuthAppException('Informe o e-mail para redefinir sua senha.');
    }

    try {
      await _client.auth.resetPasswordForEmail(
        normalizedEmail,
        redirectTo: AppConfig.passwordResetRedirectUrl,
      );
    } on AuthException catch (e) {
      if (_isRateLimitError(e.message)) {
        throw const AuthAppException(
          'Já enviamos um link recentemente.\n\nPara sua segurança, aguarde alguns minutos antes de solicitar outro.',
        );
      }
      throw AuthAppException(_mapAuthError(e.message));
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthAppException(
        _mapUnexpectedAuthError(
          e,
          fallbackMessage: 'Erro ao enviar o link de recuperacao. Tente novamente.',
        ),
      );
    }
  }

  Future<bool> isEmailConfirmed() async {
    try {
      return (await _client.auth.getUser()).user?.emailConfirmedAt != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> resendVerificationEmail(String email) async {
    try {
      await _client.auth.resend(type: OtpType.signup, email: email.trim());
    } on AuthException catch (e) {
      throw AuthAppException(_mapAuthError(e.message));
    } catch (e) {
      if (e is AppException) rethrow;
      throw AuthAppException(
        _mapUnexpectedAuthError(
          e,
          fallbackMessage: 'Erro ao reenviar o e-mail de verificacao. Tente novamente.',
        ),
      );
    }
  }

  Future<void> changePassword(String newPassword) async {
    await _passwordHistoryService.ensureNewPasswordCanBeUsed(newPassword);
    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      if (_isSamePasswordError(e)) {
        throw const SamePasswordException();
      }
      throw AuthAppException(_mapAuthError(e.message));
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException('Erro ao atualizar senha. Tente novamente.');
    }

    await _passwordHistoryService.registerPasswordHistory(newPassword);
  }

  Future<bool> checkEmailAvailable(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return true;

    try {
      return !(await _emailExists(_sha256(normalizedEmail)));
    } catch (_) {
      return true;
    }
  }

  Future<UserFlowState?> getUserFlowState(String userId) async {
    try {
      final data = await _client
          .from('user_flow_state')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return data == null ? null : UserFlowState.fromJson(data);
    } catch (_) {
      return null;
    }
  }

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
      throw AuthAppException(
        _mapUnexpectedAuthError(
          e,
          fallbackMessage: 'Nao foi possivel entrar com Google. Tente novamente.',
        ),
      );
    }
  }

  Future<bool> _emailExists(String emailHash) async =>
      await _client.rpc('email_code_exists', params: {'p_hash': emailHash})
          as bool? ??
      false;

  void _validatePassword(String password) {
    final checks = <(bool, String)>[
      (
        PasswordValidator.hasMinLength(password),
        'A senha deve ter pelo menos 8 caracteres.',
      ),
      (
        PasswordValidator.hasUppercase(password),
        'A senha deve conter uma letra maiuscula.',
      ),
      (
        PasswordValidator.hasLowercase(password),
        'A senha deve conter uma letra minuscula.',
      ),
      (PasswordValidator.hasNumber(password), 'A senha deve conter um numero.'),
      (
        PasswordValidator.hasSymbol(password),
        'A senha deve conter um simbolo (ex: @, #, \$, %).',
      ),
    ];

    for (final check in checks) {
      if (!check.$1) throw WeakPasswordException(check.$2);
    }
  }

  String _sha256(String input) => sha256.convert(utf8.encode(input)).toString();

  bool _isEmailNotConfirmedError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('confirm') || normalized.contains('not confirmed');
  }

  bool _isSamePasswordError(AuthException error) {
    final normalized = error.message.toLowerCase();
    final hasSamePasswordMessage =
        normalized.contains('should be different') ||
        normalized.contains('different from the old') ||
        normalized.contains('different from your current') ||
        normalized.contains('new password should be different');
    return error.code?.toLowerCase() == 'same_password' ||
        (error.statusCode == '422' && hasSamePasswordMessage) ||
        hasSamePasswordMessage;
  }

  bool _isRateLimitError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('rate limit') || normalized.contains('too many');
  }

  String _mapAuthError(String message) {
    final normalized = message.toLowerCase();

    if (_looksLikeSupabaseConfigError(normalized)) {
      return 'Falha na configuracao do Supabase. Revise SUPABASE_URL e SUPABASE_ANON_KEY.';
    }
    if (_looksLikeNetworkOrFetchError(normalized)) {
      return 'Falha de conexao com o Supabase. Verifique internet, dominio liberado e URL do projeto.';
    }
    if (normalized.contains('invalid login credentials') ||
        normalized.contains('invalid_credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (normalized.contains('email not confirmed')) {
      return 'E-mail nao confirmado. Verifique sua caixa de entrada.';
    }
    if (normalized.contains('user already registered') ||
        normalized.contains('already registered')) {
      return 'Este e-mail ja esta em uso.';
    }
    if (_isRateLimitError(normalized)) {
      return 'Muitas tentativas. Aguarde antes de tentar novamente.';
    }
    if (normalized.contains('network') || normalized.contains('timeout')) {
      return 'Falha de conexao. Verifique sua internet.';
    }

    final sanitizedMessage = _sanitizeAuthMessage(message);
    if (sanitizedMessage != null) {
      return 'Erro de autenticacao: $sanitizedMessage';
    }
    return 'Erro de autenticacao. Tente novamente.';
  }

  String _mapUnexpectedAuthError(
    Object error, {
    required String fallbackMessage,
  }) {
    final rawMessage = error.toString();
    final normalized = rawMessage.toLowerCase();

    if (_looksLikeSupabaseConfigError(normalized)) {
      return 'Falha na configuracao do Supabase. Revise SUPABASE_URL e SUPABASE_ANON_KEY.';
    }
    if (_looksLikeNetworkOrFetchError(normalized)) {
      return 'Falha de conexao com o Supabase. Verifique internet, dominio liberado e URL do projeto.';
    }

    final sanitizedMessage = _sanitizeAuthMessage(rawMessage);
    if (sanitizedMessage != null) {
      return 'Erro de autenticacao: $sanitizedMessage';
    }

    return fallbackMessage;
  }

  bool _looksLikeSupabaseConfigError(String normalizedMessage) {
    return normalizedMessage.contains('invalid api key') ||
        normalizedMessage.contains('apikey') ||
        normalizedMessage.contains('jwt malformed') ||
        normalizedMessage.contains('invalid jwt') ||
        normalizedMessage.contains('project not found') ||
        normalizedMessage.contains('not a valid url') ||
        normalizedMessage.contains('invalid uri');
  }

  bool _looksLikeNetworkOrFetchError(String normalizedMessage) {
    return normalizedMessage.contains('network') ||
        normalizedMessage.contains('timeout') ||
        normalizedMessage.contains('failed to fetch') ||
        normalizedMessage.contains('network request failed') ||
        normalizedMessage.contains('failed host lookup') ||
        normalizedMessage.contains('clientexception') ||
        normalizedMessage.contains('xmlhttprequest');
  }

  String? _sanitizeAuthMessage(String message) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final withoutPrefix = trimmed.replaceFirst(
      RegExp(r'^[A-Za-z]+Exception:\s*'),
      '',
    );
    if (withoutPrefix.isEmpty) {
      return null;
    }

    return withoutPrefix;
  }
}
