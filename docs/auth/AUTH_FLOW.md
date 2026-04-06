# AUTH_FLOW.md — EANTrack (FINAL)

> Fluxo completo de autenticação. Zero ambiguidade.
> Versão: 2.0 — inclui edge cases, method signatures e diagramas de transição.

---

## MAPA GERAL

```
┌─────────┐     ┌──────────┐     ┌──────────────────┐     ┌────────────┐
│  LOGIN   │────→│ REGISTER │────→│ EMAIL VERIFY     │────→│ ONBOARDING │
│  /login  │     │ /register│     │ /email-verify     │     │ /onboarding│
└────┬─────┘     └──────────┘     └──────────────────┘     └─────┬──────┘
     │                                                           │
     │  (já autenticado + email ok + onboarding ok)              │
     └───────────────────────────────────────────────────────────┘
                              │
                         ┌────▼────┐
                         │   HUB   │
                         │  /hub   │
                         └─────────┘

┌──────────────────┐
│ RECOVER PASSWORD │  (fluxo isolado)
│ /recover-password│
└──────────────────┘
```

---

## FLUXO 1: LOGIN

### Trigger
Usuário clica "Entrar" em `/login`.

### Sequência exata
```
1. setState(() => _submitted = true)
2. _formKey.currentState!.validate()
   └─ se false → PARA (erros aparecem nos campos)
3. ref.read(authNotifierProvider.notifier).signIn(email, password)
4. AuthNotifier:
   a. state = AuthLoading()
   b. await _repository.signIn(email, password)
5. AuthRepository.signIn():
   a. final response = await _client.auth.signInWithPassword(
        email: email, password: password)
   b. se AuthException → throw AppException mapeada
   c. se sucesso → return (Supabase session ativa)
6. AuthNotifier:
   a. se catch → state = AuthError(message)
   b. se sucesso → Supabase emite auth event
7. authUserStreamProvider emite novo User
8. RouterNotifier.redirect() executa:
   a. user == null → /login
   b. email não confirmado → /email-verification
   c. getUserFlowState() → check onboarding
      - incompleto → /onboarding
      - completo → /hub
```

### Mapeamento de erros
| AuthException code | AppException | Mensagem PT-BR |
|-------------------|-------------|----------------|
| `invalid_grant` | `InvalidCredentialsException` | "E-mail ou senha incorretos." |
| `Invalid login credentials` | `InvalidCredentialsException` | "E-mail ou senha incorretos." |
| `email_not_confirmed` | `EmailNotConfirmedException` | (redirect, não mostra mensagem) |
| `user_not_found` | `InvalidCredentialsException` | "E-mail ou senha incorretos." |
| `too_many_requests` | `ServerException` | "Muitas tentativas. Aguarde alguns minutos." |
| SocketException / TimeoutException | `NetworkException` | "Sem conexão. Verifique sua internet." |
| Qualquer outro | `ServerException` | "Erro inesperado. Tente novamente." |

### Edge cases
- **Duplo clique:** botão em loading ignora taps adicionais (`if state is AuthLoading return`)
- **Session expirada:** `authUserStreamProvider` emite null → redirect `/login`
- **Email confirmado durante login:** redirect normal (não vai para email-verify)

---

## FLUXO 2: REGISTRO

### Trigger
Usuário clica "Avançar" em `/register` (tab Informações).

### Sequência exata
```
1. setState(() => _submitted = true)
2. _formKey.currentState!.validate()
   └─ se false → PARA
3. ref.read(authNotifierProvider.notifier).signUp(email, password, name)
4. AuthNotifier:
   a. state = AuthLoading()
   b. await _repository.signUp(email, password, name)
5. AuthRepository.signUp():
   a. // Check email disponível
      final hash = sha256.convert(utf8.encode(email.toLowerCase())).toString()
      final exists = await _client.rpc('email_code_exists', params: {'p_hash': hash})
      se exists == true → throw EmailAlreadyInUseException()
   b. // Criar conta
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': name},
      )
   c. // Registrar hash
      await _client.rpc('insert_email_code', params: {
        'p_hash': hash,
        'p_user_id': response.user!.id,
      })
   d. return
6. AuthNotifier:
   a. se catch → state = AuthError(message)
   b. se sucesso → state = AuthEmailUnconfirmed(email: email)
7. RouterNotifier detecta → redirect /email-verification
```

