import 'package:flutter/material.dart';

abstract final class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobile && w < tablet;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
}

/// Builds the appropriate widget based on screen width.
///
/// Usage:
///   ResponsiveLayout(
///     mobile: MobileView(),
///     tablet: TabletView(),      // optional, falls back to mobile
///     desktop: DesktopView(),    // optional, falls back to tablet → mobile
///   )
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= Breakpoints.tablet && desktop != null) return desktop!;
    if (width >= Breakpoints.mobile && tablet != null) return tablet!;
    return mobile;
  }
}

/// Centers content with a max width — used for auth screens on tablet/desktop.
class CenteredCard extends StatelessWidget {
  const CenteredCard({
    super.key,
    required this.child,
    this.maxWidth = 480,
    this.padding = const EdgeInsets.all(24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
