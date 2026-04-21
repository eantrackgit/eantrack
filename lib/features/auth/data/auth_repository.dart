import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/user_flow_state.dart';
import 'auth_email_service.dart';
import 'auth_password_service.dart';
import 'auth_signing_service.dart';
import 'password_history_service.dart';

class AuthRepository {
  AuthRepository({
    required SupabaseClient client,
    required PasswordHistoryService passwordHistoryService,
  })  : _signingService = AuthSigningService(client),
        _passwordService = AuthPasswordService(
          client: client,
          passwordHistoryService: passwordHistoryService,
        ),
        _emailService = AuthEmailService(client);

  final AuthSigningService _signingService;
  final AuthPasswordService _passwordService;
  final AuthEmailService _emailService;

  Stream<User?> get authStateStream => _signingService.authStateStream;

  User? get currentUser => _signingService.currentUser;

  Future<void> signIn({required String email, required String password}) {
    return _signingService.signIn(email: email, password: password);
  }

  Future<void> signUp({required String email, required String password}) {
    return _signingService.signUp(email: email, password: password);
  }

  Future<void> signOut() {
    return _signingService.signOut();
  }

  Future<void> resetPassword(String email) {
    return _passwordService.resetPassword(email);
  }

  Future<bool> isEmailConfirmed() {
    return _emailService.verifyEmail();
  }

  Future<void> resendVerificationEmail(String email) {
    return _emailService.resendEmail(email);
  }

  Future<void> changePassword(String newPassword) {
    return _passwordService.updatePassword(newPassword);
  }

  Future<bool> checkEmailAvailable(String email) {
    return _emailService.checkEmailAvailable(email);
  }

  Future<UserFlowState?> getUserFlowState(String userId) {
    return _signingService.getUserFlowState(userId);
  }

  Future<void> signInWithGoogle() {
    return _signingService.signInWithGoogle();
  }
}