### Mapeamento de erros
| Situação | AppException | Mensagem PT-BR |
|----------|-------------|----------------|
| Email já existe (RPC) | `EmailAlreadyInUseException` | "Este e-mail já está cadastrado." |
| Supabase signup falha | `ServerException` | "Erro ao criar conta. Tente novamente." |
| Senha fraca (Supabase) | `AuthAppException` | "Senha não atende aos requisitos mínimos." |
| Network error | `NetworkException` | "Sem conexão. Verifique sua internet." |

### Validações de campo (executam só quando `_submitted == true`)
| Campo | Validators (em ordem) |
|-------|----------------------|
| Nome | `isEmpty` → "Informe seu nome" / `length < 2` → "Nome deve ter pelo menos 2 caracteres" |
| Email | `isEmpty` → "Informe seu e-mail" / `!RegExp(emailPattern).hasMatch` → "E-mail inválido" |
| Senha | `isEmpty` → "Informe uma senha" / `length < 8` → "Mínimo 8 caracteres" / `!RegExp(r'[A-Z]')` → "Inclua uma letra maiúscula" / `!RegExp(r'[a-z]')` → "Inclua uma letra minúscula" |
| Confirmar | `isEmpty` → "Confirme sua senha" / `!= senha` → "As senhas não coincidem" |

### Email debounce (independente da validação)
```dart
// Timer no State:
Timer? _emailDebounce;

// onChanged do campo email:
onChanged: (value) {
  _emailDebounce?.cancel();
  _emailDebounce = Timer(Duration(milliseconds: 800), () {
    _checkEmailAvailability(value);
  });
}

// _checkEmailAvailability:
// seta _emailChecking = true (mostra "Verificando...")
// chama repository.checkEmailAvailable(value)
// seta _emailAvailable = true/false
// seta _emailChecking = false
```
- Esse check é visual/informativo
- NÃO impede submit (o validator + signUp RPC fazem a validação real)

---

## FLUXO 3: EMAIL VERIFICATION (DETALHE MÁXIMO)

### Contexto
Após registro, Supabase envia email de verificação automaticamente.
Usuário fica nesta tela até confirmar.
Três mecanismos de detecção + controle de reenvio.

### Tela: `/email-verification`

---

### MECANISMO 1: Polling silencioso

**O que faz:** Verifica periodicamente se o email foi confirmado, sem feedback visual.

**Implementação:**
```dart
// No initState:
late final StreamSubscription _pollingSub;

_pollingSub = Stream.periodic(const Duration(seconds: 3)).listen((_) async {
  if (_status == EmailVerificationStatus.confirmed) return;
  if (_status == EmailVerificationStatus.checking) return; // evita conflito
  
  try {
    final confirmed = await ref.read(authRepositoryProvider).isEmailConfirmed(email);
    if (confirmed && mounted) {
      _onEmailConfirmed();
    }
  } catch (_) {
    // Silencioso — não mostrar erro do polling
  }
});

// No dispose:
_pollingSub.cancel();
```

**Regras:**
- Intervalo: 3 segundos
- Inicia automaticamente ao entrar na tela
- Sem limite de tentativas (cancela no dispose)
- Sem indicador visual (completamente silencioso)
- Se `_status == checking` → pula iteração (evita conflito com botão "Já confirmei")
- Se `_status == confirmed` → pula (já está em transição)
- Erros do polling são silenciados (não mostrar ao usuário)
- Cancela imediatamente no `dispose()`

**Quando detecta confirmação:**
```dart
void _onEmailConfirmed() {
  setState(() => _status = EmailVerificationStatus.confirmed);
  _pollingSub.cancel();
  // Aguarda animação Lottie (1.5s) → redirect
  Future.delayed(const Duration(milliseconds: 1500), () {
    if (mounted) context.go('/onboarding');
  });
}
```

