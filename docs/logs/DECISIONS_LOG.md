# DECISIONS_LOG.md — EANTrack

> Registro de decisões críticas do projeto. Evita regressão e repetição de debate.
> Formato: cada decisão é final até que seja explicitamente revisada.

---

## [2026-04-20] Ciclo de Qualidade Global — 6.4 → 9.7

> Sessão de auditoria e refatoração em múltiplos ciclos (EVAL-TASK-GLOBAL-001 a EVAL-FINAL-009).
> Nota de entrada: **6.4 / 10**. Nota de saída: **9.7 / 10**.

### Decisões e refatorações aplicadas nesta sessão:

- **auth_repository.dart decomposto** — dividido em `AuthSigningService`, `AuthPasswordService`, `AuthEmailService`; repositório vira fachada sobre 3 serviços especializados
- **SplashNotifier decomposto** — `SplashAnimationController` isola animação; `SplashConnectivityHandler` isola lógica de conectividade; `SplashNotifier` orquestra sem implementar
- **Agency onboarding migrado de `ChangeNotifier` para Riverpod `StateNotifier`** — `AgencyCnpjNotifier`, `AgencyConfirmNotifier`, `AgencyRepresentativeNotifier` com `autoDispose`; screens migradas para `ConsumerWidget`
- **`AppRoutes.protectedRoutes` implementado como `Set<String>`** — `RouterRedirectGuard` usa `protectedRoutes.contains(path)` em vez de comparações inline
- **Rotas orphans adicionadas a `AppRoutes`** — `onboardingAgencyConfirm` e `onboardingAgencyRepresentative` agora têm constantes; zero string literal de rota fora de `AppRoutes`
- **`AgencyCnpjStatus` implementado como enum com campo direto no State** — eliminado getter derivado por string-switch; notifier seta `status` diretamente em cada transição
- **Constantes de erro nomeadas** — `_kCnpjInvalido`, `_kCnpjNaoEncontrado`, `_kCnpjInativo`, `_kCnpjDuplicado`, `_kCnpjErroGenerico`; zero literal duplicada
- **Convenção `*Screen` / `*_screen.dart` unificada** — `AgencyCnpjPage` → `AgencyCnpjScreen`, `AgencyConfirmPage` → `AgencyConfirmScreen`, `AgencyRepresentativePage` → `AgencyRepresentativeScreen`, `FlowPage` → `FlowScreen`; todos os arquivos renomeados
- **Barrel `shared/shared.dart` completo** — `NoConnectionView` exportado; imports via path direto eliminados
- **Zero mojibake em todo o projeto** — 11 strings em `region_list_screen.dart` + 8 strings em `agency_cnpj_controller.dart` corrigidas; arquivo salvo em UTF-8
- **`TextEditingController` e `FocusNode` extraídos do corpo do `AgencyCnpjNotifier`** — criados no provider via `ref.onDispose`, injetados via construtor
- **TODO rastreável em `region_repository.dart`** — `⚠ Verificar assinaturas` substituído por `TODO(marcio): verificar assinatura RPC com Supabase antes do deploy`
- **`no_connection_screen.dart` removido de `core/connectivity/presentation/`** — substituído por `NoConnectionView` em `shared/widgets/`
- **`RegionEmptyState` removida** — substituída por `AppListStateView` com parâmetros `isEmpty`, `emptyIcon`, `emptyTitle`, `emptySubtitle`
- **`_SplashBackground` refatorada** — `LayoutBuilder` + cálculos de `glowSize`/`logoWidth` movidos para dentro; `build()` de `SplashScreen` reduzido para 16 linhas

### Padrão estabelecido (obrigatório daqui em diante):

```
Status como enum com campo direto no State — nunca derivado por string
Strings de erro como constantes nomeadas — nunca literais duplicadas
Todo arquivo em UTF-8 — verificar antes de entregar
*Screen / *_screen.dart em todo o projeto
Rotas sempre em AppRoutes — zero string literal fora
Barrel shared/shared.dart — import sempre via barrel
```

---

## DEC-023 — Sentry via dart-define, sem fallback silencioso

