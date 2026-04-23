import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../shared/shared.dart';
import 'splash_notifier.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.watch(splashNotifierProvider);

    return ListenableBuilder(
      listenable: notifier,
      builder: (context, _) => Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            _SplashBackground(notifier: notifier),
            _SplashLogo(notifier: notifier),
            _SplashSubtitle(notifier: notifier),
          ],
        ),
      ),
    );
  }
}

class _SplashBackground extends StatelessWidget {
  const _SplashBackground({required this.notifier});

  final SplashNotifier notifier;

  static const _glowColor = AppColors.splashGlow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logoWidth =
            (constraints.maxWidth * 0.58).clamp(260.0, 300.0).toDouble();
        final glowSize = (logoWidth * 0.72).clamp(168.0, 210.0).toDouble();

        return DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
            AppColors.gradientStart,
            AppColors.gradientMid,
            AppColors.gradientEnd,
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
                child: SizedBox(width: logoWidth, height: logoWidth / 3 + 30),
              ),
              if (notifier.showOfflineScreen)
                Positioned.fill(
                  child: NoConnectionView(
                    isRetrying: notifier.isRetryingConnection,
                    onRetry: notifier.retryConnection,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.notifier});

  final SplashNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final logoWidth =
            (constraints.maxWidth * 0.58).clamp(260.0, 300.0).toDouble();

        return Align(
          alignment: const Alignment(0, -0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: FadeTransition(
                opacity: notifier.logoFade,
                child: AnimatedBuilder(
                  animation: notifier.controller,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, notifier.logoLift.value),
                      child: ScaleTransition(
                        scale: notifier.logoScale,
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
            ),
          ),
        );
      },
    );
  }
}

class _SplashSubtitle extends StatelessWidget {
  const _SplashSubtitle({required this.notifier});

  final SplashNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: const Alignment(0, -0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.only(top: 96),
            child: AnimatedBuilder(
              animation: notifier.controller,
              builder: (context, child) {
                return Opacity(
                  opacity: notifier.subtitleFade.value,
                  child: Transform.translate(
                    offset: Offset(0, notifier.subtitleOffset.value),
                    child: child,
                  ),
                );
              },
              child: const Text(
                'Smart Tracking',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.splashSubtitle,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