---

### MECANISMO 2: Botão "Já confirmei"

**O que faz:** Check manual sob demanda.

**Sequência completa:**
```
1. Usuário clica "Já confirmei"
2. setState(() => _status = EmailVerificationStatus.checking)
   → botão mostra spinner
   → polling pula iterações (vê status == checking)
3. final confirmed = await repository.isEmailConfirmed(email)
4A. SE CONFIRMADO:
   → _onEmailConfirmed() (mesmo handler do polling)
   → Animação Lottie checkmark verde (500ms elasticOut)
   → Título muda para "Conta Confirmada!" (cor success)
   → Aguarda 1.5s
   → context.go('/onboarding')
4B. SE NÃO CONFIRMADO:
   → setState(() {
       _status = EmailVerificationStatus.error;
       _errorMessage = "E-mail ainda não confirmado. Verifique sua caixa de entrada.";
     })
   → Após 3s: setState(() => _status = EmailVerificationStatus.waiting)
   → Polling continua
5. SE ERRO (network etc):
   → setState(() {
       _status = EmailVerificationStatus.error;
       _errorMessage = "Erro ao verificar. Tente novamente.";
     })
   → Após 3s: setState(() => _status = EmailVerificationStatus.waiting)
```

**AuthRepository.isEmailConfirmed:**
```dart
Future<bool> isEmailConfirmed(String email) async {
  try {
    final response = await _client.rpc(
      'is_email_confirmed_status',
      params: {'p_email': email},
    );
    // response é jsonb — extrair campo de confirmação
    return response['confirmed'] == true;
  } on PostgrestException catch (e) {
    throw ServerException(e.message);
  }
}
```

---

### MECANISMO 3: Botão "Reenviar"

**O que faz:** Reenvia email de verificação + ativa cooldown.

**Sequência completa:**
```
1. Usuário clica "Reenviar verificação"
2. SE _resendCount >= 3:
   → mostrar "Limite atingido. Aguarde 30 minutos."
   → PARA (não envia)
3. setState(() => _status = EmailVerificationStatus.resending)
   → Botão reenviar mostra spinner
4. await Supabase.auth.resend(type: OtpType.signup, email: email)
5A. SE SUCESSO:
   → _resendCount++
   → Ativar cooldown via EmailCooldownNotifier:
     ref.read(emailCooldownProvider.notifier).startCooldown()
   → setState(() => _status = EmailVerificationStatus.cooldown)
   → UI mostra:
     - Botão reenviar disabled
     - LinearProgressIndicator (value: remaining/300)
     - Texto: "Reenviado! Aguarde X:XX" (minutos:segundos)
   → Ao terminar cooldown (300s):
     setState(() => _status = EmailVerificationStatus.waiting)
5B. SE ERRO:
   → setState(() {
       _status = EmailVerificationStatus.error;
       _errorMessage = "Erro ao reenviar. Tente novamente.";
     })
   → Após 3s: setState(() => _status = EmailVerificationStatus.waiting)
   → NÃO ativa cooldown em caso de erro
```

**EmailCooldownNotifier (já existe no projeto):**
```dart
class EmailCooldownNotifier extends StateNotifier<EmailCooldownState> {
  // State: { secondsRemaining: int, isActive: bool }
  // startCooldown(): inicia Timer.periodic(1s) decrementando
  // Ao chegar em 0: state = EmailCooldownState(0, false)
}

// Provider:
final emailCooldownProvider = StateNotifierProvider<EmailCooldownNotifier, EmailCooldownState>(...);
```

**Cooldown visual:**
```dart
// Barra de progresso:
LinearProgressIndicator(
  value: cooldownState.secondsRemaining / 300,
  backgroundColor: borderDefault,
  color: link,
)

// Texto timer:
String _formatTime(int seconds) {
  final min = seconds ~/ 60;
  final sec = seconds % 60;
  return '$min:${sec.toString().padLeft(2, '0')}';
}
// Resultado: "4:32", "0:15", etc
```

