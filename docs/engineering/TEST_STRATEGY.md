# EANTrack — Test Strategy

> Documento prático. Foca no que funciona neste projeto.

---

## Pirâmide de Testes

```
        [ Integration Tests ]   ← Fluxos críticos end-to-end
       [   Widget Tests    ]    ← Todas as telas (smoke + interação)
      [    Unit Tests     ]     ← Business logic, repositories, validators
```

**Meta de cobertura mínima:**
- Unit: 80% nas funções de domínio e repositórios
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

## 2. Widget Tests

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

## 3. Mocks — Regra Crítica

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

## 4. Anti-Patterns Proibidos

| Anti-pattern | Por quê |
|---|---|
| `thenReturn(Future.value(...))` | Causa erro de timing no Mocktail |
| `when()` dentro de outro stub | Loop ou comportamento indefinido |
| Expectativa de texto que não existe na UI | Testes frágeis, quebram por i18n/copy |
| Testes acoplados a detalhes visuais | Quebram sem motivo a cada ajuste de layout |
| Mocks complexos de `PostgrestBuilder` | Difíceis de manter, acoplados ao SDK |
| Overflow visual não tratado | Widget tests falham sem motivo real |

---

## 5. Layout — Resiliência Obrigatória

Testes **não devem quebrar por overflow visual**.

Componentes devem ser resilientes:
- Textos longos: `overflow: TextOverflow.ellipsis`
- Colunas com conteúdo variável: `Flexible` ou `Expanded`
- Nunca `SizedBox` com altura fixa em widgets reutilizáveis

---

## 6. Checklist de Validação por Tela (Auth)

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

## 7. Cenários de Borda (obrigatórios em todos os módulos)

- [ ] Campos em branco
- [ ] Texto muito longo (overflow de UI)
- [ ] Múltiplos taps rápidos em botão (double submit)
- [ ] Voltar no meio de fluxo multi-etapa
- [ ] Tela pequena (360px largura)

---

## 8. Ferramentas

| Ferramenta | Uso |
|---|---|
| `flutter_test` | Unit e widget tests |
| `mocktail` | Mock de dependências |
| `integration_test` | Testes end-to-end |

---

## 9. CI/CD

- `flutter analyze` → zero erros em todo PR
- `flutter test` → verde em todo PR
- Integration tests → antes de merge para main
