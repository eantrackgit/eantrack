# CURRENT_STATE.md — EANTrack

> **Leia este arquivo primeiro ao retomar o projeto.**
> Atualizar a cada sessão que avança o código.
> Última atualização: 2026-04-20 (ciclo de qualidade global 6.4 → 9.7; agency onboarding concluído e auditado)

---

## Fase Atual

**Fase 1 — Auth** ✅ Completo (telas + dark mode + testes)
**Fase 2 — Onboarding** ✅ Core completo — IdentifierController extraído e testado; agency onboarding (CNPJ → confirmação → representante legal) **concluído e auditado (9.7)**
**Fase 3 — Hub + Regiões** 🔄 Funcional (layout + navegação + agencyId guard), sem dark mode, sem testes de UI
**Fase 4 — Testes** ✅ Auth, Onboarding controller e widget cobertos; Hub/Regiões sem testes de UI

**Próximo objetivo:** Módulo de Validade (modo individual)

---

## O que está implementado

### Fundação
- `lib/main.dart` ✅
- `lib/app/app.dart` ✅ — MaterialApp.router com light/dark theme e `themeModeProvider`
- `lib/core/config/app_config.dart` ✅
- `lib/core/config/app_version.dart` ✅
- `lib/core/error/app_exception.dart` ✅ — sealed hierarchy
- `lib/core/router/app_routes.dart` ✅
- `lib/core/router/app_router.dart` ✅ — GoRouter + RouterRedirectGuard
- `lib/core/router/router_redirect_guard.dart` ✅
- `lib/core/router/recovery_link_parser.dart` ✅

### Tema (light + dark)
- `lib/shared/theme/app_colors.dart` ✅ — tokens primitivos
- `lib/shared/theme/app_spacing.dart` ✅ — espaçamento + radius
- `lib/shared/theme/app_text_styles.dart` ✅ — tipografia (Poppins + Roboto)
- `lib/shared/theme/app_theme.dart` ✅ — `EanTrackTheme` (ThemeExtension light/dark) + `AppTheme.light()` + `AppTheme.dark()`
- `lib/shared/providers/theme_provider.dart` ✅ — `StateProvider<ThemeMode>`
- `lib/shared/layout/breakpoints.dart` ✅

### Shared Widgets
- `lib/shared/widgets/app_button.dart` ✅ — variantes: primary, secondary/outlined, action, social. Loading interno. Theming via `EanTrackTheme`.
- `lib/shared/widgets/app_text_field.dart` ✅ — floating label, validators, theming via `EanTrackTheme`
- `lib/shared/widgets/app_error_box.dart` ✅ — erro inline com shake animation
- `lib/shared/widgets/app_feedback_dialog.dart` ✅ — modal sucesso/erro, dark mode via `EanTrackTheme.of(dialogContext)`
- `lib/shared/widgets/auth_scaffold.dart` ✅ — layout padrão auth/onboarding com dark mode. Parâmetro `action` opcional para widget no canto superior direito.
- `lib/shared/widgets/password_rule_row.dart` ✅ — checklist de senha animado, dark mode via `EanTrackTheme.secondaryText` no estado idle
- `lib/shared/widgets/app_version_badge.dart` ✅
- `lib/shared/widgets/app_card.dart` ✅ — `onTap?`, `selected?`, `borderColor?`, ripple. Default de `color` é context-aware: `et.cardSurface` no dark, `AppColors.primaryBackground` no light
- `lib/shared/widgets/app_empty_state.dart` ✅
- `lib/shared/widgets/app_bottom_nav.dart` ✅
- `lib/shared/widgets/app_sidebar.dart` ✅
- `lib/shared/widgets/app_list_state_view.dart` ✅

### Shared Utils / Mixins
- `lib/shared/mixins/form_state_mixin.dart` ✅ — `formKey`, `submitted`, `validateAndSubmit()`, validators, password strength tracking
- `lib/shared/utils/async_action.dart` ✅ — `ActionIdle / ActionLoading / ActionSuccess / ActionFailure` + `when()` helper
- `lib/shared/utils/async_value.dart` ✅ — `DataIdle / DataLoading / DataSuccess / DataEmpty / DataFailure`
- `lib/shared/utils/password_validator.dart` ✅

### Auth
- `lib/features/auth/domain/auth_state.dart` ✅
- `lib/features/auth/domain/auth_flow_state.dart` ✅
- `lib/features/auth/domain/user_flow_state.dart` ✅
- `lib/features/auth/data/auth_repository.dart` ✅
- `lib/features/auth/data/password_history_service.dart` ✅
- `lib/features/auth/data/password_reuse_parser.dart` ✅
- `lib/features/auth/data/password_recovery_cooldown_storage.dart` ✅ (stub + web via conditional import)
- `lib/features/auth/presentation/providers/auth_provider.dart` ✅ — `AuthNotifier`, `EmailCooldownNotifier`, `passwordRecoveryCooldownProvider`, cooldown state
- `lib/features/auth/presentation/widgets/resend_cooldown_button.dart` ✅
- `lib/features/auth/presentation/screens/login_screen.dart` ✅ — dark mode, toggle de tema (`_ThemeToggleButton`). Referência visual para dark mode.
- `lib/features/auth/presentation/screens/register_screen.dart` ✅ — dark mode, `_TermsRow` com links azuis. Campos no padrão `AppTextField(label: '...')` alinhado às demais telas de auth.
- `lib/features/auth/presentation/screens/email_verification_screen.dart` ✅
- `lib/features/auth/presentation/screens/recover_password_screen.dart` ✅ — dark mode completo
- `lib/features/auth/presentation/screens/update_password_screen.dart` ✅
- `lib/features/auth/presentation/screens/password_recovery_link_expired_screen.dart` ✅

