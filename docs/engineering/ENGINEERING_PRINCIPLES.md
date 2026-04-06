# ENGINEERING_PRINCIPLES.md — EANTrack

> Princípios de alto nível. Não são regras de código (ver CODE_RULES.md) — são decisões de arquitetura que guiam como o projeto é construído e evoluído.

---

## 1. RPC como camada principal de negócio

Toda lógica de negócio que envolve dados persiste via RPC no banco, não no frontend.

- Validações complexas (ex: histórico de senha, unicidade de email) → RPC
- Operações que precisam de atomicidade → RPC ou função SQL
- O frontend é responsável por UX — não por invariantes de negócio

**Regra:** se a lógica precisa ser confiável, ela fica no banco.

---

## 2. Segurança por padrão

- Todas as tabelas têm RLS habilitado
- RPCs que acessam dados do usuário usam `auth.uid()` internamente com `SECURITY DEFINER`
- O cliente nunca passa `user_id` como parâmetro — o banco extrai do JWT
- Secrets via `dart-define` — jamais hardcoded

**Referência:** CODE_RULES.md seção 7.

---

## 3. Erros são responsabilidade do repositório

- Repository captura exceções raw (AuthException, PostgrestException) e lança `AppException`
- Notifier recebe `AppException` e seta estado de erro
- Widget lê mensagem do estado — nunca do erro raw

A UI nunca sabe que existe Supabase. Ela só conhece `AppException`.

**Referência:** GLOBAL_PATTERNS.md seção 7.

---

## 4. Fluxos críticos são lineares e atômicos

Fluxos com múltiplos passos dependentes (ex: validar → atualizar → registrar) devem ser implementados em um único método, sequencialmente, sem estado intermediário.

```
// CORRETO
Future<void> changePassword(newPassword) async {
  await step1_check(newPassword);
  await step2_update(newPassword);
  await step3_register(newPassword);
}

// ERRADO — estado intermediário entre passos
_pendingPassword = newPassword;
await step1_check();
// ... (outro método depois)
await step3_register();
```

**Por quê:** estado intermediário quebra silenciosamente quando o fluxo é interrompido no meio.

**Referência:** docs/engineering/claude_guideline_critical_flows.md

---

## 5. Nunca assumir — sempre validar

Antes de integrar qualquer componente externo (RPC, API, serviço):

1. Validar isoladamente (botão de teste, chamada direta)
2. Confirmar parâmetros e formato de retorno
3. Só então integrar no fluxo

**Regra de ouro:** "Se não apareceu no log, pode ser que nunca foi chamado — não que falhou."

**Referência:** docs/engineering/claude_guideline_critical_flows.md

---

## 6. Sem soluções improvisadas no frontend

Proibido implementar no Flutter o que deveria estar no banco:

- Verificar unicidade de dados → RPC
- Calcular agregados → query ou RPC
- Aplicar regras de negócio sensíveis → banco com RLS

**Exceção:** validação de UX (campos obrigatórios, formato de email) pode ficar no frontend — mas não substitui a validação no banco.

---

## 7. Política de mudanças

- Nenhum arquivo de código é alterado sem task explícita
- Refatoração oportunista ("enquanto estou aqui...") é proibida
- Cada task tem escopo declarado — o que não está no escopo não é tocado
- Mudanças de documentação não afetam código e vice-versa

---

## 8. Parse defensivo de respostas externas

Respostas de RPC, APIs externas e Supabase podem chegar em formatos inesperados.

Todo parser deve aceitar múltiplos tipos:

```dart
// bool nativo
if (result is bool) return result;

// string "true"/"false"
if (result is String) return result.toLowerCase() == 'true';

// map com campo "allowed"
if (result is Map) return result['allowed'] == true;

// null → fallback seguro
if (result == null) return defaultValue;
```

**Nunca** lançar exceção em tipo inesperado em parser de resposta — retornar fallback seguro e logar.

---

## 9. Separação de responsabilidades

```
UI (Screen/Widget)   → layout, leitura de estado, callbacks
Notifier             → orquestração de ações, gerenciamento de estado
Repository           → chamadas externas (Supabase), mapeia para AppException
Domain               → modelos imutáveis, lógica pura sem I/O
Shared               → componentes visuais sem estado de negócio
```

Violações diretas (chamada Supabase em widget, lógica de negócio em build) são proibidas.

**Referência:** CODE_RULES.md seção 2.

---

## 10. Documentação é parte do entregável

Decisões de arquitetura, padrões de debug, estratégias não óbvias → documentar em `docs/`.

O código explica o **o quê**. A documentação explica o **por quê**.
