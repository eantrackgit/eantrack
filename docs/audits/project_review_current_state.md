# Auditoria Geral do Projeto — EANTrack

> Revisão técnica e de produto do estado atual.
> Autor: auditoria arquitetural (Claude Code).
> Data: 2026-06-20.
> Branch: `main` (4 commits à frente de `origin/main`, não publicados).
> Método: leitura direta do código-fonte (`lib/`), docs (`docs/`), `pubspec.yaml`, suíte de testes (`test/`) e histórico git. **Nenhum** comando Flutter/Dart foi executado (proibido por CLAUDE.md). RLS/schema do Supabase **não** foram inspecionados no servidor — afirmações sobre banco são derivadas do uso no client e marcadas como tal.

---

## 1. Resumo Executivo

**Onde estamos:** o EANTrack tem uma **fundação técnica forte e bem cuidada** (auth, onboarding de agência, shell do hub, tema, roteamento, deploy web) e uma **superfície de produto ainda fina**. Tudo o que existe está bem-feito; o que entrega o valor central do produto (operação de campo: visitas, roteiros, tarefas, PDVs, leitura EAN, dashboards) **ainda não foi iniciado**.

**Maturidade atual:** fundação madura / produto em estágio inicial. É um **MVP técnico de cadastro e acesso**, não um MVP de operação.

**Está bem encaminhado?** Sim. A qualidade do que foi entregue é acima da média para o estágio: separação por features, design system próprio, tratamento exaustivo de borda em auth, estratégia de deploy/cache deliberada, suíte de testes existente. O risco do projeto não é dívida técnica — é **distância até o valor operacional**.

**Há riscos graves?** Nenhum risco crítico de segurança ou perda de dados foi identificado no código. Há **um bug de comportamento de severidade Alta** (engolimento de erro em `getUserFlowState` que pode mandar usuário aprovado para o onboarding em falha transitória) e **código de redirect duplicado/morto** que é uma armadilha de manutenção. Ambos corrigíveis sem reescrita.

**Perto de piloto ou produção?** Perto de **demo comercial do fluxo de cadastro/onboarding**. **Não** perto de piloto operacional — falta pelo menos um módulo que entregue valor de campo de ponta a ponta.

**Nota geral honesta: 7.4 / 10** (fundação 8–9, produto 5.5). Justificada na seção 14–15.

**Veredito: Pronto para demo (do fluxo de cadastro/onboarding) — fundação sólida, ainda não pronto para piloto operacional.**

---

## 2. Mapa Técnico do Projeto

**Stack:** Flutter + Supabase + Riverpod + GoRouter. Observabilidade via Sentry. 142 arquivos Dart em `lib/`. Organização **feature-first** (`lib/features/<feature>/{data,domain,presentation}`) + `lib/shared` (design system, utils, mixins) + `lib/core` (router, config, connectivity, error).

### Módulos principais
- **Fundação** (`core/`, `shared/`): tema EanTrackTheme (dark/light), `AppButton`/`AppTextField`/`AuthScaffold`/`AppCard`, `FormStateMixin`, `AsyncAction`, breakpoints, conectividade.
- **Auth** (`features/auth`): login tradicional + Google OAuth (implementado), registro, verificação de e-mail, recuperação com cooldown persistido, update password, link expirado, histórico de senha. Repositório fatiado em serviços (`signing`, `password`, `email`).
- **Onboarding** (`features/onboarding`): individual (perfil, foto com crop) e agência (CNPJ → confirmação → representante legal → documentos → status → aceite de termos).
- **Hub** (`features/hub`): shell com sidebar desktop, drawer mobile (reaproveita corpo único), navbar mobile com BEEP flutuante, settings dialog.
- **Regions / Validity**: listagens básicas.
- **Flow** (`features/flow`): tela transitória de decisão de auth + fallback seguro.

