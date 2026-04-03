import 'package:flutter/material.dart';

/// Spacing, radius, and shadow tokens.
/// Extracted from FlutterFlow FFSpacing / FFRadius / FFShadows.
abstract final class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

abstract final class AppRadius {
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double full = 9999.0;

  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
}

abstract final class AppShadows {
  static const sm = BoxShadow(
    blurRadius: 3,
    color: Color(0x1A000000),
    offset: Offset(0, 1),
  );
  static const md = BoxShadow(
    blurRadius: 6,
    color: Color(0x1A000000),
    offset: Offset(0, 3),
  );
  static const lg = BoxShadow(
    blurRadius: 15,
    color: Color(0x1A000000),
    offset: Offset(0, 8),
  );
  static const xl = BoxShadow(
    blurRadius: 25,
    color: Color(0x1A000000),
    offset: Offset(0, 16),
  );
}
