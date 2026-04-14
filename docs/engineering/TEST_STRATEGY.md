# EANTrack — Test Strategy

> Documento prático. Foca no que funciona neste projeto.
> Última atualização: 2026-04-14 — adicionado padrão de controller tests, debounce e concorrência.

---

## Pirâmide de Testes

```
        [ Integration Tests ]   ← Fluxos críticos end-to-end
       [   Widget Tests    ]    ← Todas as telas (smoke + interação)
      [    Unit Tests     ]     ← Business logic, repositories, validators
```

**Cobertura atingida (2026-04-14):**
- Auth repository + providers: ✅ coberto
- Onboarding IdentifierController: ✅ coberto (~30 casos, incl. concorrência)
- Onboarding profile screen: ✅ coberto (widget)
- Regions repository: ✅ coberto
- Shared (FormStateMixin, PasswordValidator): ✅ coberto
- Hub / region_list_screen / choose_mode_screen: ❌ sem testes de UI (débito documentado)

**Meta de cobertura mínima:**
- Unit: 80% nas funções de domínio, repositórios e controllers
- Widget: 100% das telas (smoke test mínimo)
- Integration: fluxos críticos (auth, PDV, lançamento)

---

## 1. Repository Tests (Unit)

**NÃO usam Supabase real.** Foco: regra de negócio.

### Padrão de mock:
```dart
// CORRETO — resposta simples e previsível
when(() => client.from('table').select()).thenAnswer(
  (_) async => <Map<String, dynamic>>[],
);

// PROIBIDO
when(() => client.from('table').select()).thenReturn(Future.value([]));
```

### Regras:
- Mockar apenas `SupabaseClient` — nunca conectar ao Supabase real
- Usar `thenAnswer((_) async => data)` — nunca `thenReturn(Future)`
- Evitar builders que implementam `Future` (ex: `FakePostgrestBuilder` problemático)
- Evitar mocks complexos de `PostgrestBuilder` — preferir respostas diretas

### Padrão de grupo:
```dart
group('AuthRepository.signIn', () {
  test('retorna normalmente com credenciais válidas', () async { ... });
  test('lança EmailNotConfirmedException quando não confirmado', () async { ... });
  test('lança AuthAppException para senha incorreta', () async { ... });
  test('lança AuthAppException para usuário inexistente', () async { ... });
});
```

---

## 2. Controller Tests (Unit)

Para controllers puros (sem Riverpod), como `IdentifierController`:

### Setup mínimo:
```dart
IdentifierController _make({
  required Future<bool> Function(String) checkExists,
  VoidCallback? onStateChanged,
}) {
  return IdentifierController(
    checkExists: checkExists,
    onStateChanged: onStateChanged ?? () {},
  );
}
```

### Testando debounce (obrigatório):
```dart
// Helper para avançar além do debounce de 350ms
Future<void> _pumpDebounce(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
}

// Com chamada async depois do debounce
Future<void> _pumpDebounceAndAsync(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump();
  await tester.pump();
}
```

**Regra:** sempre verificar que `checkExists` NÃO foi chamado antes do debounce expirar.

### Testando concorrência (obrigatório para controllers com _requestId):
```dart
testWidgets('novo onChanged durante async invalida resultado anterior', (tester) async {
  final firstCheck = Completer<bool>();
  final secondCheck = Completer<bool>();

  final ctrl = _make(checkExists: (id) {
    if (id == 'primeiro123') return firstCheck.future;
    if (id == 'segundo123a') return secondCheck.future;
    return Future.value(false);
  });

  // Dispara primeira consulta
  ctrl.onChanged('primeiro123');
  await _pumpDebounceAndAsync(tester);
  expect(ctrl.status, IdentifierStatus.checking);

  // Dispara segunda ANTES da primeira completar
  ctrl.onChanged('segundo123a');
  await _pumpDebounceAndAsync(tester);

  // Primeira completa — deve ser ignorada
  firstCheck.complete(false);
  await tester.pump();
  expect(ctrl.status, IdentifierStatus.checking); // ainda aguardando segunda

  // Segunda completa — é a válida
  secondCheck.complete(false);
  await tester.pump();
  await tester.pump();
  expect(ctrl.status, IdentifierStatus.available);
});
```

