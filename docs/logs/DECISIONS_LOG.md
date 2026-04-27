# DECISIONS_LOG.md - EANTrack

> Registro de decisoes arquiteturais criticas.
> Cada decisao e considerada vigente ate revisao explicita.
> Ultima atualizacao: 2026-04-26.

---

## DEC-025 - Representante mutavel, documentos versionados

**Data:** 2026-04-26

### Contexto

O fluxo de aprovacao de agencia possui duas entidades com naturezas diferentes:

- `legal_representatives`: dados cadastrais atuais do representante legal da agencia;
- `legal_documents`: evidencias historicas enviadas para validacao.

Inicialmente a documentacao tratava representante e documento como insert-only. O comportamento real do produto foi alinhado para nao duplicar representante no modo correcao.

### Decisao

`legal_representatives` e entidade mutavel:

- pode receber `UPDATE` quando o representante ja existe;
- nao deve ser duplicada em cada correcao de documento;
- representa os dados atuais do representante vinculado a agencia.

`legal_documents` e a entidade versionada:

- o app nunca faz `UPDATE` em documentos existentes;
- cada envio cria novo registro;
- `attempt_number` incrementa por agencia;
- novas tentativas entram com `status = pending`;
- tentativas anteriores permanecem como historico.

### Motivo

O representante e identidade/cadastro; o documento e evidencia historica. Versionar ambos duplicaria dados pessoais e dificultaria auditoria. Versionar apenas os documentos preserva historico sem criar representantes redundantes.

### Impacto

No envio inicial, o app cria `legal_representatives` e insere a primeira tentativa em `legal_documents`. No modo correcao, o app atualiza o representante existente e insere nova tentativa em `legal_documents` com o mesmo `legal_representative_id`.

---

## DEC-029 - Documentos legais sao versionados por tentativa

**Data:** 2026-04-26

### Contexto

O representante legal pode ter documentos rejeitados e reenviar uma versao corrigida. O sistema precisa preservar historico para auditoria e evitar perda de evidencia.

### Decisao

`legal_documents` segue modelo insert-only. `legal_representatives` nao e versionado; ele e atualizado quando ja existe.

- nunca atualizar registros antigos;
- cada envio cria novo registro;
- `attempt_number` incrementa por agencia;
- novos envios entram como `status = pending`;
- tentativas antigas permanecem no historico.

### Motivo

Auditoria, rastreabilidade e seguranca. Um documento rejeitado deve continuar existindo como evidencia historica mesmo apos correcao.

### Impacto

O app nao faz `UPDATE` em `legal_documents`. A tela de status le views consolidadas para exibir apenas a tentativa atual ao usuario, mas o banco preserva as tentativas anteriores.

---

## DEC-030 - Status final de documento nao pertence ao client

**Data:** 2026-04-26

### Contexto

O app envia documentos, mas a aprovacao/rejeicao deve ser uma decisao de sistema/admin.

### Decisao

O client pode criar nova tentativa apenas como `pending`. Status finais como `approved` e `rejected` nao sao definidos pelo Flutter.

### Motivo

Evita escalada de privilegio, fraude operacional e inconsistencias entre app, painel administrativo e banco.

### Impacto

RLS deve limitar insert de documentos a `pending`. Updates criticos sao bloqueados por policies/triggers. O app envia `status = pending` explicitamente para novas tentativas.

---

## DEC-031 - Representante legal nao e duplicado no fluxo de correcao

**Data:** 2026-04-26

### Contexto

No fluxo "Corrigir documentacao", a agencia ja possui um representante legal. Criar novo registro a cada correcao duplicaria identidade e quebraria vinculos historicos.

### Decisao

Se existe `legalRepresentativeId` no prefill/payload:

- atualizar `legal_representatives` existente;
- reutilizar esse id no novo insert de `legal_documents`.

Se nao existe id:

- criar representante normalmente;
- usar o id criado no primeiro insert de documentos.

### Motivo

O representante e uma entidade da agencia; as tentativas documentais sao o que deve ser versionado. Duplicar representante confundiria auditoria, historico e telas de gestao.

### Impacto

Correcao de documentos nao gera POST duplicado em `legal_representatives`. Apenas `legal_documents` recebe nova tentativa.

---

