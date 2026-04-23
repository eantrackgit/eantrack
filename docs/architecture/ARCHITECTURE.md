# ARCHITECTURE.md — EANTrack (FINAL)

> Arquitetura técnica do projeto. Fonte de verdade para decisões estruturais.
> Stack, folder structure, padrões de state e navegação.

---

## Stack

| Layer | Technology | Version |
|-------|-----------|---------|
| UI | Flutter | ≥3.2 |
| State | flutter_riverpod (Notifier / StateNotifier) | ^2.6 |
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
│   └── app.dart                       # MaterialApp.router + light/dark theme + themeModeProvider
├── core/
│   ├── config/
│   │   ├── app_config.dart            # dart-define env vars (SUPABASE_URL, SUPABASE_ANON_KEY)
│   │   └── app_version.dart           # Versão lida de assets
│   ├── router/
│   │   ├── app_router.dart            # GoRouter provider + _fadePage helper
│   │   ├── app_routes.dart            # Constantes de rotas (paths e nomes)
│   │   ├── router_redirect_guard.dart # RouterRedirectGuard (ChangeNotifier)
│   │   └── recovery_link_parser.dart  # Parser de links de recuperação de senha
│   └── error/
│       └── app_exception.dart         # Sealed exception hierarchy
├── shared/
│   ├── theme/
│   │   ├── app_colors.dart            # Tokens primitivos de cor
│   │   ├── app_text_styles.dart       # Tipografia (Poppins + Roboto)
│   │   ├── app_spacing.dart           # Espaçamento + Radius + Shadow
│   │   └── app_theme.dart             # EanTrackTheme (ThemeExtension light/dark) + AppTheme.light/dark()
│   ├── providers/
│   │   └── theme_provider.dart        # StateProvider<ThemeMode> — toggle light/dark
│   ├── layout/
│   │   └── breakpoints.dart           # Mobile/tablet/desktop breakpoints
│   ├── mixins/
│   │   └── form_state_mixin.dart      # FormStateMixin<T> — formKey, submitted, validators
│   ├── utils/
│   │   ├── async_action.dart          # ActionIdle/Loading/Success/Failure
│   │   ├── async_value.dart           # DataIdle/Loading/Success/Empty/Failure
│   │   └── password_validator.dart    # Regras de força de senha
│   └── widgets/
│       ├── app_button.dart            # primary, secondary/outlined, action, social. Themed.
│       ├── app_card.dart              # onTap?, selected?, borderColor?, ripple
│       ├── app_empty_state.dart       # Estado vazio com ícone, título, ação
│       ├── app_error_box.dart         # Erro inline com shake animation
│       ├── app_feedback_dialog.dart   # Modal centralizado sucesso/erro. Dark mode via EanTrackTheme.
│       ├── app_list_state_view.dart   # View para estados de lista (loading/empty/error/loaded)
│       ├── app_text_field.dart        # Floating label, validators, theming via EanTrackTheme
│       ├── app_version_badge.dart     # Badge de versão
│       ├── auth_scaffold.dart         # Layout padrão auth/onboarding. Dark mode. action? param.
│       ├── password_rule_row.dart     # Checklist de senha animado
│       ├── app_bottom_nav.dart        # Bottom nav para mobile
│       └── app_sidebar.dart           # Sidebar fixa para desktop
└── features/
    ├── auth/
    │   ├── data/
    │   │   ├── auth_repository.dart
    │   │   ├── password_history_service.dart       # RPC check + register history
    │   │   ├── password_reuse_parser.dart          # Parser defensivo da resposta RPC
    │   │   ├── password_recovery_cooldown_storage.dart        # Conditional import
    │   │   ├── password_recovery_cooldown_storage_base.dart   # Interface
    │   │   ├── password_recovery_cooldown_storage_stub.dart   # Mobile/default
    │   │   └── password_recovery_cooldown_storage_web.dart    # Web (localStorage)
    │   ├── domain/
    │   │   ├── auth_state.dart
    │   │   ├── auth_flow_state.dart
    │   │   └── user_flow_state.dart
    │   └── presentation/
    │       ├── providers/
    │       │   └── auth_provider.dart   # AuthNotifier, EmailCooldownNotifier, passwordRecoveryCooldownProvider
    │       ├── widgets/
    │       │   └── resend_cooldown_button.dart   # Botão com countdown display
    │       └── screens/
    │           ├── login_screen.dart              # dark mode, ThemeToggleButton
    │           ├── register_screen.dart           # dark mode
    │           ├── email_verification_screen.dart
    │           ├── recover_password_screen.dart   # dark mode
    │           ├── update_password_screen.dart
    │           └── password_recovery_link_expired_screen.dart
    ├── flow/
    │   └── presentation/
    │       └── screens/
    │           └── flow_page.dart       # Tela de decisão de fluxo (auth→onboarding/hub)
    ├── onboarding/
    │   ├── data/
    │   │   └── onboarding_repository.dart   # saveMode(), identificadorExiste(), saveProfile()
    │   ├── domain/
    │   │   └── onboarding_state.dart        # Sealed: Initial/Loading/ModeSelected/Error
    │   └── presentation/
    │       ├── providers/
    │       │   └── onboarding_provider.dart
    │       └── screens/
    │           ├── choose_mode_screen.dart          # dark mode
    │           ├── onboarding_profile_screen.dart   # dark mode, identifier + sugestões
    │           ├── cnpj_screen.dart
    │           ├── company_data_screen.dart
    │           └── legal_representative_screen.dart
    ├── hub/
    │   └── presentation/
    │       └── screens/
    │           └── hub_screen.dart      # Layout responsive. ⚠️ Sem dark mode ainda.
    ├── regions/
    │   ├── data/
    │   │   └── region_repository.dart
    │   ├── domain/
    │   │   ├── region_model.dart
    │   │   └── region_state.dart
    │   └── presentation/
    │       ├── providers/
    │       │   └── region_provider.dart
    │       └── screens/
    │           └── region_list_screen.dart  # ⚠️ Sem dark mode ainda.
    ├── networks/                        # Fase futura
    ├── categories/                      # Fase futura
    ├── pdvs/                            # Fase futura
    └── industries/                      # Fase futura
