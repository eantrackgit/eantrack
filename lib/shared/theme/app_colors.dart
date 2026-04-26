import 'package:flutter/material.dart';

/// EANTrack color tokens.
/// Extracted from FlutterFlow LightModeTheme — do not modify without updating DESIGN_SYSTEM.md.
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFFF90716);
  static const secondary = Color(0xFF0E0A36);
  static const tertiary = Color(0xFFD1D5DB);
  static const alternate = Color(0xFFE0E3E7);

  /// Crimson extraído diretamente da logo SVG (paths EAN — #a4202b).
  /// Usar em contextos de identidade visual: botão Google, badges de marca.
  static const brandRed = Color(0xFFA4202B);

  // Text
  static const primaryText = Color(0xFF14181B);
  static const secondaryText = Color(0xFF57636C);

  // Backgrounds
  static const scaffoldBackground = Color(0xFF080D1F);
  static const cardBackground = Color(0xFF0F1735);
  static const primaryBackground = Color(0xFFF1F4F8);
  static const secondaryBackground = Color(0xFFFFFFFF);
  static const modalOverlayBase = Color(0xFF050816);
  static const modalOverlayMid = Color(0xFF0E0A36);
  // Intentionally same blue as actionBlue — used as glow accent in modal backdrop.
  static const modalOverlayGlow = Color(0xFF1A56DB);

  // Gradients
  static const gradientStart = Color(0xFF0B1020);
  static const gradientMid = Color(0xFF10182B);
  static const gradientEnd = Color(0xFF121A2F);

  // Splash
  static const splashGlow = Color(0xFF4D72F5);
  static const splashSubtitle = Color(0xB8E4EAF6);

  // Auth scaffold
  static const authScaffoldTop = Color(0xFF0B1020);
  static const authScaffoldMid = Color(0xFF10182B);
  static const authScaffoldBottom = Color(0xFF121A2F);

  // Action
  static const actionBlue =
      Color(0xFF1A56DB); // consulta/busca (Consultar CNPJ, Buscar CEP)

  // Misc
  static const cardGlow = Color(0xFF4D72F5);
  static const versionText = Color(0xFF8E8D8D);

  // Theme tokens
  static const scaffoldOuter = Color(0xFF0B1020);
  static const cardSurface = Color(0xFF161D2F);
  static const inputFill = Color(0xFF1C2537);
  static const inputFillDisabled = Color(0xFF141C2B);
  static const inputBorder = Color(0xFF2E3B58);
  static const inputBorderFocused = Color(0xFF4D72F5);
  static const primaryTextLight = Color(0xFFE4EAF6);
  static const secondaryTextMuted = Color(0xFF7A8DB0);
  static const divider = Color(0xFF232C45);
  static const outlinedFg = Color(0xFF8896B3);
  static const accentLink = Color(0xFF7CA5E8);

  // Informational balloons
  static const balloonBorder = Color(0xFF38BDF8);
  static const balloonBackground = Color(0x2E38BDF8);
  static const balloonIconAction = Color(0xFFFF5963);
  static const balloonIconInfo = Color(0xFFAED221);
  static const balloonTitle = Color(0xFF38BDF8);

  // Accents
  static const accent1 = Color(0xFFC7CBD1);
  static const accent2 = Color(0xFF8E8D8D);
  static const accent3 = Color(0x4DEE8B60);
  static const accent4 = Color(0xFF4CAF50);

  // Semantic
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF9CF58);
  static const error = Color(0xFFFF5963);
  static const info = Color(0xFF3B82F6);
}