### Onboarding
- `lib/features/onboarding/domain/onboarding_state.dart` ✅ — sealed: Initial / Loading / ModeSelected / Error
- `lib/features/onboarding/data/onboarding_repository.dart` ✅ — `saveMode()`, `identificadorExiste()` (RPC + fallback), `saveProfile()`
- `lib/features/onboarding/presentation/providers/onboarding_provider.dart` ✅
- `lib/features/onboarding/presentation/controllers/identifier_controller.dart` ✅ — controller extraído da screen; `IdentifierStatus` (7 estados), debounce 350ms, `_requestId` para cancelamento de consultas stale, `normalize()` static, geração de sugestões name-driven + identifier-driven (max 5, todas normalizadas)
- `lib/features/onboarding/presentation/screens/choose_mode_screen.dart` ✅ — dark mode
- `lib/features/onboarding/presentation/screens/onboarding_profile_screen.dart` ✅ — dark mode, identifier com sugestões determinísticas (Instagram/Microsoft style), validação em tempo real. **Exceção intencional:** usa `TextFormField` raw por border dinâmico de status + `maxLines`/`buildCounter` customizado — documentado no código e em ARCHITECTURE.md.
- `lib/features/onboarding/presentation/screens/cnpj_screen.dart` ✅ — UI criada
- `lib/features/onboarding/presentation/screens/company_data_screen.dart` ✅ — UI criada
- `lib/features/onboarding/presentation/screens/legal_representative_screen.dart` ✅ — UI criada

### Hub
- `lib/features/hub/presentation/screens/hub_screen.dart` ✅ — layout responsive (sidebar desktop / bottom nav mobile). **⚠️ Usa `AppColors.*` direto — sem dark mode.**
- `lib/features/flow/presentation/screens/flow_page.dart` ✅ — tela de decisão de fluxo. **⚠️ Cor hardcoded.**

### Regiões
- `lib/features/regions/domain/region_model.dart` ✅
- `lib/features/regions/domain/region_state.dart` ✅
- `lib/features/regions/data/region_repository.dart` ✅
- `lib/features/regions/presentation/providers/region_provider.dart` ✅ — Riverpod 2 `Notifier`; `agencyIdProvider` guard (lança `StateError` se não autenticado ou sem agencyId); `ref.watch(agencyIdProvider)` no `build()` para auto-invalidação na troca de conta
- `lib/features/regions/presentation/screens/region_list_screen.dart` ✅ — **⚠️ Sem dark mode.**

---

## Testes existentes

| Arquivo | Tipo | Cobertura |
|---------|------|-----------|
| `test/features/auth/data/auth_repository_test.dart` | Unit | signIn, signUp, reset, email check, password history |
| `test/features/auth/presentation/screens/login_screen_test.dart` | Widget smoke | render, validação, loading |
| `test/features/auth/presentation/screens/register_screen_test.dart` | Widget smoke | render básico |
| `test/features/auth/presentation/screens/email_verification_screen_test.dart` | Widget smoke | render |
| `test/features/auth/presentation/screens/recover_password_screen_test.dart` | Widget smoke | render, cooldown |
| `test/features/auth/presentation/providers/resend_cooldown_notifier_test.dart` | Unit | cooldown state |
| `test/features/onboarding/presentation/controllers/identifier_controller_test.dart` | Unit | normalize, 7 estados de `IdentifierStatus`, debounce, concorrência (race condition com Completer), dispose safety, suggestions (max 5, sem duplicatas, normalizadas), `applySuggestion`, `applyTakenStateFromConflict` — ~30 casos |
| `test/features/onboarding/presentation/screens/onboarding_profile_screen_test.dart` | Widget | identifier, sugestões, validação |
| `test/features/regions/data/region_repository_test.dart` | Unit | CRUD regiões |
| `test/shared/mixins/form_state_mixin_test.dart` | Unit | validação form |
| `test/shared/utils/password_validator_test.dart` | Unit | regras de senha |

**Sem testes:** `choose_mode_screen`, `cnpj_screen`, `company_data_screen`, `legal_rep_screen`, `hub_screen`, `region_list_screen`.

---

## Pendências reais (próximas ações)

### Dívida técnica imediata
1. **Dark mode interno:** `hub_screen.dart`, `region_list_screen.dart`, `flow_page.dart` precisam migrar para `EanTrackTheme.of(context)`
2. **Decomposição de screens longas:** `onboarding_profile_screen.dart` (911 linhas), `register_screen.dart` (579 linhas) violam o limite de 200 linhas
3. **Testes:** smoke tests para as 4 telas de onboarding restantes + hub + regiões