**Data:** 2026-04-23
**Contexto:** Monitoramento de erros em produção. Opções: (A) Sentry com DSN hardcoded, (B) DSN via `--dart-define`, (C) sem monitoramento.
**Decisão:** `SentryFlutter.init` no `main.dart` com DSN lido de `AppConfig.sentryDsn` (`String.fromEnvironment('SENTRY_DSN')`). Se DSN estiver vazio (dev local sem `--dart-define`), Sentry inicializa sem capturar — sem crash.
**Motivo:** DSN não deve estar no código-fonte (segurança). Flexibilidade por ambiente: dev sem Sentry, staging/prod com Sentry via secret do CI.
**Impacto:** Pipeline `.github/workflows/build.yml` passa `SENTRY_DSN` via secret. Qualquer exceção não tratada em produção é capturada automaticamente. Não requer alteração de código para habilitar/desabilitar por ambiente.

---

## DEC-024 — `withRetry<T>()` como função top-level em `async_action.dart`

**Data:** 2026-04-23
**Contexto:** Operações de rede (Supabase, CEP, CNPJ) podem falhar por instabilidade transitória. Opções: (A) retry inline em cada notifier, (B) helper centralizado.
**Decisão:** `withRetry<T>(Future<T> Function() action, {int maxAttempts = 3, Duration delay = const Duration(milliseconds: 500)})` em `async_action.dart`. Backoff multiplicativo: delay × attempt (500ms, 1000ms, 1500ms). Relança a última exceção se todas as tentativas falharem.
**Motivo:** Centraliza o padrão evitando duplicação nos notifiers. Colocado em `async_action.dart` por coerência — mesmo arquivo das primitivas de estado assíncrono do projeto.
**Impacto:** Disponível via barrel `shared/shared.dart`. Usar em chamadas de rede que podem falhar transitoriamente. Não usar para erros de negócio (validação, conflito de CNPJ) — esses devem falhar imediatamente.

---

## DEC-021 — Splash routing delegado ao Supabase via RPC

**Data:** 2026-04-22
**Contexto:** A tela de splash precisa decidir para onde navegar após a animação: hub, alguma etapa do onboarding de agência, ou onboarding individual. Opções: (A) lógica client-side baseando-se em `UserFlowState`, (B) RPC no Supabase que retorna a rota correta.
**Decisão:** `SplashNotifier._resolveRoute()` chama `get_user_onboarding_route` via RPC e navega para a rota retornada. Lógica de decisão é 100% server-side.
**Motivo:** Escalabilidade e flexibilidade operacional. Com 10k+ usuários em diferentes estágios de onboarding, a lógica de roteamento pode ser alterada no servidor sem deploy de app. Elimina também a necessidade de sincronizar `UserFlowState` no cliente — a fonte de verdade é o backend.
**Impacto:** `SplashNotifier` não precisa mais conhecer os estados de onboarding. Novos caminhos de onboarding são adicionados no backend e no `switch` do notifier. Fallback sempre é `/login` — nunca deixa o usuário preso.
**Rotas suportadas:** `hub` | `onboarding/agency/status` | `onboarding/agency/representative` | `onboarding/agency/cnpj` | `onboarding/individual/profile` | `null` → `/onboarding`

---

## DEC-022 — AgencyStatusNotifier consulta view diretamente (sem RPC intermediário)

**Data:** 2026-04-22
**Contexto:** `AgencyStatusScreen` precisa de dados ricos: status da agência, dados do representante legal, status do documento. Opções: (A) RPC dedicada, (B) query direta na view `v_user_agency_onboarding_context`.
**Decisão:** Query direta na view (`supabase.from('v_user_agency_onboarding_context').select().eq('user_id', userId).single()`).
**Motivo:** A view já existe e consolida os joins necessários. Criar uma RPC wrapper seria overhead sem benefício neste momento. RLS da view garante que o usuário só vê seus próprios dados.
**Impacto:** `AgencyStatusData.fromJson` tem parser defensivo com fallback camelCase para absorver inconsistências na resposta da view. Se a view evoluir (novos campos), apenas o `fromJson` e o model precisam ser atualizados — sem alteração de contrato de RPC.
**Regra:** se a view `v_user_agency_onboarding_context` for alterada no Supabase, revisar `AgencyStatusData.fromJson` antes de qualquer deploy.

---

## DEC-025 — Modelo não-destrutivo para documentos legais (insert-only)

