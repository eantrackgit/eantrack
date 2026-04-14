# EANTrack — Code Rules

> Regras obrigatórias. Válidas para toda a codebase. Sem exceções sem registro em DECISIONS_LOG.md.

---

## 1. Tamanho de Arquivos

| Tipo | Limite | Ação se ultrapassar |
|------|--------|-------------------|
| Screen | 200 linhas | Extrair widgets privados no mesmo arquivo ou subwidgets separados |
| Widget reutilizável | 150 linhas | Quebrar em partes menores |
| Repository | 150 linhas | Dividir por domínio |
| Notifier | 100 linhas | Separar em notifiers menores se crescer |
| Arquivo utilitário | 100 linhas | Dividir por categoria |

Regra geral: **se você precisa rolar muito para entender, o arquivo é grande demais.**

---

## 2. Separação de Responsabilidades

```
Screen       → lê estado, chama notifier, layout/UI
Notifier     → orquestra ações, gerencia estado
Repository   → chamadas Supabase, lança AppException
Domain model → dados imutáveis, lógica de negócio pura
Shared widget→ puramente visual, sem estado de negócio
```

**Proibido:**
- Chamada Supabase em widget ou notifier
- Lógica de negócio em `build()`
- Navegação dentro de repository ou notifier (use listener na screen)
- Estado global para dados que pertencem a uma feature

---

## 3. Naming

```dart
// Arquivos
auth_repository.dart       // snake_case
login_screen.dart
app_button.dart

// Classes
AuthRepository             // PascalCase
LoginScreen
AppButton

// Providers
authNotifierProvider       // camelCase + sufixo Provider
authRepositoryProvider
authUserStreamProvider

// Notifiers
AuthNotifier               // PascalCase + sufixo Notifier

// Constantes de rota
AppRoutes.login            // classe + propriedade estática

// Tokens de design
AppColors.primary
AppSpacing.md
AppRadius.sm
```

---

## 4. Riverpod

```dart
// ✅ Correto — watch no build para estado reativo
final state = ref.watch(authNotifierProvider);

// ✅ Correto — read para ações (não reativa)
ref.read(authNotifierProvider.notifier).signIn(...);

// ✅ Correto — listen para side effects (navegação, snackbar)
ref.listen<AuthState>(authNotifierProvider, (_, next) { ... });

// ❌ Errado — read no build (não reativa ao estado)
final state = ref.read(authNotifierProvider);

// ❌ Errado — watch dentro de callback/event
onPressed: () => ref.watch(...);

// ✅ autoDispose em providers de tela
StateNotifierProvider.autoDispose<...>

// ✅ Provider sem autoDispose apenas para singletons (repositories, client)
```

---

## 5. GoRouter

```dart
// Navegação que limpa stack (pós-auth, redirect)
context.go(AppRoutes.flow);

// Navegação que empilha (pode voltar)
context.push(AppRoutes.register);

// Voltar
context.pop();

// Nunca usar Navigator.push diretamente
// Nunca hardcodar strings de rota — sempre AppRoutes.*
// Redirect declarativo via GoRouter.redirect — não imperativo em build()
```

---

## 6. Supabase

```dart
// ✅ Chamadas sempre em Repository
class AuthRepository {
  Future<void> signIn(...) async {
    try {
      await _client.auth.signInWithPassword(...);
    } on AuthException catch (e) {
      throw AuthAppException(_mapError(e.message)); // mapear para PT-BR
    }
  }
}

// ❌ Nunca chamar Supabase de widget ou notifier
// ❌ Nunca expor AuthException raw para a UI
// ❌ Nunca logar dados sensíveis (email, password, JWT)
```

---

## 7. Segurança

```dart
// ✅ Secrets via dart-define
const url = String.fromEnvironment('SUPABASE_URL');

// ❌ Nunca hardcodar
const url = 'https://xxx.supabase.co'; // proibido

// ✅ Validar input antes de enviar
void _submit() {
  if (!_formKey.currentState!.validate()) return;
  // ...
}

// ✅ Tratar erro sem expor detalhes
AuthError('E-mail ou senha incorretos.') // ✅
AuthError(e.toString())                   // ❌

// ✅ Rota protegida via router redirect, não if dentro do widget
// ✅ signOut deve ser sempre aguardado antes de navegar
// ✅ Verificar emailConfirmedAt antes de marcar login completo
// ✅ Não persistir password em storage — apenas em memória de estado
```

---

## 12. Guard de agencyId (crítico)

```dart
// ✅ Sempre derivar agencyId de agencyIdProvider — nunca passar como parâmetro
final regionNotifier = ref.read(regionNotifierProvider.notifier);

// ❌ Nunca aceitar agencyId null silenciosamente
Future<void> load({String? agencyId}) async { // proibido
  if (agencyId == null) return;              // null silencioso — proibido
}

// ✅ agencyIdProvider lança StateError se não autenticado ou sem agencyId
// Isso garante que:
//   1. Usuário não autenticado nunca acessa dados
//   2. Troca de conta invalida automaticamente o notifier (via ref.watch no build)
//   3. null nunca atravessa silencioso para o repository
```

