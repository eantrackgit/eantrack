# GLOBAL_PATTERNS.md — EANTrack (FINAL)

> Padrões obrigatórios para TODO o projeto. Qualquer tela/feature deve seguir.

---

## 1. ESTADOS PADRÃO (OBRIGATÓRIO EM TODA FEATURE)

### Sealed State Pattern
```dart
sealed class FeatureState {}
class FeatureInitial extends FeatureState {}
class FeatureLoading extends FeatureState {}
class FeatureLoaded extends FeatureState { final Data data; }
class FeatureError extends FeatureState { final String message; }
```

### Widget pattern para consumir
```dart
// No build():
final state = ref.watch(featureNotifierProvider);
return switch (state) {
  FeatureInitial() => const SizedBox.shrink(),
  FeatureLoading() => const _SkeletonContent(), // skeleton, nunca overlay global
  FeatureLoaded(:final data) => _buildContent(data),
  FeatureError(:final message) => AppErrorWidget(
    message: message,
    onRetry: () => ref.read(featureNotifierProvider.notifier).load(),
  ),
};
```

### Empty State (quando FeatureLoaded mas lista vazia)
```dart
// Dentro de _buildContent:
if (data.items.isEmpty) {
  return AppEmptyState(
    icon: Icons.store,
    title: 'Nenhum PDV encontrado',
    subtitle: 'Crie uma região primeiro para começar a cadastrar PDVs.',
    actionLabel: 'Criar região',
    onAction: () => context.go('/regions/create'),
  );
}
```

---

## 2. BOTÕES — COMPORTAMENTO PADRÃO

### Loading interno (OBRIGATÓRIO em todo botão que chama backend)
```dart
// AppButton já deve ter prop isLoading:
AppButton.primary(
  label: 'Salvar',
  isLoading: state is FeatureLoading,
  onPressed: state is FeatureLoading ? null : _onSubmit,
)

// Interno: quando isLoading = true
// - Texto some (opacity 0)
// - CircularProgressIndicator(strokeWidth: 2, color: Colors.white) aparece
// - Botão mantém exatamente o mesmo tamanho
// - onPressed é null (ignora taps)
```

### Disabled
- `onPressed: null` → Flutter aplica opacity automaticamente
- Cursor: default (não pointer)
- Visual: opacity 0.5 do estado normal

### Duplo clique prevention
- Sempre checar `if (state is Loading) return;` no handler
- Botão com `onPressed: null` durante loading já previne nativamente

### Hierarquia (1 primary por tela)
| Tipo | Quando | Exemplo |
|------|--------|---------|
| Primary | Ação principal (1 por tela) | "Entrar", "Salvar", "Avançar" |
| Secondary | Ação secundária | "Cancelar", "Voltar" |
| Social | Login social | "Entrar com Google" |
| Danger | Ação destrutiva | "Excluir" (requer confirmação) |
| Text/Link | Navegação leve | "Esqueceu senha?", "Ver mais" |

### Pares de botões (navegação)
```
Row(mainAxisAlignment: MainAxisAlignment.spaceBetween)
├── AppButton.secondary("← Voltar")   // esquerda, sempre enabled
└── AppButton.primary("Avançar →")     // direita, pode ter loading/disabled
```

---

## 3. FORMULÁRIOS — VALIDAÇÃO PADRÃO

### Regra única (NUNCA desviar)
```dart
// No State:
bool _submitted = false;

// No Form: NÃO passar autovalidateMode (usar default disabled)
Form(key: _formKey, child: ...)

// Em CADA validator:
validator: (value) {
  if (!_submitted) return null;  // ← SEMPRE primeiro
  if (value == null || value.isEmpty) return 'Campo obrigatório';
  // ... validação específica
}

// No botão submit:
void _onSubmit() {
  setState(() => _submitted = true);
  if (!_formKey.currentState!.validate()) return;
  // chamar notifier...
}
```