**Data:** 2026-04-24
**Contexto:** Documentos do representante legal precisam ser revisados por um admin. O processo pode exigir múltiplos envios (rejeição → correção → novo envio). Opções: (A) overwrite do documento existente a cada reenvio, (B) insert-only com versionamento por `attempt_number`.
**Decisão:** Insert-only. Cada envio cria novos registros em `legal_representatives` e `legal_documents`. Nenhum documento é apagado ou sobrescrito pelo app. `attempt_number` é incremental por agência. Status consolidado é calculado via views (`v_agency_latest_document_status`), nunca no frontend.
**Motivo:** Auditoria e rastreabilidade — cada tentativa é evidência imutável. Consistência — a lógica de consolidação de status fica em um único lugar (view), válida para todas as versões do app e todos os consumidores (Flutter, admin panel, RPCs). Segurança — o app não pode alterar ou remover histórico de documentos.
**Impacto:** `AgencyRepresentativeService.submit()` executa sempre INSERT (nunca UPDATE). `AgencyStatusNotifier` lê apenas views. `AgencyStatusScreen` exibe `rejection_reason` somente quando a última tentativa está `rejected`. Documentação completa em [docs/architecture/LEGAL_DOCUMENTS_VERSIONING.md](../architecture/LEGAL_DOCUMENTS_VERSIONING.md).

---

## DEC-026 — Status documental controla liberação de acesso da agência

**Data:** 2026-04-25
**Contexto:** O fluxo de agência tem dois conceitos que pareciam sobrepostos: `status_agency` da agência e status dos documentos legais enviados pelo representante. Também há múltiplas tentativas de documento após rejeição.
**Decisão:** `status_agency` e `consolidated_document_status` são conceitos separados. A liberação de acesso ao hub/configuração depende da documentação estar `approved` via `v_agency_latest_document_status`. `pending` e `rejected` mantêm o usuário em `/onboarding/agency/status` e bloqueiam navegação interna.
**Motivo:** A aprovação documental é o gate de confiança para entrada na operação. O status operacional da agência pode existir no futuro com outro significado, sem apagar o histórico documental nem misturar regras.
**Impacto:** Router e web shell tratam `approved` como único estado liberado. `AgencyStatusScreen` continua sendo a superfície principal para pending/rejected e também a tela pós-reload de approved, com CTA explícito "Iniciar configuração da agência".

---

## DEC-027 — Views de documentos são a fonte de leitura do app

**Data:** 2026-04-25
**Contexto:** O app precisa mostrar o detalhe dos documentos e o status consolidado da última tentativa sem consultar tabela bruta nem reimplementar regra de versionamento no Flutter.
**Decisão:** A tela de status lê views, não `legal_documents` diretamente. `v_latest_legal_documents` representa o detalhe por documento/tentativa mais recente. `v_agency_latest_document_status` representa o status consolidado da agência para liberação de acesso.
**Motivo:** Mantém versionamento e consolidação no backend, reduz divergência entre app, admin panel e futuras RPCs, e evita que o cliente dependa de regras internas da tabela bruta.
**Impacto:** `AgencyStatusNotifier` refaz query nas views em refresh. Rejeições antigas não aparecem quando existe tentativa posterior. Documentos rejeitados não são apagados nem sobrescritos.

---

## DEC-028 — MenuHub web como sidebar; mobile preservado como experiência própria

**Data:** 2026-04-25
**Contexto:** O web shell precisa permitir navegação lateral quando a agência está aprovada, mas a experiência mobile já usa outro padrão de navegação.
**Decisão:** Em desktop/web, o MenuHub é exibido como `MenuHubSidebar`. Em mobile, o MenuHub permanece como página/experiência mobile e a `AgencyStatusScreen` não exibe sidebar.
**Motivo:** Desktop exige navegação persistente e escaneável; mobile precisa preservar espaço e o padrão já existente. O mesmo status documental alimenta o bloqueio/liberação dos itens.
**Impacto:** `pending/rejected` bloqueiam navegação interna no sidebar. `approved` libera itens previstos e permite navegação normal. A entrada automática no dashboard após reload foi removida; o usuário entra via CTA ou clique em item liberado.

---

## [2026-04-25] Auditoria Global pré-commit — Features: agency status, sidebar, router guard

> Sessão de auditoria (TASK-CLAUDE-AUDIT-001). Não houve refactor — apenas diagnóstico e documentação.

