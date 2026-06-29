part of 'menu_hub_sidebar.dart';

class _MenuHubSectionItem extends StatelessWidget {
  const _MenuHubSectionItem({
    required this.icon,
    required this.label,
    this.count,
    this.enabled = true,
    this.isDestructive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final int? count;
  final bool enabled;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final comfortable = _MenuHubLayout.comfortableOf(context);
    // Azul temático adaptativo (forte no claro, suave no escuro). Em camadas:
    // o header carrega o azul forte; o subitem usa azul suave para parecer
    // conteúdo subordinado, não uma categoria principal.
    final accent = et.accentLink;
    final iconColor = isDestructive
        ? AppColors.error
        : (comfortable
            ? accent.withValues(alpha: 0.85)
            : et.primaryText.withValues(alpha: 0.8));
    final textColor = isDestructive ? AppColors.error : et.primaryText;

    // Item de submenu confortável: ainda grande/legível (15sp), mas com peso
    // w500 -- abaixo do header (w700) -- reforçando a hierarquia visual.
    final labelStyle = comfortable
        ? AppTextStyles.bodyMedium.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: textColor,
          )
        : AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: textColor,
          );

    // Confortável: ícone azul flat (sem pílula). A pílula fica exclusiva do
    // header -> o subitem lê como opção dentro da seção, não como card.
    final Widget iconWidget = comfortable
        ? Icon(icon, size: 20, color: iconColor)
        : Icon(icon, size: 17, color: iconColor);

    final row = ConstrainedBox(
      // Confortável: altura confortável (>= 52px), porém menor que o header
      // (56px) -- subordinação também na presença física.
      constraints: BoxConstraints(minHeight: comfortable ? 52 : 0),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: comfortable ? 10 : AppSpacing.md,
          vertical: comfortable ? 8 : AppSpacing.sm,
        ),
        child: Row(
          children: [
            iconWidget,
            SizedBox(width: comfortable ? 12 : AppSpacing.sm),
            if (count != null) ...[
              Text(
                '$count',
                style: AppTextStyles.labelLarge.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Expanded(
              child: Text(
                label,
                style: labelStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (enabled)
              Icon(
                Icons.navigate_next,
                size: 18,
                color: comfortable
                    ? et.secondaryText.withValues(alpha: 0.55)
                    : et.secondaryText.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );

    // Confortável: subitem neutro/transparente dentro do painel interno da
    // seção -- só ganha azul no hover/pressed, mantendo o azul forte para o
    // header. Radius pequeno (8) -> lê como linha premium da lista interna, não
    // como card solto; o arredondamento forte pertence ao painel do grupo.
    // Compacto (legado) permanece transparente, sem regressão.
    final Widget interactive = comfortable
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enabled ? onTap : null,
                hoverColor: accent.withValues(alpha: 0.08),
                splashColor: accent.withValues(alpha: 0.10),
                highlightColor: accent.withValues(alpha: 0.06),
                child: row,
              ),
            ),
          )
        : Material(
            color: Colors.transparent,
            child: InkWell(onTap: enabled ? onTap : null, child: row),
          );

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: interactive,
    );
  }
}

class _MenuHubActionButton extends StatelessWidget {
  const _MenuHubActionButton({required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);
    final comfortable = _MenuHubLayout.comfortableOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        comfortable ? AppSpacing.sm : AppSpacing.md,
        AppSpacing.xs,
        comfortable ? AppSpacing.sm : AppSpacing.md,
        AppSpacing.sm,
      ),
      child: SizedBox(
        height: comfortable ? 46 : 34,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: et.primaryText,
            side: BorderSide(color: et.inputBorder),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: et.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuHubBillingRow extends StatelessWidget {
  const _MenuHubBillingRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.receipt_outlined,
            size: 13,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
