# CURRENT_STATE.md - EANTrack

> Leia este arquivo primeiro ao retomar o projeto.
> Estado real do produto apos os ajustes de status, aceite, documentos versionados,
> representante legal, router, HubScreen, RegionListScreen desktop e RLS.
> Ultima atualizacao: 2026-06-20.

---

## Resumo Executivo

O fluxo de agencia esta funcional no nucleo de onboarding:

- cadastro/confirmacao da agencia;
- cadastro do representante legal;
- envio de documentos;
- tela de status com refresh real;
- correcao de documentos sem sobrescrever historico;
- aceite obrigatorio de termos apos aprovacao;
- gate de acesso ao hub baseado em agencia aprovada, documento aprovado e termos aceitos.
- HubScreen sem dados mockados: usuario e agencia vêm de providers reais.
- RegionListScreen com sidebar desktop, dark mode via EanTrackTheme e layout responsivo.
- Card "Status do documento" reestruturado com secoes rotuladas: REPRESENTANTE LEGAL, CONTATO e STATUS DA SOLICITAÇÃO.

`/flow` nao e estado final. Ele atua apenas como decisor/transicao. O usuario nao deve ficar preso em `/flow`.

Nota atual do projeto: estado funcional e coerente para auditoria global de onboarding de agencia. Nao ha divergencia conhecida entre documentacao e codigo neste fluxo.

---

## Onboarding / Status da Agencia

### Comportamento atual

- `pending` mantem o usuario em `/onboarding/agency/status`.
- `rejected` mantem o usuario em `/onboarding/agency/status` e libera CTA de correcao.
- `approved` nao redireciona automaticamente para o hub.
- A entrada no hub/configuracao exige acao explicita do usuario.
- O CTA e dinamico:
  - `pending`: aguardando validacao, sem avancar;
  - `rejected`: corrigir documentacao;
  - `approved`: aceitar termos e comecar, ou entrar se ja aceitou.
- O botao de refresh consulta o banco real novamente via provider/notifier.
- A tela de status e a superficie principal para acompanhar solicitacao, documentos e proximos passos.

### Fontes de leitura

- **Fonte real no client:** `AgencyStatusNotifier` (via `AgencyStatusRepository.getAgencyStatusFull`) consulta a RPC **`get_agency_status_full`** — uma única chamada que consolida agencia + representante + documento + aceite num só registro. O app **nao** consulta as views diretamente.
- A RPC `get_agency_status_full` opera sobre o `auth.uid()` da sessao e deve consolidar, server-side, o contexto da agencia (`v_user_agency_onboarding_context`) e o status documental mais recente (`v_agency_latest_document_status`).
- `statusAgency` e `consolidatedDocumentStatus` chegam ao app como campos do registro retornado pela RPC; `AgencyStatusData.fromJson` aceita variacoes de nome de coluna (ex.: `status_agency`/`agency_status`, `consolidated_document_status`/`document_status`).
- O registro da RPC deve expor os dados do representante usados no prefill, incluindo `legal_representative_id` e `representative_role`.
- O aceite de termos (`fetchAgencyTerms`/`acceptAgencyTerms`) le/escreve direto na tabela `agencies`, filtrando por `id` + `user_uuid`.
- `UserFlowState.isOnboardingComplete` foi removido. O fluxo de agencia nao decide acesso por string de `agency_status`.

---

## Aceite de Termos

### Estado atual

O aceite de termos e obrigatorio apos aprovacao da agencia/documentos e antes de liberar hub/menu.

- O hub/menu permanece bloqueado sem aceite.
- O modal de aceite e central, responsivo e possui area rolavel.
- O texto do modal contempla:
  - Termos de Uso;
  - Politica de Privacidade;
  - responsabilidade pelas informacoes e documentos enviados;
  - autorizacao de uso dos dados para validacao, seguranca e operacao;
  - ciencia sobre possivel inicio de cobranca conforme plano, condicoes comerciais e recursos habilitados;
  - regras operacionais, suspensao, cancelamento e tratamento de dados.
- O checkbox e obrigatorio para habilitar a acao de aceite.

### Persistencia

O aceite e persistido na agencia nos campos:

- `terms_accepted`;
- `terms_accepted_at`;
- `terms_version`.

A versao atual dos termos nao foi alterada nos ultimos ajustes.

---

## Documentos Versionados

### Regra atual

