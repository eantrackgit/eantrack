# LEGAL_DOCUMENTS_VERSIONING.md - EANTrack

> Modelo de documentos legais versionados.
> Fonte de verdade para envio, rejeicao, correcao e aprovacao de documentos de representantes legais.
> Decisao arquitetural: DEC-025.

---

## 1. Visao Geral

O sistema separa duas responsabilidades:

- `legal_representatives`: cadastro atual do representante legal da agencia. E entidade mutavel.
- `legal_documents`: historico versionado dos documentos enviados. E entidade insert-only para o app.

Essa separacao e intencional. O representante e a identidade/cadastro atual; as tentativas de documentos sao as evidencias historicas auditaveis.

---

## 2. Tabelas

### `legal_representatives`

Armazena os dados cadastrais atuais do representante legal.

Regra atual:

- no primeiro envio, o app cria o representante;
- em correcao de documentos, se `legalRepresentativeId` ja existe, o app faz `UPDATE`;
- o representante nao e duplicado a cada tentativa;
- `updated_at` registra a atualizacao cadastral.

Campos principais:

| Campo | Papel |
|-------|-------|
| `id` | Identificador do representante usado por `legal_documents` |
| `agency_id` | Agencia vinculada |
| `user_id` | Usuario autenticado que informou/atualizou os dados |
| `full_name` | Nome atual do representante |
| `email` | E-mail atual |
| `phone` | Telefone atual |
| `role` | Cargo atual |
| `cpf` | CPF atual |

### `legal_documents`

Armazena as tentativas documentais vinculadas ao representante.

Regra atual:

- o app nunca faz `UPDATE` em registros existentes de `legal_documents`;
- cada envio cria uma nova linha;
- `attempt_number` incrementa por agencia;
- novas tentativas entram com `status = pending`;
- tentativas antigas permanecem no historico;
- status final e motivo de rejeicao sao responsabilidade de sistema/admin.

Campos principais:

| Campo | Papel |
|-------|-------|
| `id` | Identificador da tentativa documental |
| `agency_id` | Agencia vinculada |
| `legal_representative_id` | Representante atual usado na tentativa |
| `document_type` | `RG`, `CNH` ou `CONTRATO SOCIAL` |
| `front_url` | URL do arquivo frente ou arquivo unico |
| `back_url` | URL do verso quando aplicavel |
| `status` | `pending`, `approved` ou `rejected` |
| `attempt_number` | Numero sequencial da tentativa por agencia |
| `rejection_reason` | Motivo definido por admin/sistema quando rejeitado |

---

## 3. Versionamento

O versionamento acontece somente em `legal_documents`.

### Regra de `attempt_number`

- Primeira tentativa: `attempt_number = 1`.
- Nova correcao/reenvio: `MAX(attempt_number para agency_id) + 1`.
- O app nao reutiliza tentativa antiga.
- O app nao altera status de tentativa antiga.

### Correcao de documento

Documento rejeitado -> usuario corrige -> app:

1. atualiza `legal_representatives` existente, se houver `legalRepresentativeId`;
2. calcula o proximo `attempt_number`;
3. envia arquivos para storage;
4. cria nova linha em `legal_documents` com `status = pending`;
5. mantem a tentativa rejeitada anterior intacta.

---

## 4. Storage

Bucket:

```text
doc_legal_representatives
```

Padrao de path:

```text
{agencyId}/{representativeId}/attempt_{n}/front.{ext}
{agencyId}/{representativeId}/attempt_{n}/back.{ext}
```

Extensoes permitidas:

- `.jpg`
- `.png`
- `.pdf`

O app nao converte arquivos para `.webp`. A extensao no path deve bater com o conteudo real, e o upload usa o `contentType` correspondente ao arquivo selecionado.

Exemplo:

```text
doc_legal_representatives/
  agency-uuid/
    representative-uuid/
      attempt_1/
        front.jpg
        back.jpg
      attempt_2/
        front.pdf
```

Como o representante nao e duplicado no modo correcao, o `representativeId` pode permanecer o mesmo entre tentativas. A separacao por `attempt_{n}` evita colisao de paths.

---

## 5. Views

### `v_latest_legal_documents`

Retorna a tentativa mais recente por combinacao relevante de agencia/documento.

Uso:

- debug;
- painel admin;
- suporte;
- consultas internas.

### `v_agency_latest_document_status`

Consolida o status atual da agencia com base na tentativa documental mais recente.

Uso no app:

- `AgencyStatusNotifier`;
- `AgencyStatusScreen`;
- gate de acesso no router/menu.

O app nao consulta `legal_documents` diretamente para decidir status exibido ao usuario.

---

## 6. Fluxo Atual

### Envio inicial

```text
INSERT legal_representatives
_nextAttemptNumber -> 1
Upload front/back com extensao real e MIME correto
INSERT legal_documents attempt_number=1 status=pending
UI -> pending
```

### Rejeicao

```text
Admin/sistema atualiza a tentativa 1 para rejected
UI -> rejected + rejection_reason
```

### Correcao

```text
UPDATE legal_representatives existente
_nextAttemptNumber -> 2
Upload novos arquivos em attempt_2
INSERT legal_documents attempt_number=2 status=pending
Tentativa 1 permanece rejected no historico
UI -> pending
```

### Aprovacao

```text
Admin/sistema atualiza a tentativa mais recente para approved
UI -> approved
Gate final ainda exige terms_accepted
```

---

## 7. Invariantes

| Regra | Estado atual |
|-------|--------------|
| Representante e mutavel | `UPDATE` permitido em `legal_representatives` |
| Representante nao duplica em correcao | Usa `legalRepresentativeId` existente |
| Documento e versionado | Nova linha em `legal_documents` por envio |
| Documento antigo nao muda no app | Sem `UPDATE` pelo Flutter |
| Nova tentativa sempre pending | Insert envia `status = pending` |
| Historico preservado | Tentativas antigas continuam no banco/storage |
| Status final nao pertence ao client | Admin/sistema controla aprovacao/rejeicao |

---

## 8. Rollback

Rollback automatico so deve remover dados criados na mesma tentativa parcial.

No envio inicial, se o representante foi criado e a tentativa falha antes de completar, o app pode remover o representante recem-criado.

No fluxo de correcao, quando o representante ja existia, rollback nao deve apagar o representante nem historico anterior.

Arquivos ja enviados ao storage podem ficar orfaos em falha parcial; a proxima tentativa usa outro `attempt_number`, sem sobrescrever historico.

---

## 9. Decisao Arquitetural

### Por que `legal_representatives` e mutavel?

Porque representa dados cadastrais atuais. Corrigir telefone, e-mail, nome ou cargo nao deve criar uma nova identidade de representante.

### Por que `legal_documents` e insert-only?

Porque representa evidencia historica. Cada documento enviado precisa permanecer auditavel com data, status e tentativa.

### Por que nao versionar ambos?

Porque duplicaria dados pessoais e confundiria a auditoria. O historico que importa para aprovacao e o das tentativas documentais; o representante e apenas o cadastro vinculado a elas.
