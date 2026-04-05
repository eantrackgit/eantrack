/// Base sealed exception hierarchy.
///
/// All repositories throw AppException subclasses.
/// Raw Supabase/network errors are never exposed to the UI.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

// --- Auth ---

class AuthAppException extends AppException {
  const AuthAppException(super.message);
}

class EmailNotConfirmedException extends AuthAppException {
  const EmailNotConfirmedException()
      : super('E-mail não confirmado. Verifique sua caixa de entrada.');
}

class EmailAlreadyInUseException extends AuthAppException {
  const EmailAlreadyInUseException() : super('Este e-mail já está em uso.');
}

class WeakPasswordException extends AuthAppException {
  const WeakPasswordException(super.message);
}

class SamePasswordException extends AuthAppException {
  const SamePasswordException()
      : super('A nova senha deve ser diferente da atual.');
}

class PasswordReusedException extends AuthAppException {
  const PasswordReusedException()
      : super('Você já usou essa senha antes. Escolha uma diferente.');
}

class PasswordReuseCheckException extends AuthAppException {
  const PasswordReuseCheckException()
      : super('Não foi possível validar sua nova senha. Tente novamente.');
}

class PasswordHistoryRegisterException extends AuthAppException {
  const PasswordHistoryRegisterException()
      : super('Não foi possível registrar o histórico da senha.');
}

// --- Network ---

class NetworkException extends AppException {
  const NetworkException([super.message = 'Sem conexão com a internet.']);
}

// --- Server ---

class ServerException extends AppException {
  const ServerException([super.message = 'Erro no servidor. Tente novamente.']);
}
