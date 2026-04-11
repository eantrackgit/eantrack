# DECISIONS_LOG.md — EANTrack

> Registro de decisões críticas do projeto. Evita regressão e repetição de debate.
> Formato: cada decisão é final até que seja explicitamente revisada.

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
**Decisão:** `EanTrackTheme` como `ThemeExtension<EanTrackTheme>` com tokens semânticos (14 tokens). Dois presets: `EanTrackTheme.light` e `EanTrackTheme.dark`. Acesso via `EanTrackTheme.of(context)`. Toggle via `StateProvider<ThemeMode>` (`themeModeProvider`).
**Motivo:** ThemeExtension é o padrão oficial Flutter, integra com `MaterialApp.darkTheme`, suporta `lerp()` para transições suaves, e não exige `BuildContext` no lugar errado. Tokens semânticos isolam widgets das cores primitivas — mudança de paleta não requer alterar widgets.
**Impacto:** `AppButton`, `AppTextField`, `AuthScaffold`, `AppFeedbackDialog`, e todas as telas de auth/onboarding migradas. Telas internas (hub, regiões) ainda usam `AppColors.*` direto — pendente de migração.

---

## DEC-019 — Algoritmo determinístico de sugestões de identificador

**Data:** 2026-04-10
**Contexto:** `onboarding_profile_screen.dart` precisa sugerir identificadores disponíveis. Opções: (A) random com retry, (B) baseado em timestamp, (C) lista fixa de candidatos em ordem determinística.
**Decisão:** Lista fixa de candidatos em ordem pré-definida (sem aleatoriedade). Candidatos derivados do nome: `joaosilva`, `joao.silva`, `joao_silva`, `joaosilva1`, `joaosilva.oficial`, `joaosilva.pro`. Se ocupados, sufixos numéricos até 10.
**Motivo:** Testabilidade — dado nome fixo, sugestões são sempre as mesmas. Previsibilidade — `joaosilva` é sempre o primeiro candidato quando nome+sobrenome existem. Instagram e Microsoft usam abordagem similar.
**Impacto:** `_buildNameDrivenCandidates()` e `_buildUncheckedSuggestions()` em `onboarding_profile_screen.dart`. Filtro de `_minIdentifierLength` NÃO se aplica a sugestões (apenas a input do usuário). `_applySuggestion()` chama `_validateIdentifier()` diretamente para contornar guards de comprimento mínimo.
