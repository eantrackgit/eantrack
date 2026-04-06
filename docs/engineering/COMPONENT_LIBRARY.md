# COMPONENT_LIBRARY.md — EANTrack

> Inventário de widgets e utils implementados na arquitetura Flutter puro.
> Para spec visual de cada componente → `/docs/design/DESIGN_SYSTEM.md`
> Para padrões de uso → `/docs/engineering/GLOBAL_PATTERNS.md`

---

## Widgets implementados (`lib/shared/widgets/`)

| Componente | Arquivo | Variantes / Props chave |
|-----------|---------|------------------------|
| `AppButton` | `app_button.dart` | Variantes: `primary`, `outlined`, `social`. Props: `label`, `isLoading`, `onPressed`, `leadingIcon`, `trailingIcon`. Loading via spinner interno no botão — nunca overlay global. |
| `AppTextField` | `app_text_field.dart` | label floating, obscure toggle, validator support, `AppValidators` embutidos |
| `AppCard` | `app_card.dart` | `child`, `color?`, `padding?`, `onTap?`, `selected?`, `borderColor?`. Com ripple quando `onTap` definido. |
| `AppErrorBox` | `app_error_box.dart` | Caixa de erro inline com ícone + texto PT-BR + shake animation. Usar acima do botão primary em formulários. |
| `AppFeedbackDialog` | `app_feedback_dialog.dart` | Modal centralizado de sucesso/erro. Chamar via `showAppFeedbackDialog(context, title, message, icon, accentColor)`. Padrão para feedback crítico. |
| `AuthScaffold` | `auth_scaffold.dart` | Scaffold padrão auth/onboarding: bg `AppColors.secondary`, card centralizado maxWidth 480, scroll seguro. Usar em todas as telas Auth e Onboarding. |
| `PasswordRuleRow` | `password_rule_row.dart` | Row de checklist de senha com animação (ícone + texto colorido). Independente de auth. |
| `AppVersionBadge` | `app_version_badge.dart` | Badge de versão lida de `assets/config/version.json`. Renderizado no rodapé do AuthScaffold. |

---

## Mixins implementados (`lib/shared/mixins/`)

| Mixin | Arquivo | Fornece |
|-------|---------|---------|
| `FormStateMixin<T>` | `form_state_mixin.dart` | `formKey`, `submitted`, `validateAndSubmit()`, validators (email, password, confirm, required), rastreamento força/confirmação de senha em tempo real |

**Uso obrigatório em toda tela com formulário:**
```dart
class _MyScreenState extends ConsumerState<MyScreen>
    with FormStateMixin<MyScreen> {
  // formKey, submitted, emailValidator(), validateAndSubmit() disponíveis
}
```

---

## Utils implementados (`lib/shared/utils/`)

| Util | Arquivo | Fornece |
|------|---------|---------|
| `AsyncAction<T>` | `async_action.dart` | Estado de ação local: `ActionIdle / ActionLoading / ActionSuccess / ActionFailure` + extensão `.isLoading`, `.isFailure`, `.errorMessage` |
| `AsyncValue<T>` | `async_value.dart` | Estado de dados assíncronos: `DataIdle / DataLoading / DataSuccess / DataEmpty / DataFailure` |

**Uso obrigatório para ações locais (botão, submit, reenvio):**
```dart
AsyncAction<void> _action = const ActionIdle();

// No handler:
setState(() => _action = const ActionLoading());
try {
  await doWork();
  setState(() => _action = const ActionSuccess(null));
} catch (e) {
  setState(() => _action = ActionFailure(e.toString()));
}

// No build:
AppButton(isLoading: _action.isLoading, onPressed: _action.isLoading ? null : _submit)
if (_action.isFailure) AppErrorBox(_action.errorMessage!)
```

---

## Import único (barrel)

```dart
import '../../../shared/shared.dart'; // ajustar nível relativo
```

Exporta: tema, widgets, AuthScaffold, AppErrorBox, PasswordRuleRow, FormStateMixin, AsyncAction, AsyncValue, Breakpoints.

---

## Theme tokens (`lib/shared/theme/`)

| Arquivo | Classe | Tokens |
|---------|--------|--------|
| `app_colors.dart` | `AppColors` | Ver [TOKEN_MAPPING.md](../architecture/TOKEN_MAPPING.md) para mapeamento completo |
| `app_text_styles.dart` | `AppTextStyles` | `displayLarge/Medium/Small`, `headlineLarge/Medium/Small`, `titleLarge/Medium/Small`, `labelLarge/Medium/Small`, `bodyLarge/Medium/Small` |
| `app_spacing.dart` | `AppSpacing` + `AppRadius` + `AppShadows` | `AppSpacing.xs/sm/md/lg/xl` · `AppRadius.sm/md/lg/full` + `.smAll/.mdAll/.lgAll` · `AppShadows.sm/md/lg/xl` |
| `app_theme.dart` | `AppTheme` | `ThemeData` builder |

**Nomes reais dos tokens de texto** (usar estes — não h1/h2/h3):

| Para usar como... | Token real |
|-------------------|-----------|
| Título de tela (24px, bold) | `AppTextStyles.headlineSmall` |
| Subtítulo de seção (22px) | `AppTextStyles.titleLarge` |
| Corpo padrão (14px) | `AppTextStyles.bodyMedium` |
| Caption / erro (12px) | `AppTextStyles.bodySmall` |
| Label UI (12px, secondaryText) | `AppTextStyles.labelSmall` |

---

## Layout (`lib/shared/layout/`)

| Arquivo | Classe | Conteúdo |
|---------|--------|----------|
| `breakpoints.dart` | `Breakpoints` | `mobile < 600`, `tablet < 1200`, `isDesktop(context)`, `isMobile(context)` |

---

## Widgets a implementar (Fase 2 — BACKLOG)

| Componente | Task | Arquivo destino | Observação |
|-----------|------|----------------|-----------|
| `AppCard` (extensão) | UI-001 | `app_card.dart` | Adicionar `onTap?`, `selected?`, `borderColor?` ao AppCard existente |
| `AppEmptyState` | UI-002 | `app_empty_state.dart` | |
| `AppSearchBar` | UI-003 | `app_search_bar.dart` | |
| `AppTabBar` | UI-004 | `app_tab_bar.dart` | |
| `AppBottomNav` | UI-006 | `app_bottom_nav.dart` | |
| `AppSidebar` | UI-007 | `app_sidebar.dart` | |
| `AppStatusBadge` | UI-008 | `app_status_badge.dart` | |
