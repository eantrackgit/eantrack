import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../features/auth/domain/auth_state.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../data/region_repository.dart';
import '../../domain/region_state.dart';

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final regionRepositoryProvider = Provider<RegionRepository>((ref) {
  return RegionRepository(Supabase.instance.client);
});

// ---------------------------------------------------------------------------
// Agency ID derived from auth state
// ---------------------------------------------------------------------------

/// Returns the authenticated user's agencyId, or null if unavailable.
final agencyIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is AuthAuthenticated) {
    return authState.flowState?.agencyId;
  }
  return null;
});

// ---------------------------------------------------------------------------
// Region notifier
// ---------------------------------------------------------------------------

// autoDispose removed: the provider stays in memory while the app is running,
// avoiding a re-fetch when navigating back to the screen.
// ref.watch(agencyIdProvider) guarantees automatic invalidation on account swap.
final regionNotifierProvider =
    StateNotifierProvider<RegionNotifier, RegionState>((ref) {
  return RegionNotifier(
    repository: ref.read(regionRepositoryProvider),
    agencyId: ref.watch(agencyIdProvider),
  );
});

class RegionNotifier extends StateNotifier<RegionState> {
  RegionNotifier({
    required RegionRepository repository,
    required String? agencyId,
  })  : _repository = repository,
        _agencyId = agencyId,
        super(RegionInitial()) {
    load();
  }

  final RegionRepository _repository;
  final String? _agencyId;

  Future<void> load() async {
    final agencyId = _agencyId;
    if (agencyId == null) {
      state = RegionError('Agencia nao encontrada. Faca login novamente.');
      return;
    }

    state = RegionLoading();
    try {
      final regions = await _repository.fetchRegions(agencyId: agencyId);
      state = RegionLoaded(regions);
    } catch (e) {
      state = RegionError(e.toString());
    }
  }

  Future<bool> createRegion(String name) async {
    final agencyId = _agencyId;
    if (agencyId == null) return false;

    try {
      await _repository.createRegion(name: name, agencyId: agencyId);
      await load(); // reloads list
      return true;
    } catch (e) {
      // Keeps current state; the error is reported via the return value.
      return false;
    }
  }

  Future<void> toggleActive(String regionId, {required bool isActive}) async {
    try {
      await _repository.toggleActive(regionId: regionId, isActive: isActive);
      await load();
    } catch (_) {
      // State was already updated optimistically; revert if needed.
      await load();
    }
  }

  Future<bool> isNameAvailable(String name) async {
    return _repository.isNameAvailable(name);
  }
}
