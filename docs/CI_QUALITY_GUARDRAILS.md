# CI Quality Guardrails — EANTrack

> Regras de engenharia obrigatórias. Não há exceção.

---

## REGRA PRINCIPAL

Nenhum commit relevante pode ser entregue com:

- `flutter analyze` com erros
- `flutter test` falhando

---

## FLUXO OBRIGATÓRIO ANTES DE COMMIT

```
1. flutter analyze
2. flutter test
```

Se qualquer um falhar:

1. **parar**
2. **corrigir**
3. **não empilhar mudanças**
4. revalidar do zero

---

## PROIBIÇÕES EXPLÍCITAS

- Corrigir múltiplos blocos de código sem validar entre eles
- Alterar testes sem entender o comportamento real do código
- Usar mocks complexos desnecessários (ex: `FakePostgrestBuilder` com `Future`)
- Ignorar erro do `flutter analyze` — zero tolerância
- Commitar código "para testar no CI" — CI não é sandbox

---

## ORDEM OBRIGATÓRIA DE CORREÇÃO

Quando houver falhas, corrigir nesta ordem:

```
1. Compile errors
2. Analyze errors
3. Test failures
4. Warnings
5. Feature
```

Nunca pular etapas. Nunca corrigir feature antes de testes.

---

## TEMPLATE DE FINALIZAÇÃO DE TASK

Toda task entregue deve incluir este bloco:

```
STATUS:
- ANALYZE: limpo / com warnings
- TESTS: passando / falhando
- RISCO: baixo / médio / alto
- ARQUIVOS ALTERADOS: lista
```

---

## REGRA DE SEGURANÇA

Se houver conflito entre corrigir um teste e alterar código de produção:

> **Priorizar manter o comportamento real.**
> Testes devem refletir o app — não o contrário.

---

## NOTA OPERACIONAL

O ambiente atual apresenta instabilidade ao rodar comandos pesados de validação.
Ver `AGENTS.md` → seção **REGRA OPERACIONAL CRÍTICA** para detalhes sobre execução local.
O desenvolvedor valida manualmente após cada entrega.
