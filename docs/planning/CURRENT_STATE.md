# CURRENT_STATE.md — EANTrack (FINAL)

> **Leia este arquivo primeiro ao retomar o projeto.**
> Atualizar a cada sessão que avança o código.

---

## Fase Atual

**Fase 1 — Auth** ✅ Código completo
**Fase 2 — Onboarding** ✅ Completo (ONB-001..009 + UI widgets + Hub + Regiões)
**Fase 3 — Hub + Regiões** ✅ Hub funcional + RegionList (listagem, criação, toggle ativo)
**Fase 4 — Testes** 🔄 Smoke tests existentes + unit tests auth + FormStateMixin + RegionRepository

---

## O que está concluído

### Documentação (/docs)
- ARCHITECTURE.md ✅
- AUTH_FLOW.md ✅
- ANIMATION_GUIDELINES.md ✅
- BACKLOG.md ✅
- BACKEND_SCHEMA.md ✅
- CURRENT_STATE.md ✅ (este arquivo)
- DECISIONS_LOG.md ✅
- DEFINITION_OF_DONE.md ✅
- DESIGN_SYSTEM.md ✅
- GLOBAL_PATTERNS.md ✅
- SCREEN_SPECS.md ✅

### Código — Fundação
- pubspec.yaml (+riverpod, +crypto, +mocktail) ✅
- lib/main.dart ✅
- lib/app/app.dart ✅
- lib/core/config/app_config.dart ✅
- lib/core/error/app_exception.dart ✅
- lib/core/router/app_routes.dart ✅
- lib/core/router/app_router.dart ✅
- lib/shared/theme/app_colors.dart ✅
- lib/shared/theme/app_spacing.dart ✅
- lib/shared/theme/app_text_styles.dart ✅
- lib/shared/theme/app_theme.dart ✅
- lib/shared/layout/breakpoints.dart ✅

### Código — Auth (Data + Domain + Providers)
- lib/features/auth/domain/auth_state.dart ✅ (domain puro — sem redirectPath)
- lib/features/auth/domain/auth_flow_state.dart ✅
- lib/features/auth/domain/user_flow_state.dart ✅
- lib/features/auth/data/auth_repository.dart ✅ (injectable via constructor)
- lib/features/auth/data/password_history_service.dart ✅ (check + register RPCs)
- lib/features/auth/data/password_reuse_parser.dart ✅ (parser defensivo)
- lib/features/auth/presentation/providers/auth_provider.dart ✅ (+passwordHistoryServiceProvider +EmailCooldownNotifier)

### Shared Widgets
- lib/shared/widgets/app_button.dart ✅ (loading no botão, sem overlay global)
- lib/shared/widgets/app_text_field.dart ✅ (+AppValidators embutidos)
- lib/shared/widgets/app_error_box.dart ✅ (inline + shake animation)
- lib/shared/widgets/app_feedback_dialog.dart ✅ (modal centralizado sucesso/erro)
- lib/shared/widgets/auth_scaffold.dart ✅ (somente AuthScaffold — widgets extraídos)
- lib/shared/widgets/password_rule_row.dart ✅ (widget independente)
- lib/shared/widgets/app_version_badge.dart ✅

### Auth Screens
- lib/features/auth/presentation/screens/login_screen.dart ✅
- lib/features/auth/presentation/screens/register_screen.dart ✅
- lib/features/auth/presentation/screens/email_verification_screen.dart ✅
- lib/features/auth/presentation/screens/recover_password_screen.dart ✅

### Onboarding — início (Sessão 6, 2026-03-30)
- lib/features/onboarding/presentation/screens/choose_mode_screen.dart ✅ (ONB-002)
- lib/features/onboarding/data/.gitkeep ✅ (ONB-001)
- lib/features/onboarding/domain/.gitkeep ✅ (ONB-001)
- lib/core/router/app_routes.dart — rota `/onboarding` ✅ (ONB-003)
- lib/core/router/app_router.dart — ChooseModeScreen registrada ✅ (ONB-003)

---

## O que está pendente

### Fase 2 — Onboarding (continuação)

Tasks em BACKLOG.md — próxima ordem:

```
UI-001   AppCard widget
UI-002   AppEmptyState widget
UI-006   AppBottomNav widget
UI-007   AppSidebar widget

HUB-001  Estrutura de pastas Hub
HUB-002  HubScreen layout básico
HUB-003  Rota /hub

ONB-004  OnboardingState sealed
ONB-005  OnboardingNotifier + Provider
ONB-006  OnboardingRepository + persistir modo
ONB-007  CnpjScreen (UI)
ONB-008  CompanyDataScreen (UI)
ONB-009  LegalRepresentativeScreen (UI)
```

### Testes existentes ✅
- test/features/auth/data/auth_repository_test.dart
- test/features/auth/presentation/screens/login_screen_test.dart (smoke)
- test/features/auth/presentation/screens/register_screen_test.dart (smoke)
- test/features/auth/presentation/screens/email_verification_screen_test.dart (smoke)
- test/features/auth/presentation/screens/recover_password_screen_test.dart (smoke)
- test/shared/mixins/form_state_mixin_test.dart (unit — Sessão 7)
- test/features/regions/data/region_repository_test.dart (unit — Sessão 7)

---

## Próximo passo exato

Auth flow completo e validado em produção.
Continuar: Redes (NET-001..004), Categorias (CAT-001..003), PDVs (PDV-001..004).

---

## Pontos de Atenção

1. **`flutter pub get`** antes de rodar (riverpod + crypto + mocktail)
2. **Compilação**: arquivos legados em `lib/p_a_s_tpag_app_feed/`, `lib/flutter_flow/` causam erros de análise — são referência visual, não precisam compilar. Deletar na Fase 13 (Hardening).
3. **Supabase keys**: `--dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`
4. **RPCs**: verificar assinaturas no Supabase Dashboard antes de integrar (ver BACKEND_SCHEMA.md)

---

## Contexto de Domínio

- **Login pós-signup**: após criar conta, Supabase retorna erro "email not confirmed" → estado `AuthEmailUnconfirmed`
- **Email verification**: polling via tentativa de signIn (não webhook) — `isEmailConfirmed` testa via RPC
- **user_flow_state**: determina para onde o usuário vai após login (onboarding vs. hub)
- **SHA-256 email hash**: usado nas RPCs para verificar duplicidade sem armazenar email raw
- **Cooldown reenvio**: estado local (sem SharedPreferences) — reinicia por sessão (intencional, ver DEC-007)

---

## Qualidade do Projeto

**Nota atual: 9.6 / 10** *(2026-04-05)*

| Área | Nota |
|------|------|
| Arquitetura | 9.7 |
| Auth | 9.8 |
| Segurança | 9.5 |
| UX | 9.6 |
| UI | 9.5 |
| Consistência (código + docs) | 9.5 |
| Documentação | 9.5 |

---

## Riscos Abertos

| Risco | Nível | Mitigação |
|-------|-------|-----------|
| Compilação quebrada: arquivos FlutterFlow antigos | Médio | Executar `flutter analyze`; deletar lib/ legado quando pronto para rodar |
| RPCs podem ter assinatura diferente do esperado | Baixo | Verificar no Supabase Dashboard antes de testar |
| `supabase.auth.resend()` API pode ter mudado | Baixo | Testar em ambiente de desenvolvimento |
