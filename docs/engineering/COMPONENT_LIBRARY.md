# COMPONENT_LIBRARY.md — EANTrack

> Inventário de widgets e utils implementados na arquitetura Flutter puro.
> Para spec visual de cada componente → `/docs/design/DESIGN_SYSTEM.md`
> Para padrões de uso → `/docs/engineering/GLOBAL_PATTERNS.md`
> Última atualização: 2026-04-11

---

## Widgets implementados (`lib/shared/widgets/`)

| Componente | Arquivo | Variantes / Props chave |
|-----------|---------|------------------------|
| `AppButton` | `app_button.dart` | Variantes: `primary`, `secondary`/`outlined`, `action`, `social`. Props: `label`, `isLoading`, `onPressed`, `leadingIcon`, `trailingIcon`. Theming via `EanTrackTheme`. Spinner interno — sem overlay global. |
| `AppTextField` | `app_text_field.dart` | Floating label, obscure toggle, validator, theming via `EanTrackTheme`. **Convenção:** `label` sempre preenchido com o nome do campo — nunca `label: ''`. |
| `AppCard` | `app_card.dart` | `child`, `color?`, `padding?`, `onTap?`, `selected?`, `borderColor?`. Ripple via `Material + InkWell` quando `onTap` definido. `color` default context-aware: `et.cardSurface` no dark, `AppColors.primaryBackground` no light. |
| `AppErrorBox` | `app_error_box.dart` | Erro inline com ícone + texto PT-BR + shake animation. Usar acima do botão primary em formulários. |
| `AppFeedbackDialog` | `app_feedback_dialog.dart` | Modal sucesso/erro com blur backdrop. Chamar via `showAppFeedbackDialog(context, ...)` ou `AppFeedback.showSuccess/showError`. Theming via `EanTrackTheme.of(dialogContext)` — dark mode completo. |
| `AppEmptyState` | `app_empty_state.dart` | Estado vazio com ícone, título, subtítulo e ação opcional. |
| `AppListStateView` | `app_list_state_view.dart` | Wrapper para estados de lista: loading (skeleton) / empty (AppEmptyState) / error (AppErrorBox) / loaded (child). |
| `AuthScaffold` | `auth_scaffold.dart` | Scaffold padrão auth/onboarding. Dark mode via `EanTrackTheme`. Parâmetro `action?` para widget no canto superior direito (ex: toggle de tema). maxWidth 480. |
| `PasswordRuleRow` | `password_rule_row.dart` | Checklist de senha animado (ícone + texto colorido). Dark mode compliant: idle usa `et.secondaryText`; satisfied usa `AppColors.success`; unsatisfied usa `AppColors.error`. |
| `AppVersionBadge` | `app_version_badge.dart` | Badge de versão lida de assets. |
| `AppBottomNav` | `app_bottom_nav.dart` | Bottom navigation bar para mobile. |
| `AppSidebar` | `app_sidebar.dart` | Sidebar fixa para desktop (240px). |

### Widgets específicos de feature

| Componente | Arquivo | Descrição |
|-----------|---------|-----------|
| `ResendCooldownButton` | `lib/features/auth/presentation/widgets/resend_cooldown_button.dart` | Botão com countdown integrado. Props: `cooldown`, `isLoading`, `readyLabel`, `lockedLabelBuilder`, `onPressed`. Usar em telas de reenvio (email verify, recover password). |

---

## Mixins implementados (`lib/shared/mixins/`)

| Mixin | Arquivo | Fornece |
|-------|---------|---------|
| `FormStateMixin<T>` | `form_state_mixin.dart` | `formKey`, `submitted`, `validateAndSubmit()`, `emailValidator`, `passwordValidator`, `confirmValidator`, `requiredValidator`, rastreamento força/confirmação de senha em tempo real |

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
| `PasswordValidator` | `password_validator.dart` | Regras de força de senha (mínimo, maiúscula, minúscula) |

**Uso obrigatório para ações locais (botão, submit, reenvio):**
```dart
AsyncAction<void> _action = const ActionIdle();

setState(() => _action = const ActionLoading());
try {
  await doWork();
  setState(() => _action = const ActionSuccess(null));
} catch (e) {
  setState(() => _action = ActionFailure(e.toString()));
}

// No build:
AppButton(isLoading: _action.isLoading, onPressed: _action.isLoading ? null : _submit)
if (_action.isFailure) AppErrorBox(message: _action.errorMessage!)
```

---

## Providers globais (`lib/shared/providers/`)

| Provider | Arquivo | Tipo | Descrição |
|----------|---------|------|-----------|
| `themeModeProvider` | `theme_provider.dart` | `StateProvider<ThemeMode>` | Toggle light/dark. Default: `ThemeMode.light`. Consumido por `app.dart`. |

---

## Import único (barrel)

```dart
import '../../../shared/shared.dart'; // ajustar nível relativo
```

Exporta: tema, `EanTrackTheme`, widgets, `AuthScaffold`, `AppErrorBox`, `PasswordRuleRow`, `FormStateMixin`, `AsyncAction`, `AsyncValue`, `Breakpoints`, `themeModeProvider`.

---

## Theme tokens (`lib/shared/theme/`)

| Arquivo | Classe | Uso |
|---------|--------|-----|
| `app_colors.dart` | `AppColors` | Tokens primitivos de cor — usar para acentos fixos (error, success, actionBlue). Para cores context-aware (light vs dark) → usar `EanTrackTheme`. |
| `app_text_styles.dart` | `AppTextStyles` | Tipografia — sempre com `.copyWith(color: et.primaryText)` para respeitar o tema |
| `app_spacing.dart` | `AppSpacing` + `AppRadius` + `AppShadows` | `AppSpacing.xs/sm/md/lg/xl` · `AppRadius.smAll/.mdAll/.lgAll` · `AppShadows.*` |
| `app_theme.dart` | `EanTrackTheme` + `AppTheme` | `EanTrackTheme.of(context)` para tokens semânticos. `AppTheme.light()` / `AppTheme.dark()` para ThemeData. |

**Tokens de texto (nomes reais — não usar h1/h2/buttonText):**

| Para usar como... | Token real |
|-------------------|-----------|
| Título de tela (24px) | `AppTextStyles.headlineSmall` |
| Subtítulo de seção (22px) | `AppTextStyles.titleLarge` |
| Corpo padrão (14px) | `AppTextStyles.bodyMedium` |
| Caption / erro (12px) | `AppTextStyles.bodySmall` |
| Label UI (12px) | `AppTextStyles.labelSmall` |
| Botão (16px, semi-bold) | `AppTextStyles.titleSmall` |

**Regra de ouro para cores:**
- Cor fixa (sempre igual em light e dark) → `AppColors.*`
- Cor semântica (muda entre temas) → `EanTrackTheme.of(context).*`

---

## Layout (`lib/shared/layout/`)

| Arquivo | Classe | Conteúdo |
|---------|--------|----------|
| `breakpoints.dart` | `Breakpoints` | `mobile < 600`, `tablet < 1200`, `isDesktop(context)`, `isMobile(context)` |

---

## Widgets a implementar (Fase futura)

| Componente | Arquivo destino | Observação |
|-----------|----------------|-----------|
| `AppSearchBar` | `app_search_bar.dart` | Campo de busca com debounce |
| `AppTabBar` | `app_tab_bar.dart` | Tabs internas |
| `AppStatusBadge` | `app_status_badge.dart` | active/inactive/pending/approved/rejected |
| `AppDatePicker` | `app_date_picker.dart` | Seleção de data contextual |
