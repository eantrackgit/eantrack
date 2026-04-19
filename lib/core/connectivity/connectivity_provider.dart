import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_notifier.dart';
import 'connectivity_service.dart';
import 'connectivity_state.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return HttpConnectivityService();
});

final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectionStatus>((ref) {
      return ConnectivityNotifier(ref.read(connectivityServiceProvider));
    });
