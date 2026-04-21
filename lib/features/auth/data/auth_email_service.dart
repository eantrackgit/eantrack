import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import 'auth_signing_service.dart';

class AuthEmailService extends AuthDataServiceBase {
  const AuthEmailService(super.client);

  Future<bool> verifyEmail() async {
    try {
      return (await client.auth.getUser()).user?.emailConfirmedAt != null;
    } catch (_) {
      return false;
    }
  }

  Future<void> resendEmail(String email) async {
    try {
      await client.auth.resend(type: OtpType.signup, email: email.trim());
    } on AuthException catch (e) {
      throw mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw mapUnexpectedException(
        e,
        fallbackMessage: 'Erro ao reenviar o e-mail de verificacao. Tente novamente.',
      );
    }
  }

  Future<bool> checkEmailAvailable(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return true;

    try {
      return !(await emailExists(sha256Hash(normalizedEmail)));
    } catch (_) {
      return true;
    }
  }

  Future<void> updateEmail(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw const AuthAppException('Informe o e-mail para atualizar.');
    }

    try {
      await client.auth.updateUser(
        UserAttributes(email: normalizedEmail),
      );
    } on AuthException catch (e) {
      throw mapAuthException(e);
    } catch (e) {
      if (e is AppException) rethrow;
      throw mapUnexpectedException(
        e,
        fallbackMessage: 'Erro ao atualizar o e-mail. Tente novamente.',
      );
    }
  }
}
