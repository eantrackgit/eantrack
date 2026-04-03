# EANTrack - Build Log

> Registro cronologico do que foi construido, alterado e validado.

---

## 2026-04-01 - Sessão 7: Hardening Enterprise — 7.2 → 9.2

### Fase 1 — Correções de Base
- [x] lib/shared/widgets/app_button.dart — fix: secondary=outlined (era idêntico a primary); +named constructors: .primary()/.secondary()/.outlined()/.action()/.social()
- [x] lib/shared/widgets/app_card.dart — add: onTap?, selected?, borderColor?; InkWell+Material quando tappable
- [x] lib/shared/widgets/app_empty_state.dart — NOVO: widget UI-002
- [x] lib/shared/widgets/app_bottom_nav.dart — NOVO: widget UI-006
- [x] lib/shared/widgets/app_sidebar.dart — NOVO: widget UI-007 (240px, secondary bg, selectedItem highlight)
- [x] lib/shared/shared.dart — exporta novos widgets

### Fase 2 — Hub Funcional
- [x] lib/features/hub/presentation/screens/hub_screen.dart — NOVO: layout responsivo (sidebar desktop / BottomNav mobile), grid de 6 módulos
- [x] lib/core/router/app_router.dart — /hub → HubScreen; /flow → redirect /hub
- [x] lib/features/onboarding/presentation/screens/choose_mode_screen.dart — individual → AppRoutes.hub (era .flow)

### Fase 3 — Feature Real: Regiões
- [x] lib/features/regions/domain/region_model.dart — RegionModel.fromRpc()
- [x] lib/features/regions/domain/region_state.dart — sealed: Initial/Loading/Loaded/Error
- [x] lib/features/regions/data/region_repository.dart — fetchRegions, isNameAvailable, createRegion, toggleActive
- [x] lib/features/regions/presentation/providers/region_provider.dart — RegionNotifier + agencyIdProvider
- [x] lib/features/regions/presentation/screens/region_list_screen.dart — CRUD completo: list/search/tab-filter/create-dialog/toggle-active
- [x] lib/core/router/app_router.dart — /hub/regions → RegionListScreen

### Fase 4 — Testes
- [x] test/shared/mixins/form_state_mixin_test.dart — NOVO: 10 testes unitários
- [x] test/features/regions/data/region_repository_test.dart — NOVO: 9 testes unitários

### Fase 5 — Onboarding Completo
- [x] lib/features/onboarding/domain/onboarding_state.dart — sealed: Initial/Loading/ModeSelected/Error
- [x] lib/features/onboarding/data/onboarding_repository.dart — saveMode()
- [x] lib/features/onboarding/presentation/providers/onboarding_provider.dart — OnboardingNotifier
- [x] lib/features/onboarding/presentation/screens/cnpj_screen.dart — UI com máscara CNPJ + consulta placeholder + checkbox
- [x] lib/features/onboarding/presentation/screens/company_data_screen.dart — dados mock pré-preenchidos
- [x] lib/features/onboarding/presentation/screens/legal_representative_screen.dart — formulário CPF/RG/Nasc/Órgão + FormStateMixin + upload placeholder
- [x] lib/core/router/app_router.dart — /onboarding/cnpj, /onboarding/agency, /onboarding/legal-rep registradas

### Corrigido — Documentação
- [x] docs/engineering/COMPONENT_LIBRARY.md — documentados padrões reais (AuthScaffold, FormStateMixin, AsyncAction)
- [x] docs/planning/AGENTS.md — padrão de tela com AuthScaffold + FormStateMixin
- [x] docs/design/DESIGN_SYSTEM.md — TOKEN_MAPPING table
- [x] docs/planning/BACKLOG.md — tokens corrigidos em UI-001..008, HUB-002

### Pendente
- [ ] flutter analyze (validar compilação)
- [ ] Verificar assinatura `list_regions_by_agency_exhibition` no Supabase Dashboard
- [ ] Integração real onboarding CNPJ com API externa
- [ ] Redes, Categorias, PDVs

---

## 2026-04-01 - Sessão 7: Hardening Enterprise — Auditoria código vs docs

### Analisado
- lib/shared/shared.dart — barrel export completo
- lib/shared/widgets/auth_scaffold.dart — AuthScaffold + AppErrorBox + PasswordRuleRow implementados
- lib/shared/mixins/form_state_mixin.dart — FormStateMixin implementado
- lib/shared/utils/async_action.dart — AsyncAction<T> sealed implementado
- lib/shared/widgets/app_card.dart — AppCard existente (simpler than spec)
- lib/shared/theme/app_colors.dart — tokens reais vs nomes de spec
- lib/shared/theme/app_text_styles.dart — nomes reais vs h1/h2/h3 da spec
- lib/shared/theme/app_spacing.dart — AppRadius.smAll/mdAll/lgAll confirmados
- lib/features/onboarding/presentation/screens/choose_mode_screen.dart — implementação real (superior à spec)
- lib/features/auth/presentation/screens/email_verification_screen.dart — polling ATIVO via Stream.periodic(3s)
- lib/features/auth/presentation/screens/login_screen.dart — usa FormStateMixin + AsyncAction + AuthScaffold

