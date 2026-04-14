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

/// Returns the authenticated user's agencyId.
///
/// Throws [StateError] if the user is not authenticated or if the account
/// does not have an agency id associated with it.
final agencyIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) {
    throw StateError('Usuario nao autenticado.');
  }

  final agencyId = authState.flowState?.agencyId;
  if (agencyId == null) {
    throw StateError('Agency ID nao encontrado para o usuario autenticado.');
  }

  return agencyId;
});

// ---------------------------------------------------------------------------
// Region notifier
// ---------------------------------------------------------------------------

// autoDispose removed: the provider stays in memory while the app is running,
// avoiding a re-fetch when navigating back to the screen.
// ref.watch(agencyIdProvider) guarantees automatic invalidation on account swap.
final regionNotifierProvider = NotifierProvider<RegionNotifier, RegionState>(
  RegionNotifier.new,
);

class RegionNotifier extends Notifier<RegionState> {
  RegionRepository get _repository => ref.read(regionRepositoryProvider);
  String get _agencyId => ref.read(agencyIdProvider);

  @override
  RegionState build() {
    ref.watch(agencyIdProvider);
    Future.microtask(load);
    return RegionInitial();
  }

  Future<void> load() async {
    state = RegionLoading();
    try {
      final regions = await _repository.fetchRegions(agencyId: _agencyId);
      state = RegionLoaded(regions);
    } catch (e) {
      state = RegionError('Erro ao carregar dados. Tente novamente.');
    }
  }

  Future<bool> createRegion(String name) async {
    try {
      await _repository.createRegion(name: name, agencyId: _agencyId);
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
