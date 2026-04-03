sealed class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingLoading extends OnboardingState {}

class OnboardingModeSelected extends OnboardingState {
  OnboardingModeSelected({required this.mode});

  /// 'individual' ou 'agencia'
  final String mode;
}

class OnboardingError extends OnboardingState {
  OnboardingError({required this.message});
  final String message;
}
