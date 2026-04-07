# Password History — Implementação e Diagnóstico

## Objetivo

Impedir que o usuário:

- reutilize a senha atual
- reutilize qualquer uma das últimas N senhas (default: 3)

---

## Arquitetura

Fluxo **obrigatoriamente linear**:

```
1. check_password_reuse_current_user  (RPC)
2. updateUser                          (Supabase Auth)
3. register_password_history_current_user (RPC)
4. logout
```

Implementado em `lib/features/auth/data/auth_repository.dart` → método `changePassword`.

---

## Regras de negócio

### Senha igual à atual

- Detectado via Supabase Auth (422 / same_password)
- Exceção: `SamePasswordException`
- Mensagem: "A nova senha deve ser diferente da atual."

### Senha já utilizada (histórico)

- Detectado via RPC `check_password_reuse_current_user`
- Retorno da RPC: `{ "allowed": false, "reason": "PASSWORD_REUSED" }`
- Exceção: `PasswordReusedException`
- Mensagem: "Você já usou essa senha antes. Escolha uma diferente."

### Senha válida

Fluxo continua normalmente pelos 3 passos.

---

## RPCs

### check_password_reuse_current_user

```json
params: { "p_new_password": "string", "p_history_limit": 3 }
return: { "allowed": bool, "reason": string | null }
```

### register_password_history_current_user

```json
params: { "p_password": "string", "p_keep_last": 3 }
```

---

## Exceções

| Exceção | Causa | Mensagem |
|---|---|---|
| `SamePasswordException` | 422 do Supabase Auth | "A nova senha deve ser diferente da atual." |
| `PasswordReusedException` | RPC retorna `allowed: false` | "Você já usou essa senha antes. Escolha uma diferente." |
| `PasswordReuseCheckException` | Falha na RPC de check | "Não foi possível validar sua nova senha. Tente novamente." |
| `PasswordHistoryRegisterException` | Falha na RPC de register | "Não foi possível registrar o histórico da senha." |

---

## Lições críticas (bugs reais enfrentados)

### ERRO 1 — RPC não era chamada

- **Causa:** fluxo fragmentado com 3 métodos separados + estado interno `_passwordPendingHistoryRegistration`
- **Correção:** fluxo unificado em método único `changePassword`

### ERRO 2 — Parâmetro errado no register

```dart
'p_new_password'  // ERRADO
'p_password'      // CORRETO
```

### ERRO 3 — Parse incorreto da RPC

- **Problema:** RPC pode retornar `bool`, `num`, `String`, `Map`, `List` ou `null`
- **Correção:** `PasswordReuseCheckResult.fromRpcResponse` em `password_reuse_parser.dart` com parser robusto para todos os tipos

### ERRO 4 — Diagnóstico enganoso

- **Sintoma:** RPC não aparecia no log do Supabase
- **Causa real:** a função nem era chamada (fluxo quebrado antes)
- **Lição:** sempre perguntar "a função foi chamada?" antes de investigar a RPC

### ERRO 5 — Método duplicado

- **Causa:** existia `_legacyChangePasswordFlowV2` no repositório que interceptava o fluxo
- **Correção:** remoção do método duplicado

---

## Estratégia de debug

**Regra 1** — Validar RPC isoladamente antes de integrar (botão de teste foi essencial)

**Regra 2** — Log por etapa obrigatório:
```
STEP 1 - check
STEP 2 - update
STEP 3 - register
```

**Regra 3** — Nunca confiar no "não apareceu no log" sem confirmar que o código chegou até aquela linha

**Regra 4** — Nunca usar estado mutável intermediário para fluxo crítico
```dart
// ERRADO
_passwordPendingHistoryRegistration = newPassword;

// CORRETO
await registerRpc(newPassword);  // passar por parâmetro no mesmo fluxo
```

---

## Arquivos relevantes

| Arquivo | Papel |
|---|---|
| `lib/features/auth/data/auth_repository.dart` | `changePassword`, `_isSamePasswordError` |
| `lib/features/auth/data/password_history_service.dart` | `ensureNewPasswordCanBeUsed`, `registerPasswordHistory` |
| `lib/features/auth/data/password_reuse_parser.dart` | `PasswordReuseCheckResult.fromRpcResponse` — parser defensivo |
| `lib/features/auth/presentation/screens/update_password_screen.dart` | Tela que chama `authRepositoryProvider.changePassword` |
| `lib/core/error/app_exception.dart` | Definição das exceções |
