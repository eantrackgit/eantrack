# ✅ CONCLUÍDA — TASK-QA-001: Logging no catch de AgencyStatusNotifier
> Aplicada no commit `ca892e1 fix(audit)`. Verificada em auditoria 2026-04-23.

NUNCA execute dart format, dart analyze, flutter test, flutter run
## CONTEXTO

`AgencyStatusNotifier.load()` tem um bloco `on Exception` que engole a exceção
silenciosamente sem logar. Viola CODE_RULES regra 16:
> "Catch não pode ser vazio — deve logar com debugPrint."

O bloco atual (linha ~220):
```dart
} on Exception {
  state = state.copyWith(
    status: AgencyStatusLoading.error,
    error: _kLoadErrorMsg,
  );
}
```

## OBJETIVO

Adicionar `catch (e)` e `debugPrint` ao bloco de exceção, sem alterar mais nada.

## ARQUIVO

`lib/features/onboarding/agency/controllers/agency_status_notifier.dart`

## ALTERAÇÃO EXATA

Substituir:
```dart
    } on Exception {
      state = state.copyWith(
        status: AgencyStatusLoading.error,
        error: _kLoadErrorMsg,
      );
    }
```

Por:
```dart
    } on Exception catch (e) {
      debugPrint('[AgencyStatus] Erro ao carregar status: $e');
      state = state.copyWith(
        status: AgencyStatusLoading.error,
        error: _kLoadErrorMsg,
      );
    }
```

Verificar que `debugPrint` está disponível — ele vem de `package:flutter/material.dart`
que já está importado no arquivo.

## ENTREGA ESPERADA

- `on Exception catch (e)` com log antes do `copyWith`
- Comportamento do estado (`error`, `_kLoadErrorMsg`) inalterado
- Nenhuma outra linha alterada

## NÃO FAZER

- Não mudar a mensagem de erro `_kLoadErrorMsg`
- Não adicionar imports
- Não alterar outros métodos do notifier
- Não alterar o arquivo de provider/factory no mesmo arquivo