O modelo de documentos legais e insert-only. O versionamento mora em
`legal_documents`, nao em `legal_representatives`.

- O app nunca atualiza registros antigos de `legal_documents`.
- Cada envio cria nova tentativa.
- `attempt_number` e incremental por agencia.
- Novos envios entram sempre com `status = pending`.
- Rejeicoes e aprovacoes anteriores permanecem no historico.
- A view consolidada reflete a tentativa mais recente.
- `legal_representatives` e entidade mutavel: pode receber `UPDATE` para manter
  os dados atuais do representante sem duplicar cadastro.
- Upload preserva extensao real (`.jpg`, `.png`, `.pdf`) e MIME correspondente; nao ha conversao para `.webp`.

### Fluxo de correcao

Documento rejeitado -> usuario corrige -> app cria novo registro em `legal_documents` com:

- mesmo `agency_id`;
- mesmo `legal_representative_id` quando ja existe;
- novo `attempt_number`;
- `status = pending`;
- novas URLs de documento.

O registro rejeitado anterior nao e alterado.

---

## Representante Legal

### Estado atual

No fluxo inicial, se nao existe representante para a agencia:

- o app cria um registro em `legal_representatives`;
- usa o id criado para inserir `legal_documents`.

No fluxo de correcao, se ja existe representante:

- o app nao duplica `legal_representatives`;
- atualiza o representante existente com `UPDATE`;
- usa o mesmo `legalRepresentativeId` para inserir nova tentativa em `legal_documents`.

### Prefill

O prefill da tela de representante usa os campos disponiveis no status/contexto:

- nome;
- CPF;
- e-mail;
- telefone;
- cargo (`representative_role`);
- tipo de documento.

O cargo aparece no dropdown quando a view retorna valor compativel com as opcoes do app.

---

## MenuHub / Web

### Desktop

- O `MenuHubSidebar` aparece apenas em desktop.
- A `HubScreen` consome `authNotifierProvider` para nome do usuario e `agencyStatusProvider(null)` para dados/status da agencia.
- A `HubScreen` nao usa mais `userName`, `agencyName` ou status aprovados hardcoded.
- A `AgencyStatusScreen` foi adaptada para o layout web/desktop.
- A `RegionListScreen` possui sidebar desktop via `MenuHubSidebar`, layout responsivo desktop/mobile e dark mode via `EanTrackTheme`. Mesma integracao com `authNotifierProvider` e `agencyStatusProvider(null)` que o HubScreen.
- A tela de status usa grid com cards alinhados, incluindo `Dados da agencia` e `Status do documento`.
- O card "Status do documento" exibe secoes rotuladas em sequencia:
  - tag do tipo de documento (CONTRATO SOCIAL etc);
  - REPRESENTANTE LEGAL: nome + cargo;
  - CONTATO: e-mail + telefone lado a lado;
  - STATUS DA SOLICITAÇÃO: badge de status.
- Light/dark mode aplicado em HubScreen, AgencyStatusScreen, RegionListScreen e MenuHubSidebar.

### Mobile

- O paradigma mobile foi preservado.
- Sidebar nao aparece no mobile.
- O conteudo empilha naturalmente, sem Row forcado.

### Gate de acesso

O acesso ao hub/menu depende de:

- `status_agency = approved`;
- documentos aprovados na tentativa consolidada;
- `terms_accepted = true`.

Enquanto uma dessas condicoes nao estiver satisfeita, o usuario permanece no fluxo de status/onboarding.

---

## Router

### Estado atual

- O router e a unica fonte de gate para liberar agencia ao hub.
- `_hasAgencyHubAccess` define acesso de agencia usando `statusAgency`, `consolidatedDocumentStatus` e `termsAccepted`.
- Redirect para status esta correto para usuarios de agencia ainda bloqueados.
- `pending` e `rejected` nao caem em `/flow` como destino final.
- `approved` nao faz entrada automatica no hub.
- Regressao `approved -> rejected` e tratada: usuario volta a ficar bloqueado no status/correcao.
- `pageKey` e aplicado nas paginas do `GoRouter` para evitar reuso incorreto de tela/estado.
- `/flow` atua como tela de decisao e possui protecoes contra estado vazio/preso.
- Checks antigos baseados em `UserFlowState.isOnboardingComplete` e string de `agencyStatus` foram removidos.
- `RouterRedirectGuard` expoe metodo `refresh()` como alias semantico de `notifyListeners()`; `appRouterProvider` usa `guard.refresh()` ao reagir a mudancas do `agencyStatusProvider`.

