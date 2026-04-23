/// Estado de uma ação assíncrona local (botão, reenvio, submit, etc.).
///
/// Uso em State:
///   AsyncAction<void> _action = const ActionIdle();
///
///   Future<void> _submit() async {
///     setState(() => _action = const ActionLoading());
///     try {
///       await doWork();
///       setState(() => _action = const ActionSuccess(null));
///     } catch (e) {
///       setState(() => _action = ActionFailure(e.toString()));
///     }
///   }
///
///   // No build:
///   AppButton(
///     isLoading: _action.isLoading,
///     onPressed: _action.isLoading ? null : _submit,
///   )
///   if (_action.isFailure) AppErrorBox(_action.errorMessage!)
sealed class AsyncAction<T> {
  const AsyncAction();
}

class ActionIdle<T> extends AsyncAction<T> {
  const ActionIdle();
}

class ActionLoading<T> extends AsyncAction<T> {
  const ActionLoading();
}

class ActionSuccess<T> extends AsyncAction<T> {
  const ActionSuccess(this.value);
  final T value;
}

class ActionFailure<T> extends AsyncAction<T> {
  const ActionFailure(this.message);
  final String message;
}

/// Executa [action] com retry exponencial.
/// Lança a última exceção se todas as tentativas falharem.
Future<T> withRetry<T>(
  Future<T> Function() action, {
  int maxAttempts = 3,
  Duration delay = const Duration(milliseconds: 500),
}) async {
  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await action();
    } catch (_) {
      if (attempt == maxAttempts) rethrow;
      await Future.delayed(delay * attempt);
    }
  }
  throw StateError('unreachable');
}

extension AsyncActionX<T> on AsyncAction<T> {
  bool get isIdle => this is ActionIdle<T>;
  bool get isLoading => this is ActionLoading<T>;
  bool get isSuccess => this is ActionSuccess<T>;
  bool get isFailure => this is ActionFailure<T>;

  String? get errorMessage =>
      this is ActionFailure<T> ? (this as ActionFailure<T>).message : null;

  T? get value =>
      this is ActionSuccess<T> ? (this as ActionSuccess<T>).value : null;

  R when<R>({
    required R Function() onIdle,
    required R Function() onLoading,
    required R Function(T value) onSuccess,
    required R Function(String message) onFailure,
  }) =>
      switch (this) {
        ActionIdle<T>() => onIdle(),
        ActionLoading<T>() => onLoading(),
        ActionSuccess<T>(:final value) => onSuccess(value),
        ActionFailure<T>(:final message) => onFailure(message),
      };
}
