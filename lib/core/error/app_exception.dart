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

// --- Profile photo ---

class ProfilePhotoException extends AppException {
  const ProfilePhotoException(super.message);
}

class NotAuthenticatedException extends ProfilePhotoException {
  const NotAuthenticatedException()
      : super('Sua sessão expirou. Entre novamente para salvar sua foto.');
}

class StorageBucketMissingException extends ProfilePhotoException {
  const StorageBucketMissingException()
      : super('Não foi possível enviar sua foto agora. Tente novamente em instantes.');
}

class StoragePermissionDeniedException extends ProfilePhotoException {
  const StoragePermissionDeniedException()
      : super(
          'Não foi possível enviar a imagem. Verifique as permissões de armazenamento.',
        );
}

class InvalidFileException extends ProfilePhotoException {
  const InvalidFileException()
      : super('Não conseguimos ler esta imagem. Tente escolher outra foto.');
}

class FileTooLargeException extends ProfilePhotoException {
  const FileTooLargeException()
      : super('Imagem muito grande. Escolha uma foto menor.');
}

class UploadFailedException extends ProfilePhotoException {
  const UploadFailedException()
      : super('Não foi possível enviar sua foto agora. Tente novamente em instantes.');
}

class ProfileUpdateFailedException extends ProfilePhotoException {
  const ProfileUpdateFailedException()
      : super(
          'A foto foi enviada, mas não conseguimos atualizar seu perfil agora.',
        );
}