### Bugs descobertos
- AppButton: `.primary` e `.secondary` têm estilo idêntico (mesmo bg navy, mesmo fg white) — registrado em COMPONENT_LIBRARY.md

### Corrigido — Documentação
- [x] docs/engineering/COMPONENT_LIBRARY.md — removida afirmação falsa "não usa AuthScaffold/FormStateMixin/AsyncAction"; documentados como implementados
- [x] docs/planning/AGENTS.md — substituído padrão de tela com AppColors.bgPrimary (inexistente) pelo padrão real com AuthScaffold + FormStateMixin
- [x] docs/design/DESIGN_SYSTEM.md — adicionada tabela TOKEN_MAPPING (nomes de spec → tokens reais AppColors/AppTextStyles)
- [x] docs/planning/BACKLOG.md — corrigidos tokens inexistentes em UI-001/002/003/004/006/007/008 e HUB-002

### Pendente
- [ ] Fix AppButton: diferenciar primary (navy) vs secondary (outlined ou ghost)
- [ ] Auth tests (adiados — DEC-010)

---

## 2026-03-30 - Sessao 6: Onboarding TASK-001 - Escolha do modo operacional

### Criado
- [x] lib/features/onboarding/presentation/screens/choose_mode_screen.dart - tela inicial real do onboarding
- [x] lib/features/onboarding/data/.gitkeep
- [x] lib/features/onboarding/domain/.gitkeep

### Alterado
- [x] lib/core/router/app_routes.dart - adicionada rota base `/onboarding`
- [x] lib/core/router/app_router.dart - `ChooseModeScreen` registrada no router
- [x] lib/features/auth/domain/auth_state.dart - redirect pos-auth atualizado para `/onboarding`

### Testado
- [ ] `dart format` nos arquivos alterados
- [ ] `flutter analyze` focado nas rotas e tela de onboarding

### Pendente
- [ ] TASK-002 - tela de CNPJ da agencia
- [ ] Persistencia de `mode` e `current_step` em `user_flow_state`

---

## 2026-03-29 - Sessao 5: Consolidacao Auth + Transicao para Arquiteto

### Criado
- [x] STATUS_PROJETO_PTBR.md - estado do projeto em PT-BR para leitura rapida
- [x] CODEX_TASK.md - prompt de tarefa para Codex executar testes Auth

### Atualizado
- [x] DECISIONS_LOG.md - DEC-016 (divisao Claude/Codex) + DEC-017 (testes delegados)
- [x] CURRENT_STATE.md - fase 1 code-complete, proximo passo definido
- [x] BUILD_LOG.md - este entry

### Decisao de papel
- Claude assume papel de Arquiteto (decisao, revisao, definicao de tarefas)
- Codex assume papel de Executor (implementacao, testes, repeticao)

---

## 2026-03-29 - Sessao 4: RecoverPasswordScreen + EmailVerificationScreen

### Criado / Alterado
- [x] lib/features/auth/presentation/screens/email_verification_screen.dart - implementacao real completa
- [x] lib/features/auth/presentation/screens/recover_password_screen.dart - implementacao real completa

### Comportamento implementado - EmailVerificationScreen
- Stream.periodic(3s) polling -> `checkEmailConfirmed()` -> `_confirmed = true` -> delay 4s -> `_navigate()`
- `_navigating` guard previne navegacao dupla
- AnimatedSwitcher: SVG logo <-> Lottie Success_(1).json
- E-mail censurado (`jo**@gmail.com`) via `_censor()`
- Resend com cooldown: `emailCooldownProvider`, Timer.periodic(1s) para countdown display
- Volta para login via `context.go(AppRoutes.login)`

### Comportamento implementado - RecoverPasswordScreen
- Form com AppTextField email + AppValidators.email
- `authNotifier.resetPassword(email)` no submit
- Loading state via AppLoadingOverlay
- Sucesso: `AuthUnauthenticated` via ref.listen -> snackbar confirmacao -> `context.go(AppRoutes.login)`
- Erro: `AuthError` via ref.listen -> snackbar de erro
- Layout: botoes em Row (Voltar 135px outlined + Enviar expanded primary)
- `_submitted` flag para distinguir "sucesso pos-reset" de mount normal