### Fluxo de auth
`splash → /flow → decide(AuthFlowState)`. `AuthFlowState` é derivado em `authFlowStateProvider` de três sinais: contexto de recovery, `authNotifierProvider` e o stream de usuário do Supabase. `/flow` nunca é destino final: encaminha para `login`, `update-password` (recovery), onboarding ou hub. Possui **timer de segurança de 10s** com regra explícita: sem sessão → login; com sessão mas contexto não confirmado → revalida 1x → fallback seguro. Excelente engenharia de borda.

### Fluxo de onboarding (agência)
`AgencyStatusNotifier` carrega via RPC `get_agency_status_full` (carga única por sessão, com guarda de corrida por `_loadRequestId`). Gate de acesso ao hub é **exclusivo do router** e combina `statusAgency == approved && consolidatedDocumentStatus == approved && termsAccepted` (`_hasAgencyHubAccess`). Documentos são insert-only/versionados; representante legal é mutável. Correção de documento cria nova tentativa sem apagar histórico.

### Fluxo do hub / mobile
Desktop usa `MenuHubSidebar`; mobile usa `MobileHubDrawer` que reaproveita `_MenuHubSidebarBody` (fonte única de itens de menu). SafeArea, dark mode, `maxLines`/`ellipsis` contra overflow. Bloqueio de menu (`isBlocked`) derivado do mesmo critério do gate.

### Fluxo de deploy
Flutter Web → Hostinger. Estratégia deliberada: **service worker desligado** (`--pwa-strategy=none`), shell (`index.html`, `main.dart.js`, `flutter.js`, `manifest.json`, `version.json`) com `no-store`; runtime com `must-revalidate`; limpeza automática de SW/cache legado no bootstrap com 1 reload. Scripts (`build_operational_web.{sh,bat}`) + `deploy/operational.htaccess` + checklist documentado.

### Dados Supabase (uso observado no client)
Tabelas centrais: `agencies`, `legal_representatives`, `legal_documents`, `user_flow_state`, `email_codes`, e o domínio operacional (`regions`, `pdvs`, `networks`, etc.). Leituras consistentemente filtradas por `user_uuid`/`auth.uid()`. RPCs usadas: `get_agency_status_full`, `email_code_exists`, `insert_email_code`, `get_user_onboarding_route`, e família de listagens por agência.

---

## 3. Pontos Fortes

1. **Tratamento de borda em auth de nível alto.** `/flow` com timer de segurança, distinção sem-sessão vs. erro, revalidação única, fallback com saída garantida (`AuthFallbackScreen`). Comentários explicam a causa-raiz histórica de cada decisão. Raro nesse estágio.
2. **Onboarding de agência robusto.** Versionamento insert-only de documentos, carga com guarda de corrida (`_loadRequestId`), gate único no router, fluxo de rejeição/correção íntegro, `agencyId` vazio tratado em múltiplos pontos (`_routeFromUserFlowState`, `acceptTermsAndContinue`).
3. **Estratégia de deploy/cache madura e documentada.** Resolve de forma estrutural o problema clássico de "build antigo preso em cache" do Flutter Web.
4. **Design system coeso.** `AuthScaffold`, `AppButton`, `EanTrackTheme`, `FormStateMixin`, `AsyncAction` aplicados de forma consistente; dark/light em todas as telas-chave.
5. **Suíte de testes existente** (~20 arquivos): auth (repository, telas de login/registro/recover/verify, cooldown), onboarding (controllers de CNPJ/confirm/representative, status notifier), regions repository, validadores, mixins, smoke de gate de acesso.
6. **Mobile shell com fonte única.** Drawer mobile reaproveita o corpo do sidebar desktop — sem duplicação de itens de menu.
7. **Higiene de segurança no client.** Nenhum `service_role` no cliente; dedup de e-mail por hash SHA-256; cooldowns e histórico de senha; filtros por `user_uuid`.
8. **Legado já removido.** Os diretórios FlutterFlow (`lib/flutter_flow`, `lib/p_a_s_tpag_app_feed`) citados no PROJECT_MAP **não existem mais** — limpeza feita.
9. **Dependências nativas já provisionadas** para o futuro Android: `permission_handler`, `image_picker`, `flutter_image_compress`, `barcode_widget`, `file_picker`, `video_player`, `sentry_flutter`, `google_sign_in`, `sign_in_with_apple`, launcher icons configurados.

