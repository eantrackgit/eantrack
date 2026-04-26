# LEGAL_DOCUMENTS_VERSIONING.md — EANTrack

> Modelo de documentos legais versionados.
> Fonte de verdade para o fluxo de envio, rejeição, correção e aprovação de representantes legais de agências.
> Decisão arquitetural registrada em DEC-025.

---

## 1. Visão Geral

O sistema adota um modelo **não-destrutivo** para documentos legais: cada envio cria um novo registro histórico, nenhum documento é apagado ou sobrescrito, e o status consolidado é sempre calculado no backend via views — nunca no app.

Contexto operacional:
- 1 agência possui 1 representante legal por processo de aprovação
- A aprovação é uma jornada iterativa: o documento pode ser rejeitado e resubmetido N vezes
- O histórico completo de todas as tentativas é preservado para fins de auditoria e rastreabilidade

---

## 2. Modelo de Dados

### Tabela: `legal_representatives`

Armazena os dados cadastrais do representante legal. Um novo registro é criado a cada nova tentativa de envio — não existe atualização do registro anterior.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid | PK gerado pelo banco |
| `agency_id` | uuid | FK para `agencies` — obrigatório |
| `user_id` | uuid | FK para `auth.users` — usuário autenticado que fez o envio |
| `full_name` | text | Nome completo do representante |
| `email` | text | E-mail de contato |
| `phone` | text | Telefone somente dígitos |
| `role` | text | Cargo declarado (Sócio, Diretor, Administrador, Procurador, Outro) |
| `cpf` | text | CPF somente dígitos |
| `created_at` | timestamptz | Criado em |
| `updated_at` | timestamptz | Atualizado em |

---

### Tabela: `legal_documents`

Armazena os documentos vinculados ao representante legal. Cada linha representa uma tentativa imutável de envio.

| Campo | Tipo | Descrição |
|-------|------|-----------|
| `id` | uuid | PK gerado pelo banco |
| `agency_id` | uuid | FK para `agencies` — obrigatório |
| `legal_representative_id` | uuid | FK para `legal_representatives` |
| `document_type` | text | Tipo: `RG` \| `CNH` \| `CONTRATO SOCIAL` |
| `front_url` | text | URL pública do arquivo frente (ou único para Contrato Social) |
| `back_url` | text | URL pública do arquivo verso — nullable (ausente para Contrato Social) |
| `status` | text | `pending` \| `approved` \| `rejected` — **DEFAULT: `pending`** |
| `attempt_number` | integer | Número sequencial da tentativa, escopado por `agency_id` |
| `rejection_reason` | text | Motivo da rejeição — nullable; preenchido pelo admin no painel externo |
| `created_at` | timestamptz | Criado em |
| `updated_at` | timestamptz | Atualizado em |

**Constraint de unicidade:**
```sql
UNIQUE (agency_id, document_type, attempt_number)
```

**Invariantes:**
- O app Flutter nunca executa `UPDATE` nesta tabela
- O app Flutter nunca executa `DELETE` nesta tabela (exceto rollback de falha parcial na mesma tentativa de envio)
- `status` parte sempre como `pending` via DEFAULT do banco — o app não envia o campo no INSERT
- `rejection_reason` é preenchido exclusivamente pelo admin via painel externo

---

## 3. Versionamento

### Regra do attempt_number

O `attempt_number` é um contador sequencial por agência:

- Primeira tentativa: `attempt_number = 1`
- Cada nova correção ou reenvio: `attempt_number = MAX(attempt_number para agency_id) + 1`
- Nunca reutiliza um número anterior
- Nunca pula números (sequência contínua)

### Como o app calcula o próximo attempt

```
_nextAttemptNumber(agencyId):
  SELECT attempt_number
  FROM legal_documents
  WHERE agency_id = {agencyId}
  ORDER BY attempt_number DESC
  LIMIT 1
  → retorna resultado + 1
  → retorna 1 se nenhum registro existir
```

