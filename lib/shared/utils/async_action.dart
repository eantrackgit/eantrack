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

extension AsyncActionX<T> on AsyncAction<T> {
  bool get isIdle => this is ActionIdle<T>;
  bool get isLoading => this is ActionLoading<T>;
  bool get isSuccess => this is ActionSuccess<T>;
  bool get isFailure => this is ActionFailure<T>;

  String? get errorMessage =>
      this is ActionFailure<T> ? (this as ActionFailure<T>).message : null;

  T? get value =>
      this is ActionSuccess<T> ? (this as ActionSuccess<T>).value : null;
}
