# ✅ CONCLUÍDA — TASK-QA-003: Adicionar onboardingAgencyStatus ao RouterRedirectGuard
> Aplicada no commit `d505d0c refactor: ajustes pós-auditoria`. Verificada em auditoria 2026-04-23.

NUNCA execute dart format, dart analyze, flutter test, flutter run

## CONTEXTO

`RouterRedirectGuard` classifica as rotas em três categorias para aplicar redirects:
- `isGuestRoute` — rotas públicas (login, register, recover)
- `isOnboardingRoute` — rotas de onboarding (acessíveis apenas durante `onboardingRequired`)
- `isAppRoute` — rotas protegidas (acessíveis apenas durante `authenticated`)

A rota `/onboarding/agency/status` (`AppRoutes.onboardingAgencyStatus`) foi criada
no commit `8823f4a` mas **não foi adicionada a nenhuma das três categorias**.

Isso significa que a rota está acessível sem autenticação — qualquer URL direta
para `/onboarding/agency/status` não é redirecionada mesmo com usuário não logado.
O comportamento correto é: acessível somente durante `onboardingRequired`.

## ARQUIVO

`lib/core/router/router_redirect_guard.dart`

## ALTERAÇÃO EXATA

Localizar o bloco `isOnboardingRoute` (aproximadamente linha 42):

```dart
final isOnboardingRoute = path == AppRoutes.onboarding ||
    path == AppRoutes.onboardingIndividual ||
    path == AppRoutes.onboardingCnpj ||
    path == AppRoutes.onboardingAgency ||
    path == AppRoutes.onboardingLegalRep ||
    path == AppRoutes.onboardingAgencyCnpj ||
    path == AppRoutes.onboardingAgencyConfirm ||
    path == AppRoutes.onboardingAgencyRepresentative;
```

Adicionar `AppRoutes.onboardingAgencyStatus` ao final:

```dart
final isOnboardingRoute = path == AppRoutes.onboarding ||
    path == AppRoutes.onboardingIndividual ||
    path == AppRoutes.onboardingCnpj ||
    path == AppRoutes.onboardingAgency ||
    path == AppRoutes.onboardingLegalRep ||
    path == AppRoutes.onboardingAgencyCnpj ||
    path == AppRoutes.onboardingAgencyConfirm ||
    path == AppRoutes.onboardingAgencyRepresentative ||
    path == AppRoutes.onboardingAgencyStatus;
```

## COMPORTAMENTO APÓS A CORREÇÃO

| authFlowState | Acesso a /onboarding/agency/status | Resultado |
|---------------|-------------------------------------|-----------|
| `unauthenticated` | Bloqueado → redirect para `/flow` | ✅ correto |
| `onboardingRequired` | Permitido | ✅ correto |
| `recovery` | Bloqueado → redirect para `/flow` | ✅ correto |
| `authenticated` | Bloqueado → redirect para `/flow` | ✅ correto |

O splash já navega para esta rota apenas quando o usuário tem sessão ativa e está
em estado de onboarding (`get_user_onboarding_route` retorna `'onboarding/agency/status'`),
portanto o fluxo normal não é afetado.

## ENTREGA ESPERADA

- `isOnboardingRoute` contém `path == AppRoutes.onboardingAgencyStatus`
- Nenhuma outra linha do arquivo alterada

## NÃO FAZER

- Não adicionar a rota a `isGuestRoute` ou `isAppRoute`
- Não adicionar a rota a `AppRoutes.protectedRoutes`
- Não alterar outros arquivos
- Não alterar a lógica do redirect — apenas o predicado `isOnboardingRoute`
