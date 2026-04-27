# BACKLOG.md - EANTrack

> Proximos passos apos ajustes de status, aceite, documentos versionados,
> router, UI desktop e RLS.
> Este backlog direciona produto, tecnica e compliance para auditoria global.
> Ultima atualizacao: 2026-04-26.

---

## Prioridade Imediata - Auditoria Global

### AUDIT-001 - Validar contrato das views de onboarding

Confirmar no Supabase que `v_user_agency_onboarding_context` expoe:

- `agency_id`;
- `status_agency`;
- `legal_representative_id`;
- `representative_name`;
- `representative_cpf`;
- `representative_email`;
- `representative_phone`;
- `representative_role`;
- `document_type`;
- campos de aceite.

### AUDIT-002 - Validar view da tentativa documental atual

Confirmar que `v_agency_latest_document_status` reflete sempre a tentativa mais recente por agencia, considerando:

- `attempt_number`;
- data de criacao/atualizacao;
- status da tentativa;
- motivo de rejeicao quando aplicavel.

### AUDIT-003 - Validar gate de acesso ponta a ponta

Garantir os cenarios:

- pending -> status;
- rejected -> status + correcao;
- corrected -> nova tentativa pending;
- approved sem aceite -> status + modal de aceite;
- approved com aceite -> hub/menu liberado;
- approved -> rejected -> bloqueio novamente.

---

## UX / Produto

### UX-001 - Feedback pos envio de documentos

Exibir estado claro apos reenvio:

- "Documento enviado para analise";
- status pending;
- orientacao de aguardar validacao.

### UX-002 - Timeline de tentativas de documentos

Criar visualizacao do historico:

- tentativa 1 rejected;
- tentativa 2 pending;
- tentativa 3 approved;
- datas;
- motivo de rejeicao quando existir.

### UX-003 - SLA de analise

Comunicar prazo esperado, por exemplo:

- "Analise em ate 24h";
- estado visual quando prazo estiver proximo/expirado.

### UX-004 - Central de ajuda / tutorial

Adicionar entrada "Como configurar" com:

- guia inicial da agencia;
- explicacao dos status;
- orientacao sobre documentos;
- duvidas sobre cobranca/planos.

### UX-005 - Confirmacao amigavel ao sair do status

Revisar comportamento de voltar/sair na tela de status, principalmente mobile, para evitar logout acidental ou confuso.

---

## Tecnico

### TECH-001 - Padronizar botoes responsivos

Revisar componentes que usam largura infinita dentro de `Row`.

Objetivo:

- evitar overflow;
- padronizar `Expanded`, `Flexible` e largura minima;
- manter consistencia desktop/mobile.

### TECH-002 - Revisao global light/dark

Auditar telas internas:

- Hub;
- Regioes;
- Flow;
- sidebar;
- cards de status;
- modais.

Migrar hardcoded colors restantes para tokens semanticos quando aplicavel.

### TECH-003 - Separar status operacional da agencia

Avaliar se `status_agency` deve representar:

- status cadastral;
- status operacional;
- status comercial;
- ou apenas gate administrativo.

Manter `document_status` como conceito separado.

### TECH-004 - Testes do fluxo de agencia

Adicionar cobertura focada:

- submit inicial cria representante + documento pending;
- correcao atualiza representante existente + cria nova tentativa pending;
- router bloqueia sem termos aceitos;
- status screen renderiza CTA correto por estado;
- MenuHub bloqueia/libera por gate composto.

### TECH-005 - Observabilidade do onboarding

Adicionar eventos/logs controlados para:

- envio de documento;
- correcao de documento;
- aceite de termos;
- refresh de status;
- bloqueios por gate.

---

## Compliance / Negocio

### COMP-001 - Versionamento formal de termos

Planejar evolucao de `terms_version`:

- v1;
- v2;
- v3;
- estrategia de reaceite quando houver mudanca relevante.

### COMP-002 - Historico futuro de aceite

Avaliar tabela dedicada para historico:

- agency_id;
- user_id;
- terms_version;
- accepted_at;
- ip/device/user agent quando permitido;
- texto/hash da versao aceita.

### COMP-003 - Definir evento de inicio de cobranca

Formalizar qual evento inicia cobranca:

- aprovacao da agencia;
- aceite dos termos;
- inicio de configuracao;
- primeiro uso operacional;
- ativacao de recursos pagos.

### COMP-004 - Politica de suspensao/cancelamento

Documentar como status operacional, termos e cobranca se relacionam em:

- suspensao;
- cancelamento;
- inadimplencia;
- reativacao.

---

## Produto - Pos Onboarding

### PROD-001 - Configuracao inicial da agencia

Definir primeira experiencia apos hub liberado:

- regioes;
- redes;
- categorias;
- PDVs;
- equipe;
- plano/assinatura.

### PROD-002 - Estado vazio orientado

Cada modulo inicial deve ter:

- empty state claro;
- CTA unico;
- ajuda contextual;
- indicacao de progresso da configuracao.

### PROD-003 - MenuHub com dados reais

Garantir que sidebar/hub usem dados reais de:

- usuario;
- agencia;
- status/gate;
- plano quando existir.

---

## Regras para Proximas Tasks Codex

Cada task deve:

1. alterar poucos arquivos;
2. declarar arquivos permitidos;
3. separar frontend, backend e documentacao;
4. nao alterar policies sem task explicita;
5. nao rodar `flutter analyze`, `dart format` ou testes quando a task proibir;
6. manter historico documental insert-only;
7. manter gate: agencia aprovada + documento aprovado + termos aceitos.