### Regra de liberacao

O router considera a combinacao dos estados da agencia, documento e aceite. `approved` isolado nao basta.

Nao existe mais gate duplicado em `UserFlowState`; usuarios de agencia passam pelo status/router, e usuarios individuais continuam usando perfil completo como regra propria.

---

## Auth — Remember Me, Google e Fallback de /flow

### Remember Me / Lembrar-me (pronto)

- Preferencia `keep_connected` controla a restauracao de sessao entre aberturas do app.
- Card de "Conta salva" no login exibe e-mail + nome salvos localmente (somente cache de UX, **nunca** credenciais); "Trocar" limpa so o cache local.
- No logout: com `keep_connected = true`, e-mail e nome salvos sao preservados para o proximo login; com `false`, sao limpos.
- O prompt de "manter conectado" e mostrado no maximo uma vez por `userId`/dispositivo.
- Documentacao detalhada: `docs/architecture/remember_me.md`.

### Google OAuth (implementado, caminho feliz)

- Botao "Entrar com Google" no login chama `signInWithGoogle` (Supabase OAuth).
- A transicao para `AuthAuthenticated` apos o callback e tratada por `onExternalAuthChange` (listener do stream).
- Pendencia conhecida: tratamento de colisao/duplicacao de conta (e-mail ja cadastrado por senha vs. Google) ainda nao implementado.

### Fallback seguro em /flow (pronto)

- `/flow` e a unica rota que o router nunca redireciona; e o gateway de auth de toda rota protegida.
- Timer de seguranca de 10s: sem sessao -> login direto; com sessao mas contexto nao confirmado -> revalida 1x -> se ainda assim falhar, exibe `AuthFallbackScreen` ("Tentar novamente" / "Voltar para login").
- `AuthError` confirmado (ex.: falha real em `getUserFlowState`, agora propagada) leva ao fallback em vez de empurrar o usuario para o onboarding.

---

## Banco / Supabase

### RPC / Views

- `get_agency_status_full` — **RPC efetivamente consumida pelo app** para status da agencia. Sem parametros (usa `auth.uid()`); retorna um registro consolidado (agencia + representante + documento + aceite). Ver BACKEND_SCHEMA.md.
- `get_user_onboarding_route` considera `terms_accepted` antes de devolver rota de hub.
- `v_user_agency_onboarding_context` expoe o contexto de onboarding da agencia e deve incluir `legal_representative_id` e `representative_role`. Usada server-side pela RPC `get_agency_status_full`.
- `v_agency_latest_document_status` representa a tentativa documental mais recente/consolidada. Usada server-side pela RPC `get_agency_status_full`.

### RLS e seguranca

Estado esperado das regras:

- usuario pode inserir documentos apenas como `pending`;
- usuario nao altera status final de documento;
- aceite de termos e permitido mesmo com agencia `approved`;
- updates criticos de `status_agency` sao protegidos por trigger;
- status final de documentos e controlado por sistema/admin, nao pelo client.

Sem alteracao recente de policies, estrutura de tabela ou backend nesta atualizacao de documentacao.

---

## Testes / Validacao

Nesta rodada de documentacao:

- nao foi alterado codigo;
- nao foi alterado banco;
- nao foram executados `flutter analyze`, `dart format` ou `flutter test`.

Observacao operacional: comandos globais de analyze/format/test continuam evitados quando a task solicita explicitamente nao executar.

---

## Divergencias Conhecidas

Nenhuma divergencia conhecida no fluxo documentado de agencia/status/aceite/documentos.

Agencia e documento sao conceitos separados, lidos de fontes distintas e combinados apenas no gate do router.

---

## Pontos de Verificacao para Auditoria Global

- Verificar no Supabase se `v_user_agency_onboarding_context` expoe `legal_representative_id` e `representative_role`.
- Verificar se RLS de `legal_documents` aceita insert com `status = pending` e bloqueia status final vindo do usuario.
- Verificar se `get_user_onboarding_route` nao libera hub sem `terms_accepted`.
- Verificar se a view de status consolidado ordena pela tentativa correta, preferencialmente por `attempt_number` e/ou data.
- Verificar se rollback do fluxo inicial nao apaga historico no fluxo de correcao.
