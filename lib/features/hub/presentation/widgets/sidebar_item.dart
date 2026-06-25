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
    // Azul temático adaptativo (forte no claro, suave no escuro). Itens
    // navegáveis ganham presença azul; destrutivo permanece em vermelho.
    final accent = et.accentLink;
    final tint = isDestructive ? AppColors.error : accent;
    final iconColor = isDestructive
        ? AppColors.error
        : (comfortable ? accent : et.primaryText.withValues(alpha: 0.8));
    final textColor = isDestructive ? AppColors.error : et.primaryText;

    // Item de submenu confortável: fonte maior (15.5sp / w600) e área de toque
    // ampla, quase do tamanho do título do grupo mas mantendo hierarquia.
    final labelStyle = comfortable
        ? AppTextStyles.bodyMedium.copyWith(
            fontSize: 15.5,
            fontWeight: FontWeight.w600,
            color: textColor,
          )
        : AppTextStyles.bodySmall.copyWith(
            fontWeight: FontWeight.w500,
            color: textColor,
          );

    // Confortável: ícone numa mini-pílula azul, ecoando o header e dando a
    // sensação de "lista de ações". Compacto mantém o ícone legado simples.
    final Widget iconWidget = comfortable
        ? Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          )
        : Icon(icon, size: 17, color: iconColor);

    final row = ConstrainedBox(
      // Confortável (desktop + mobile) ganha altura/área de toque maior
      // (>= 58px); compacto mantém o tamanho mínimo legado.
      constraints: BoxConstraints(minHeight: comfortable ? 58 : 0),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: comfortable ? 12 : AppSpacing.md,
          vertical: comfortable ? 9 : AppSpacing.sm,
        ),
        child: Row(
          children: [
            iconWidget,
            SizedBox(width: comfortable ? 14 : AppSpacing.sm),
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
                size: comfortable ? 20 : 18,
                color: comfortable
                    ? accent.withValues(alpha: 0.6)
                    : et.secondaryText.withValues(alpha: 0.7),
              ),
          ],
        ),
      ),
    );

    // Confortável: cada item vira um bloco leve com tint azul, radius e
    // gap -> lista moderna premium, com hover/pressed azul. Compacto
    // (legado) permanece transparente, sem regressão.
    final Widget interactive = comfortable
        ? Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 3,
            ),
            child: Material(
              color: enabled ? tint.withValues(alpha: 0.05) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: enabled ? onTap : null,
                hoverColor: accent.withValues(alpha: 0.10),
                splashColor: accent.withValues(alpha: 0.12),
                highlightColor: accent.withValues(alpha: 0.08),
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
