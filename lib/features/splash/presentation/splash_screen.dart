import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 620);
  static const _glowColor = Color(0xFF4D72F5);

  late final AnimationController _ctrl;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoLift;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _subtitleOffset;

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
        context.go(AppRoutes.login);
      }
    });
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
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
    );
  }
}