```

---

## Divergência de Padrão entre Módulos

O projeto tem dois padrões estruturais coexistentes. Conhecê-los evita confusão ao navegar pelo código.

### Padrão A — Auth (`features/auth/`)

Segue a divisão clássica `data / domain / presentation`:

```
auth/
├── data/
│   ├── auth_repository.dart          # fachada; delega para 3 services
│   ├── auth_signing_service.dart     # sign in / sign up / OAuth
│   ├── auth_email_service.dart       # verificação e reenvio
│   └── auth_password_service.dart    # reset e update de senha
├── domain/
│   ├── auth_state.dart               # sealed AuthState (6 subclasses)
│   ├── auth_flow_state.dart          # enum AuthFlowState (4 valores)
│   └── user_flow_state.dart
└── presentation/
    ├── providers/auth_provider.dart  # AuthNotifier + providers de infra
    └── screens/
```

Fluxo: `Screen → AuthNotifier → AuthRepository → AuthSigningService → Supabase`

### Padrão B — Agency (`features/onboarding/agency/`)

Usa `controllers/` para os notifiers e `services/` para acesso direto ao Supabase/APIs, **sem** camada `Repository`:

```
agency/
├── controllers/
│   ├── agency_cnpj_controller.dart        # AgencyCnpjNotifier (StateNotifier)
│   ├── agency_confirm_controller.dart
│   ├── agency_representative_controller.dart
│   └── agency_status_notifier.dart
├── services/
│   ├── cnpj_service.dart                  # HTTP ReceitaWS + Supabase
│   ├── cep_service.dart
│   ├── agency_confirm_service.dart
│   └── agency_representative_service.dart
├── models/
└── screens/
```

Fluxo: `Screen → AgencyCnpjNotifier → CnpjService → Supabase/HTTP`

> **Regra de convivência:** ao criar novos módulos, seguir o template da seção
> "Template de Módulo" (Padrão A). O Padrão B é legado do agency e não deve
> ser replicado.

### Padrão de Estado — Agency usa enum + copyWith

Enquanto Auth e Onboarding usam sealed classes, Agency usa enum de status + `copyWith`:

```dart
enum AgencyCnpjStatus { idle, loading, invalid, notFound, inactive, duplicate, genericError, success }