**Controle de tentativas:**
- `int _resendCount = 0` no State
- Max 3 reenvios → após o 3º, mostrar "Limite atingido"
- Resetado quando email é confirmado
- NÃO persistido no backend (só local, no State)
- Se usuário sair e voltar da tela → contador reseta (aceitável)

---

### ESTADOS DA TELA (ENUM)

```dart
enum EmailVerificationStatus {
  waiting,    // Polling ativo, UI padrão
  checking,   // Botão "Já confirmei" clicado, spinner no botão
  resending,  // Reenviando email, spinner no link/botão reenviar
  cooldown,   // Cooldown ativo, barra de progresso visível
  confirmed,  // Email confirmado! Lottie + redirect
  error,      // Erro temporário (3s) → volta para waiting
}
```

### DIAGRAMA DE TRANSIÇÕES (COMPLETO)

```
                 ┌──────────────────────────────────────┐
                 │                                      │
    ┌────────────▼───────────┐                          │
    │       WAITING          │                          │
    │ (polling ativo)        │                          │
    └──┬────────┬────────┬───┘                          │
       │        │        │                              │
  [polling]  [clica    [clica                           │
  [detecta]  "Já       "Reenviar"]                      │
       │     confirmei"]  │                             │
       │        │         │                             │
       │   ┌────▼────┐  ┌─▼──────────┐                 │
       │   │CHECKING │  │ RESENDING  │                  │
       │   │(spinner)│  │ (spinner)  │                  │
       │   └──┬───┬──┘  └──┬─────┬──┘                  │
       │   [ok] [!ok]   [ok]   [erro]                   │
       │     │    │       │      │                      │
       │     │    │  ┌────▼───┐  │                      │
       │     │    │  │COOLDOWN│  │                      │
       │     │    │  │(5 min) │  │                      │
       │     │    │  └───┬────┘  │                      │
       │     │    │   [timer    │                       │
       │     │    │    expirou]  │                      │
       │     │    │      │      │                       │
       │     │  ┌─▼──────▼──────▼──┐                    │
       │     │  │      ERROR       │──── (3s) ──────────┘
       │     │  │  (msg temporária)│
       │     │  └──────────────────┘
       │     │
  ┌────▼─────▼───┐
  │  CONFIRMED   │
  │ (Lottie 1.5s)│
  └──────┬───────┘
         │
    [redirect]
         │
  ┌──────▼───────┐
  │ /onboarding  │
  └──────────────┘
```

### UI COMPLETA POR ESTADO

| Estado | Título | Subtítulo | Botão principal | Link reenviar | Barra | Extra |
|--------|--------|-----------|-----------------|---------------|-------|-------|
| waiting | "Confirme sua conta" | "verifique seu e-mail..." | "Já confirmei" (enabled) | "Reenviar verificação" (enabled) | hidden | — |
| checking | "Confirme sua conta" | "verifique seu e-mail..." | Spinner 18px | disabled | hidden | — |
| resending | "Confirme sua conta" | "verifique seu e-mail..." | disabled | Spinner texto | hidden | — |
| cooldown | "Confirme sua conta" | "verifique seu e-mail..." | "Já confirmei" (enabled) | disabled + "X:XX" | LinearProgress | — |
| confirmed | "Conta Confirmada!" ✅ | "Bem-vindo ao EANTrack" | "Continuar" (enabled) | hidden | hidden | Lottie checkmark |
| error | "Confirme sua conta" | "verifique seu e-mail..." | "Já confirmei" (enabled) | "Reenviar" (enabled) | hidden | ErrorBanner com msg |

---

## FLUXO 4: RECOVER PASSWORD

### Sequência
```
1. setState(() => _submitted = true)
2. _formKey.currentState!.validate()
   └─ se false → PARA
3. ref.read(authNotifierProvider.notifier).resetPassword(email)
4. AuthRepository:
   await _client.auth.resetPasswordForEmail(email)
5. Sucesso → _showSuccess = true → banner verde "Link enviado para seu email"
6. Erro → AuthError(message) → ErrorBanner
7. Usuário recebe email → clica link → Supabase handle → redirect /login
```