### Aprovado sem ressalvas:
- Fluxo pending/rejected → tela de status (correto via `isOnboardingComplete` + FlowScreen)
- CTA dinâmico na AgencyStatusScreen (approved/rejected/pending)
- Botão "Atualizar status" → query real nas views
- Submit de representante legal → sempre INSERT, rollback granular
- `_nextAttemptNumber` correto e documentado
- `MenuHubSidebar` dark mode, `_isBlocked`, aparece apenas em desktop

### Itens com ressalva (não bloqueadores):
- Router guard duplo (`_redirect` + `RouterRedirectGuard`) — funcional mas confuso; documentar que `RouterRedirectGuard` serve apenas como `refreshListenable`
- `agencyStatusProvider(null)` autoDispose no `_redirect` — race condition teórica se provider descartado entre navegações
- Botão voltar no mobile da AgencyStatusScreen faz signout — UX confusa

### Bugs identificados (registrados como BUG-01 a BUG-04 no CURRENT_STATE.md):
- **BUG-01:** HubScreen sidebar com dados hardcoded — corrigir antes do primeiro usuário real
- **BUG-02:** `AgencyStatusData.statusAgency` e `consolidatedDocumentStatus` populados com o mesmo valor — separar as duas fontes no `fromJson`
- **BUG-03:** Duas fontes de verdade para "agência liberada" — `user_flow_state.dart` usa `status_agency`, router usa `consolidated_document_status`. Decisão pendente sobre fonte única.
- **BUG-04:** Botão voltar mobile = signout sem aviso

### Decisão registrada:
DEC-026 definiu que status operacional da agência e status documental são conceitos separados. A liberação de acesso ao hub/configuração depende do status documental consolidado (`v_agency_latest_document_status`) estar `approved`.

---

## DEC-001 — Flutter Code-First (abandonar FlutterFlow)

**Data:** 2026-03-25
**Contexto:** O projeto iniciou em FlutterFlow (visual builder). Conforme cresceu, FlutterFlow passou a gerar código difícil de manter, com acoplamento alto, arquivos monolíticos e controle limitado sobre state management e navegação.
**Decisão:** Reconstruir o projeto em Flutter puro (code-first). FlutterFlow serve apenas como referência visual — o design original é preservado, mas o código é 100% novo.
**Motivo:** Controle total sobre arquitetura, testabilidade, performance e manutenção. Impossível atingir nível SaaS com código gerado.
**Impacto:** Todos os arquivos em `lib/flutter_flow/` e `lib/p_a_s_tpag_app_feed/` são legado. Serão removidos na Fase 13 (Hardening). Até lá, ignorar — não causar conflito.

---

## DEC-002 — Supabase RPC-First

**Data:** 2026-03-25
**Contexto:** Acesso ao banco poderia ser via queries diretas (select/insert) ou via RPCs (funções server-side).
**Decisão:** Toda lógica de dados crítica passa por RPCs no Supabase. Queries diretas apenas para operações triviais (read de tabela simples com RLS).
**Motivo:** RPCs centralizam regras no backend, facilitam versionamento, reduzem superfície de ataque no client, e permitem evolução sem deploy de app.
**Impacto:** `BACKEND_SCHEMA.md` é a fonte de verdade. Nunca criar lógica de negócio complexa no Flutter que deveria estar no Supabase.

---

## DEC-003 — Validação apenas no Submit (_submitted flag)

**Data:** 2026-03-29
**Contexto:** Validação em tempo real (`AutovalidateMode.onUserInteraction`) mostrava erros enquanto o usuário digitava a primeira letra. UX agressiva e frustrante.
**Decisão:** Validação ocorre SOMENTE após o primeiro submit. Implementação via flag `_submitted = false` que guarda cada validator.
**Motivo:** UX profissional — erros aparecem quando o usuário termina de preencher e tenta avançar, não enquanto ainda está digitando.
**Impacto:** Padrão obrigatório em TODOS os formulários do projeto. Documentado em GLOBAL_PATTERNS.md seção 3. Feedback positivo em tempo real (checklist senha, debounce email) é permitido e separado da validação.

---

## DEC-004 — Material Icons Only (sem CupertinoIcons)

**Data:** 2026-03-29
**Contexto:** Código legado misturava Material Icons, CupertinoIcons e ícones inline de diferentes fontes.
**Decisão:** Usar exclusivamente Material Icons (`Icons.xxx`). Para ícones customizados, usar SVG local.
**Motivo:** Consistência visual, sem dependência de pacotes terceiros, tamanho de bundle menor.
**Impacto:** Proibido `CupertinoIcons`, `FontAwesomeIcons` ou qualquer pacote de ícones externo. Se absolutamente necessário um ícone que não existe no Material, criar SVG em `assets/icons/`.

