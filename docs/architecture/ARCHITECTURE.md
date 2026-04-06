# ARCHITECTURE.md — EANTrack (FINAL)

> Arquitetura técnica do projeto. Fonte de verdade para decisões estruturais.
> Stack, folder structure, padrões de state e navegação.

---

## Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| UI | Flutter | ≥3.2 |
| State | flutter_riverpod (StateNotifier) | ^2.6 |
| Navigation | go_router | ^14.x |
| Backend | supabase_flutter | ^2.9 |
| Auth Extras | google_sign_in, sign_in_with_apple | current |
| Crypto | crypto (SHA-256) | ^3.0 |
| Animations | flutter_animate, lottie | current |
| Testing | flutter_test + mocktail | current |

---

## Princípios Arquiteturais

1. **Feature-first** — código organizado por domínio de negócio, não por camada
2. **Unidirectional data flow** — UI → Notifier → Repository → Supabase
3. **Sem lógica em widgets** — telas apenas chamam métodos do notifier e leem state
4. **Repository como boundary** — todas as chamadas Supabase passam pelo repository
5. **Sealed state classes** — state handling exhaustivo, sem nullable fields para estado
6. **Erros tipados** — hierarquia AppException, nunca erros raw do Supabase na UI
7. **Navegação controla transições** — telas não definem animações de entrada/saída; toda transição de rota é responsabilidade do `app_router.dart` via `_fadePage()`. Widgets de tela são estáticos.
8. **Domain sem navegação** — nenhum model, state ou entity conhece rotas. Redirect é responsabilidade exclusiva do router ou da camada de apresentação.
9. **Services injetáveis** — nenhum service é instanciado diretamente dentro de outro. Toda dependência chega via constructor injection + Riverpod provider.

---

## Estrutura de Pastas

```
lib/
├── main.dart                          # WidgetsFlutterBinding + Supabase init + ProviderScope
├── app/
│   └── app.dart                       # MaterialApp.router + theme
├── core/
│   ├── config/
│   │   └── app_config.dart            # dart-define env vars
│   ├── router/
│   │   ├── app_router.dart            # GoRouter provider + RouterNotifier
│   │   └── app_routes.dart            # Route names and paths
│   └── error/
│       └── app_exception.dart         # Sealed exception hierarchy
├── shared/
│   ├── theme/
│   │   ├── app_colors.dart            # Color tokens
│   │   ├── app_text_styles.dart       # Typography (Poppins + Roboto)
│   │   ├── app_spacing.dart           # Spacing + Radius + Shadow tokens
│   │   └── app_theme.dart             # ThemeData builder
│   ├── layout/
│   │   └── breakpoints.dart           # Mobile/tablet/desktop breakpoints
│   └── widgets/
│       ├── app_button.dart
│       ├── app_card.dart
│       ├── app_empty_state.dart
│       ├── app_error_box.dart         # Caixa de erro inline com shake animation
│       ├── app_feedback_dialog.dart   # Modal centralizado de sucesso/erro
│       ├── app_text_field.dart
│       ├── app_version_badge.dart
│       ├── auth_scaffold.dart         # Layout padrão de auth/onboarding
│       ├── password_rule_row.dart     # Linha de regra de senha (checklist)
│       ├── app_bottom_nav.dart
│       └── app_sidebar.dart
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── auth_repository.dart
    │   │   ├── password_history_service.dart  # RPC check + register history
    │   │   └── password_reuse_parser.dart     # Parser defensivo da resposta RPC
    │   ├── domain/
    │   │   ├── auth_state.dart
    │   │   ├── auth_flow_state.dart
    │   │   └── user_flow_state.dart
    │   └── presentation/
    │       ├── providers/
    │       │   └── auth_provider.dart
    │       └── screens/
    │           ├── login_screen.dart
    │           ├── register_screen.dart
    │           ├── email_verification_screen.dart
    │           ├── recover_password_screen.dart
    │           ├── update_password_screen.dart
    │           └── password_recovery_link_expired_screen.dart
    ├── onboarding/                    # Fase 2
    ├── hub/                           # Fase 2
    ├── regions/                       # Fase 3
    ├── networks/                      # Fase 3
    ├── categories/                    # Fase 3
    ├── pdvs/                          # Fase 4
    └── industries/                    # Fase 4
```

---

## State Management

### Tipos de Provider Usados