### O que NÃO fazer
- ❌ `AutovalidateMode.onUserInteraction`
- ❌ `AutovalidateMode.always`
- ❌ Validar no `onChanged` com erro visual
- ❌ FocusNode + onBlur para validação (complexidade desnecessária)

### Feedback positivo em tempo real (PERMITIDO)
Esses NÃO são erros — são feedback visual via `onChanged`:
- Password strength checklist (cores verde/cinza)
- Email availability check (debounce → "Verificando..." / "Disponível" ✓)
- Character counter
- CNPJ mask auto-format

### Validators centralizados (AppValidators)
| Método | Input | Output (se inválido) |
|--------|-------|---------------------|
| `email(value)` | String? | "Informe seu e-mail" / "E-mail inválido" |
| `password(value)` | String? | "Informe uma senha" / "Mínimo 8 caracteres" / "Inclua maiúscula" / "Inclua minúscula" |
| `confirmPassword(value, password)` | String?, String | "Confirme sua senha" / "Senhas não coincidem" |
| `name(value)` | String? | "Informe seu nome" / "Nome muito curto" |
| `cnpj(value)` | String? | "Informe o CNPJ" / "CNPJ inválido" |
| `cpf(value)` | String? | "Informe o CPF" / "CPF inválido" |
| `phone(value)` | String? | "Informe o telefone" / "Telefone inválido" |
| `cep(value)` | String? | "Informe o CEP" / "CEP inválido" |
| `required(value)` | String? | "Campo obrigatório" |

Todos retornam `null` se válido, `String` se inválido.
Todos devem ser guardados com `if (!_submitted) return null;` no widget.

---

## 4. ÍCONES — REGRA GLOBAL

### Usar SOMENTE Material Icons
```dart
// CORRETO:
Icons.email_outlined
Icons.visibility_off

// PROIBIDO:
CupertinoIcons.mail            // ❌
FontAwesomeIcons.lock          // ❌ (exceto: FontAwesomeIcons.squareGooglePlus no botão social)
CustomIcons.something          // ❌ (salvo SVG local aprovado)
```

### Exceção aprovada
`FontAwesomeIcons.squareGooglePlus` — permitido exclusivamente no botão "Entrar com Google" (login e register). Nenhum outro ícone FontAwesome.

### Se precisar ícone customizado
1. Criar SVG e salvar em `assets/icons/`
2. Usar `SvgPicture.asset('assets/icons/nome.svg', width: 24)`
3. Nunca adicionar pacote de ícones novo sem aprovação

### Tabela completa: ver DESIGN_SYSTEM.md seção 8

---

## 5. NAVEGAÇÃO — PADRÕES

### GoRouter
- Toda rota definida em `AppRoutes` (constantes)
- Nenhum path literal espalhado no código
- Paths: kebab-case (`/email-verification`, não `/emailVerification`)

### Redirect guards
- 3 zonas: pública, email-verify, protegida
- Lógica centralizada em `RouterNotifier.redirect()`
- Detalhes completos: ver AUTH_FLOW.md

### Transições
- Padrão: fade 300ms (GoRouter default)
- Sem custom transitions

### Deep links
- IDs em path params ok (`/pdvs/:id`)
- Dados sensíveis NUNCA em params (email, tokens, etc)

---

## 6. RESPONSIVIDADE

### Breakpoints
```dart
class Breakpoints {
  static const double mobile = 600;   // < 600px
  static const double tablet = 1200;  // 600–1200px
  // > 1200px = desktop
}
```

### Uso
```dart
// Via ResponsiveLayout (já existe):
ResponsiveLayout(
  mobile: MobileLoginScreen(),
  tablet: TabletLoginScreen(),   // optional, fallback to mobile
  desktop: DesktopLoginScreen(), // optional, fallback to tablet
)

// Via LayoutBuilder pontual:
LayoutBuilder(builder: (context, constraints) {
  final isMobile = constraints.maxWidth < Breakpoints.mobile;
  // ...
})
```