**Regra:** todo notifier que acessa dados scoped por agência deve usar `ref.read(agencyIdProvider)` para acessar o agencyId, nunca receber como parâmetro externo.

---

## 13. Normalização Centralizada de Identificadores

```dart
// ✅ Sempre normalizar via IdentifierController.normalize() — método static
final normalized = IdentifierController.normalize(rawInput);

// ❌ Nunca duplicar lógica de normalização em outros lugares
final normalized = rawInput.trim().toLowerCase(); // duplicação — proibido

// ✅ Normalização inclui: strip acentos, lowercase, remove @, remove chars inválidos
// Resultado: apenas [a-z0-9._-]
```

---

## 14. Debounce + Async — Regras Críticas

```dart
// ✅ Cancelar debounce anterior antes de criar novo
_debounce?.cancel();
_requestId++;
_debounce = Timer(const Duration(milliseconds: 350), () => _validate(...));

// ✅ Sempre verificar _requestId no callback async — descartar resultado stale
Future<void> _validate(String id, {required int requestId}) async {
  final result = await checkExists(id);
  if (requestId != _requestId) return; // stale — ignora
  // atualiza estado
}

// ❌ Nunca atualizar estado sem verificar se a chamada ainda é válida
final result = await checkExists(id);
state = result ? StatusTaken() : StatusAvailable(); // perigoso — pode ser stale

// ✅ Sempre verificar _disposed antes de atualizar estado
if (_disposed || requestId != _requestId) return;

// ✅ Todo controller com debounce DEVE ter testes de:
//   - resultado antes do debounce (checkExists não chamado)
//   - resultado após debounce (checkExists chamado com valor correto)
//   - concorrência: segunda chamada invalida primeira (usando Completer)
//   - dispose: onStateChanged não chamado após dispose
```

---

## 8. Estado Inconsistente

```dart
// Prevenir double-submit: checar isLoading antes de chamar ação
onPressed: isLoading ? null : _submit,

// Limpar erro ao navegar para outra tela
// (authNotifier.clearError() quando retornar para login)

// Sealed state: sempre tratar todos os casos
switch (state) {
  case AuthLoading(): ...
  case AuthAuthenticated(): ...
  case AuthUnauthenticated(): ...
  case AuthEmailUnconfirmed(): ...
  case AuthError(): ...
  case AuthInitial(): ...
}
```

---

## 9. Qualidade de Código

```dart
// ✅ Nome que dispensa comentário
Future<bool> isEmailConfirmed() → claro
Future<bool> check() → vago, evitar

// ✅ Funções curtas e com uma responsabilidade
String _mapAuthError(String message) { ... }  // só mapeia erros

// ✅ Evitar comentários óbvios
// Seta o estado para loading ← desnecessário
state = const AuthLoading(); // o código já explica

// ✅ Comentários apenas para "por que", nunca "o que"
// SHA-256 hash para verificação de duplicidade sem expor o e-mail raw
final hash = _sha256(normalized);

// ❌ print() em produção — usar debugPrint() ou remover
// ❌ TODO sem issue/ticket referenciado em código crítico
// ❌ Código comentado — se não serve, delete
```

---

## 10. Imports

Ordem obrigatória (separados por linha em branco):
```dart
// 1. dart:
import 'dart:convert';

// 2. flutter:
import 'package:flutter/material.dart';

// 3. packages externos:
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// 4. projeto (absolutos):
import '../../../core/error/app_exception.dart';
import '../domain/auth_state.dart';
```

---

## 11. Testes

```dart
// Cada repository: test de sucesso + test de cada erro possível
// Cada screen: smoke test (renderiza sem crash)
// Notifier: test de transição de estado
// Sem mock de Supabase diretamente — usar mock do repository
// Nunca conectar ao Supabase real em tests unitários
```

---

## Resumo em Uma Frase por Regra

1. Arquivo grande → divide antes que vire problema
2. Lógica de negócio → no domain/notifier, nunca no widget
3. Navegação → via listener, nunca dentro de repository
4. Supabase → só via repository, erros mapeados para PT-BR
5. Secrets → dart-define, jamais hardcoded
6. Riverpod → watch no build, read em callbacks, listen para side effects
7. Estado → sealed, tratamento exaustivo, sem nullable flags
8. Segurança → validar input, não expor erro raw, não persistir senha
9. agencyId → sempre de agencyIdProvider, nunca null silencioso, nunca parâmetro externo
10. Normalização → centralizada em IdentifierController.normalize(), sem duplicação
11. Debounce → sempre cancelar anterior + verificar _requestId para descartar stale + testar concorrência
12. Notifier (Riverpod 2) → para novos módulos, usar Notifier + NotifierProvider
