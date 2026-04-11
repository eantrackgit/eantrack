import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'app_card.dart';
import 'app_version_badge.dart';

// Espaço reservado na base do scroll para o badge fixo não sobrepor o card.
const double _kVersionFooterHeight = 24.0;

/// Standard layout for auth and onboarding screens.
///
/// Usa [EanTrackTheme] para adaptar cores ao modo claro/escuro.
/// O parâmetro [action] permite inserir um widget no canto superior direito
/// (ex: botão de alternância de tema).
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.showLogo = false,
    this.logoWidth = 180,
    this.logoHeight = 60,
    this.padding,
    this.action,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final bool showLogo;
  final double logoWidth;
  final double logoHeight;
  final EdgeInsetsGeometry? padding;

  /// Widget opcional posicionado no canto superior direito do scaffold.
  /// Ideal para controles globais como alternância de tema.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    return Scaffold(
      backgroundColor: et.scaffoldOuter,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: AppSpacing.xl,
                    // Reserva espaço para o badge fixo não cobrir o card.
                    bottom: AppSpacing.xl + _kVersionFooterHeight,
                  ),
                  child: AppCard(
                    color: et.cardSurface,
                    padding: padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showLogo) ...[
                          Center(
                            child: SvgPicture.asset(
                              'assets/images/eantrack.svg',
                              width: logoWidth,
                              height: logoHeight,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        if (title != null) ...[
                          Text(
                            title!,
                            style: AppTextStyles.headlineSmall.copyWith(
                              color: et.primaryText,
                            ),
                            textAlign:
                                showLogo ? TextAlign.center : TextAlign.start,
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              subtitle!,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: et.secondaryText,
                              ),
                              textAlign:
                                  showLogo ? TextAlign.center : TextAlign.start,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        child,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Versão discreta fixada no rodapé, fora do card e do scroll.
            const Positioned(
              bottom: 8,
              left: 0,
              right: 0,
              child: AppVersionBadge(),
            ),
            // Slot opcional para controles no canto superior direito.
            if (action != null)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: action!,
              ),
          ],
        ),
      ),
    );
  }
}