class AgencyCnpjState {
  final AgencyCnpjStatus status;
  final String cnpj;
  final bool isLoading;
  final String? error;
  final CnpjModel? cnpjData;
  AgencyCnpjState copyWith({...}) { ... }
}
```

Sealed classes permitem pattern matching exhaustivo no switch — preferir para novos módulos.

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

// Auth actions + state (legado — manter para Auth)
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(...);

// Novos módulos — padrão Riverpod 2 Notifier
final regionNotifierProvider = NotifierProvider<RegionNotifier, RegionState>(
  RegionNotifier.new,
);
```

### Padrão Riverpod 2 — Notifier

Para novos módulos, usar `Notifier` em vez de `StateNotifier`:

```dart
class RegionNotifier extends Notifier<RegionState> {
  RegionRepository get _repository => ref.read(regionRepositoryProvider);
  String get _agencyId => ref.read(agencyIdProvider);

  @override
  RegionState build() {
    ref.watch(agencyIdProvider); // auto-invalida na troca de conta
    Future.microtask(load);      // carrega dados ao montar
    return RegionInitial();
  }
}
```

Vantagens sobre `StateNotifier`:
- `ref` disponível diretamente (sem `ProviderRef` no constructor)
- `build()` como ponto central de setup e auto-dispose declarativo
- `ref.watch()` no `build()` recria o notifier quando dependência muda

### Padrão de Guard — agencyId

Todo acesso a dados scoped por agência passa por `agencyIdProvider`:

```dart
final agencyIdProvider = Provider<String>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is! AuthAuthenticated) {
    throw StateError('Usuario nao autenticado.');
  }
  final agencyId = authState.flowState?.agencyId;
  if (agencyId == null) {
    throw StateError('Agency ID nao encontrado para o usuario autenticado.');
  }
  return agencyId;
});
```

**Regra:** nunca passar `agencyId` como parâmetro explícito para notifiers — sempre derivar de `agencyIdProvider`. Garante que:
1. Usuário não autenticado nunca acessa dados
2. Troca de conta invalida automaticamente o estado do notifier
3. null nunca passa silencioso para o repository

### Padrão de Controller — IdentifierController

Para lógica complexa de campo (validação assíncrona + debounce + sugestões), extrair um controller puro (sem Riverpod):

```dart
class IdentifierController {
  IdentifierController({
    required this.checkExists,  // injetado pela screen
    required this.onStateChanged,
  });

  Timer? _debounce;
  int _requestId = 0;   // cancela consultas stale

  void onChanged(String raw) {
    _debounce?.cancel();
    _requestId++;
    // debounce 350ms → _validate(normalized, requestId: _requestId)
  }

  Future<void> _validate(String id, {required int requestId, ...}) async {
    final exists = await checkExists(id);
    if (requestId != _requestId) return; // stale — ignora resultado
    // atualiza estado
  }
}
```

**Regras:**
- Controller não conhece Riverpod, nem Flutter (exceto `TextEditingController`)
- `_requestId` é incrementado a cada nova chamada — respostas fora de ordem são descartadas
- `dispose()` seta `_disposed = true` e cancela o timer

### Fluxo de Estado

```
Ação do usuário (tap no botão)
  → Widget chama ref.read(regionNotifierProvider.notifier).createRegion(...)
  → RegionNotifier lê agencyId via ref.read(agencyIdProvider)
  → RegionNotifier chama RegionRepository.createRegion(...)
  → Repository chama Supabase
  → RegionNotifier seta state = RegionLoaded(regions) ou mantém estado atual
  → Widget lê ref.watch(regionNotifierProvider) → rebuild
```

### Anti-patterns Proibidos

- `ref.read()` dentro de `build()` — usar `ref.watch()` para state reativo
- Lógica de negócio em `build()` de widget
- Chamada Supabase direta no widget
- `setState()` para algo que afeta múltiplos widgets
- Passar `agencyId` como parâmetro explícito — sempre derivar de `agencyIdProvider`
- Ignorar resultado de `_requestId` em chamadas assíncronas com debounce

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

## Sistema de Tema (Light / Dark)

### EanTrackTheme — ThemeExtension

Todos os tokens semânticos de cor estão em `EanTrackTheme` (ThemeExtension), acessível via:

```dart
final et = EanTrackTheme.of(context);
```