```dart
// Supabase client — singleton
final supabaseClientProvider = Provider<SupabaseClient>(...);

// Repository — singleton por feature
final authRepositoryProvider = Provider<AuthRepository>(...);

// Auth stream do Supabase
final authUserStreamProvider = StreamProvider<User?>(...);

// Auth actions + state
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);
```

### Fluxo de Estado

```
Ação do usuário (tap no botão)
  → Widget chama ref.read(authNotifierProvider.notifier).signIn(...)
  → AuthNotifier seta state = AuthLoading()
  → AuthNotifier chama AuthRepository.signIn(...)
  → Repository chama Supabase
  → AuthNotifier seta state = AuthAuthenticated() ou AuthError()
  → Widget lê ref.watch(authNotifierProvider) → rebuild
```

### Anti-patterns Proibidos

- `ref.read()` dentro de `build()` — usar `ref.watch()` para state reativo
- Lógica de negócio em `build()` de widget
- Chamada Supabase direta no widget
- `setState()` para algo que afeta múltiplos widgets

---

## Padrão de Navegação

### GoRouter com RouterNotifier (Riverpod-compatible)

```dart
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen(authUserStreamProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    // Lógica completa em AUTH_FLOW.md
  }
}
```

### Guards de Rota (3 zonas)

1. **Pública** — login, register, recover password (redirect se logado)
2. **Email verify** — após signup, antes do onboarding
3. **Protegida** — todas as telas do app (redirect para login se não autenticado)

> Lógica completa de redirect em AUTH_FLOW.md

---

## Integração Supabase

### Repository Pattern

```dart
class AuthRepository {
  const AuthRepository({
    required SupabaseClient client,
    required PasswordHistoryService passwordHistoryService,
  });
  // Todas as chamadas Supabase aqui — retorna tipos de domínio ou lança AppException
}
```

### RPCs Usados em Auth

| RPC | Purpose |
|-----|---------|
| `email_code_exists(p_hash)` | Check duplicidade de email (SHA-256 hash) |
| `insert_email_code(p_hash, p_user_id)` | Armazena hash pós-signup |
| `check_password_reuse_current_user(p_new_password, p_history_limit)` | Verifica se nova senha já foi usada recentemente |
| `register_password_history_current_user(p_password, p_keep_last)` | Registra nova senha no histórico |

### Tabelas Principais

| Tabela | Purpose |
|--------|---------|
| `user_flow_state` | Rastreia progresso de onboarding e modo do usuário |
| `email_codes` | Hashes SHA-256 de emails cadastrados |

> Schema completo em BACKEND_SCHEMA.md

---

## Responsividade

```dart
class Breakpoints {
  static const double mobile = 600;   // < 600px
  static const double tablet = 1200;  // 600–1200px
  // > 1200px = desktop
}
```

- Auth screens: card centralizado, max-width 420px (480 para register/onboarding)
- Internal screens: sidebar fixa em desktop, bottom nav em mobile

---

## Tratamento de Erros

```
AppException (sealed)
├── AuthAppException (abstract)
│   ├── InvalidCredentialsException
│   ├── EmailNotConfirmedException
│   ├── EmailAlreadyInUseException
│   └── WeakPasswordException
├── NetworkException
├── ServerException
└── ValidationException
```

- Repositories: throw AppException
- Notifiers: catch → seta ErrorState(exception.message)
- Widgets: lê ErrorState → exibe mensagem
- Mensagens sempre em PT-BR, user-friendly, max 1 linha

---

## Segurança

- Supabase URL e anon key via `dart-define` (nunca hardcoded)
- RLS habilitado em todas as tabelas (enforced no Supabase)
- Unicidade de email via SHA-256 hash (sem armazenar email raw em tabela custom)
- Validação de senha: mín. 8 chars, maiúscula + minúscula
- Rate limiting de reenvio: contador + duração de bloqueio
- Dados sensíveis nunca em route parameters
- Session gerenciada pelo Supabase Auth (JWT)

---

## Template de Módulo

Cada feature segue esta estrutura obrigatória:

```
features/{name}/
├── data/
│   └── {name}_repository.dart       # Supabase calls, throws AppException
├── domain/
│   ├── {name}_state.dart             # Sealed state class
│   └── {name}_model.dart             # Domain data models
└── presentation/
    ├── providers/
    │   └── {name}_provider.dart      # StateNotifier + Providers
    └── screens/
        └── {name}_screen.dart        # Pure UI, calls notifier, reads state
```
