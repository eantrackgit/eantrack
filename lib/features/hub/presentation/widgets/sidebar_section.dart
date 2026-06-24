part of 'menu_hub_sidebar.dart';

/// Sinaliza para a subárvore do menu se o layout é "confortável" (mobile),
/// permitindo que itens e áreas de toque cresçam sem precisar passar uma flag
/// por dezenas de construtores. Desktop não fornece este widget -> o default é
/// compacto, preservando exatamente o visual atual da sidebar fixa.
class _MenuHubLayout extends InheritedWidget {
  const _MenuHubLayout({
    required this.comfortable,
    required super.child,
  });

  final bool comfortable;

  static bool comfortableOf(BuildContext context) {
    final widget =
        context.dependOnInheritedWidgetOfExactType<_MenuHubLayout>();
    return widget?.comfortable ?? false;
  }

  @override
  bool updateShouldNotify(_MenuHubLayout oldWidget) =>
      comfortable != oldWidget.comfortable;
}

/// Seção do menu do Hub.
///
/// Desktop (default, `collapsible == false`): cabeçalho estático com o título
/// em maiúsculas e os itens sempre visíveis — visual original, sem regressão.
///
/// Mobile (`collapsible == true`): delega para [_CollapsibleMenuSection], um
/// accordion dedicado com header tocável, chevron animado e conteúdo que
/// abre/fecha com animação.
class _MenuHubSection extends StatelessWidget {
  const _MenuHubSection({
    required this.icon,
    required this.title,
    required this.children,
    this.wrapInCard = true,
    this.collapsible = false,
    this.initiallyExpanded = true,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool wrapInCard;
  final bool collapsible;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (collapsible) {
      return _CollapsibleMenuSection(
        icon: icon,
        title: title,
        initiallyExpanded: initiallyExpanded,
        children: children,
      );
    }

    final et = EanTrackTheme.of(context);
    final childrenWidget = wrapInCard
        ? Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              color: et.cardSurface,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: et.surfaceBorder.withValues(alpha: 0.7),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Row(
            children: [
              Icon(icon, size: 13, color: et.primaryText),
              const SizedBox(width: AppSpacing.xs),
              Text(
                title.toUpperCase(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: et.primaryText,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        childrenWidget,
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }
}

/// Accordion premium usado apenas no drawer mobile.
///
/// Header acionável (ícone + título + chevron animado) e conteúdo que desce/
/// sobe com `AnimatedSize`. O conteúdo fechado não é renderizado (altura zero
/// real), então só o header fica visível quando colapsado.
class _CollapsibleMenuSection extends StatefulWidget {
  const _CollapsibleMenuSection({
    required this.icon,
    required this.title,
    required this.children,
    this.initiallyExpanded = true,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<_CollapsibleMenuSection> createState() =>
      _CollapsibleMenuSectionState();
}

class _CollapsibleMenuSectionState extends State<_CollapsibleMenuSection> {
  static const _animDuration = Duration(milliseconds: 240);
  static const _animCurve = Curves.easeOutCubic;

  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final et = EanTrackTheme.of(context);

    final header = Semantics(
      button: true,
      expanded: _expanded,
      label: widget.title,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggle,
          borderRadius: AppRadius.mdAll,
          child: AnimatedContainer(
            duration: _animDuration,
            curve: _animCurve,
            constraints: const BoxConstraints(minHeight: 54),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: _expanded
                  ? et.inputFill.withValues(alpha: 0.6)
                  : Colors.transparent,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: _expanded
                    ? et.surfaceBorder.withValues(alpha: 0.7)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(widget.icon, size: 21, color: et.primaryText),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: et.primaryText,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0.0,
                  duration: _animDuration,
                  curve: _animCurve,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: et.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // AnimatedSize anima entre o conteúdo real e uma caixa de altura zero,
    // produzindo a sensação de descida/subida. ClipRect evita vazamento do
    // conteúdo durante a transição.
    final content = ClipRect(
      child: AnimatedSize(
        duration: _animDuration,
        curve: _animCurve,
        alignment: Alignment.topCenter,
        child: _expanded
            ? Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.xs,
                  bottom: AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.children,
                ),
              )
            : const SizedBox(width: double.infinity, height: 0),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, content],
      ),
    );
  }
}