### Regras para controller tests:
- Cobrir todos os estados do enum (idle, typing, tooShort, checking, available, taken, error)
- Testar `dispose()`: verificar que callback NÃO é chamado após dispose
- Testar normalização (`normalize()`) com acentos, `@`, caracteres inválidos
- Testar `applySuggestion` e `applyTakenStateFromConflict` separadamente
- Usar `addTearDown(ctrl.dispose)` em todo teste

---

## 3. Widget Tests

**NÃO depender de texto frágil ou layout rígido.**

### Setup obrigatório:
```dart
testWidgets('LoginScreen renderiza sem erro', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authNotifierProvider.overrideWith(...)],
      child: MaterialApp(  // sempre MaterialApp wrapping
        home: Scaffold(    // sempre Scaffold
          body: LoginScreen(),
        ),
      ),
    ),
  );
  expect(find.byType(LoginScreen), findsOneWidget);
});
```

### Requerimentos:
- `MaterialApp` obrigatório no topo
- `Scaffold` obrigatório como parent
- Viewport adequado — usar `tester.binding.setSurfaceSize(Size(400, 800))`

### Proibições:
- NÃO depender de texto exato que pode mudar
- NÃO depender de posicionamento rígido de elementos
- NÃO quebrar por overflow visual — componentes devem usar `Flexible` / `ellipsis`

### Assets (SVG):
```dart
// Posicionar FakeAssetBundle corretamente
await tester.pumpWidget(
  DefaultAssetBundle(
    bundle: FakeAssetBundle(),
    child: MaterialApp(home: MyScreen()),
  ),
);
```

---

## 4. Mocks — Regra Crítica

### CORRETO:
```dart
thenAnswer((_) async => data)           // async simples
thenAnswer((_) async => null)           // retorno nulo
thenAnswer((_) async => throw MyEx())   // exceção
```

### PROIBIDO:
```dart
thenReturn(Future.value(data))          // nunca para async
thenReturn(Future.error(e))             // nunca para async
when() dentro de outro stub             // causa loop infinito
```

---

## 5. Anti-Patterns Proibidos

| Anti-pattern | Por quê |
|---|---|
| `thenReturn(Future.value(...))` | Causa erro de timing no Mocktail |
| `when()` dentro de outro stub | Loop ou comportamento indefinido |
| Expectativa de texto que não existe na UI | Testes frágeis, quebram por i18n/copy |
| Testes acoplados a detalhes visuais | Quebram sem motivo a cada ajuste de layout |
| Mocks complexos de `PostgrestBuilder` | Difíceis de manter, acoplados ao SDK |
| Overflow visual não tratado | Widget tests falham sem motivo real |

---

## 6. Layout — Resiliência Obrigatória

Testes **não devem quebrar por overflow visual**.

Componentes devem ser resilientes:
- Textos longos: `overflow: TextOverflow.ellipsis`
- Colunas com conteúdo variável: `Flexible` ou `Expanded`
- Nunca `SizedBox` com altura fixa em widgets reutilizáveis

---

## 7. Checklist de Validação por Tela (Auth)

### LoginScreen
- [ ] Renderiza sem erro
- [ ] E-mail inválido exibe erro de validação
- [ ] Senha curta exibe erro de validação
- [ ] Loading state: botão desabilitado
- [ ] Erro de autenticação exibido no `AppErrorBox`
- [ ] Links de navegação presentes

### RegisterScreen
- [ ] Todos os campos obrigatórios validados
- [ ] Senhas diferentes: mensagem clara
- [ ] Loading durante signup
- [ ] Sucesso navega para EmailVerificationScreen

### EmailVerificationScreen
- [ ] E-mail exibido (censurado)
- [ ] Botão reenvio presente
- [ ] Timer de cooldown visível

### RecoverPasswordScreen
- [ ] Campo e-mail obrigatório
- [ ] E-mail inválido: mensagem de erro
- [ ] Feedback de sucesso exibido

---

## 8. Cenários de Borda (obrigatórios em todos os módulos)

- [ ] Campos em branco
- [ ] Texto muito longo (overflow de UI)
- [ ] Múltiplos taps rápidos em botão (double submit)
- [ ] Voltar no meio de fluxo multi-etapa
- [ ] Tela pequena (360px largura)

---

## 9. Ferramentas

| Ferramenta | Uso |
|---|---|
| `flutter_test` | Unit e widget tests |
| `mocktail` | Mock de dependências |
| `integration_test` | Testes end-to-end |

---

## 10. CI/CD

- `flutter analyze` → zero erros em todo PR
- `flutter test` → verde em todo PR
- Integration tests → antes de merge para main