## DEC-032 - Status operacional da agencia e status documental sao conceitos separados

**Data:** 2026-04-26

### Contexto

O sistema possui status da agencia e status dos documentos legais. Eles podem evoluir de forma independente.

### Decisao

`agency_status` e `document_status` nao sao equivalentes.

O acesso ao hub depende da combinacao:

- agencia aprovada;
- documento consolidado aprovado;
- termos aceitos.

### Motivo

A agencia pode ter um estado operacional proprio no futuro, enquanto a documentacao legal possui ciclo de validacao e historico independente.

### Impacto

Router, MenuHub e status screen usam gate composto. Regressao documental para `rejected` volta a bloquear acesso mesmo que a agencia ja tenha estado aprovado anteriormente.

---

## DEC-033 - Aceite de termos e gate obrigatorio antes do hub

**Data:** 2026-04-26

### Contexto

A liberacao da agencia pode iniciar configuracao/uso do ambiente e futuramente cobranca conforme plano e recursos habilitados.

### Decisao

O aceite de termos e obrigatorio antes de liberar hub/menu.

O aceite e persistido diretamente na agencia:

- `terms_accepted`;
- `terms_accepted_at`;
- `terms_version`.

Nao foi criada tabela separada de historico nesta etapa.

### Motivo

Simplicidade operacional agora, sem perder o minimo necessario para compliance. A estrutura permite evoluir para historico de aceite no futuro.

### Impacto

Mesmo com agencia/documento aprovados, o usuario continua bloqueado ate aceitar os termos. O modal contem texto real com termos, privacidade, responsabilidade pelos dados e ciencia sobre cobranca.

---

## DEC-034 - Router nao usa `/flow` como destino final

**Data:** 2026-04-26

### Contexto

`/flow` e uma tela de decisao/transicao. Quando ela se torna destino final, o usuario pode ficar preso em estado vazio.

### Decisao

`/flow` nao representa estado final do usuario. O router deve redirecionar para status, onboarding, login ou hub conforme estado real.

### Motivo

Evita loops e telas vazias em reload, refresh de provider ou estados intermediarios.

### Impacto

Pending/rejected permanecem na tela de status. Approved nao entra automaticamente no hub; precisa passar pelo gate de aceite e acao explicita.

---

## DEC-035 - MenuHub web como sidebar; mobile preservado

**Data:** 2026-04-26

### Contexto

Desktop precisa de navegacao persistente e escaneavel. Mobile precisa preservar espaco e o paradigma atual de paginas.

### Decisao

No desktop/web, MenuHub aparece como sidebar. No mobile, o menu permanece no paradigma mobile.

### Motivo

Experiencias responsivas exigem layouts diferentes, nao apenas o mesmo layout espremido.

### Impacto

AgencyStatusScreen possui layout desktop proprio com cards mais densos. Mobile empilha conteudo naturalmente e nao exibe sidebar.

---

## DEC-036 - RLS e triggers protegem estados criticos

**Data:** 2026-04-26

### Contexto

O client precisa escrever dados de onboarding, mas nao pode controlar estados finais de aprovacao.

### Decisao

Estados criticos sao protegidos no banco:

- insert de documentos limitado a `pending`;
- usuario nao altera status final;
- aceite permitido mesmo com agencia aprovada;
- trigger protege `status_agency`;
- revisoes finais continuam responsabilidade de sistema/admin.

### Motivo

Seguranca e auditabilidade devem estar no backend, nao apenas na UI.

### Impacto

O app continua compativel com RLS atual: cria tentativa pending, atualiza representante quando necessario e nao altera historico documental.

---

## DEC-037 - Views sao contrato de leitura do status da agencia

**Data:** 2026-04-26

### Contexto

O app precisa mostrar status, representante e tentativa atual sem reimplementar joins/regras no Flutter.

### Decisao

As views de Supabase sao o contrato de leitura:

- `v_user_agency_onboarding_context` para contexto geral;
- `v_agency_latest_document_status` para tentativa documental consolidada.

### Motivo

Centraliza a regra de consolidacao no banco e reduz divergencia entre app, auditoria e futuros paineis internos.

### Impacto

Quando a view muda, revisar `AgencyStatusData.fromJson`. Campos como `representative_role` e `legal_representative_id` devem estar disponiveis para prefill e correcao.