Essa operação é read-then-increment sem garantia atômica. Em uso normal (onboarding single-user) não há risco de colisão. A constraint `UNIQUE (agency_id, document_type, attempt_number)` no banco é a proteção final contra duplicidade em casos excepcionais.

### Organização no Storage

**Bucket:** `doc_legal_representatives`

**Padrão de path:**
```
{agencyId}/{representativeId}/attempt_{n}/front.webp
{agencyId}/{representativeId}/attempt_{n}/back.webp
```

Como cada tentativa insere um novo `legal_representatives` com ID único, o `representativeId` muda a cada tentativa, garantindo que os paths nunca colidam. Arquivos de tentativas anteriores permanecem acessíveis indefinidamente.

**Exemplo de estrutura real:**
```
doc_legal_representatives/
  agency-uuid-abc/
    rep-uuid-001/           ← tentativa 1
      attempt_1/
        front.webp
        back.webp
    rep-uuid-002/           ← tentativa 2 (após rejeição)
      attempt_2/
        front.webp
        back.webp
```

---

## 4. Views de Status

### `v_latest_legal_documents`

Retorna a **última tentativa** por `(agency_id, document_type)`.

**Uso no app:** detalhamento interno, debug, painéis administrativos.

**Lógica:** para cada combinação `(agency_id, document_type)`, retorna somente o registro com o maior `attempt_number`.

---

### `v_agency_latest_document_status`

Consolida o **status da agência** a partir da última tentativa disponível.

**Uso no app:** único ponto de leitura de status para `AgencyStatusScreen` e `AgencyStatusNotifier`.

**Regra de consolidação por agência:**

| Condição | Status retornado |
|----------|-----------------|
| Qualquer documento da última tentativa está `rejected` | `rejected` |
| Todos os documentos da última tentativa estão `approved` | `approved` |
| Demais casos | `pending` |

**Campos relevantes retornados:**
- `agency_id`
- `consolidated_document_status` (`pending` \| `approved` \| `rejected`)
- `rejection_reason` — nullable; presente apenas quando `consolidated_document_status = rejected`
- `document_type`, `attempt_number`
- Metadados do representante (nome, email, telefone, CPF)

---

## 5. Uso no App

### Regra fundamental

> O app **não consulta `legal_documents` diretamente** para exibir status ao usuário.

Toda leitura de status passa pelas views. Essa regra centraliza a lógica de consolidação no backend e garante consistência independente da versão do app instalada.

**Mapeamento de consultas:**

| Finalidade | Fonte de dados |
|------------|----------------|
| Tela de status — usuário final | `v_agency_latest_document_status` |
| Contexto geral da agência (nome, região) | `v_user_agency_onboarding_context` |
| Detalhes / debug / admin | `v_latest_legal_documents` |
| Novo envio de documento | `INSERT` em `legal_documents` (nunca `UPDATE`) |

### Fluxo do AgencyStatusNotifier

```
load():
  1. GET v_user_agency_onboarding_context WHERE user_id = {uid}
     → extrai agency_id, dados da agência, dados do representante

  2. GET v_agency_latest_document_status WHERE agency_id = {id}
     → consolidated_document_status, rejection_reason (se rejected)

  3. Mescla os dois objetos em AgencyStatusData
     → único modelo consumido pela UI
```

Se `v_agency_latest_document_status` não retornar registro (nenhum documento enviado ainda), o notifier usa fallback `{ consolidated_document_status: 'pending', rejection_reason: null }`.

---

## 6. Fluxo Completo

### Cenário de uso padrão

