import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../../../shared/shared.dart';
import '../domain/user_flow_state.dart';

abstract class AuthDataServiceBase {
  const AuthDataServiceBase(this.client);

  final SupabaseClient client;

  AppException mapAuthException(AuthException error) {
    final backendMessage = extractBackendMessage(
      error,
      fallbackMessage: 'Erro de autenticacao.',
    );

    if (isEmailNotConfirmedError(backendMessage)) {
      return const EmailNotConfirmedException();
    }

    return toAppException(
      backendMessage,
      statusCode: error.statusCode,
    );
  }

  AppException mapUnexpectedException(
    Object error, {
    required String fallbackMessage,
  }) {
    final backendMessage = extractBackendMessage(
      error,
      fallbackMessage: fallbackMessage,
    );
    return toAppException(backendMessage);
  }

  Future<bool> emailExists(String emailHash) async =>
      await client.rpc('email_code_exists', params: {'p_hash': emailHash})
          as bool? ??
      false;

  String sha256Hash(String input) => sha256.convert(utf8.encode(input)).toString();

  AppException toAppException(
    String backendMessage, {
    String? statusCode,
  }) {
    final normalized = backendMessage.toLowerCase();

    if (isInvalidCredentialsError(normalized)) {
      return const AuthAppException('E-mail ou senha incorretos.');
    }

    if (looksLikeSupabaseConfigError(normalized)) {
      return ServerException(backendMessage);
    }

    if (looksLikeAuthError(normalized, statusCode: statusCode)) {
      return AuthAppException(backendMessage);
    }

    if (looksLikeSessionError(normalized)) {
      return AuthAppException(backendMessage);
    }

    return AuthAppException(backendMessage);
  }

  bool isEmailNotConfirmedError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('confirm') || normalized.contains('not confirmed');
  }

  bool isInvalidCredentialsError(String normalizedMessage) {
    return normalizedMessage.contains('invalid login credentials') ||
        normalizedMessage.contains('invalid_credentials') ||
        normalizedMessage.contains('user not found');
  }

  bool looksLikeSupabaseConfigError(String normalizedMessage) {
    return normalizedMessage.contains('missing supabase url') ||
        normalizedMessage.contains('missing supabase anon key') ||
        normalizedMessage.contains('invalid api key');
  }

  bool looksLikeAuthError(
    String normalizedMessage, {
    String? statusCode,
  }) {
    return statusCode == '401' ||
        normalizedMessage.contains('invalid login credentials') ||
        normalizedMessage.contains('invalid_credentials') ||
        normalizedMessage.contains('email not confirmed') ||
        normalizedMessage.contains('user not found');
  }

  bool looksLikeSessionError(String normalizedMessage) {
    return normalizedMessage.contains('invalid jwt') ||
        normalizedMessage.contains('jwt malformed') ||
        normalizedMessage.contains('jwt expired');
  }

  String extractBackendMessage(
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

class AuthSigningService extends AuthDataServiceBase {
  const AuthSigningService(super.client);

  Stream<User?> get authStateStream =>
      client.auth.onAuthStateChange.map((e) => e.session?.user);

  User? get currentUser => client.auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user == null) {
        throw const AuthAppException('E-mail ou senha incorretos.');
      }
    } on AuthException catch (e) {
      throw mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw mapUnexpectedException(
        e,
        fallbackMessage: 'Erro ao realizar login. Tente novamente.',
      );
    }
  }

  Future<void> signUp({required String email, required String password}) async {
    _validatePassword(password);
    final normalizedEmail = email.trim().toLowerCase();
    final emailHash = sha256Hash(normalizedEmail);

    try {
      if (await emailExists(emailHash)) {
        throw const EmailAlreadyInUseException();
      }
    } on EmailAlreadyInUseException {
      rethrow;
    } on Exception catch (e) {
      debugPrint('[AuthSigning] Erro: $e');
    }

    try {
      final response = await client.auth.signUp(
        email: normalizedEmail,
        password: password,
      );
      if (response.user == null) {
        throw const AuthAppException('Erro ao criar conta. Tente novamente.');
      }
      await client.rpc('insert_email_code', params: {
        'p_hash': emailHash,
        'p_user_id': response.user!.id,
      });
    } on AuthException catch (e) {
      throw mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw mapUnexpectedException(
        e,
        fallbackMessage: 'Erro ao criar conta. Tente novamente.',
      );
    }
  }

  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } on Exception catch (e) {
      debugPrint('[AuthSigning] Erro: $e');
    }
  }

  Future<UserFlowState?> getUserFlowState(String userId) async {
    try {
      final data = await client
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
      await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback',
      );
    } on AuthException catch (e) {
      throw mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw mapUnexpectedException(
        e,
        fallbackMessage: 'Nao foi possivel entrar com Google. Tente novamente.',
      );
    }
  }

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
}