---

## 2026-03-29 - Sessao 3: RegisterScreen

### Criado / Alterado
- [x] lib/features/auth/data/auth_repository.dart - `checkEmailAvailable()` (SHA-256 + RPC)
- [x] lib/features/auth/presentation/screens/register_screen.dart - implementacao real completa

### Comportamento implementado
- Debounce 2s no email -> `checkEmailAvailable()` -> hint visual (idle/checking/available/taken)
- Password strength em tempo real: 3 indicadores (min 8, maiuscula, minuscula)
- Termos obrigatorios com erro inline
- Erros de submissao via `ref.listen` -> `_submissionError` local
- Pos-cadastro: `AuthEmailUnconfirmed` -> navega para `/email-verification`

---

## 2026-03-29 - Sessao 2: CODE_RULES + Shared Widgets + Login Screen

### Criado
- [x] CODE_RULES.md - regras obrigatorias de codigo limpo, seguranca e organizacao
- [x] lib/shared/widgets/app_button.dart - primary/secondary/outlined + loading/disabled
- [x] lib/shared/widgets/app_text_field.dart - com AppValidators
- [x] lib/shared/widgets/app_loading_overlay.dart - Lottie overlay + AppLoadingIndicator standalone
- [x] lib/features/auth/presentation/screens/login_screen.dart - implementacao real

### Fluxo Auth - comportamento validado
- Sessao persistente: `authUserStreamProvider` (Supabase stream) -> GoRouter redirect automatico
- Login bem-sucedido: `AuthAuthenticated` -> `context.go(redirectPath)` via `ref.listen`
- Email nao confirmado: `AuthEmailUnconfirmed` -> `context.go(AppRoutes.emailVerification)`
- Erro: `AuthError` -> caixa de erro inline na tela
- Loading: `AuthLoading` -> overlay Lottie + botao desabilitado

---

## 2026-03-29 - Sessao 1: Mapeamento + Fundacao

### Analisado
- Estrutura completa do projeto FlutterFlow exportado
- Modulo Auth completo: login, cadastro, verificacao de e-mail, recuperacao de senha
- Custom actions relevantes: `funcFazerLogin`, `signUpWithEmail`, `verificarEmailConfirmado`, `updateEmailCooldown`
- Tabela `user_flow_state` (rastreamento de onboarding)
- Sistema de tema (FlutterFlowTheme -> tokens extraidos)
- `app_state.dart` (FFAppState -> substituido por Riverpod)
- `enums.dart` (Loadingstate, Situacaocadastral, ENuserMODE, ENTYPEdoc)

### Criado - Documentacao
- [x] PROJECT_MAP.md
- [x] ARCHITECTURE.md
- [x] DESIGN_SYSTEM.md
- [x] REBUILD_GUIDELINES.md
- [x] REBUILD_ROADMAP.md
- [x] MODULE_TEMPLATE.md
- [x] TEST_STRATEGY.md
- [x] BUILD_LOG.md
- [x] DECISIONS_LOG.md
- [x] CURRENT_STATE.md

### Criado - Codigo (Fundacao)
- [x] pubspec.yaml - dependencias principais
- [x] lib/main.dart - entry point com Riverpod + Supabase
- [x] lib/app/app.dart - MaterialApp.router
- [x] lib/core/config/app_config.dart - dart-define env vars
- [x] lib/core/error/app_exception.dart - sealed exception hierarchy
- [x] lib/core/router/app_routes.dart - route names e paths
- [x] lib/core/router/app_router.dart - GoRouter + RouterNotifier
- [x] lib/shared/theme/app_colors.dart
- [x] lib/shared/theme/app_spacing.dart
- [x] lib/shared/theme/app_text_styles.dart
- [x] lib/shared/theme/app_theme.dart
- [x] lib/shared/layout/breakpoints.dart

### Criado - Auth (Data + Domain + Provider)
- [x] lib/features/auth/domain/user_flow_state.dart
- [x] lib/features/auth/domain/auth_state.dart
- [x] lib/features/auth/data/auth_repository.dart
- [x] lib/features/auth/presentation/providers/auth_provider.dart

### Pendente desta sessao
- [ ] lib/shared/widgets/app_button.dart
- [ ] lib/shared/widgets/app_text_field.dart
- [ ] lib/shared/widgets/app_loading_overlay.dart
- [ ] Telas Auth (4 screens)
- [ ] Testes

---

## Template para proximas entradas

```text
## YYYY-MM-DD - Sessao N: {titulo}

### Analisado
- ...

### Criado
- [x] arquivo/funcionalidade

### Alterado
- arquivo: motivo

### Testado
- feature: resultado

### Pendente
- [ ] proximos itens
```
