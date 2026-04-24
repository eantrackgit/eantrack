import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/agency_onboarding_repository.dart';

class AgencyOnboardingResetState {
  const AgencyOnboardingResetState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
  });

  final bool isLoading;
  final String? error;
  final bool isSuccess;

  AgencyOnboardingResetState copyWith({
    bool? isLoading,
    Object? error = _unset,
    bool? isSuccess,
  }) {
    return AgencyOnboardingResetState(
      isLoading: isLoading ?? this.isLoading,
      error: identical(error, _unset) ? this.error : error as String?,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

const _unset = Object();

final agencyOnboardingNotifierProvider = StateNotifierProvider.autoDispose<
    AgencyOnboardingNotifier, AgencyOnboardingResetState>(
  (ref) => AgencyOnboardingNotifier(
    ref.read(agencyOnboardingRepositoryProvider),
  ),
);

class AgencyOnboardingNotifier
    extends StateNotifier<AgencyOnboardingResetState> {
  AgencyOnboardingNotifier(this._repository)
      : super(const AgencyOnboardingResetState());

  final AgencyOnboardingRepository _repository;

  Future<bool> resetAgencyOnboarding(String agencyId) async {
    state = const AgencyOnboardingResetState(
      isLoading: true,
      isSuccess: false,
    );

    try {
      await _repository.deleteAgencyOnboardingById(agencyId);
      state = const AgencyOnboardingResetState(
        isLoading: false,
        isSuccess: true,
      );
      return true;
    } on AgencyOnboardingRepositoryException catch (e) {
      state = AgencyOnboardingResetState(
        isLoading: false,
        error: e.message,
        isSuccess: false,
      );
      return false;
    } catch (_) {
      state = const AgencyOnboardingResetState(
        isLoading: false,
        error: 'Nao foi possivel reiniciar o cadastro da agencia.',
        isSuccess: false,
      );
      return false;
    }
  }

  void clearState() {
    state = const AgencyOnboardingResetState();
  }
}
