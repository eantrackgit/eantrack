import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/connectivity/connectivity_state.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';
import 'splash_animation_controller.dart';
import 'splash_connectivity_handler.dart';

final splashNotifierProvider = Provider.autoDispose<SplashNotifier>((ref) {
  final notifier = SplashNotifier(ref);
  ref.listen<ConnectionStatus>(
    connectivityProvider,
    (_, next) => notifier.handleConnectionStatus(next),
  );
  ref.onDispose(notifier.dispose);
  return notifier;
});

class SplashNotifier extends ChangeNotifier {
  SplashNotifier(this._ref) {
    _animation = SplashAnimationController(
      onCompleted: () => _connectivity.handleConnectionStatus(
        _ref.read(connectivityProvider),
      ),
    );
    _connectivity = SplashConnectivityHandler(
      connectivityNotifier: _ref.read(connectivityProvider.notifier),
      onChanged: notifyListeners,
      onNavigate: _resolveRoute,
      canNavigate: () => !_hasNavigated,
      isAnimationCompleted: () => _animation.isCompleted,
    );
  }

  final Ref _ref;
  late final SplashAnimationController _animation;
  late final SplashConnectivityHandler _connectivity;
  bool _hasNavigated = false;
  AnimationController get controller => _animation.controller;
  Animation<double> get logoFade => _animation.fadeAnimation;
  Animation<double> get logoScale => _animation.scaleAnimation;
  Animation<double> get logoLift => _animation.liftAnimation;
  Animation<double> get subtitleFade => _animation.subtitleFadeAnimation;
  Animation<double> get subtitleOffset => _animation.subtitleOffsetAnimation;
  bool get showOfflineScreen => _connectivity.showOfflineScreen;
  bool get isRetryingConnection => _connectivity.isRetryingConnection;
  void handleConnectionStatus(ConnectionStatus status) => _connectivity.handleConnectionStatus(status);
  Future<void> retryConnection() => _connectivity.retryConnection();
  Future<void> _resolveRoute() async {
    if (_hasNavigated) return;
    _hasNavigated = true;

    final supabase = Supabase.instance.client;
    final session = supabase.auth.currentSession;

    if (session == null) {
      _ref.read(appRouterProvider).go(AppRoutes.login);
      return;
    }

    try {
      final route = await supabase.rpc('get_user_onboarding_route') as String?;

      switch (route) {
        case 'hub':
          _ref.read(appRouterProvider).go(AppRoutes.hub);
        case 'onboarding/agency/status':
          _ref.read(appRouterProvider).go(AppRoutes.onboardingAgencyStatus);
        case 'onboarding/agency/representative':
          _ref.read(appRouterProvider).go(AppRoutes.onboardingAgencyRepresentative);
        case 'onboarding/agency/cnpj':
          _ref.read(appRouterProvider).go(AppRoutes.onboardingAgencyCnpj);
        case 'onboarding/individual/profile':
          _ref.read(appRouterProvider).go(AppRoutes.onboardingIndividualProfile);
        default:
          _ref.read(appRouterProvider).go(AppRoutes.onboarding);
      }
    } on Exception catch (e) {
      debugPrint('[Splash] Erro ao resolver rota: $e');
      _ref.read(appRouterProvider).go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }
}
