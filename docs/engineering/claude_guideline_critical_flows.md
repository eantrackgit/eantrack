# CLAUDE_GUIDELINE — Diagnóstico e Implementação de Fluxos Críticos

## O que não fazer

* Não fragmentar fluxo crítico em múltiplos métodos
* Não usar estado intermediário (variáveis de instância)
* Não assumir que erro está no backend sem validar chamada
* Não confiar apenas em logs de API
* Não implementar RPC sem validar isoladamente

---

## O que fazer

### 1. Sempre implementar fluxo linear

```
A → B → C → D
```

Nunca:

```
A → (salva estado) → B → (lê estado) → C
```

---

### 2. Sempre validar RPC isoladamente primeiro

Criar:

* botão de teste
* chamada direta
* log detalhado

---

### 3. Sempre logar cada etapa

```
STEP 1
STEP 2
STEP 3
```

---

### 4. Sempre validar parse de resposta

Aceitar:

* bool
* string ("true"/"false")
* map
* list

---

### 5. Sempre tratar erro técnico separado de regra de negócio

Exemplo:

* regra: senha reutilizada
* técnico: RPC falhou

---

### 6. Sempre suspeitar do fluxo antes do backend

Perguntas obrigatórias:

* essa função está sendo chamada?
* esse trecho está sendo executado?
* tem return antes?
* tem exceção silenciosa?

---

## Regra de ouro

> "Se não apareceu no log, pode ser que nunca foi chamado — não que falhou."

---

## Padrão de debug oficial

1. validar chamada isolada
2. validar sessão
3. validar parâmetros
4. validar parse
5. integrar no fluxo

Nunca pular etapas.

---

## Filosofia

> Primeiro provar que funciona. Depois integrar. Nunca o contrário.
