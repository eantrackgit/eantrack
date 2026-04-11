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
  static const _animationDuration = Duration(milliseconds: 680);

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;
  late final Animation<double> _subtitleFade;
  late final Animation<double> _subtitleOffset;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.68, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(
      begin: 0.94,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.76, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.18, 0.82, curve: Curves.easeOutCubic),
    );
    _subtitleOffset = Tween<double>(
      begin: 8,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.18, 0.82, curve: Curves.easeOutCubic),
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
      body: DecoratedBox(
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
              alignment: const Alignment(0, -0.12),
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF4D72F5).withValues(alpha: 0.08),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x224D72F5),
                      blurRadius: 80,
                      spreadRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FadeTransition(
                    opacity: _fade,
                    child: ScaleTransition(
                      scale: _scale,
                      child: SvgPicture.asset(
                        'assets/images/eantrack.svg',
                        width: 200,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
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
                        fontWeight: FontWeight.w500,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
