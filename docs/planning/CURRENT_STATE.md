# CURRENT_STATE.md — EANTrack

> **Leia este arquivo primeiro ao retomar o projeto.**
> Atualizar a cada sessão que avança o código.
> Última atualização: 2026-04-25 (agency status web shell, documentos versionados, sidebar desktop, router guard, FlowScreen safety)

---

## Fase Atual

**Fase 1 — Auth** ✅ Completo (telas + dark mode + testes)
**Fase 2 — Onboarding** ✅ Core completo — agency onboarding completo (CNPJ → confirmação → representante → status); documentos versionados com rollback; sidebar desktop; router guard corrigido; pending/rejected permanecem na tela de status; approved exige ação explícita para entrar no hub/configuração
**Fase 3 — Hub + Regiões** 🔄 Funcional (layout + navegação + agencyId guard), sem dark mode, sem testes de UI. **⚠️ HubScreen com dados hardcoded no sidebar — ver Bugs Conhecidos.**
**Fase 4 — Testes** ✅ Auth, Onboarding controller e widget cobertos; Hub/Regiões sem testes de UI

**Próximo objetivo:** Polimento UX (dados reais no sidebar, refinamento visual light/dark, estados loading/error, hierarquia tipográfica, botão voltar status screen) → depois Módulo de Validade

---

## O que está implementado

### Fundação
- `lib/main.dart` ✅ — Sentry inicializado via `SentryFlutter.init`, DSN via `--dart-define=SENTRY_DSN`
- `lib/app/app.dart` ✅ — MaterialApp.router com light/dark theme e `themeModeProvider`
- `lib/core/config/app_config.dart` ✅ — expõe `sentryDsn` via `String.fromEnvironment`
- `lib/core/config/app_version.dart` ✅
- `.github/workflows/build.yml` ✅ — CI pipeline com jobs APK (Android) e Web via secrets do repositório
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
- `lib/shared/utils/async_action.dart` ✅ — `ActionIdle / ActionLoading / ActionSuccess / ActionFailure` + `when()` helper + `withRetry<T>()` (backoff exponencial, 3 tentativas, delay 500ms × attempt)
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
- `lib/features/onboarding/presentation/screens/onboarding_profile_screen.dart` ✅ — dark mode, identifier com sugestões determinísticas (Instagram/Microsoft style), validação em tempo real. Widgets `_ProfileHeader` e `_IdentifierSuggestions` extraídos. **Exceção intencional:** usa `TextFormField` raw por border dinâmico de status + `maxLines`/`buildCounter` customizado — documentado no código e em ARCHITECTURE.md.
- `lib/features/onboarding/presentation/screens/cnpj_screen.dart` ✅ — UI criada
- `lib/features/onboarding/presentation/screens/company_data_screen.dart` ✅ — UI criada
- `lib/features/onboarding/presentation/screens/legal_representative_screen.dart` ✅ — UI criada

### Onboarding — Agency Status + Documentos Versionados

**Modelo de documentos:** insert-only, não-destrutivo, `attempt_number` incremental. Documentação completa: [docs/architecture/LEGAL_DOCUMENTS_VERSIONING.md](../architecture/LEGAL_DOCUMENTS_VERSIONING.md)

**Fluxo atual do web shell/status:**
- `pending` e `rejected` mantêm o usuário em `/onboarding/agency/status`, inclusive após F5/reload ou regressão de status.
- `approved` também permanece na tela de status após reload; não há redirecionamento automático para dashboard.
- Entrada no hub/configuração é explícita: CTA "Iniciar configuração da agência" ou clique em item liberado do MenuHubSidebar.
- Botão "Atualizar status da solicitação" chama `agencyStatusProvider(...).refresh()` e refaz query real nas views; mudança no Supabase reflete na UI sem F5.
- Enquanto status ainda está indefinido/carregando, o router não empurra o usuário para `/flow` vazio.
- Mobile preserva o comportamento de status sem sidebar; sidebar aparece apenas em desktop.