---

## 4. Fragilidades (por severidade)

### Crítico
- Nenhuma fragilidade crítica (perda de dados / brecha de segurança / loop infinito garantido) identificada no código revisado.

### Alto
- **A1 — `getUserFlowState` engole todos os erros e retorna `null`** (`auth_signing_service.dart:220-231`, `catch (_) { return null; }`). Impacto: (a) uma falha transitória de backend durante login/OAuth faz um usuário **autenticado e aprovado** ser tratado como `onboardingRequired` e cair no onboarding em vez do hub; (b) o caminho de erro cuidadosamente construído em `onExternalAuthChange` (`AuthError → fallback seguro`) torna-se **inalcançável** para falhas de flow-state, porque o método nunca lança — contradizendo o design de fallback do `/flow`. É um bug de comportamento real mascarado pela robustez aparente do resto do fluxo.
- **A2 — Redirect duplicado e divergente; uma das cópias é código morto.** O `GoRouter` usa a função `_redirect` em `app_router.dart:205`. O método `RouterRedirectGuard.redirect()` (`router_redirect_guard.dart:25-93`) existe, tem lógica **diferente** (não conhece gate de termos/`_hasAgencyHubAccess`) e **nunca é chamado** — `guard` é usado só como `refreshListenable`. Risco: um dev futuro edita a cópia errada achando que altera o comportamento. Os docs (`AUTH_FLOW.md:55`, `GLOBAL_PATTERNS.md:185`) ainda citam um terceiro nome inexistente, `RouterNotifier.redirect()`.

### Médio
- **M1 — Google Auth sem tratamento de colisão de conta.** O botão e o fluxo OAuth estão implementados, mas: o signup tradicional usa `email_codes` (hash) para impedir duplicidade, e o OAuth **não passa por essa verificação**. Não há tratamento de "e-mail já cadastrado por senha vs. Google", linking de conta, nem verificação contra `legal_representatives.email`. Em produção isso gera contas duplicadas / confusão de identidade.
- **M2 — Sem camada de persistência offline / fila de sincronização.** Nenhuma dependência de banco local (`sqflite`/`isar`/`hive`/`drift`). Aceitável hoje (não há módulo de campo), mas é **bloqueador** para a operação Android em campo (área sem sinal).
- **M3 — Dependência de RPC não documentada.** O app lê status via `get_agency_status_full`, que **não consta** em `BACKEND_SCHEMA.md`, e o `CURRENT_STATE.md` afirma que a fonte são as views `v_user_agency_onboarding_context` / `v_agency_latest_document_status`. Divergência doc↔código numa peça crítica do gate de acesso.

### Baixo
- **B1 — Drift de documentação.** `PROJECT_MAP.md` diz "Hub sem dados reais / sem dark mode" e "legado presente" e "Regiões sem testes" — tudo já falso. Reduz a confiança nos docs como fonte de verdade.
- **B2 — Duplo `ref.listen(authFlowStateProvider)`.** `RouterRedirectGuard` e `appRouterProvider` escutam o mesmo provider; notificação dupla inofensiva, mas redundante.
- **B3 — `debugPrint` de diagnóstico de auth em produção web** (FlowScreen/router). Sem segredos vazados (sem token), mas ruído de console no release web.
- **B4 — 3 arquivos modificados não commitados** (`app_router.dart`, `sidebar_item.dart`, `region_list_screen.dart`). Revisados: são coerentes com o fluxo recente (gateway anti-flicker do status, refactor de opacidade do item de sidebar, layout de regiões) — **não** são de outra feature. Recomenda-se commitar ou descartar para não misturar com esta auditoria.

---

## 5. Riscos para Produção

