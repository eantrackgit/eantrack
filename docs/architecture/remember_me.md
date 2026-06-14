# remember_me.md — EANTrack (FINAL)

> Arquitetura da feature "Lembrar-me" (keep_connected). Fonte de verdade para
> o fluxo de conta lembrada no dispositivo, separação Banco/Local/Auth e
> regras de escrita.
> Versão: 1.0

---

## 1. Objetivo

Lembrar a conta no dispositivo para facilitar login futuro.

A feature existe para reduzir fricção: ao reabrir o app, o usuário que marcou
"Lembrar-me" vê sua conta pronta para entrar (e-mail preenchido, identidade
reconhecível) em vez de uma tela de login em branco.

---

## 2. O que a feature NÃO faz

- **Não aumenta o tempo de sessão** — a duração/renovação do token continua
  100% controlada pelo Supabase Auth (`autoRefreshToken: true`).
- **Não cria sessão "infinita"** — se `keep_connected = false`, a sessão
  restaurada automaticamente no boot é encerrada localmente
  (`signOut(scope: SignOutScope.local)`); o usuário precisa logar de novo.
- **Não salva senha.**
- **Não salva token nem refresh token.**
- **Não salva e-mail no banco** — `savedLoginEmail` vive apenas em
  `SharedPreferences`, no dispositivo.
- **Não salva displayName no banco** — `savedDisplayName` é cache local,
  usado só para iniciais/avatar do cartão de conta salva.
- **Não substitui o Supabase Auth** — quem decide se a sessão é válida é
  sempre o Supabase (`onAuthStateChange`, `currentUser`); `keep_connected` é
  apenas uma preferência sobre o que fazer com uma sessão já válida.
- **Não cria tabela nova, não altera schema, não altera RLS.**

---

## 3. Responsabilidades por camada

| Camada | O que guarda | Exemplos |
|---|---|---|
| **Banco** (`public.user_settings`) | Preferência oficial leve | `keep_connected boolean` — única coluna desta feature |
| **Local storage** (`SharedPreferences`) | Cache de UX | `savedLoginEmail`, `savedDisplayName`, `keep_connected_prompt_answered_<userId>` |
| **Supabase Auth** | Sessão / autenticação | `currentUser`, `user.id`, `user.email`, `user.userMetadata`, JWT, refresh token |
| **Router / onboarding** | Autorização e destino pós-login | `authFlowStateProvider`, `FlowScreen`, rotas de onboarding |

Regra central: **Banco = preferência oficial leve / Local storage = UX /
Supabase Auth = sessão e autenticação / Router e onboarding = autorização e
contexto do app.** Nenhuma camada duplica a responsabilidade da outra.

Chaves locais (`lib/shared/data/keep_connected_prompt_storage.dart`):

| Chave | Conteúdo | Uso |
|---|---|---|
| `eantrack_keep_connected_email` | e-mail normalizado (lowercase) | Cartão "Conta salva" no login |
| `eantrack_keep_connected_display_name` | nome de exibição | Iniciais do avatar no cartão |
| `keep_connected_prompt_answered_<userId>` | bool | Evita reexibir o diálogo "Lembrar-me?" |

---

## 4. Fluxos

### 4.1 Boot / F5 com sessão restaurada

```
main.dart → _applyKeepConnectedPreferenceToRestoredSession()
  1. Se a URL tem parâmetros de callback OAuth → não faz nada (deixa o
     callback ser tratado pelo fluxo normal).
  2. Se não há usuário restaurado (currentUser == null) → não faz nada.
  3. getKeepConnected(user.id)        -- 1 SELECT
     ├─ erro de leitura → fail-open (ver seção 4.9), nenhuma escrita.
     ├─ KeepConnectedBootCache.set(user.id, valor)  -- entrega o valor já
     │   lido para o load() de app.dart, evitando 2º SELECT.
     ├─ true  → mantém sessão restaurada.
     └─ false → clearSavedLoginEmail() (local) +
                signOut(scope: SignOutScope.local) (sessão local apenas).
```

