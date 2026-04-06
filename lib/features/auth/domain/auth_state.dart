import 'package:supabase_flutter/supabase_flutter.dart';

import 'user_flow_state.dart';

/// Sealed auth state. All widgets must handle all cases exhaustively.
sealed class AuthState {
  const AuthState();
}

/// Initial state before the auth stream emits.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// An async operation is in progress (sign in, sign up, reset password).
class AuthLoading extends AuthState {
  const AuthLoading([this.message]);
  final String? message;
}

/// No active session.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User registered but email not yet confirmed.
/// Only email is kept — password is NEVER stored in state.
class AuthEmailUnconfirmed extends AuthState {
  const AuthEmailUnconfirmed({required this.email});

  final String email;
}

/// Fully authenticated and email confirmed.
class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({
    required this.user,
    required this.flowState,
  });

  final User user;
  final UserFlowState? flowState;
}

/// An error occurred. [message] is user-friendly Portuguese text.
class AuthError extends AuthState {
  const AuthError(this.message);
  final String message;
}
