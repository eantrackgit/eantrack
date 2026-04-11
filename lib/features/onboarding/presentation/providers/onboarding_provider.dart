import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/onboarding_repository.dart';
import '../../domain/onboarding_state.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// Onboarding notifier
// ---------------------------------------------------------------------------

final onboardingNotifierProvider =
    StateNotifierProvider.autoDispose<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(ref.read(onboardingRepositoryProvider));
});

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  OnboardingNotifier(this._repository) : super(OnboardingInitial());

  final OnboardingRepository _repository;

  /// Seleciona o modo sem persistir ainda.
  void selectMode(String mode) {
    state = OnboardingModeSelected(mode: mode);
  }

  /// Persiste o modo selecionado no banco.
  ///
  /// Retorna true em sucesso. Em erro, seta [OnboardingError] e retorna false.
  Future<bool> saveMode(String mode) async {
    state = OnboardingLoading();
    try {
      await _repository.saveMode(mode);
      if (!mounted) return true;
      state = OnboardingModeSelected(mode: mode);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = OnboardingError(message: e.toString());
      return false;
    }
  }
}