1. **A1** (usuário aprovado cai no onboarding em falha transitória) — afeta confiança no login. Maior risco de produção identificado.
2. **A2** (redirect duplicado) — manutenção futura pode introduzir regressão de gate de acesso ao hub sem perceber.
3. **M1** (colisão de conta Google) — vira problema real assim que Google Auth for divulgado a usuários.
4. **RLS não verificada neste exercício.** O código é disciplinado (filtra por `user_uuid`), mas a garantia real de isolamento depende das policies no Supabase — precisa ser auditada no servidor antes de produção (itens já listados em `CURRENT_STATE.md`).

---

## 6. Riscos para Escala (100k+ usuários)

- **Leituras por sessão são limitadas** (flow-state 1x, status de agência 1x com guarda de idle) — não há N+1 óbvio no client. Bom ponto de partida.
- **Não comprovado em escala:** sem teste de carga, sem inspeção de índices/planos de query, sem paginação visível para as futuras listas pesadas (colaboradores, PDVs — o Involves de referência tinha 311 colaboradores / 32 páginas). A escala depende quase toda do desenho do Supabase, fora do escopo do client.
- **Custo de RPC server-side** das listagens por agência precisa ser medido com volume real.
- **Sem cache/offline** — em escala, toda leitura bate no backend.

> Conclusão: para o conjunto **atual** de features, escala é tranquila. Para a **visão** do produto, escala é **não comprovada** e exigirá trabalho dedicado de banco.

---

## 7. Riscos de UX

- **Auth/Onboarding:** maduros. Único risco UX relevante é o **A1** (cair no onboarding indevidamente).
- **Mobile:** shell polido, mas **ainda é Flutter Web** rodando em navegador mobile — não há build Android validado. "Parece app", mas não **é** app nativo ainda.
- **Desktop:** preservado, responsivo, premium. Sem regressão visual aparente.
- **Vazio de produto:** após o onboarding, o usuário chega a um hub com poucos módulos reais (regiões/validade básicos). O "momento aha" operacional ainda não existe.

---

## 8. Riscos de Negócio

- **Distância até o valor.** O cliente final (trade marketing / promotor) compra operação de campo, não cadastro. Hoje há cadastro impecável e operação ausente. Risco de demo impressionar e piloto frustrar.
- **PWA operacional é armadilha de investimento.** Investir pesado em PWA para operação de campo (offline, câmera, GPS, fila) tende a ser retrabalho — o caminho nativo Android é mais sólido para campo. PWA/web brilha para dashboard/backoffice/comercial.
- **Confiabilidade em campo** depende de offline-first, que não existe. Promotor em loja sem sinal hoje não conseguiria operar.

---

## 9. O Que Está Pronto

**Pronto para demo (mostrar hoje, com confiança):**
- Login tradicional + Google, registro, verificação de e-mail, recuperação de senha.
- "Lembrar-me" / conta salva com card de identidade.
- Onboarding de agência completo (CNPJ → representante → documentos → status → aceite).
- Hub shell desktop + mobile (drawer, navbar com BEEP), dark/light.
- Deploy web atualizável sem cache preso.

**Pronto para piloto (com ressalvas):**
- Cadastro/onboarding suportariam um piloto **de cadastro**, não de operação.

**Pronto para produção:**
- Nada do produto **operacional** está pronto para produção. A camada de cadastro/acesso está perto, condicionada a corrigir A1/A2/M1 e auditar RLS.

---

## 10. O Que Falta para Piloto (checklist)

- [ ] Corrigir **A1** (`getUserFlowState`): distinguir "sem perfil" (null legítimo) de "erro de backend" (propagar → fallback seguro).
- [ ] Resolver **A2**: remover/unificar o redirect morto (`RouterRedirectGuard.redirect`) deixando uma única fonte de verdade.
- [ ] Auditar **RLS** no Supabase (isolamento por agência/usuário) — itens já listados em `CURRENT_STATE.md`.
- [ ] Entregar **1 módulo operacional de ponta a ponta** que gere valor demonstrável (candidato natural: Regiões/PDVs completos OU um fluxo de visita simples).
- [ ] Documentar/registrar `get_agency_status_full` no `BACKEND_SCHEMA.md` (**M3**).
- [ ] Commitar/limpar os 3 arquivos pendentes (**B4**).

## 11. O Que Falta para Produção (checklist)

