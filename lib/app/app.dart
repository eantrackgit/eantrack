import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/connectivity/connectivity_provider.dart';
import '../core/router/app_router.dart';
import '../shared/shared.dart';

class EanTrackApp extends ConsumerWidget {
  const EanTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'EANTrack',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      builder: (context, child) {
        return _ConnectivityBootstrap(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

class _ConnectivityBootstrap extends ConsumerWidget {
  const _ConnectivityBootstrap({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(connectivityProvider);
    return child;
  }
}