Em seguida, `app.dart` (`_EanTrackAppState.initState`) chama
`keepConnectedController.load(userId: user.id)`. Esse `load()` primeiro tenta
`KeepConnectedBootCache.consume(user.id)`: se o valor já foi lido por
`main.dart`, é reaproveitado e **nenhum segundo SELECT ocorre**.

O `ref.listen(authUserStreamProvider, ...)` em `app.dart` também pode chamar
`load(userId: user.id)` para a emissão inicial do stream — o
`_loadedUserId` interno do controller faz dessa segunda chamada um no-op.

### 4.2 Login tradicional

```
LoginScreen → authNotifierProvider.notifier.signIn(email, password)
  → AuthRepository.signIn() → Supabase signInWithPassword
  → AuthAuthenticated(user, flowState)
  → authFlowStateProvider recalcula → FlowScreen._decide()
       case authenticated / onboardingRequired:
         _ensureKeepConnectedPromptAnswered(user)
           → controller.syncAfterLogin(user.id, user.email)   -- 1 SELECT
               keepConnected == true  → salva savedLoginEmail + savedDisplayName
               keepConnected == false → limpa savedLoginEmail + savedDisplayName
           → shouldShowPrompt(user.id) (100% local)
               true  → showKeepConnectedPromptDialog
               false → segue
       → navega para hub/onboarding
```

### 4.3 OAuth Google — callback

```
signInWithGoogle() → state = AuthLoading('Entrando com Google...')
  → browser redireciona para o Google e volta com a sessão Supabase
  → authUserStreamProvider emite o novo User
  → AuthNotifier.onExternalAuthChange(user)
       state = AuthLoading('Verificando...')
       flowState = getUserFlowState(user.id)
       state = AuthAuthenticated(user, flowState)
```

Enquanto `AuthNotifier` ainda está em `AuthLoading`, `authFlowStateProvider`
pode já reportar `onboardingRequired` (porque `authUser` já existe no stream,
mas `authState` ainda não é `AuthAuthenticated`). `FlowScreen._decide()`
chama `_resolveOnboardingRouteFromState()`, que verifica:

```dart
final authState = ref.read(authNotifierProvider);
if (authState is! AuthAuthenticated) return; // aguarda
```

Ou seja: **nenhuma leitura/sincronização de Remember Me (`syncAfterLogin`,
`clearSavedLoginEmail`) acontece enquanto o login OAuth ainda está sendo
verificado.** Quando `onExternalAuthChange` termina e o estado vira
`AuthAuthenticated`, `authFlowStateProvider` reemite, `FlowScreen` decide de
novo — agora com o usuário já confirmado — e segue o mesmo caminho do item
4.2 (`syncAfterLogin` → prompt → navegação).

Isso garante que o callback OAuth do Google **não pode limpar o cache local
("Conta salva") de outra conta antes de a autenticação/onboarding estarem
decididos**, e não há perda silenciosa de cache de outro usuário.

### 4.4 `syncAfterLogin` (resumo)

`KeepConnectedController.syncAfterLogin(userId, loginEmail)`:

1. `load(userId: userId)` — 1 SELECT real (ou reaproveita boot cache /
   `_loadedUserId` se já lido nesta sessão).
2. Se erro de leitura → não toca no cache local (mantém estado anterior).
3. `keepConnected == true` → `saveSavedLoginEmail(loginEmail)` +
   `saveSavedDisplayName(resolveDisplayNameFromUser(currentUser))`.
4. `keepConnected == false` → `clearSavedLoginEmail()` (limpa e-mail e nome
   juntos — ver `KeepConnectedPromptStorage.clearSavedLoginEmail`).

### 4.5 Diálogo "Lembrar-me?"

- Mostrado no máximo uma vez por `userId`/dispositivo
  (`shouldShowPrompt` → `wasPromptAnswered`, 100% local, sem SELECT).
