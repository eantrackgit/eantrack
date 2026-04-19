import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/connectivity_provider.dart';
import '../../../core/connectivity/connectivity_state.dart';
import '../../../core/connectivity/presentation/no_connection_screen.dart';
import '../../../core/router/app_routes.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 620);
  static const _glowColor = Color(0xFF4D72F5);

  late final AnimationController _ctrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoLift;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _subtitleOffset;
  bool _animationCompleted = false;
  bool _showOfflineScreen = false;
  bool _isRetryingConnection = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _logoFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.58, curve: Curves.easeOutCubic),
    );
    _logoScale = Tween<double>(
      begin: 0.92,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _logoLift = Tween<double>(
      begin: 10,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.22, 0.74, curve: Curves.easeOutCubic),
    );
    _subtitleOffset = Tween<double>(
      begin: 6,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.22, 0.74, curve: Curves.easeOutCubic),
      ),
    );

    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _animationCompleted = true;
        _handleConnectionStatus(ref.read(connectivityProvider));
      }
    });
    _ctrl.forward();
  }

  void _handleConnectionStatus(ConnectionStatus status) {
    if (!_animationCompleted || _showOfflineScreen || _hasNavigated || !mounted) {
      return;
    }

    switch (status) {
      case ConnectionStatus.online:
        _goToLogin();
        return;
      case ConnectionStatus.offline:
        setState(() => _showOfflineScreen = true);
        return;
      case ConnectionStatus.checking:
        return;
    }
  }

  void _goToLogin() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    context.go(AppRoutes.login);
  }

  Future<void> _retryConnection() async {
    if (_isRetryingConnection) return;

    setState(() => _isRetryingConnection = true);
    final status = await ref.read(connectivityProvider.notifier).checkConnection();
    if (!mounted) return;

    if (status == ConnectionStatus.online) {
      setState(() {
        _isRetryingConnection = false;
        _showOfflineScreen = false;
      });
      _goToLogin();
      return;
    }

    setState(() => _isRetryingConnection = false);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ConnectionStatus>(connectivityProvider, (_, next) {
      _handleConnectionStatus(next);
    });

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final logoWidth =
                  (constraints.maxWidth * 0.58).clamp(260.0, 300.0).toDouble();
              final glowSize =
                  (logoWidth * 0.72).clamp(168.0, 210.0).toDouble();

              return DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF080B1A),
                      Color(0xFF0E1631),
                      Color(0xFF111B3A),
                    ],
                  ),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: const Alignment(0, -0.08),
                      child: Container(
                        width: glowSize,
                        height: glowSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              _glowColor.withValues(alpha: 0.14),
                              _glowColor.withValues(alpha: 0.05),
                              _glowColor.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.58, 1.0],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _glowColor.withValues(alpha: 0.16),
                              blurRadius: 56,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Align(
                      alignment: const Alignment(0, -0.08),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FadeTransition(
                                opacity: _logoFade,
                                child: AnimatedBuilder(
                                  animation: _ctrl,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _logoLift.value),
                                      child: ScaleTransition(
                                        scale: _logoScale,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: SvgPicture.asset(
                                    'assets/images/eantrack.svg',
                                    width: logoWidth,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              AnimatedBuilder(
                                animation: _ctrl,
                                builder: (context, child) {
                                  return Opacity(
                                    opacity: _subtitleFade.value,
                                    child: Transform.translate(
                                      offset: Offset(0, _subtitleOffset.value),
                                      child: child,
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Smart Tracking',
                                  style: TextStyle(
                                    color: Color(0xB8E4EAF6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          if (_showOfflineScreen)
            Positioned.fill(
              child: NoConnectionScreen(
                isRetrying: _isRetryingConnection,
                onRetry: _retryConnection,
              ),
            ),
        ],
      ),
    );
  }
}
