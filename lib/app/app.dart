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
      final user = ref.read(supabaseClientProvider).auth.currentUser;
      if (user != null) {
        ref
            .read(keepConnectedControllerProvider.notifier)
            .load(userId: user.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authUserStreamProvider, (previous, next) {
      next.whenData((user) {
        final themeController = ref.read(userThemeControllerProvider.notifier);
        final keepConnectedController =
            ref.read(keepConnectedControllerProvider.notifier);
        if (user == null) {
          themeController.clearSessionState();
          keepConnectedController.clearSessionState();
          return;
        }

        // onAuthStateChange also fires on token refresh for the same user
        // (every ~50min with autoRefreshToken). Skip the reload then to
        // avoid a keep_connected read per refresh across 100k+ sessions.
        if (previous?.valueOrNull?.id == user.id) return;

        themeController.loadForCurrentUser();
        keepConnectedController.load(userId: user.id);
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
