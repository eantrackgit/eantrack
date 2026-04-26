import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

// ---------------------------------------------------------------------------
// EanTrackTheme — semantic color tokens for light/dark mode
// ---------------------------------------------------------------------------

/// Tokens semânticos de cor acessíveis via [EanTrackTheme.of(context)].
///
/// Sempre que uma cor precisar variar entre claro/escuro, usar este extension
/// em vez de [AppColors] diretamente.
@immutable
class EanTrackTheme extends ThemeExtension<EanTrackTheme> {
  const EanTrackTheme({
    required this.scaffoldOuter,
    required this.cardSurface,
    required this.sidebarSurface,
    required this.inputFill,
    required this.inputFillDisabled,
    required this.inputBorder,
    required this.inputBorderFocused,
    required this.primaryText,
    required this.secondaryText,
    required this.divider,
    required this.surface,
    required this.surfaceBorder,
    required this.ctaBackground,
    required this.ctaForeground,
    required this.outlinedFg,
    required this.socialBg,
    required this.socialFg,
    required this.socialBorder,
    required this.accentLink,
  });

  /// Fundo do Scaffold externo (atrás do card nas telas de auth).
  final Color scaffoldOuter;

  /// Fundo do card/container principal.
  final Color cardSurface;

  /// Fundo da sidebar lateral — diferenciado de cardSurface para criar profundidade.
  final Color sidebarSurface;

  /// Fill de campos de entrada (estado habilitado).
  final Color inputFill;

  /// Fill de campos de entrada (estado desabilitado).
  final Color inputFillDisabled;

  /// Borda de campos em estado idle/habilitado.
  final Color inputBorder;

  /// Borda de campos em estado focado.
  final Color inputBorderFocused;

  /// Cor primária de texto (títulos, conteúdo principal).
  final Color primaryText;

  /// Cor secundária de texto (subtítulos, hints, labels).
  final Color secondaryText;

  /// Cor de divisores e separadores.
  final Color divider;

  /// Fundo de containers secundários (chips, banners, painéis internos).
  final Color surface;

  /// Borda de containers secundários.
  final Color surfaceBorder;

  /// Fundo do botão primário (CTA principal).
  final Color ctaBackground;

  /// Foreground (texto/ícone) do botão primário.
  final Color ctaForeground;

  /// Cor de borda e texto do botão outlined/secundário.
  final Color outlinedFg;

  /// Fundo do botão social (Google). Neutro em dark, brand em light.
  final Color socialBg;

  /// Foreground (texto/ícone) do botão social.
  final Color socialFg;

  /// Borda do botão social (visível em dark, transparente em light).
  final Color socialBorder;

  /// Cor de links inline (recuperação de senha, etc.).
  final Color accentLink;

  // -------------------------------------------------------------------------
  // Accessor
  // -------------------------------------------------------------------------

  static EanTrackTheme of(BuildContext context) =>
      Theme.of(context).extension<EanTrackTheme>()!;

  // -------------------------------------------------------------------------
  // Presets
  // -------------------------------------------------------------------------

  static const EanTrackTheme light = EanTrackTheme(
    scaffoldOuter: AppColors.secondary,
    cardSurface: AppColors.secondaryBackground,
    sidebarSurface: AppColors.primaryBackground,
    inputFill: AppColors.secondaryBackground,
    inputFillDisabled: AppColors.primaryBackground,
    inputBorder: AppColors.alternate,
    inputBorderFocused: AppColors.actionBlue,
    primaryText: AppColors.primaryText,
    secondaryText: AppColors.secondaryText,
    divider: AppColors.accent1,
    surface: AppColors.secondaryBackground,
    surfaceBorder: AppColors.alternate,
    ctaBackground: AppColors.secondary,
    ctaForeground: AppColors.secondaryBackground,
    outlinedFg: AppColors.secondary,
    socialBg: AppColors.brandRed,
    socialFg: AppColors.secondaryBackground,
    socialBorder: Colors.transparent,
    accentLink: AppColors.actionBlue,
  );

  static const EanTrackTheme dark = EanTrackTheme(
      scaffoldOuter: AppColors.scaffoldOuter,
      cardSurface: AppColors.cardSurface,
      sidebarSurface: AppColors.scaffoldOuter,
      inputFill: AppColors.inputFill,
      inputFillDisabled: AppColors.inputFillDisabled,
      inputBorder: AppColors.inputBorder,
      inputBorderFocused: AppColors.inputBorderFocused,
      primaryText: AppColors.primaryTextLight,
      secondaryText: AppColors.secondaryTextMuted,
      divider: AppColors.divider,
      surface: AppColors.inputFill,
      surfaceBorder: AppColors.inputBorder,
      ctaBackground: AppColors.primary,
    ctaForeground: Color(0xFFFFFFFF),
      outlinedFg: AppColors.outlinedFg,
      socialBg: AppColors.inputFill,
      socialFg: AppColors.primaryTextLight,
      socialBorder: AppColors.inputBorder,
      accentLink: AppColors.accentLink,
  );

  // -------------------------------------------------------------------------
  // ThemeExtension interface
  // -------------------------------------------------------------------------

