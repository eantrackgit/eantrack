import 'package:flutter/material.dart';

/// EANTrack color tokens.
/// Extracted from FlutterFlow LightModeTheme — do not modify without updating DESIGN_SYSTEM.md.
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFFF90716);
  static const secondary = Color(0xFF0E0A36);
  static const tertiary = Color(0xFFD1D5DB);
  static const alternate = Color(0xFFE0E3E7);

  // Text
  static const primaryText = Color(0xFF14181B);
  static const secondaryText = Color(0xFF57636C);

  // Backgrounds
  static const primaryBackground = Color(0xFFF1F4F8);
  static const secondaryBackground = Color(0xFFFFFFFF);
  static const modalOverlayBase = Color(0xFF050816);
  static const modalOverlayMid = Color(0xFF0E0A36);
  // Intentionally same blue as actionBlue — used as glow accent in modal backdrop.
  static const modalOverlayGlow = Color(0xFF1A56DB);

  // Action
  static const actionBlue =
      Color(0xFF1A56DB); // consulta/busca (Consultar CNPJ, Buscar CEP)

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