- `lib/features/onboarding/agency/controllers/agency_status_notifier.dart` ✅
  - `AgencyDocumentStatus` — enum: `pending | approved | rejected`
  - `AgencyStatusData` — model rico com `fromJson` defensivo (snake_case + camelCase fallback via `_toCamelCase`), `copyWith`
  - `AgencyStatusState` — `AgencyStatusLoading` enum + `data` + `error`, `copyWith` com sentinel para nullable
  - `AgencyStatusNotifier` — consulta `v_user_agency_onboarding_context` (contexto) + `v_agency_latest_document_status` (status consolidado da última tentativa); suporte a `mockStatus` para debug
  - `agencyStatusProvider` — `StateNotifierProvider.autoDispose.family<..., AgencyDocumentStatus?>` (parâmetro para override de debug)
  - **⚠️ Design gap:** `statusAgency` e `consolidatedDocumentStatus` são populados com o mesmo valor em `fromJson`. `statusAgency` deveria refletir `agencies.status_agency`, mas lê apenas o campo de documento. Ver Bugs Conhecidos.
- `lib/features/onboarding/agency/services/agency_representative_service.dart` ✅
  - `submit()` — INSERT em `legal_representatives` + upload Storage + INSERT em `legal_documents`
  - `_nextAttemptNumber()` — calcula `MAX(attempt_number) + 1` para a agência
  - Storage path: `{agencyId}/{representativeId}/attempt_{n}/front.webp` [+ `back.webp`]
  - Rollback automático em falha parcial (delete apenas do registro recém-criado)
- `lib/features/onboarding/agency/screens/agency_status_screen.dart` ✅
  - Exibe status consolidado da última tentativa (via `v_agency_latest_document_status`)
  - CTA dinâmico por status: approved → "Iniciar configuração da agência" / rejected → reenvio / pending → desabilitado
  - Approved não redireciona automaticamente para dashboard após reload; entrada no hub depende de ação explícita
  - Botão "Atualizar status da solicitação" refaz consulta real via notifier e exibe loading no padrão existente
  - `rejection_reason` exibido apenas quando última tentativa = rejected
  - Reenvio: navega para `AgencyRepresentativeScreen` com `AgencyStatusData` como `prefillData`
  - Dark mode completo via `EanTrackTheme`
  - **⚠️ Mobile:** botão voltar (leading) faz signout sem aviso — UX confuso para usuário em pending
- `lib/features/onboarding/agency/screens/agency_representative_screen.dart` ✅ — aceita `prefillData: AgencyStatusData?` (fluxo de reenvio) além de `payload: AgencyConfirmPayload?` (fluxo inicial)

### Hub — MenuHub Sidebar Desktop

- `lib/features/hub/presentation/widgets/menu_hub_sidebar.dart` ✅
  - Sidebar 280px, dark mode completo, seções: Identidade, Estrutura, Operacional, Planos, Conta
  - `_isBlocked` → `agencyStatus != approved` → itens com `Opacity(0.45)` + `enabled: false`
  - Pending/rejected bloqueiam navegação interna; approved libera os itens previstos
  - Rodapé "Sair da conta" sempre visível
  - Web/desktop: MenuHub vira sidebar em `Breakpoints.isDesktop(context)` no HubScreen e na AgencyStatusScreen
  - Mobile: MenuHub continua como página/experiência mobile; AgencyStatusScreen não exibe sidebar
  - **⚠️ HubScreen passa dados hardcoded** (userName, agencyName, agencyStatus) — ver Bugs Conhecidos

### Splash
- `lib/features/splash/presentation/splash_notifier.dart` ✅ — orquestrador; delega animação para `SplashAnimationController` e conectividade para `SplashConnectivityHandler`
- `lib/features/splash/presentation/splash_animation_controller.dart` ✅
- `lib/features/splash/presentation/splash_connectivity_handler.dart` ✅
- **Roteamento inteligente via RPC:** após animação + conexão OK, chama `get_user_onboarding_route` no Supabase. Resultado mapeia para rota direta sem lógica client-side. Fallback: `/login` em session null ou exception. (DEC-021)

### Hub
- `lib/features/hub/presentation/screens/hub_screen.dart` ✅ — layout responsive (sidebar desktop / bottom nav mobile). **⚠️ Usa `AppColors.*` direto — sem dark mode.**
- `lib/features/flow/presentation/screens/flow_screen.dart` ✅ — tela de decisão de fluxo com proteção contra estado preso: reset pós-redirect para `/flow`, `finally` resiliente em `_resolveOnboardingRouteFromState()` e safety timer de 8s com fallback para login. **⚠️ Cor hardcoded.**

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

| `test/features/onboarding/agency/` | Widget + Unit | Fluxo de agência: CNPJ, confirmação, representante legal, status |

**Sem testes:** `choose_mode_screen`, `cnpj_screen`, `company_data_screen`, `legal_rep_screen`, `hub_screen`, `region_list_screen`, `agency_status_screen`.