```
ENVIO INICIAL
├── INSERT legal_representatives → gera representativeId (novo UUID)
├── _nextAttemptNumber: MAX = 0 → attempt_number = 1
├── Upload: {agencyId}/{representativeId}/attempt_1/front.webp [+ back.webp]
├── INSERT legal_documents: attempt_number=1, status=DEFAULT(pending)
└── UI: v_agency_latest_document_status → pending

REJEIÇÃO (admin no painel externo)
├── UPDATE legal_documents SET status='rejected', rejection_reason='Documento ilegível'
│   WHERE agency_id=X AND attempt_number=1
└── UI: v_agency_latest_document_status → rejected + motivo exibido

CORREÇÃO (usuário clica "Corrigir documentação")
├── INSERT legal_representatives → gera novo representativeId
├── _nextAttemptNumber: MAX = 1 → attempt_number = 2
├── Upload: {agencyId}/{novo_representativeId}/attempt_2/front.webp
├── INSERT legal_documents: attempt_number=2, status=DEFAULT(pending)
│   (tentativa 1 permanece intacta no banco e no storage)
└── UI: v_agency_latest_document_status → pending (attempt_number=2)
    rejection_reason da tentativa 1 NÃO aparece

APROVAÇÃO (admin no painel externo)
├── UPDATE legal_documents SET status='approved'
│   WHERE agency_id=X AND attempt_number=2
└── UI: v_agency_latest_document_status → approved
    CTA: "Continuar para configuração" → AppRoutes.hub
```

### Invariantes do fluxo

- A tentativa anterior (attempt_number=1) permanece intacta no banco e no storage
- A UI sempre considera o status da **última** tentativa via view
- `rejection_reason` de uma tentativa rejeitada nunca aparece quando há tentativa posterior
- O agencyId é validado no controller antes de qualquer operação — submit é bloqueado se vazio

---

## 7. Regras de Negócio

| Regra | Detalhe |
|-------|---------|
| Documentos não são apagados | Exceto: rollback automático de falha parcial na mesma tentativa de envio (ver abaixo) |
| Sem UPDATE de documento pelo app | `status` e `rejection_reason` são gerenciados exclusivamente pelo backend/admin |
| Status nunca calculado no frontend | Toda consolidação é responsabilidade das views |
| attempt_number sempre incremental | Sem reutilização, sem salto |
| agencyId obrigatório | Controller bloqueia submit se `agencyId.isEmpty` |
| status padrão = pending | Garantido pelo `DEFAULT` da coluna no banco |
| rejection_reason condicional na UI | Exibido apenas se `consolidatedDocumentStatus == rejected` |

### Rollback de falha parcial

Se o upload do arquivo frente tiver sucesso mas o upload do verso ou o INSERT em `legal_documents` falhar, o service executa rollback:
1. DELETE em `legal_documents` WHERE `legal_representative_id = {id}` (apenas o registro recém-criado)
2. DELETE em `legal_representatives` WHERE `id = {id}` (apenas o registro recém-criado)

Arquivos já enviados ao storage **não são removidos** no rollback — podem ficar como orphãos. A próxima tentativa gerará um novo `representativeId` e paths distintos, sem interferência.

---

## 8. Decisões Arquiteturais

### Por que versionamento e não overwrite?

**Auditoria e rastreabilidade.** Cada tentativa é um registro histórico independente. Em processos regulatórios ou disputas, é possível apresentar exatamente quais documentos foram enviados, em qual data e com qual resultado. Sobrescrever destruiria essa evidência.

### Por que views e não lógica no app?

**Centralização e consistência.** A lógica "qual é o status atual da agência?" envolve múltiplas tentativas, múltiplos documentos e regras de consolidação. Implementar no app criaria risco de divergência entre versões instaladas. Na view, a regra é definida uma vez e é idêntica para todos os consumidores: app Flutter, admin panel, RPCs internas.

### Por que não usar UPDATE em legal_documents?

**Integridade do histórico.** Um modelo insert-only garante que cada linha é imutável após a criação — somente o admin pode alterar `status` via painel externo, e isso é rastreado pelo `updated_at`. Nunca há ambiguidade sobre o que foi enviado originalmente versus o que foi alterado posteriormente.

### Por que separar legal_representatives de legal_documents?

**Normalização e extensibilidade.** Um representante pode ter múltiplos tipos de documento (RG + Contrato Social, por exemplo). A separação permite que cada documento tenha seu próprio ciclo de vida — status, tentativas, rejection_reason — sem duplicar os dados cadastrais do representante. A tabela `legal_documents` escala para múltiplos documentos obrigatórios sem alteração de schema.