  @override
  EanTrackTheme copyWith({
    Color? scaffoldOuter,
    Color? cardSurface,
    Color? sidebarSurface,
    Color? inputFill,
    Color? inputFillDisabled,
    Color? inputBorder,
    Color? inputBorderFocused,
    Color? primaryText,
    Color? secondaryText,
    Color? divider,
    Color? surface,
    Color? surfaceBorder,
    Color? ctaBackground,
    Color? ctaForeground,
    Color? outlinedFg,
    Color? socialBg,
    Color? socialFg,
    Color? socialBorder,
    Color? accentLink,
  }) {
    return EanTrackTheme(
      scaffoldOuter: scaffoldOuter ?? this.scaffoldOuter,
      cardSurface: cardSurface ?? this.cardSurface,
      sidebarSurface: sidebarSurface ?? this.sidebarSurface,
      inputFill: inputFill ?? this.inputFill,
      inputFillDisabled: inputFillDisabled ?? this.inputFillDisabled,
      inputBorder: inputBorder ?? this.inputBorder,
      inputBorderFocused: inputBorderFocused ?? this.inputBorderFocused,
      primaryText: primaryText ?? this.primaryText,
      secondaryText: secondaryText ?? this.secondaryText,
      divider: divider ?? this.divider,
      surface: surface ?? this.surface,
      surfaceBorder: surfaceBorder ?? this.surfaceBorder,
      ctaBackground: ctaBackground ?? this.ctaBackground,
      ctaForeground: ctaForeground ?? this.ctaForeground,
      outlinedFg: outlinedFg ?? this.outlinedFg,
      socialBg: socialBg ?? this.socialBg,
      socialFg: socialFg ?? this.socialFg,
      socialBorder: socialBorder ?? this.socialBorder,
      accentLink: accentLink ?? this.accentLink,
    );
  }

  @override
  EanTrackTheme lerp(EanTrackTheme? other, double t) {
    if (other is! EanTrackTheme) return this;
    return EanTrackTheme(
      scaffoldOuter: Color.lerp(scaffoldOuter, other.scaffoldOuter, t)!,
      cardSurface: Color.lerp(cardSurface, other.cardSurface, t)!,
      sidebarSurface: Color.lerp(sidebarSurface, other.sidebarSurface, t)!,
      inputFill: Color.lerp(inputFill, other.inputFill, t)!,
      inputFillDisabled:
          Color.lerp(inputFillDisabled, other.inputFillDisabled, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      inputBorderFocused:
          Color.lerp(inputBorderFocused, other.inputBorderFocused, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      secondaryText: Color.lerp(secondaryText, other.secondaryText, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceBorder: Color.lerp(surfaceBorder, other.surfaceBorder, t)!,
      ctaBackground: Color.lerp(ctaBackground, other.ctaBackground, t)!,
      ctaForeground: Color.lerp(ctaForeground, other.ctaForeground, t)!,
      outlinedFg: Color.lerp(outlinedFg, other.outlinedFg, t)!,
      socialBg: Color.lerp(socialBg, other.socialBg, t)!,
      socialFg: Color.lerp(socialFg, other.socialFg, t)!,
      socialBorder: Color.lerp(socialBorder, other.socialBorder, t)!,
      accentLink: Color.lerp(accentLink, other.accentLink, t)!,
    );
  }
}

// ---------------------------------------------------------------------------
// AppTheme
// ---------------------------------------------------------------------------

abstract final class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.primary,
        onPrimary: AppColors.info,
        secondary: AppColors.secondary,
        onSecondary: AppColors.info,
        error: AppColors.error,
        onError: AppColors.info,
        surface: AppColors.secondaryBackground,
        onSurface: AppColors.primaryText,
      ),
      scaffoldBackgroundColor: AppColors.primaryBackground,
      extensions: const [EanTrackTheme.light],
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: AppColors.secondaryBackground,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: const BorderSide(color: AppColors.alternate),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: const BorderSide(color: AppColors.alternate),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: const BorderSide(color: AppColors.actionBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: AppColors.info,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          textStyle: AppTextStyles.titleSmall,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.info,
        elevation: 0,
      ),
    );
  }

  static ThemeData dark() {
    const et = EanTrackTheme.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.primaryTextLight,
        secondary: AppColors.primary,
        onSecondary: AppColors.primaryTextLight,
        error: AppColors.error,
        onError: AppColors.primaryTextLight,
        surface: AppColors.cardSurface,
        onSurface: AppColors.primaryTextLight,
      ),
      scaffoldBackgroundColor: et.scaffoldOuter,
      extensions: const [EanTrackTheme.dark],
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
      ),
      inputDecorationTheme: InputDecorationTheme(
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: et.inputFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 4,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: BorderSide(color: et.inputBorderFocused, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.smAll,
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondary,
          foregroundColor: const Color(0xFFE4EAF6),
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
          textStyle: AppTextStyles.titleSmall,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: et.cardSurface,
        foregroundColor: et.primaryText,
        elevation: 0,
      ),
    );
  }
}
