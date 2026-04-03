# EANTrack — Test Strategy

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

## 1. Unit Tests

### O que testar com unit tests:
- Toda função em `AuthRepository` (signIn, signUp, resetPassword, etc.)
- Validators (`validateEmail`, `validatePassword`, `validateCNPJ`, etc.)
- Funções utilitárias migradas de `custom_functions.dart`
- Lógica de cooldown de reenvio de e-mail
- `UserFlowState.isOnboardingComplete` e outras computed properties
- State transitions em Notifiers (via mock do repository)

### Padrão:
```dart
group('AuthRepository.signIn', () {
  test('retorna normalmente com credenciais válidas', () async { ... });
  test('lança EmailNotConfirmedException quando e-mail não confirmado', () async { ... });
  test('lança AuthAppException para senha incorreta', () async { ... });
  test('lança AuthAppException para usuário inexistente', () async { ... });
});
```

### Mock:
- `mocktail` para mock de `SupabaseClient` e `AuthRepository`
- Nunca conectar ao Supabase real em unit tests

---

## 2. Widget Tests

### O que testar com widget tests:
- Cada tela renderiza sem erros (smoke test)
- Campos de formulário exibem erros de validação corretamente
- Botões estão habilitados/desabilitados nos estados corretos
- Textos corretos para cada estado (Loading, Error, Empty, etc.)
- Responsividade: renderiza em larguras diferentes (360, 600, 1200px)

### Padrão:
```dart
testWidgets('LoginScreen renderiza sem erro', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authNotifierProvider.overrideWith(...)],
      child: MaterialApp.router(routerConfig: testRouter),
    ),
  );
  expect(find.byType(LoginScreen), findsOneWidget);
});

testWidgets('LoginScreen exibe erro de validação para e-mail inválido', (tester) async {
  // ...
});
```

### Simulação de estados:
- Override de providers com `ProviderScope.overrides`
- `MockAuthNotifier` com estados pré-definidos

---

## 3. Integration Tests

### Fluxos a testar (obrigatórios antes de cada release):

#### Auth
- [ ] Cadastro completo → verificação de e-mail → onboarding
- [ ] Login com credenciais válidas → redirect correto
- [ ] Login com senha errada → mensagem de erro correta
- [ ] Esqueceu senha → recebe e-mail
- [ ] Sessão expirada → redirect para login
- [ ] Auto-login ao abrir app com sessão válida

#### PDV (Fase 6)
- [ ] Cadastro de PDV com CNPJ válido
- [ ] Cadastro com CNPJ inválido → erro claro

#### Produto (Fase 8)
- [ ] Lançamento de produto completo
- [ ] Edição de produto existente

---

## 4. Cenários de Borda (obrigatórios em todos os módulos)

- [ ] Sem conexão com internet
- [ ] Resposta lenta do servidor (timeout)
- [ ] Campos em branco
- [ ] Texto muito longo (overflow de UI)
- [ ] Tela muito pequena (320px)
- [ ] Tela muito larga (1920px)
- [ ] Caracteres especiais em campos de texto
- [ ] Múltiplos taps rápidos em botão (double submit)
- [ ] Voltar no meio de um fluxo multi-etapa

---

## 5. Checklist de Validação por Tela (Auth)

### LoginScreen
- [ ] Renderiza logo e campos corretamente
- [ ] E-mail inválido: exibe "E-mail inválido"
- [ ] Senha < 8 chars: exibe erro
- [ ] Credenciais erradas: exibe mensagem de erro (não "Internal server error")
- [ ] Loading state: botão desabilitado, spinner visível
- [ ] Sucesso: navega para tela correta
- [ ] Link "Esqueceu a senha" navega para RecoverPasswordScreen
- [ ] Link "Criar conta" navega para RegisterScreen
- [ ] Funciona em mobile (360px) e desktop (1200px)

### RegisterScreen
- [ ] Todos os campos obrigatórios validados
- [ ] E-mail duplicado: mensagem "Este e-mail já está em uso"
- [ ] Senhas diferentes: mensagem clara
- [ ] Senha fraca: feedback em tempo real
- [ ] Termos: checkbox obrigatório
- [ ] Loading durante signup
- [ ] Sucesso: navega para EmailVerificationScreen

### EmailVerificationScreen
- [ ] E-mail censored exibido corretamente
- [ ] Botão reenvio desabilitado durante cooldown
- [ ] Timer de cooldown exibido em HH:mm:ss
- [ ] Máximo de tentativas respeitado
- [ ] Animação de sucesso quando e-mail confirmado
- [ ] Navega para onboarding após confirmação
- [ ] Botão voltar navega para login

### RecoverPasswordScreen
- [ ] Campo e-mail obrigatório
- [ ] E-mail inválido: mensagem de erro
- [ ] Sucesso: loading modal + redirect para login
- [ ] Feedback adequado de que o e-mail foi enviado

---

## 6. Ferramentas

| Ferramenta | Uso |
|-----------|-----|
| `flutter_test` | Unit e widget tests |
| `mocktail` | Mock de dependências |
| `integration_test` | Testes end-to-end |
| `flutter analyze` | Análise estática (zero warnings) |
| `flutter test --coverage` | Relatório de cobertura |

---

## 7. CI/CD (futuro)

- Rodar `flutter analyze` em todo PR
- Rodar unit + widget tests em todo PR
- Rodar integration tests antes de merge para main
- Build APK + web em todo push para main
