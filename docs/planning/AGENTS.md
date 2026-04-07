# AGENTS.md — EANTrack

> Regras de execução para o Codex. Ler antes de implementar qualquer task.

---

## PAPEL DO AGENTE

Executor técnico. Implementa tarefas definidas. **Não decide arquitetura.**

---

## REGRA DE OURO

Antes de escrever código:

1. Existe padrão no projeto? → **usar padrão existente**
2. Existe widget/util pronto? → **reutilizar**
3. Existe forma mais simples? → **usar a mais simples**

---

## CONTEXTO OBRIGATÓRIO

Ler antes de implementar:

| Arquivo | Quando |
|---------|--------|
| `/docs/planning/CURRENT_STATE.md` | Sempre — estado atual |
| `/docs/design/DESIGN_SYSTEM.md` | Sempre — tokens visuais |
| `/docs/engineering/GLOBAL_PATTERNS.md` | Sempre — padrões de state, forms, erros |
| `/docs/product/SCREEN_SPECS.md` | Ao implementar tela |
| `/docs/auth/AUTH_FLOW.md` | Ao tocar em auth/router |
| `/docs/architecture/BACKEND_SCHEMA.md` | Ao integrar com Supabase |

---

## PADRÃO DE TELA

### Telas Auth / Onboarding — usar `AuthScaffold`

```dart
import '../../../shared/shared.dart'; // barrel único

class MyScreen extends ConsumerStatefulWidget { ... }

class _MyScreenState extends ConsumerState<MyScreen>
    with FormStateMixin<MyScreen> {

  AsyncAction<void> _action = const ActionIdle();

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Título da tela',
      subtitle: 'Subtítulo opcional',
      isLoading: _action.isLoading,
      child: Column(
        children: [
          if (_action.isFailure) AppErrorBox(_action.errorMessage!),
          AppTextField(label: 'E-mail', validator: emailValidator),
          AppButton.primary('Avançar', onPressed: _action.isLoading ? null : _submit),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!validateAndSubmit()) return; // seta submitted + valida
    setState(() => _action = const ActionLoading());
    try {
      await ref.read(myProvider.notifier).doSomething();
      setState(() => _action = const ActionSuccess(null));
    } catch (e) {
      setState(() => _action = ActionFailure(e.toString()));
    }
  }
}
```

### Telas internas (Hub, listas) — usar `Scaffold` direto

```dart
Scaffold(
  backgroundColor: AppColors.primaryBackground,
  body: ...,
)
```

### Formulários — `FormStateMixin` obrigatório (não reinventar `_submitted` manualmente)

`FormStateMixin` já fornece: `formKey`, `submitted`, `validateAndSubmit()`, `emailValidator`, `passwordValidator`, `confirmValidator`, `requiredValidator`, `onPasswordChanged`, `onConfirmChanged`.

---

## TAMANHO DE CÓDIGO

- Screen: ≤ **200 linhas** (extrair widgets privados `_NomeWidget` no mesmo arquivo se ultrapassar)
- Widget reutilizável: ≤ 150 linhas
- Repository: ≤ 150 linhas
- Notifier: ≤ 100 linhas

---

## PRINCÍPIOS

- Código deve ser **pequeno, legível e previsível**
- Evitar abstrações desnecessárias
- Evitar duplicação
- Preferir clareza a reutilização precoce

---

## PROIBIDO

- Criar novos padrões sem instrução explícita
- Criar helpers genéricos para uso único
- Usar `AutovalidateMode` (qualquer variante) em formulários
- Usar hexadecimais inline — sempre `AppColors.*`
- Usar `AppSpacing.*` para border radius — sempre `AppRadius.*`
- Usar `CupertinoIcons`, `FontAwesomeIcons` — somente `Icons.*`
- Chamar Supabase fora de Repository
- Navegar dentro de Repository ou Notifier
- Usar path literal de rota — sempre `AppRoutes.*`
- Alterar arquitetura
- Refatorar partes não solicitadas
- Executar: `flutter analyze`, `flutter test`, `dart format`

---

## SEGURANÇA

- Nunca logar email, senha ou JWT
- Nunca hardcodar `SUPABASE_URL` ou `SUPABASE_ANON_KEY`
- Erros Supabase sempre mapeados para PT-BR antes de chegar na UI
- Validar input no submit, não no onChange (exceto feedback positivo)

---

## FORMATO DE RESPOSTA

- Código em inglês
- Comentários/explicações em PT-BR (apenas quando necessário)
- Sem sumário ao final — o código já é a entrega
- Máximo 3 arquivos por task (DEC-011)

## REGRA OPERACIONAL CRÍTICA — NÃO EXECUTAR COMANDOS PESADOS

O ambiente atual apresenta travamento/instabilidade ao executar comandos locais pesados de validação.

### PROIBIDO EXECUTAR SEM AUTORIZAÇÃO EXPLÍCITA
NÃO executar automaticamente:
- `dart format`
- `flutter format`
- `flutter analyze`
- `flutter test`
- `flutter pub get`
- `flutter build`
- qualquer comando de validação global ou demorado

### REGRA
O agente deve:
1. implementar apenas as alterações solicitadas
2. informar quais arquivos foram alterados
3. descrever objetivamente o que foi feito
4. encerrar a entrega SEM rodar validações locais automáticas

### EXCEÇÃO
Só executar qualquer comando se o usuário pedir explicitamente no prompt atual.

Exemplos de autorização explícita:
- "rode o analyze"
- "pode executar os testes"
- "pode formatar"
- "valide localmente"

Se não houver autorização explícita, assumir sempre:
**NÃO RODAR NENHUM COMANDO.**

### FORMATO DE ENTREGA ESPERADO
Ao finalizar uma task, responder apenas com:
- arquivos alterados
- resumo objetivo da implementação
- possíveis pontos de atenção
- confirmação de que NÃO executou comandos locais

### OBJETIVO
Preservar fluidez, evitar travamentos e impedir loops improdutivos no ambiente.