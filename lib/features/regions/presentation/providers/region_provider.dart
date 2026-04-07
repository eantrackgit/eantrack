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
// Agency ID derivado do estado de auth
// ---------------------------------------------------------------------------

/// Retorna o agencyId do usuário autenticado, ou null se não disponível.
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

// autoDispose removido: o provider persiste em memória enquanto o app estiver
// rodando, evitando re-fetch ao navegar de volta para a tela.
// ref.watch(agencyIdProvider) garante invalidação automática ao trocar conta.
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
    if (_agencyId == null) {
      state = RegionError('Agência não encontrada. Faça login novamente.');
      return;
    }

    state = RegionLoading();
    try {
      final regions = await _repository.fetchRegions(agencyId: _agencyId!);
      state = RegionLoaded(regions);
    } catch (e) {
      state = RegionError(e.toString());
    }
  }

  Future<bool> createRegion(String name) async {
    if (_agencyId == null) return false;

    try {
      await _repository.createRegion(name: name, agencyId: _agencyId!);
      await load(); // recarrega lista
      return true;
    } catch (e) {
      // Mantém estado atual — o erro é reportado via retorno
      return false;
    }
  }

  Future<void> toggleActive(String regionId, {required bool isActive}) async {
    try {
      await _repository.toggleActive(regionId: regionId, isActive: isActive);
      await load();
    } catch (_) {
      // Estado já foi atualizado otimisticamente — reverter se necessário
      await load();
    }
  }

  Future<bool> isNameAvailable(String name) async {
    return _repository.isNameAvailable(name);
  }
}