- "Sim, lembrar-me" / "Agora não" → `answerPrompt(userId, value, loginEmail)`
  → `setKeepConnected(...)` (grava no banco) + `markPromptAnswered(userId)`.
- "Agora não" **não** interrompe a sessão recém-autenticada — apenas registra
  a preferência para os próximos boots.

### 4.6 Preferências (UserSettingsDialog)

- Ao abrir: `load(forceRefresh: true)` — sempre reflete o valor atual do
  banco, mesmo que o boot/login já tenha lido este `userId` na sessão.
- Ao alternar o switch: `setKeepConnected(value)`.
  - Se `value == state.keepConnected` (sem mudança real) → **nenhuma leitura
    nem escrita no banco**, apenas sincroniza o cache local.
  - Se mudou → 1 UPDATE (`setKeepConnectedIfChanged`) + sincroniza cache
    local (`saveSavedLoginEmail`/`saveSavedDisplayName` ou
    `clearSavedLoginEmail`).

### 4.7 "Trocar" conta salva (LoginScreen)

- `_switchSavedLoginEmail()` chama apenas `clearSavedLoginEmail()` (local).
- **Não** altera `keep_connected` no banco — a preferência remota do usuário
  permanece a mesma; apenas o cartão de "conta salva" deste dispositivo é
  limpo para permitir digitar outro e-mail.

### 4.8 Logout

```
AuthNotifier.signOut():
  _isSigningOut = true
  1. load(userId: user.id)               -- garante keep_connected atual
  2. keepConnected == true
       → saveSavedLoginEmail(user.email) + saveSavedDisplayName(...)
     keepConnected == false
       → clearSavedLoginEmail()            -- limpa e-mail e nome juntos
  3. repo.signOut()                        -- encerra a sessão Supabase
  4. clearSessionState()                   -- zera estado em memória
  5. state = AuthUnauthenticated()
  _isSigningOut = false
```

O evento `signedOut` do stream do Supabase, disparado por `repo.signOut()`,
pode chegar ao `ref.listen(authUserStreamProvider, ...)` enquanto `signOut()`
ainda está em `await`. `onSignedOut()` verifica `_isSigningOut` e retorna
imediatamente nesse caso — **a lógica de cache/estado do logout roda uma
única vez**, não duas.

Se o `signedOut` for emitido **fora** de um `signOut()` explícito (logout
disparado por outra aba/sessão, por exemplo), `_isSigningOut` é `false` e
`onSignedOut()` aplica a mesma regra de preservar/limpar o cache local com
base no `keep_connected` conhecido.

### 4.9 Refresh token

`autoRefreshToken: true` faz o Supabase emitir `tokenRefreshed` periodicamente
para o **mesmo usuário**. Em `app.dart`:

```dart
if (previous?.valueOrNull?.id == user.id) return;
```

Esse early-return evita qualquer `load()`/SELECT em refresh de token. Não há,
em lugar nenhum do código desta feature, uma escrita (`setKeepConnected`)
disparada por evento automático — escrita só ocorre por ação explícita do
usuário (seção 5).

### 4.10 Fail-open no boot/F5

Se `getKeepConnected(user.id)` falhar no boot (`main.dart`), o erro é
capturado, logado via `debugPrint`, e a sessão restaurada **é mantida como
está** — o usuário não é deslogado por uma falha transitória de rede. Essa é
uma escolha consciente de confiabilidade/UX: um erro pontual de leitura não
pode custar um logout forçado. A preferência é checada de novo no próximo
boot/login. Nenhuma escrita no banco ocorre nesse caminho de erro.

---

## 5. Regras de escrita no banco

`user_settings.keep_connected` só é escrito (`setKeepConnectedIfChanged`) a
partir de **ação explícita do usuário**:

- Resposta ao diálogo "Lembrar-me?" (`answerPrompt`).
- Alternância do switch em Preferências (`setKeepConnected`).

**Nunca** é escrito por:

- Boot / F5 / `initState`.
- Emissão do `authUserStreamProvider` (login, logout, sessão restaurada).
- Refresh token.
- Redirecionamento de rota / `FlowScreen` / router.
- Renderização de qualquer tela.
- Leitura da preferência (`load`, `syncAfterLogin`, `forceRefresh`).

`setKeepConnected` também evita escrita redundante: se o valor solicitado já
é igual ao valor em `state` (e não há leitura em andamento), o método retorna
sem chamar o repositório — apenas sincroniza o cache local.

---

## 6. Escalabilidade (100k+ usuários)

- **Dedup por `userId`/sessão** — `KeepConnectedController._loadedUserId`
  garante no máximo 1 SELECT real por usuário por sessão de app, mesmo com
  múltiplos chamadores (`main.dart`, `app.dart`, `syncAfterLogin`).
- **Boot cache de uso único** — `KeepConnectedBootCache` evita que o SELECT
  feito antes do `runApp` seja repetido pelo `load()` de `app.dart`.
- **Refresh token não gera SELECT nem UPDATE** — o early-return por
  `user.id` igual em `app.dart` cobre o caso mais frequente em escala (a cada
  ~50 min por sessão ativa).
- **Eventos automáticos nunca escrevem** — apenas ações de UI explícitas
  chamam `setKeepConnectedIfChanged` (seção 5), eliminando picos de UPDATE
  por reconexão/refresh em massa.
- **Banco guarda só um boolean** — `user_settings.keep_connected` é a única
  coluna desta feature; nenhuma tabela nova, sem joins adicionais.
- **Cache visual é local** — `savedLoginEmail`/`savedDisplayName` vivem em
  `SharedPreferences`, sem custo de banco/rede.
- **Preferências força refresh só ao abrir** — o único ponto que sempre lê o
  banco é a tela de Preferências (`forceRefresh: true`), que é uma ação
  explícita e de baixa frequência.

---

## 7. OAuth Google

- Login com Google é apenas **um método de autenticação** — o Remember Me é
  agnóstico ao método de login (e-mail/senha ou Google): o mesmo
  `syncAfterLogin(userId, loginEmail)` é usado em ambos os casos.
- O vínculo real entre sessão e preferência é sempre `auth.uid()`
  (Supabase) + o contexto interno (`AuthAuthenticated.user.id`) — nunca o
  cache local.
- O callback OAuth **não pode** limpar o cache local ("Conta salva") de outra
  conta antes do `AuthNotifier` resolver `AuthAuthenticated` (ver seção 4.3).
  Enquanto `authState is! AuthAuthenticated`,
  `_resolveOnboardingRouteFromState()` não chama `syncAfterLogin` nem
  qualquer função que toque o cache local.

---

## 8. Decisões de produto

- **Slot único de conta salva** — o cache local
  (`savedLoginEmail`/`savedDisplayName`) guarda **uma única conta por
  dispositivo**. Fazer login com outra conta substitui o slot anterior.
  Multi-conta no mesmo dispositivo está fora do escopo da v1; é uma decisão
  de produto/UX, não uma limitação técnica acidental.
- **"Trocar" é local** — limpa apenas o cache local do dispositivo (seção
  4.7), nunca a preferência `keep_connected` do usuário no banco.
- **`savedLoginEmail`/`savedDisplayName` são cache de UX, não credenciais** —
  podem ser perdidos (limpar dados do app, troca de dispositivo) sem impacto
  algum na autenticação; na pior hipótese o usuário digita o e-mail de novo.
- **Chaves `keep_connected_prompt_answered_<userId>` acumulam por
  dispositivo** — risco baixo (poucos bytes por usuário, sem dado sensível).
  Documentado como TODO técnico em
  `lib/shared/data/keep_connected_prompt_storage.dart` para uma futura
  rotina de limpeza local; não implementado nesta versão porque qualquer
  estratégia de poda (ex.: remover flags de usuários que não são a "conta
  salva" atual) reintroduziria o diálogo "Lembrar-me?" para contas legítimas
  em dispositivos compartilhados — uma mudança de comportamento que não foi
  solicitada.