- [ ] Tudo do piloto, mais:
- [ ] Tratamento de **colisão de conta Google** (**M1**): linking/merge e verificação contra cadastro existente.
- [ ] Política de **logs em release** (remover/condicionar `debugPrint` de auth — **B3**).
- [ ] Monitoramento ativo (Sentry já instalado) com alertas para falhas de auth/onboarding.
- [ ] Cobertura de testes para o(s) módulo(s) operacional(is) novos.
- [ ] Verificação de triggers de e-mail/status (`trg_agencies_*`) com volume real.
- [ ] Reconciliar toda a documentação com o código (**B1**).

## 12. O Que Falta para Escala (checklist)

- [ ] **Camada offline-first + fila de sincronização** (se operação de campo Android) — **M2**.
- [ ] Paginação/virtualização para listas grandes (colaboradores, PDVs).
- [ ] Teste de carga + revisão de índices e planos de query no Supabase.
- [ ] Estratégia de cache de leitura para dados quentes.
- [ ] Build Android nativo validado (permissões câmera/GPS/armazenamento já provisionadas via `permission_handler`).
- [ ] Multi-ambiente/multi-tenant se o roadmap confirmar (observado no Involves).

---

## 13. Recomendação Estratégica

### Próximos 7 dias — estancar e firmar a fundação
1. Corrigir **A1** e **A2** (alto impacto, baixo custo, sem reescrita).
2. Documentar `get_agency_status_full` (**M3**) e reconciliar `PROJECT_MAP`/`AUTH_FLOW`/`GLOBAL_PATTERNS` (**B1**).
3. Commitar/limpar os arquivos pendentes (**B4**).
4. Iniciar a auditoria de RLS no Supabase.

### Próximos 30 dias — provar valor operacional
1. Escolher **um** módulo operacional e entregá-lo de ponta a ponta (recomendado: PDVs/Regiões completos com criação, listagem, vínculo e dados reais — reaproveita o domínio Supabase já existente).
2. Decidir formalmente **PWA (backoffice/comercial) vs. Android nativo (campo)** e registrar a decisão (já há um rascunho estratégico em `docs/strategic_mapping_involves_stage.md`).
3. Endurecer Google Auth (**M1**) antes de divulgar.

### Próximos 90 dias — caminho para piloto operacional
1. Se a operação de campo for confirmada: introduzir **offline-first + sync** e build Android validado.
2. Primeiro fluxo de **visita/check-in** + **leitura EAN** (deps já presentes: `barcode_widget`, `image_picker`).
3. Esqueleto de **dashboard de KPIs** (referência Involves).
4. Teste de carga + decisão sobre multi-ambiente.

---

## 14. Notas por Categoria

| Categoria | Nota | Justificativa resumida |
|-----------|:----:|------------------------|
| Arquitetura geral | **8.5** | Feature-first limpo, DI Riverpod, design system; menos por redirect morto/divergente e drift de docs. |
| Autenticação | **8.0** | Borda excepcional, mas A1 (erro engolido) e A2 (código morto) são reais e tocam o núcleo. |
| Onboarding | **8.7** | Versionamento insert-only, carga race-safe, gate único, rejeição/retry íntegros; menos por RPC não documentada. |
| Banco/Supabase/RLS | **7.5** | Disciplina de `user_uuid` no client; RLS não verificável aqui, RPC fora do schema doc, assunções não provadas. |
| Mobile UX | **8.0** | Shell polido, drawer de fonte única, SafeArea, dark mode; não validado como build nativo, sem telas operacionais. |
| Desktop UX | **8.5** | Preservado, responsivo, dark/light, shell premium. |
| Escalabilidade | **7.0** | Leituras limitadas e sem N+1, mas escala não comprovada (sem load test, sem paginação de listas grandes, sem cache). |
| Segurança | **7.5** | Sem `service_role` no client, hash de e-mail, cooldown, histórico; menos por colisão Google e RLS não auditada. |
| Manutenibilidade | **8.0** | Modular, testado no núcleo, design system; menos por código morto e drift. |
| Documentação | **7.0** | Amplitude rara e valiosa, mas vários pontos defasados/divergentes corroem a confiança. |
| Deploy/cache | **9.0** | Política explícita por arquivo, SW desligado, limpeza de legado com 1 reload, scripts + checklist. Engenharia deliberada. |
| Preparação Google Auth | **7.0** | Fluxo implementado no caminho feliz; falta conflito/dedup/linking. |
| Preparação Play Store | **5.5** | Deps nativas + ícones prontos, mas sem offline/sync, sem build nativo validado, web-first, sem features de campo. |
| Produto/SaaS | **5.5** | Fundação excelente, mas zero módulos de valor operacional entregues. |