### Após envio bem-sucedido
- Banner verde permanece visível
- Botão muda para "Reenviar" (com cooldown simples de 60s)
- Link "← Voltar ao login" sempre disponível

---

## FLUXO 5: CHANGE PASSWORD (troca de senha via recovery link)

### Contexto
Usuário recebe link de recovery por email → clica → Supabase injeta sessão com `AuthChangeEvent.passwordRecovery` → app detecta via `AuthRecoveryContextNotifier` → `authFlowStateProvider` retorna `AuthFlowState.recovery` → GoRouter permite acesso a `/update-password`.

### Método: `AuthRepository.changePassword(newPassword)`

Fluxo linear e atômico — os 3 passos rodam na mesma chamada:

```
STEP 1 — check reuse (RPC)
  ↓ check_password_reuse_current_user(p_new_password, p_history_limit: 3)
  ↓ parse resultado via PasswordReuseCheckResult.fromRpcResponse
  ↓ se !allowed → throw PasswordReusedException (mensagem específica)

STEP 2 — updateUser (Supabase Auth)
  ↓ _client.auth.updateUser(UserAttributes(password: newPassword))
  ↓ se 422 / same_password → throw SamePasswordException
  ↓ se outro AuthException → throw AuthAppException

STEP 3 — register history (RPC)
  ↓ register_password_history_current_user(p_password, p_keep_last: 3)
  ↓ se PostgrestException → throw PasswordHistoryRegisterException
```

### Tratamento de erros

| Exceção | Causa | Mensagem ao usuário |
|---|---|---|
| `SamePasswordException` | STEP 2: Supabase 422 | "A nova senha deve ser diferente da atual." |
| `PasswordReusedException` | STEP 1: RPC retorna `allowed: false` | "Você já usou essa senha antes. Escolha uma diferente." |
| `PasswordReuseCheckException` | STEP 1: RPC falhou | "Não foi possível validar sua nova senha. Tente novamente." |
| `PasswordHistoryRegisterException` | STEP 3: RPC falhou | "Não foi possível registrar o histórico da senha." |

### Após sucesso
1. Modal de sucesso via `showAppFeedbackDialog`
2. `authNotifierProvider.notifier.signOut()`
3. GoRouter detecta `AuthUnauthenticated` → redirect `/login`

### Links expirados
Se o usuário clicar em link de recovery expirado, a URL contém `error=access_denied` ou `error_code=otp_expired`. O GoRouter detecta esses parâmetros no redirect e envia para `/password-recovery-link-expired`.

---

## GUARDS DE ROTA (RouterNotifier.redirect)

### Lógica resumida (em ordem de prioridade)

```
1. URL contém error=access_denied / error_code=otp_expired
   → redirect /password-recovery-link-expired

2. path == /splash | /flow | /password-recovery-link-expired
   → null (sem redirect — essas rotas se auto-gerenciam)

3. path == /update-password && authFlowState != recovery
   → redirect /flow

4. isGuestRoute && authFlowState != unauthenticated
   → redirect /flow

5. isOnboardingRoute && authFlowState != onboardingRequired
   → redirect /flow

6. isAppRoute && authFlowState != authenticated
   → redirect /flow

7. qualquer outro caso → null (permitir)
```

`authFlowState` é derivado de `authFlowStateProvider` (Riverpod) com base em:
- `isRecovery` (AuthRecoveryContextNotifier detecta `passwordRecovery` event)
- `authUser` (authUserStreamProvider)
- `isOnboardingComplete` (authOnboardingCompleteProvider)

---

## SESSÃO

| Aspecto | Detalhe |
|---------|---------|
| Gerenciamento | 100% Supabase Auth (JWT) |
| Persistência | Automática (supabase_flutter) |
| Stream | `authUserStreamProvider` (StreamProvider<User?>) |
| Token refresh | Automático pelo SDK |
| Sign-out | `Supabase.auth.signOut()` → stream emite null → redirect /login |
| Token expiry | Supabase refresh automático (não precisa tratar) |
