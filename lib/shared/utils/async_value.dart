/// Estado de carregamento de dados (listas, fetch, load inicial).
///
/// Complementa [AsyncAction] (para ações pontuais) cobrindo o ciclo de vida
/// de dados carregados de uma fonte remota.
///
/// Uso típico em State:
///   AsyncValue<List<Pdv>> _pdvs = const DataIdle();
///
///   Future<void> _load() async {
///     setState(() => _pdvs = const DataLoading());
///     try {
///       final data = await repository.fetchPdvs();
///       setState(() => _pdvs = data.isEmpty
///           ? const DataEmpty()
///           : DataSuccess(data));
///     } catch (e) {
///       setState(() => _pdvs = DataFailure(e.toString()));
///     }
///   }
///
///   // No build:
///   switch (_pdvs) {
///     DataIdle() || DataLoading() => const CircularProgressIndicator(),
///     DataSuccess(:final data) => ListView(...),
///     DataEmpty() => const _EmptyState(),
///     DataFailure(:final message) => AppErrorBox(message),
///   }
sealed class AsyncValue<T> {
  const AsyncValue();
}

/// Estado inicial antes de qualquer carregamento.
class DataIdle<T> extends AsyncValue<T> {
  const DataIdle();
}

/// Carregamento em andamento.
class DataLoading<T> extends AsyncValue<T> {
  const DataLoading();
}

/// Dados carregados com sucesso (lista não vazia / objeto presente).
class DataSuccess<T> extends AsyncValue<T> {
  const DataSuccess(this.data);
  final T data;
}

/// Carregamento bem-sucedido, mas sem dados (lista vazia).
class DataEmpty<T> extends AsyncValue<T> {
  const DataEmpty();
}

/// Carregamento falhou.
class DataFailure<T> extends AsyncValue<T> {
  const DataFailure(this.message);
  final String message;
}

extension AsyncValueX<T> on AsyncValue<T> {
  bool get isIdle => this is DataIdle<T>;
  bool get isLoading => this is DataLoading<T>;
  bool get isSuccess => this is DataSuccess<T>;
  bool get isEmpty => this is DataEmpty<T>;
  bool get isFailure => this is DataFailure<T>;

  /// Dado carregado, ou null.
  T? get data => this is DataSuccess<T> ? (this as DataSuccess<T>).data : null;

  /// Mensagem de erro, ou null.
  String? get errorMessage =>
      this is DataFailure<T> ? (this as DataFailure<T>).message : null;
}