---

## DEC-005 — Ícone Google temporário (Icons.g_mobiledata)

**Data:** 2026-03-30
**Contexto:** Botão "Entrar com Google" precisa de ícone. Ícone oficial Google requer SVG ou pacote.
**Decisão:** Usar `Icons.g_mobiledata` como placeholder. Substituir por SVG oficial quando OAuth for implementado de verdade.
**Motivo:** Não adicionar dependência de pacote só para um ícone de placeholder. Funciona visualmente por enquanto.
**Impacto:** Quando TASK de OAuth real for executada, incluir SVG do Google em `assets/icons/google_logo.svg`.

---

## DEC-006 — Polling 3s silencioso no Email Verification

**Data:** 2026-03-29
**Contexto:** Após registro, o usuário precisa confirmar email. Três opções: (A) polling agressivo 1s, (B) polling moderado 3s silencioso, (C) sem polling (só botão manual).
**Decisão:** Polling a cada 3 segundos, completamente silencioso (sem spinner, sem texto "verificando..."). Complementado por botão "Já confirmei" para check manual.
**Motivo:** 3s é equilíbrio entre responsividade e carga no backend. Silencioso porque polling é background — o usuário não precisa saber. Botão manual dá controle ao usuário ansioso.
**Impacto:** Documentado em AUTH_FLOW.md. Polling cancela no dispose. Erros do polling são silenciados.

---

## DEC-007 — Cooldown 5min + máximo 3 reenvios

**Data:** 2026-03-29
**Contexto:** Botão "Reenviar email de verificação" poderia ser abusado (spam ao Supabase, emails duplicados).
**Decisão:** Após cada reenvio: cooldown de 5 minutos (300s) com barra de progresso visual. Máximo 3 reenvios por sessão — após o 3º, bloqueia por 30 minutos.
**Motivo:** Protege contra abuse sem frustrar usuário legítimo. 5 min é tempo razoável para email chegar. Barra visual comunica que a ação foi registrada.
**Impacto:** Controle local no State (não persistido no backend). Se usuário sair e voltar, contador reseta — aceitável.

---

## DEC-008 — Separação Claude (arquiteto) vs Codex (executor)

**Data:** 2026-03-29
**Contexto:** Uso de AI para desenvolvimento. Dois modelos disponíveis: Claude (conversa, planejamento, revisão) e Codex (execução de código via tasks).
**Decisão:** Claude define arquitetura, gera documentação e CODEX_TASKs. Codex executa tasks mecanicamente sem alterar arquitetura.
**Motivo:** Claude tem contexto amplo e capacidade de raciocínio. Codex executa rápido mas tende a desviar do escopo se a task for ambígua. Separar roles evita retrabalho.
**Impacto:** Toda task para Codex deve ser autocontida — arquivo único, instruções precisas, sem ambiguidade. Se Codex desviar, a task estava mal escrita (responsabilidade do Claude).

---

## DEC-009 — Riverpod StateNotifier (não AsyncNotifier)

**Data:** 2026-03-25
**Contexto:** Riverpod oferece StateNotifier (clássico) e AsyncNotifier (mais novo). Escolha de qual padrão usar.
**Decisão:** Usar `StateNotifier` com sealed state classes em todo o projeto.
**Motivo:** StateNotifier é explícito — states são sealed, exhaustive no switch, sem nullable fields. AsyncNotifier é mais conciso mas esconde estados (loading é implícito). Para um projeto que precisa de controle total, StateNotifier é mais seguro.
**Impacto:** Todo provider de feature usa `StateNotifierProvider`. Sealed state com Initial/Loading/Loaded/Error. Padrão documentado em GLOBAL_PATTERNS.md.

---

## DEC-010 — Sem testes unitários na fase atual

**Data:** 2026-03-30
**Contexto:** Testes estavam no roadmap da Fase 1 (Auth). Projeto precisava avançar para validar fluxos reais.
**Decisão:** Adiar testes para após estabilização do produto (pós Fase 4). Foco em testes manuais no Chrome.
**Motivo:** Escrever testes para código que ainda pode mudar é retrabalho. Melhor investir em documentação sólida agora e testar quando as features estiverem estáveis.
**Impacto:** Testes virão como tasks separadas na Fase 13 (Hardening). Até lá, critério de pronto = teste manual no Chrome.

