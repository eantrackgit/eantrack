import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

// Dimensões/elevações da navbar, centralizadas para evitar números mágicos
// espalhados pelos widgets abaixo. Paddings usam os tokens AppSpacing/
// AppRadius já adotados no resto do app.
const double _kBarHeight = 64;
const double _kBeepDiameter = 52;
const double _kBeepIconSizeFactor = 0.46;
const double _kSideIconSize = 22;
const double _kLabelFontSize = 11;
const double _kLabelGap = 2;

// O BEEP fica visualmente acima da linha dos demais ícones para reforçar
// que é o destaque principal — sem virar um FAB grande, é só esse respiro.
const double _kBeepLift = 4;

// O recorte é um "vale" raso: o raio define a curvatura (levemente maior
// que o BEEP, para abraçá-lo) e a profundidade controla o quanto o
// container é de fato cortado. Profundidade pequena = recorte intencional,
// não uma cratera do tamanho do botão.
const double _kNotchRadius = 32;
const double _kNotchDepth = 12;
const double _kCornerRadius = AppRadius.lg;

const double _kBarElevation = 6;
const double _kBeepElevationActive = 5;
const double _kBeepElevationInactive = 3;

/// Barra de navegação inferior para mobile, com o item central "BEEP"
/// flutuante sobre um recorte no container principal.
///
/// A API pública é só [currentIndex]/[onTap]: este widget apenas reporta
/// qual item foi tocado. Navegação real (rotas, push/go) é decidida por
/// quem usa o componente — hoje, a `HubScreen`.
///
/// Uso:
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

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

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
          height: _kBarHeight + _kBeepLift,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: PhysicalShape(
                  clipper: const _BeepNotchClipper(),
                  color: et.sidebarSurface,
                  elevation: _kBarElevation,
                  child: SizedBox(
                    height: _kBarHeight,
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
                        // Espaço reservado sob o BEEP: o botão flutua acima
                        // deste slot, fora da Row (ver Positioned abaixo).
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
              // BEEP poking _kBeepLift acima da linha dos demais ícones —
              // ver comentário sobre _kBeepLift no topo do arquivo.
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Center(
                  child: _BeepButton(
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

/// Recorta um vale raso e largo no topo central do container, por onde o
/// BEEP aparece. Ver constantes [_kNotchRadius]/[_kNotchDepth]: a
/// profundidade pequena garante que o corte pareça intencional/integrado,
/// em vez de um buraco do tamanho inteiro do botão atrás dele.
class _BeepNotchClipper extends CustomClipper<Path> {
  const _BeepNotchClipper();

  @override
  Path getClip(Size size) {
    final barPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(_kCornerRadius),
        ),
      );

    // Círculo centrado acima do container: só a calota inferior dele
    // (altura _kNotchDepth) chega a interceptar a barra.
    const notchCenterY = _kNotchDepth - _kNotchRadius;
    final notchPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, notchCenterY),
          radius: _kNotchRadius,
        ),
      );

    return Path.combine(PathOperation.difference, barPath, notchPath);
  }

  // Geometria é toda fixa (constantes do topo do arquivo); não há estado
  // que justifique reclip entre frames.
  @override
  bool shouldReclip(covariant _BeepNotchClipper oldClipper) => false;
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
            Icon(selected ? activeIcon : icon, size: _kSideIconSize, color: color),
            const SizedBox(height: _kLabelGap),
            // FittedBox evita overflow/corte do label em telas estreitas
            // (360–430px) sem precisar truncar o texto com ellipsis.
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: _kLabelFontSize,
                  color: color,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeepButton extends StatelessWidget {
  const _BeepButton({required this.selected, required this.onTap});

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
          elevation: selected ? _kBeepElevationActive : _kBeepElevationInactive,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: _kBeepDiameter,
              height: _kBeepDiameter,
              child: Icon(
                // Ícone provisório (placeholder); refinamento do ícone do
                // BEEP fica para outra tarefa.
                Icons.qr_code_scanner_rounded,
                size: _kBeepDiameter * _kBeepIconSizeFactor,
                color: et.ctaForeground,
              ),
            ),
          ),
        ),
        const SizedBox(height: _kLabelGap),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'BEEP',
            maxLines: 1,
            style: AppTextStyles.labelSmall.copyWith(
              fontSize: _kLabelFontSize,
              color: selected ? et.ctaBackground : et.secondaryText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
