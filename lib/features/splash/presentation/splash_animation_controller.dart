import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class SplashAnimationController extends ChangeNotifier implements TickerProvider {
  SplashAnimationController({required VoidCallback onCompleted})
      : _onCompleted = onCompleted {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.58, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _liftAnimation = Tween<double>(begin: 10, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.72, curve: Curves.easeOutCubic),
      ),
    );
    _subtitleFadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.22, 0.74, curve: Curves.easeOutCubic),
    );
    _subtitleOffsetAnimation = Tween<double>(begin: 6, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.22, 0.74, curve: Curves.easeOutCubic),
      ),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _isCompleted = true;
        _onCompleted();
      }
    });
    _controller.forward();
  }

  final VoidCallback _onCompleted;
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _liftAnimation;
  late final Animation<double> _subtitleFadeAnimation;
  late final Animation<double> _subtitleOffsetAnimation;
  bool _isCompleted = false;

  AnimationController get controller => _controller;
  Animation<double> get fadeAnimation => _fadeAnimation;
  Animation<double> get scaleAnimation => _scaleAnimation;
  Animation<double> get liftAnimation => _liftAnimation;
  Animation<double> get subtitleFadeAnimation => _subtitleFadeAnimation;
  Animation<double> get subtitleOffsetAnimation => _subtitleOffsetAnimation;
  bool get isCompleted => _isCompleted;

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
