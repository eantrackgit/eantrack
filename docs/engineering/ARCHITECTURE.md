# Architecture

This document records the current feature structure used by EANTrack and the
rules we follow when adding new application code.

## Feature Structure

The codebase currently uses two feature organization styles.

### Auth: data / domain / presentation

Auth follows a layered structure:

- `data`: repositories, services, Supabase access, persistence concerns.
- `domain`: state objects and business concepts shared by auth flows.
- `presentation`: screens, providers, controllers, and UI-specific logic.

This structure is appropriate for auth because the feature has several public
flows, shared state, external dependencies, and cross-screen behavior such as
login, registration, password recovery, email verification, and redirect logic.

### Onboarding Agency: controllers / services / screens

Agency onboarding currently uses a flatter structure:

- `controllers`: Riverpod `StateNotifier` classes and screen state.
- `services`: Supabase, HTTP, upload, and validation integration points.
- `screens`: Flutter UI for each step.
- `models`: payloads and DTO-like objects passed between steps.

This structure was chosen because the agency onboarding flow is step-oriented:
CNPJ lookup, agency confirmation, representative upload, and status display.
Each step has a focused controller/service pair and a clear screen boundary.

## Why The Divergence Exists

The divergence is intentional for now. Auth is a broader capability with shared
domain state and multiple entry points. Agency onboarding is a guided wizard
where the controller/service/screen split keeps local flow code easy to scan.

The tradeoff is that contributors must recognize both styles. That is acceptable
while the onboarding surface is still concentrated around a small set of steps.

## Future Convergence Plan

When agency onboarding grows beyond the current wizard, move it toward the auth
shape gradually:

1. Keep `models` as stable contracts while adding a `domain` directory for
   state and flow concepts shared across screens.
2. Move Supabase/HTTP implementations from `services` into `data` only when
   there is a repository boundary worth naming.
3. Keep UI in `presentation/screens` and state management in
   `presentation/controllers` or `presentation/providers`.
4. Avoid broad rewrites. Migrate one flow at a time when a feature change already
   touches that area.

Until that migration happens, new onboarding code should follow the existing
local pattern unless it introduces shared domain behavior.

## Dependency Injection

Services are injected through constructors.

Controllers and notifiers should accept optional service parameters:

```dart
AgencyConfirmNotifier({
  required this.cnpjModel,
  CepService? cepService,
  AgencyConfirmService? confirmService,
})  : _cepService = cepService ?? CepService(),
      _confirmService = confirmService ?? AgencyConfirmService();
```

This keeps production setup simple while allowing tests to pass mocks directly.
Do not create hidden network clients inside methods when they can be supplied at
construction time.

## Data Flow

The default flow for screen-driven features is:

```text
Screen -> Notifier -> Service -> Supabase
```

- `Screen`: renders state, receives user input, calls notifier methods.
- `Notifier`: owns UI state, validation, loading/error transitions, and flow
  decisions for that screen.
- `Service`: performs IO and integration work such as Supabase RPCs, database
  writes, HTTP calls, storage upload, and low-level mapping.
- `Supabase`: backend boundary. No screen should call Supabase directly.

For tests, replace the service or Supabase client at the constructor/provider
boundary. Tests must not perform real Supabase, HTTP, or storage calls.