| Token | Light | Dark | Uso |
|-------|-------|------|-----|
| `scaffoldOuter` | navy `#0E0A36` | `#0D1117` | Fundo do Scaffold em auth/onboarding |
| `cardSurface` | branco `#FFFFFF` | `#161D2F` | Card/container principal |
| `inputFill` | branco `#FFFFFF` | `#1C2537` | Fill de campos habilitados |
| `inputFillDisabled` | cinza claro `#F1F4F8` | `#141C2B` | Fill de campos desabilitados |
| `inputBorder` | `#E0E3E7` | `#2E3B58` | Borda idle de campos |
| `inputBorderFocused` | navy `#0E0A36` | `#4D72F5` | Borda focada de campos |
| `primaryText` | `#14181B` | `#E4EAF6` | Texto principal |
| `secondaryText` | `#57636C` | `#7A8DB0` | Labels, subtítulos, ícones idle |
| `divider` | `#C7CBD1` | `#232C45` | Divisores |
| `surface` | branco `#FFFFFF` | `#1C2537` | Containers secundários internos |
| `surfaceBorder` | `#E0E3E7` | `#2E3B58` | Borda de containers secundários |
| `ctaBackground` | navy `#0E0A36` | `#4D72F5` | Background do botão primary |
| `ctaForeground` | branco | branco | Texto/ícone do botão primary |
| `outlinedFg` | navy `#0E0A36` | `#8896B3` | Borda e texto do botão outlined |
| `socialBg` | `AppColors.primary` (vermelho) | `#1C2537` | Background do botão social (Google) |
| `socialFg` | branco | `#E4EAF6` | Texto/ícone do botão social |
| `socialBorder` | transparente | `#2E3B58` | Borda do botão social (visível só no dark) |
| `accentLink` | `#1A56DB` | `#7CA5E8` | Links inline (recuperação de senha, etc.) |

### Toggle de Tema

```dart
// Provider global (shared/providers/theme_provider.dart)
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

// Em app.dart
themeMode: ref.watch(themeModeProvider),

// Toggle em qualquer widget
ref.read(themeModeProvider.notifier).state =
    isDark ? ThemeMode.light : ThemeMode.dark;
```

### Status atual do dark mode

| Tela / Feature | Dark Mode | Observação |
|---------------|-----------|------------|
| Auth (login, register, recover, update) | ✅ Completo | login é referência visual |
| Onboarding (choose_mode, profile) | ✅ Completo | — |
| Modais (`app_feedback_dialog`) | ✅ Completo | blur backdrop + EanTrackTheme |
| `PasswordRuleRow` | ✅ Completo | idle via `et.secondaryText` |
| `AppCard` | ✅ Completo | default seguro: `et.cardSurface` no dark |
| Hub | ❌ Usa AppColors direto | pendente |
| Regiões | ❌ Usa AppColors direto | pendente |
| flow_page | ❌ Cor hardcoded | pendente |

### Exceções de implementação (documentadas e intencionais)

| Local | Exceção | Motivo |
|-------|---------|--------|
| `onboarding_profile_screen.dart` | Usa `TextFormField` raw (não `AppTextField`) | Border dinâmico por status do identificador; `maxLines`/`buildCounter` customizado no campo descrição — não suportados por `AppTextField` |
| `email_verification_screen._PasswordModal` | Usa `TextField` raw | `errorText` direto + controle próprio de `obscure`; bordas alinhadas ao padrão (`AppRadius.smAll`, `AppColors.error`) |

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
│   ├── WeakPasswordException
│   ├── SamePasswordException
│   ├── PasswordReusedException
│   ├── PasswordReuseCheckException
│   └── PasswordHistoryRegisterException
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
    ├── controllers/                   # (opcional) controllers puros sem Riverpod
    │   └── {name}_controller.dart    # lógica complexa de campo (debounce, async, sugestões)
    ├── providers/
    │   └── {name}_provider.dart      # Notifier + Providers (Riverpod 2)
    └── screens/
        └── {name}_screen.dart        # Pure UI, calls notifier, reads state
```

### Quando usar controller vs. notifier

| Caso | Usar |
|------|------|
| Estado global de feature (lista, form de criação) | `Notifier` + `NotifierProvider` |
| Lógica complexa de campo único (validação async, debounce, sugestões) | Controller puro (sem Riverpod) |
| Estado simples de UI (toggle, loading local) | `setState` na própria screen |
