import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/validity_repository.dart';
import '../../domain/validity_state.dart';

final validityRepositoryProvider = Provider<ValidityRepository>(
  (_) => ValidityRepository(),
);

// autoDispose removido: provider permanece em memória evitando re-fetch
// ao navegar de volta para a tela (mesmo padrão do regionNotifierProvider).
final validityNotifierProvider =
    NotifierProvider<ValidityNotifier, ValidityState>(
  ValidityNotifier.new,
);

class ValidityNotifier extends Notifier<ValidityState> {
  ValidityRepository get _repository => ref.read(validityRepositoryProvider);

  @override
  ValidityState build() {
    Future.microtask(load);
    return ValidityInitial();
  }

  Future<void> load() async {
    state = ValidityLoading();
    try {
      final items = await _repository.fetchItems();
      state = ValidityLoaded(items);
    } catch (_) {
      state = ValidityError('Erro ao carregar lançamentos. Tente novamente.');
    }
  }

  Future<void> refresh() => load();
}
