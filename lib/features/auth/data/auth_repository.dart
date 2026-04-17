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
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw _mapUnexpectedException(
        e,
        fallbackMessage: 'Erro ao realizar login. Tente novamente.',
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
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw _mapUnexpectedException(
        e,
        fallbackMessage: 'Erro ao criar conta. Tente novamente.',
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
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw _mapUnexpectedException(
        e,
        fallbackMessage: 'Erro ao enviar o link de recuperacao. Tente novamente.',
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
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw _mapUnexpectedException(
        e,
        fallbackMessage: 'Erro ao reenviar o e-mail de verificacao. Tente novamente.',
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
      throw _mapAuthException(e);
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
      throw _mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw _mapUnexpectedException(
        e,
        fallbackMessage: 'Nao foi possivel entrar com Google. Tente novamente.',
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

  AppException _mapAuthException(AuthException error) {
    final backendMessage = _extractBackendMessage(
      error,
      fallbackMessage: 'Erro de autenticacao.',
    );

    if (_isEmailNotConfirmedError(backendMessage)) {
      return const EmailNotConfirmedException();
    }

    return _toAppException(
      backendMessage,
      statusCode: error.statusCode,
    );
  }

  AppException _mapUnexpectedException(
    Object error, {
    required String fallbackMessage,
  }) {
    final backendMessage = _extractBackendMessage(
      error,
      fallbackMessage: fallbackMessage,
    );
    return _toAppException(backendMessage);
  }

  AppException _toAppException(
    String backendMessage, {
    String? statusCode,
  }) {
    final normalized = backendMessage.toLowerCase();

    if (_looksLikeSupabaseConfigError(normalized)) {
      return ServerException(backendMessage);
    }

    if (_looksLikeAuthError(normalized, statusCode: statusCode)) {
      return AuthAppException(backendMessage);
    }

    if (_looksLikeSessionError(normalized)) {
      return AuthAppException(backendMessage);
    }

    return AuthAppException(backendMessage);
  }

  bool _looksLikeSupabaseConfigError(String normalizedMessage) {
    return normalizedMessage.contains('missing supabase url') ||
        normalizedMessage.contains('missing supabase anon key') ||
        normalizedMessage.contains('invalid api key');
  }

  bool _looksLikeAuthError(
    String normalizedMessage, {
    String? statusCode,
  }) {
    return statusCode == '401' ||
        normalizedMessage.contains('invalid login credentials') ||
        normalizedMessage.contains('invalid_credentials') ||
        normalizedMessage.contains('email not confirmed') ||
        normalizedMessage.contains('user not found');
  }

  bool _looksLikeSessionError(String normalizedMessage) {
    return normalizedMessage.contains('invalid jwt') ||
        normalizedMessage.contains('jwt malformed') ||
        normalizedMessage.contains('jwt expired');
  }

  String _extractBackendMessage(
    Object error, {
    required String fallbackMessage,
  }) {
    if (error is AuthException) {
      final message = error.message.trim();
      return message.isEmpty ? fallbackMessage : message;
    }

    if (error is PostgrestException) {
      final message = error.message.trim();
      if (message.isNotEmpty) {
        return message;
      }

      final details = error.details?.toString().trim() ?? '';
      if (details.isNotEmpty) {
        return details;
      }

      final hint = error.hint?.trim() ?? '';
      if (hint.isNotEmpty) {
        return hint;
      }

      return fallbackMessage;
    }

    final rawMessage = error.toString().trim();
    if (rawMessage.isEmpty) {
      return fallbackMessage;
    }

    return rawMessage.replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
  }
}