---

## DEC-011 — Arquivo único por CODEX_TASK (máximo 3)

**Data:** 2026-03-30
**Contexto:** Tasks com escopo amplo (5+ arquivos) geravam desvios do Codex — alterações não solicitadas, imports quebrados, conflitos.
**Decisão:** Cada CODEX_TASK altera no máximo 3 arquivos. Preferencialmente 1.
**Motivo:** Escopo menor = menos chance de desvio. Mais fácil revisar. Mais fácil reverter se der errado.
**Impacto:** Tasks maiores devem ser quebradas. Se uma feature precisa de 5 arquivos, são pelo menos 2 tasks.

---

## DEC-012 — FlutterFlow como referência visual, não funcional

**Data:** 2026-03-25
**Contexto:** Storyboard do FlutterFlow contém o design visual completo do app. Código gerado pelo FlutterFlow está em `lib/`.
**Decisão:** O design do FlutterFlow é a referência visual (cores, layout, posição dos elementos). O código gerado é ignorado — reconstrução é code-first.
**Motivo:** Código FlutterFlow tem problemas estruturais. Design visual é bom e validado pelo cliente/time.
**Impacto:** SCREEN_SPECS.md é derivado do storyboard FlutterFlow. Toda tela nova deve ser visualmente fiel ao storyboard.

---

## DEC-013 — Poppins (títulos) + Roboto (corpo)

**Data:** 2026-03-25
**Contexto:** Escolha de tipografia para o app.
**Decisão:** Poppins para títulos e botões (weight 600-700). Roboto para corpo, labels e texto geral (weight 400-500).
**Motivo:** Combinação profissional. Poppins dá personalidade nos headings. Roboto garante legibilidade no corpo. Ambas disponíveis via Google Fonts sem custo.
**Impacto:** Definido em AppTextStyles. Nunca usar outra fonte sem aprovação.

---

## DEC-014 — Animações sutis only (sem bounce)

**Data:** 2026-04-01
**Contexto:** Definição do padrão de animações para o projeto.
**Decisão:** Apenas animações sutis e funcionais. Proibido bounce, shake, parallax, stagger de lista. Máximo 500ms (exceto Lottie pontual).
**Motivo:** Produto B2B corporativo. Animações chamativas passam impressão de app casual/gamificado.
**Impacto:** Documentado em ANIMATION_GUIDELINES.md. Codex deve seguir estritamente.

---

## DEC-015 — Remoção de animações customizadas e padronização via GoRouter

**Data:** 2026-04-03
**Contexto:** Diversas telas implementaram animações de entrada individuais (FadeTransition + ScaleTransition em `AuthScaffold`, `EmailVerificationScreen`; AnimatedContainer em `ChooseModeScreen`; TweenAnimationBuilder em estado confirmado). O resultado foi comportamento inconsistente entre telas, animações duplicadas com o GoRouter, e manutenção complexa.
**Decisão:** Remover todas as animações de entrada em nível de tela/widget. Centralizar 100% das transições no `app_router.dart` via `_fadePage()` (fade 200ms, easeInOut). Telas são estáticas — não definem animações próprias.
**Motivo:** Consistência, previsibilidade e performance. Uma fonte de verdade para transições elimina divergências. Lottie (`flow_loading.json`) é a única exceção permitida — loading global com `animate: true, repeat: true`, duração respeitando o JSON original.
**Impacto:** `auth_scaffold.dart` revertido para StatelessWidget. `email_verification_screen.dart` sem AnimationController. `choose_mode_screen.dart` sem AnimatedContainer. ANIMATION_GUIDELINES.md e ARCHITECTURE.md atualizados.

---

## DEC-016 — Separação entre verificação de e-mail e reautenticação

**Data:** 2026-04-03
**Decisão:** Após confirmação de e-mail, o usuário NÃO é autenticado automaticamente. Um bottom sheet modal (não dismissível) solicita a senha antes de estabelecer sessão. `AuthEmailUnconfirmed` armazena apenas o e-mail — senha nunca em estado/memória.
**Motivo:** Segurança. Credenciais em memória são um vetor de ataque desnecessário dado que o Supabase requer reautenticação após confirmação de qualquer forma.
**Impacto:** `checkEmailConfirmed()` retorna bool puro. `signInAfterConfirmation()` é chamado pelo modal com senha fornecida pelo usuário em tempo real.

