import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_service.dart';
import 'connectivity_state.dart';

class ConnectivityNotifier extends StateNotifier<ConnectionStatus> {
  ConnectivityNotifier(this._service) : super(ConnectionStatus.checking) {
    _subscription = _service.onConnectivityChanged.listen((_) {
      _scheduleRecheck();
    });
    _pollTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _scheduleRecheck(),
    );
    unawaited(checkConnection());
  }

  final ConnectivityService _service;
  StreamSubscription<void>? _subscription;
  Timer? _debounce;
  Timer? _pollTimer;
  bool _isChecking = false;
  bool _hasPendingCheck = false;
  bool _isDisposed = false;
  Completer<ConnectionStatus>? _activeCheckCompleter;

  Future<ConnectionStatus> checkConnection() async {
    if (_isDisposed) return state;

    if (_isChecking) {
      _hasPendingCheck = true;
      return _activeCheckCompleter?.future ?? Future.value(state);
    }

    _isChecking = true;
    final completer = Completer<ConnectionStatus>();
    _activeCheckCompleter = completer;
    state = ConnectionStatus.checking;

    try {
      final hasInternet = await _service.hasInternet();
      if (_isDisposed) return state;
      state = hasInternet ? ConnectionStatus.online : ConnectionStatus.offline;
    } catch (_) {
      if (_isDisposed) return state;
      state = ConnectionStatus.offline;
    } finally {
      if (!completer.isCompleted) {
        completer.complete(state);
      }
      if (identical(_activeCheckCompleter, completer)) {
        _activeCheckCompleter = null;
      }

      _isChecking = false;

      if (!_isDisposed && _hasPendingCheck) {
        _hasPendingCheck = false;
        unawaited(checkConnection());
      }
    }

    return completer.future;
  }

  void _scheduleRecheck() {
    if (_isDisposed) return;

    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (_isDisposed) return;
      unawaited(checkConnection());
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _debounce?.cancel();
    _pollTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
