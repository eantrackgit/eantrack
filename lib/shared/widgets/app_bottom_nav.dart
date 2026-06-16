import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Barra de navegação inferior para mobile, com o item central "BEEP"
/// flutuante e levemente elevado sobre um recorte no container principal.
///
/// Uso em HubScreen (mobile layout):
///   AppBottomNav(
///     currentIndex: _currentIndex,
///     onTap: (i) => setState(() => _currentIndex = i),
///   )
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const int beepIndex = 2;
  static const double _barHeight = 64;
  static const double _beepDiameter = 52;
  static const double _beepLift = 4;
  static const double _notchGap = 6;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    const beepRadius = _beepDiameter / 2;
    const pocketCenterY = beepRadius - _beepLift;
    const pocketRadius = beepRadius + _notchGap;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        child: SizedBox(
          height: _barHeight + _beepLift,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: PhysicalShape(
                  clipper: const _BeepNotchClipper(
                    cornerRadius: AppRadius.lg,
                    pocketCenterY: pocketCenterY,
                    pocketRadius: pocketRadius,
                  ),
                  color: et.sidebarSurface,
                  elevation: 6,
                  child: SizedBox(
                    height: _barHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: _NavItem(
                            icon: Icons.home_outlined,
                            activeIcon: Icons.home_rounded,
                            label: 'Início',
                            selected: currentIndex == 0,
                            onTap: () => onTap(0),
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: Icons.support_agent_outlined,
                            activeIcon: Icons.support_agent_rounded,
                            label: 'Chamados',
                            selected: currentIndex == 1,
                            onTap: () => onTap(1),
                          ),
                        ),
                        const Expanded(child: SizedBox.shrink()),
                        Expanded(
                          child: _NavItem(
                            icon: Icons.help_outline_rounded,
                            activeIcon: Icons.help_rounded,
                            label: 'Ajuda',
                            selected: currentIndex == 3,
                            onTap: () => onTap(3),
                          ),
                        ),
                        Expanded(
                          child: _NavItem(
                            icon: Icons.person_outline_rounded,
                            activeIcon: Icons.person_rounded,
                            label: 'Você',
                            selected: currentIndex == 4,
                            onTap: () => onTap(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: _BeepButton(
                    diameter: _beepDiameter,
                    selected: currentIndex == beepIndex,
                    onTap: () => onTap(beepIndex),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Recorta o container da navbar com um "bolso" circular no topo central,
/// onde o botão BEEP se encaixa — apenas [AppBottomNav._beepLift] pixels
/// do botão ficam visíveis acima da linha do container.
class _BeepNotchClipper extends CustomClipper<Path> {
  const _BeepNotchClipper({
    required this.cornerRadius,
    required this.pocketCenterY,
    required this.pocketRadius,
  });

  final double cornerRadius;
  final double pocketCenterY;
  final double pocketRadius;

  @override
  Path getClip(Size size) {
    final barPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(cornerRadius),
        ),
      );
    final pocketPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, pocketCenterY),
          radius: pocketRadius,
        ),
      );
    return Path.combine(PathOperation.difference, barPath, pocketPath);
  }

  @override
  bool shouldReclip(covariant _BeepNotchClipper oldClipper) =>
      oldClipper.cornerRadius != cornerRadius ||
      oldClipper.pocketCenterY != pocketCenterY ||
      oldClipper.pocketRadius != pocketRadius;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final color = selected ? et.ctaBackground : et.secondaryText;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(selected ? activeIcon : icon, size: 22, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeepButton extends StatelessWidget {
  const _BeepButton({
    required this.diameter,
    required this.selected,
    required this.onTap,
  });

  final double diameter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final circleColor = selected
        ? et.ctaBackground
        : et.ctaBackground.withValues(alpha: 0.85);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: circleColor,
          shape: const CircleBorder(),
          elevation: selected ? 5 : 3,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: Icon(
                Icons.qr_code_scanner_rounded,
                size: diameter * 0.46,
                color: et.ctaForeground,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'BEEP',
          style: AppTextStyles.labelSmall.copyWith(
            color: selected ? et.ctaBackground : et.secondaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
