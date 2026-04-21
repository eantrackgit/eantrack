import 'package:flutter/foundation.dart';

import '../../../core/connectivity/connectivity_notifier.dart';
import '../../../core/connectivity/connectivity_state.dart';

class SplashConnectivityHandler {
  SplashConnectivityHandler({
    required ConnectivityNotifier connectivityNotifier,
    required VoidCallback onChanged,
    required VoidCallback onNavigate,
    required bool Function() canNavigate,
    required bool Function() isAnimationCompleted,
  })  : _connectivityNotifier = connectivityNotifier,
        _onChanged = onChanged,
        _onNavigate = onNavigate,
        _canNavigate = canNavigate,
        _isAnimationCompleted = isAnimationCompleted;

  final ConnectivityNotifier _connectivityNotifier;
  final VoidCallback _onChanged;
  final VoidCallback _onNavigate;
  final bool Function() _canNavigate;
  final bool Function() _isAnimationCompleted;
  bool _showOfflineScreen = false;
  bool _isRetryingConnection = false;

  bool get showOfflineScreen => _showOfflineScreen;
  bool get isRetryingConnection => _isRetryingConnection;

  void handleConnectionStatus(ConnectionStatus status) {
    if (!_isAnimationCompleted() || _showOfflineScreen || !_canNavigate()) {
      return;
    }

    switch (status) {
      case ConnectionStatus.online:
        _onNavigate();
        return;
      case ConnectionStatus.offline:
        if (_showOfflineScreen) return;
        _showOfflineScreen = true;
        _onChanged();
        return;
      case ConnectionStatus.checking:
        return;
    }
  }

  Future<void> retryConnection() async {
    if (_isRetryingConnection) return;

    _isRetryingConnection = true;
    _onChanged();

    final status = await _connectivityNotifier.checkConnection();
    if (status == ConnectionStatus.online) {
      _isRetryingConnection = false;
      _showOfflineScreen = false;
      _onChanged();
      if (_canNavigate()) _onNavigate();
      return;
    }

    _isRetryingConnection = false;
    _onChanged();
  }
}