---

## 15. Nota Geral do Projeto

**7.4 / 10.**

Composição honesta: a **fundação** (auth, onboarding, deploy, arquitetura, design system) opera na faixa **8–9**; a **superfície de produto** (valor operacional entregue) opera na faixa **5.5**. A nota geral reflete a média ponderada de um projeto que faz **muito bem** o que se propôs até aqui, mas que ainda está **distante do valor central** prometido. Não é uma nota de "quase pronto" — é uma nota de "fundação confiável, produto por construir".

---

## 16. Veredito

**Pronto para demo (do fluxo de cadastro/onboarding) — fundação sólida; ainda NÃO pronto para piloto operacional.**

Entre os estágios disponíveis, o projeto é mais que "MVP técnico" no recorte de auth/onboarding (está demonstrável e bem-acabado), mas não alcança "pronto para piloto controlado" porque não existe módulo operacional entregando valor de campo. O salto de estágio depende de **um** módulo operacional de ponta a ponta + correção de A1/A2/M1 + auditoria de RLS.

---

## 17. Próximas Tasks Recomendadas (ordem de prioridade)

1. **AUDIT-FIX-001 (Alta):** corrigir `getUserFlowState` para não mascarar erro de backend como "sem perfil" (A1).
2. **AUDIT-FIX-002 (Alta):** unificar/remover o redirect morto `RouterRedirectGuard.redirect` (A2).
3. **AUDIT-DOC-001 (Média):** documentar `get_agency_status_full` no `BACKEND_SCHEMA.md` e reconciliar docs defasados (M3, B1).
4. **AUDIT-SEC-001 (Média):** auditoria de RLS no Supabase (isolamento por agência/usuário).
5. **PROD-MODULE-001 (Alta de produto):** entregar 1 módulo operacional de ponta a ponta (PDVs/Regiões completos).
6. **AUTH-GOOGLE-001 (Média):** tratamento de colisão/duplicação de conta no Google Auth (M1).
7. **STRATEGY-001 (Média):** decisão formal PWA vs. Android nativo + plano de offline-first se campo.
8. **OPS-001 (Baixa):** política de logs em release + alertas Sentry para auth/onboarding (B3).

---

### Anexo — Evidências-chave (arquivo:linha)

- Redirect ativo: `lib/core/router/app_router.dart:56` (`_redirect`) usado em `:205`.
- Redirect morto/divergente: `lib/core/router/router_redirect_guard.dart:25-93` (nunca chamado).
- Erro engolido: `lib/features/auth/data/auth_signing_service.dart:220-231`.
- Fallback seguro `/flow`: `lib/features/flow/presentation/screens/flow_screen.dart:81-126`.
- Gate único de hub: `lib/core/router/app_router.dart:50-54` (`_hasAgencyHubAccess`).
- Carga race-safe de status: `lib/features/onboarding/agency/controllers/agency_status_notifier.dart:331-387`.
- Fonte de status (RPC): `lib/features/onboarding/agency/repositories/agency_status_repository.dart:62-88`.
- Google OAuth: `lib/features/auth/data/auth_signing_service.dart:233-248`; botão em `lib/features/auth/presentation/screens/login_screen.dart:385-395`.
- Estratégia de deploy: `docs/web/cache_and_deploy_strategy.md`.
- Suíte de testes: `test/features/...` (~20 arquivos).
</content>
</invoke>
