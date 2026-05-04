import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/connectivity/connectivity_provider.dart';
import '../core/router/app_router.dart';
import '../features/auth/presentation/providers/auth_provider.dart';
import '../shared/shared.dart';

class EanTrackApp extends ConsumerStatefulWidget {
  const EanTrackApp({super.key});

  @override
  ConsumerState<EanTrackApp> createState() => _EanTrackAppState();
}

class _EanTrackAppState extends ConsumerState<EanTrackApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(userThemeControllerProvider.notifier).loadForCurrentUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authUserStreamProvider, (previous, next) {
      next.whenData((user) {
        final controller = ref.read(userThemeControllerProvider.notifier);
        if (user == null) {
          controller.clearSessionState();
          return;
        }

        controller.loadForCurrentUser();
      });
    });
    ref.listen(themeModeProvider, (previous, next) {
      if (previous == null || previous == next) return;
      ref
          .read(userThemeControllerProvider.notifier)
          .persistThemeChange(next);
    });

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
