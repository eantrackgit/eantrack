import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/app_config.dart';
import '../../../core/error/app_exception.dart';
import 'auth_signing_service.dart';
import 'password_history_service.dart';

class AuthPasswordService extends AuthDataServiceBase {
  const AuthPasswordService({
    required SupabaseClient client,
    required PasswordHistoryService passwordHistoryService,
  })  : _passwordHistoryService = passwordHistoryService,
        super(client);

  final PasswordHistoryService _passwordHistoryService;

  Future<void> resetPassword(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw const AuthAppException('Informe o e-mail para redefinir sua senha.');
    }

    try {
      await client.auth.resetPasswordForEmail(
        normalizedEmail,
        redirectTo: AppConfig.passwordResetRedirectUrl,
      );
    } on AuthException catch (e) {
      throw mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw mapUnexpectedException(
        e,
        fallbackMessage: 'Erro ao enviar o link de recuperacao. Tente novamente.',
      );
    }
  }

  Future<void> updatePassword(String newPassword) async {
    await _passwordHistoryService.ensureNewPasswordCanBeUsed(newPassword);
    try {
      await client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      if (_isSamePasswordError(e)) {
        throw const SamePasswordException();
      }
      throw mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw const ServerException('Erro ao atualizar senha. Tente novamente.');
    }

    await _passwordHistoryService.registerPasswordHistory(newPassword);
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
}