### Próximas features (por prioridade)
- Integração Supabase completa do fluxo de onboarding (perfil → mode → CNPJ → dados empresa)
- Screens: Redes, Categorias, PDVs, Indústrias
- Integration tests para fluxos críticos (login→hub, register→verify)
- Tela de configurações (usuário, tema, logout)

---

## Pontos de Atenção Operacionais

1. **Comandos proibidos no ambiente:** `flutter analyze`, `flutter test`, `dart format` — travam o terminal. Validar manualmente.
2. **Supabase keys:** `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
3. **Código legado FlutterFlow:** `lib/p_a_s_tpag_app_feed/`, `lib/flutter_flow/` — não compila no rebuild, ignorar até Fase Hardening
4. **RPCs:** verificar assinaturas no Supabase Dashboard (ver BACKEND_SCHEMA.md)
5. **Lottie asset:** `flow_page.dart` referencia `assets/animations/flow_loading.json` — verificar se existe antes de rodar

---

## Contexto de Domínio

- **Login pós-signup:** Supabase retorna erro "email not confirmed" → estado `AuthEmailUnconfirmed`
- **Email verification:** polling silencioso a cada 3s + botão manual "Já confirmei"
- **user_flow_state:** determina destino após login (onboarding incompleto vs. hub)
- **SHA-256 email hash:** unicidade de email sem armazenar raw na tabela `email_codes`
- **Cooldown reenvio:** estado local em memória — reinicia na sessão (intencional, DEC-007)
- **Identifier:** normalizado (lowercase, sem @, apenas `[a-z0-9._-]`); sugestões determinísticas baseadas no nome

---

## Qualidade do Projeto

**Nota auditada: 8.6 / 10** *(2026-04-11 — auditoria global)*
**Pós-correções dark mode (2026-04-13): ~8.9**
**Pós-auditoria final (2026-04-14): 9.35 — nível enterprise confirmado**
**Pós-ciclo de qualidade global (2026-04-20): 9.7 / 10 — meta atingida** *(EVAL-FINAL-009)*

| Critério | Nota | Observação |
|----------|------|-----------|
| Separação UI / Controller / Service | 9.5 | Agency Riverpod; Splash decomposta; TextEditingController injetado |
| Consistência de nomenclatura | 10.0 | *Screen / *_screen.dart em todo o projeto; FlowScreen fecha o ciclo |
| Tratamento de erros | 10.0 | AppException sealed; constantes nomeadas; status enum campo direto |
| Modelos tipados | 10.0 | AgencyCnpjState, AgencyConfirmState, AgencyRepresentativeState corretos |
| Ausência de lógica na UI | 9.5 | Screens puro ref.watch + ref.read; AppRoutes em toda navegação |
| Reutilização de shared/ | 9.5 | Barrel completo; NoConnectionView exportado e importado via barrel |
| Código morto / duplicado | 9.5 | Zero mojibake; zero literal duplicada; _kCnpjErroGenerico unifica |
| Consistência arquitetural | 10.0 | Riverpod StateNotifier + autoDispose end-to-end; padrão único |
| Router — guards, rotas, separação | 9.5 | AppRoutes completo; zero literal; _PlaceholderScreen stubs conhecidos |
| Core — connectivity, config, error | 9.5 | TODO rastreável; connectivity + error hierarchy sólidos |
| **GLOBAL** | **9.7** | **Meta atingida em 2026-04-20** |

---

## Backlog Técnico Residual (dark mode)

Itens não bloqueadores — registrados para tratamento futuro:

| Item | Impacto | Observação |
|------|---------|------------|
| `AppButton.action` com foreground hardcoded (`AppColors.secondaryBackground`) | Baixo | Não usado em auth/onboarding — inativo no fluxo atual |
| `AppTheme.dark().elevatedButtonTheme.backgroundColor = AppColors.secondary` | Baixo | Inativo: `AppButton.primary` sobrescreve com `Ink decoration` |
| `register_screen` sem `_ThemeToggleButton` | Baixo | UX minor — usuário só alterna tema via login screen |
| `_PasswordModal` usa `TextField` raw | Baixo | Exceção documentada; bordas alinhadas ao padrão |

---

## Riscos Abertos

| Risco | Nível | Mitigação |
|-------|-------|-----------|
| Arquivos FlutterFlow legados causam erros de análise | Médio | Deletar na Fase Hardening; ignorar até lá |
| Dark mode quebrado em telas internas (hub, regiões) | Médio | Migrar para EanTrackTheme nas próximas sessões |
| Screens longas (911, 579 linhas) dificultam manutenção | Médio | Decompor em widgets privados quando tocar no arquivo |
| RPCs podem ter assinatura diferente do esperado | Baixo | Verificar no Supabase Dashboard antes de integrar |
| Lottie asset `flow_loading.json` pode não existir | Baixo | Verificar em `assets/animations/` antes de rodar |