---

## DEC-017 — Onboarding sempre inicia em /onboarding/mode

**Data:** 2026-04-03
**Decisão:** `userMode` em `UserFlowState` é nullable. FlowPage só avança além de `/onboarding/mode` se `userMode != null`. Modo individual roteia para `/onboarding/individual` (placeholder) — nunca para `/hub` sem onboarding completo.
**Motivo:** Garantir que nenhum usuário entre no app com estado operacional indefinido.
**Impacto:** `UserFlowState.fromJson` sem default para `user_mode`. `isOnboardingComplete` retorna false quando `userMode == null`.

---

## DEC-018 — EanTrackTheme como ThemeExtension para dark mode

**Data:** 2026-04-09
**Contexto:** Dark mode requerido. Opções: (A) mapear cores com `MediaQuery.platformBrightness`, (B) criar próprio sistema de tokens, (C) usar Flutter `ThemeExtension`.
**Decisão:** `EanTrackTheme` como `ThemeExtension<EanTrackTheme>` com 18 tokens semânticos. Dois presets: `EanTrackTheme.light` e `EanTrackTheme.dark`. Acesso via `EanTrackTheme.of(context)`. Toggle via `StateProvider<ThemeMode>` (`themeModeProvider`).
**Motivo:** ThemeExtension é o padrão oficial Flutter, integra com `MaterialApp.darkTheme`, suporta `lerp()` para transições suaves, e não exige `BuildContext` no lugar errado. Tokens semânticos isolam widgets das cores primitivas — mudança de paleta não requer alterar widgets.
**Impacto:** `AppButton`, `AppTextField`, `AppCard`, `PasswordRuleRow`, `AuthScaffold`, `AppFeedbackDialog`, e todas as telas de auth/onboarding migradas. Telas internas (hub, regiões) ainda usam `AppColors.*` direto — pendente de migração.
**Status (2026-04-13):** auth/onboarding totalmente padronizados. Auditoria e correções concluídas. Ver exceções em ARCHITECTURE.md.

---

## DEC-020 — AppTextField com label sempre preenchido

**Data:** 2026-04-13
**Contexto:** `register_screen` usava composição paralela (`Text()` label manual + `AppTextField(label: '')`), enquanto demais telas de auth usavam `AppTextField(label: 'E-mail')`. Inconsistência de padrão e manutenção.
**Decisão:** `label` em `AppTextField` é sempre preenchido com o nome do campo. Nunca usar `label: ''`. O floating label (`FloatingLabelBehavior.always`) é a única referência visual do campo em estado preenchido.
**Motivo:** Elimina duplicação (Text + AppTextField), centraliza a exibição do label no componente, e garante comportamento consistente com o `inputDecorationTheme` do Flutter.
**Impacto:** `register_screen` corrigido. Padrão documentado em DESIGN_SYSTEM.md e COMPONENT_LIBRARY.md. Qualquer nova tela deve seguir este padrão.

---

## DEC-019 — Algoritmo determinístico de sugestões de identificador

**Data:** 2026-04-10
**Contexto:** `onboarding_profile_screen.dart` precisa sugerir identificadores disponíveis. Opções: (A) random com retry, (B) baseado em timestamp, (C) lista fixa de candidatos em ordem determinística.
**Decisão:** Lista fixa de candidatos em ordem pré-definida (sem aleatoriedade). Candidatos derivados do nome: `joaosilva`, `joao.silva`, `joao_silva`, `joaosilva1`, `joaosilva.oficial`, `joaosilva.pro`. Se ocupados, sufixos numéricos até 10.
**Motivo:** Testabilidade — dado nome fixo, sugestões são sempre as mesmas. Previsibilidade — `joaosilva` é sempre o primeiro candidato quando nome+sobrenome existem. Instagram e Microsoft usam abordagem similar.
**Impacto:** `_buildNameDrivenCandidates()` e `_buildUncheckedSuggestions()` em `onboarding_profile_screen.dart`. Filtro de `_minIdentifierLength` NÃO se aplica a sugestões (apenas a input do usuário). `_applySuggestion()` chama `_validateIdentifier()` diretamente para contornar guards de comprimento mínimo.