---

## Bugs Conhecidos (pré-commit)

| ID | Arquivo | Descrição | Severidade |
|----|---------|-----------|-----------|
| BUG-01 | `hub_screen.dart:78-83` | Sidebar no hub com dados hardcoded (userName, agencyName, agencyHandle, agencyStatus: approved) | Alta — UX quebrada para qualquer usuário real |
| BUG-02 | `agency_status_notifier.dart:86,104` | `statusAgency` e `consolidatedDocumentStatus` populados com o mesmo valor em `fromJson`; `statusAgency` não reflete `agencies.status_agency` | Média — UI exibe dois campos idênticos, inconsistência quando banco divergir |
| BUG-03 | `user_flow_state.dart:49` vs `app_router.dart` | `isOnboardingComplete` ainda usa `agencies.status_agency`, enquanto o web shell protege acesso pelo status documental consolidado quando disponível. | Média — comportamento funcional, mas a fonte de verdade deve ser unificada/documentada antes de escalar |
| BUG-04 | `agency_status_screen.dart:80-85` | Botão voltar no mobile faz signout sem aviso. Usuário em pending que pressiona voltar é deslogado. | Baixa — confuso mas não causa perda de dados |

---

## Pendências reais (próximas ações)

### Dívida técnica imediata — Fase de Polimento
1. **BUG-01 (HubScreen sidebar hardcoded):** Integrar dados reais do auth state (nome, agência, role) no sidebar. Injetar `agencyStatus` real via provider.
2. **BUG-02 (statusAgency = consolidatedDocumentStatus):** Separar os dois campos no `fromJson` — `statusAgency` deve ler `agencies.status_agency` da view `v_user_agency_onboarding_context`, `consolidatedDocumentStatus` continua lendo da view de documentos.
3. **BUG-03 (duas fontes de verdade):** Alinhar `isOnboardingComplete` à mesma fonte usada pelo router para liberação de acesso: documentação aprovada via `v_agency_latest_document_status`.
4. **BUG-04 (botão voltar = signout):** Substituir por navegação ou remover leading no mobile da AgencyStatusScreen quando chegou via onboarding (sem rota para pop).
5. **Dark mode interno:** `hub_screen.dart`, `region_list_screen.dart`, `flow_screen.dart` precisam migrar para `EanTrackTheme.of(context)`
6. **Decomposição de screens longas:** `register_screen.dart` (579 linhas) viola o limite de 200 linhas
7. **Testes:** smoke tests para `agency_status_screen`, hub, sidebar

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
**Pós-agency-status + splash RPC (2026-04-22): não reavaliado** — novo código segue os mesmos padrões.
**Pós-infra (2026-04-23): não reavaliado** — Sentry, withRetry, dark mode agency_status resolvido, CI pipeline adicionado.

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
| `hub_screen.dart` e `region_list_screen.dart` usam `AppColors.*` direto | Médio | Tratar junto na sprint de dark mode interno |

---

## Riscos Abertos

| Risco | Nível | Mitigação |
|-------|-------|-----------|
| `agencyStatusProvider(null)` autoDispose pode estar sem dados no primeiro redirect | Médio | Router evita `/flow` vazio e direciona onboarding autenticado para status; ainda vale considerar provider eager se o shell crescer |
| Duas fontes de verdade para "agência liberada" (`status_agency` operacional vs `consolidated_document_status` documental) | Médio | Tratar como conceitos separados: acesso ao app depende do status documental aprovado; status operacional futuro deve ter semântica própria |
| `admin_review_legal_documents` RPC recebe `p_agency_id` (não `p_document_id`) — pode alterar múltiplas tentativas no banco | Médio | Verificar implementação da RPC no Supabase Dashboard; confirmar que ela altera apenas a última tentativa |
| Arquivos FlutterFlow legados causam erros de análise | Médio | Deletar na Fase Hardening; ignorar até lá |
| Dark mode quebrado em telas internas (hub, regiões) | Médio | Migrar para EanTrackTheme nas próximas sessões |
| Screens longas (911, 579 linhas) dificultam manutenção | Médio | Decompor em widgets privados quando tocar no arquivo |
| RPCs podem ter assinatura diferente do esperado | Baixo | Verificar no Supabase Dashboard antes de integrar |
| Lottie asset `flow_loading.json` pode não existir | Baixo | Verificar em `assets/animations/` antes de rodar |
