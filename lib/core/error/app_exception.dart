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

// --- Network ---

class NetworkException extends AppException {
  const NetworkException([super.message = 'Sem conexão com a internet.']);
}

// --- Server ---

class ServerException extends AppException {
  const ServerException([super.message = 'Erro no servidor. Tente novamente.']);
}