### Regras
- Nunca largura fixa sem fallback
- Auth screens: card centralizado (420px) em desktop, full-width em mobile
- Internal screens: sidebar (desktop) vs bottom nav (mobile)
- Testar sempre no Chrome com viewport 375px (mobile)

---

## 7. ERROS — HIERARQUIA

### AppException (sealed)
```
AppException (sealed, abstract)
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

### Regras
- Repository: throws AppException
- Notifier: catches → seta ErrorState(exception.message)
- Widget: lê ErrorState → mostra mensagem
- Mensagens SEMPRE em PT-BR, user-friendly, max 1 linha
- Nunca mostrar stack trace ou erro raw do Supabase

---

## 8. LOADING — PADRÕES

| Tipo | Quando usar | Implementação |
|------|-------------|---------------|
| Botão loading | Submit de form, ação pontual | Spinner dentro do botão (18px) |
| Skeleton | Carregamento de lista/conteúdo | Shimmer nos cards placeholder |
| Inline | Busca em campo (debounce) | Texto "Verificando..." ou spinner 14px |

### Proibido
- `AppLoadingOverlay` ou qualquer spinner de tela inteira — removido do projeto
- Loading global bloqueante em ações de formulário ou auth
- Texto "Carregando..." sozinho sem spinner
- Loading infinito sem timeout (max 30s → mostrar erro)

### Regra
Loading acontece **no botão da ação**. O usuário sabe exatamente o que está em andamento.

---

## 9. FEEDBACK — PADRÕES

### Modal centralizado (`showAppFeedbackDialog`) — padrão principal

Usar para:
- Sucesso de ação crítica (trocar senha, salvar dados importantes)
- Erro de autenticação ou regra de negócio que requer atenção explícita
- Qualquer feedback que não pode ser ignorado

### `AppErrorBox` — erros inline

Usar em formulários para exibir erro de auth/backend acima do botão de submit.
Não usar SnackBar para erros de formulário.

### SnackBar — feedback leve e transitório

Usar apenas para:
- Info passageira (ex: "Link copiado", "Filtro aplicado")
- Confirmação não-crítica de ações reversíveis (ex: "Região criada")

### Proibido
- SnackBar para erros de formulário
- SnackBar para erros de autenticação
- SnackBar como substituto de modal em ações críticas

---

## 10. NOMENCLATURA

### Arquivos (snake_case)
```
{feature_name}_screen.dart
{feature_name}_repository.dart
{feature_name}_state.dart
{feature_name}_provider.dart
{feature_name}_model.dart
app_{widget_name}.dart          # shared widgets
```

### Classes (PascalCase)
```
{FeatureName}Screen
{FeatureName}Repository
{FeatureName}State
{FeatureName}Notifier
{FeatureName}Model
App{WidgetName}                  # shared widgets
```

### Providers (camelCase)
```
{featureName}RepositoryProvider
{featureName}NotifierProvider
{featureName}StreamProvider
```

### Idioma
- Código: inglês
- Mensagens UI: PT-BR
- Comentários: PT-BR quando necessário (raro)
- Docs: PT-BR

---

## 11. ESTRUTURA DE FEATURE (TEMPLATE)

```
lib/features/{name}/
├── data/
│   └── {name}_repository.dart       # Supabase calls, throws AppException
├── domain/
│   ├── {name}_state.dart             # Sealed state class
│   └── {name}_model.dart             # Domain models (fromJson/toJson)
└── presentation/
    ├── providers/
    │   └── {name}_provider.dart      # StateNotifier + Providers
    └── screens/
        └── {name}_screen.dart        # UI pura, chama notifier, lê state
```

### Regras
- Nunca criar estrutura diferente sem aprovação
- Cada feature é independente (imports entre features → via providers)
- Shared code vai em `lib/shared/`
- Core code vai em `lib/core/`
