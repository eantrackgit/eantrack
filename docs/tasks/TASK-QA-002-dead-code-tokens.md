# ✅ CONCLUÍDA — TASK-QA-002: Remover código morto e tokens hardcoded em AgencyStatusScreen
> Aplicada no commit `ca892e1 fix(audit)`. Verificada em auditoria 2026-04-23.

NUNCA execute dart format, dart analyze, flutter test, flutter run
## CONTEXTO

`agency_status_screen.dart` tem três problemas de qualidade introduzidos no commit
`8823f4a feat(agency): tela de status`:

**Problema A — Parâmetro `BuildContext context` não utilizado em 6 funções**

As funções abaixo recebem `BuildContext context` mas não o usam em nenhuma linha:

```dart
TextStyle _cardLabelStyle(BuildContext context) { ... }
TextStyle _cardTitleStyle(BuildContext context) { ... }
TextStyle _cardBodyLargeStyle(BuildContext context) { ... }
TextStyle _cardBodyStyle(BuildContext context) { ... }
TextStyle _cardMutedStyle(BuildContext context) { ... }
TextStyle _supportTextStyle(BuildContext context) { ... }
```

Todas estão no final do arquivo. Cada uma apenas chama `AppTextStyles.*` e `AppColors.*`.

**Problema B — `Colors.white` hardcoded em `_StatusCtaButton`**

Em `_StatusCtaButton.build()`:
```dart
foregroundColor: Colors.white,
disabledForegroundColor: Colors.white,
```
e:
```dart
style: AppTextStyles.titleSmall.copyWith(color: Colors.white),
```
`Colors.white` não é token — deve ser `AppColors.secondaryBackground`.

**Problema C — `Container(color: Colors.transparent, ...)` morto em `_ActionButton`**

Em `_ActionButton.build()`:
```dart
return Container(
  color: Colors.transparent,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [...],
  ),
);
```
O `Container` com `color: Colors.transparent` não tem efeito visual nenhum.
É wrapper morto.

## ARQUIVO

`lib/features/onboarding/agency/screens/agency_status_screen.dart`

## ALTERAÇÕES EXATAS

### A — Remover parâmetro `BuildContext context` das 6 funções

Remover o parâmetro das assinaturas:
```dart
// ANTES
TextStyle _cardLabelStyle(BuildContext context) {
TextStyle _cardTitleStyle(BuildContext context) {
TextStyle _cardBodyLargeStyle(BuildContext context) {
TextStyle _cardBodyStyle(BuildContext context) {
TextStyle _cardMutedStyle(BuildContext context) {
TextStyle _supportTextStyle(BuildContext context) {

// DEPOIS
TextStyle _cardLabelStyle() {
TextStyle _cardTitleStyle() {
TextStyle _cardBodyLargeStyle() {
TextStyle _cardBodyStyle() {
TextStyle _cardMutedStyle() {
TextStyle _supportTextStyle() {
```

Atualizar todos os call sites dessas funções dentro do mesmo arquivo.
Exemplo: `_cardBodyStyle(context)` → `_cardBodyStyle()`.

### B — Substituir `Colors.white` por `AppColors.secondaryBackground`

Em `_StatusCtaButton.build()`:
```dart
// ANTES
foregroundColor: Colors.white,
disabledForegroundColor: Colors.white,
// ...
style: AppTextStyles.titleSmall.copyWith(color: Colors.white),

// DEPOIS
foregroundColor: AppColors.secondaryBackground,
disabledForegroundColor: AppColors.secondaryBackground,
// ...
style: AppTextStyles.titleSmall.copyWith(color: AppColors.secondaryBackground),
```

### C — Remover o `Container` morto em `_ActionButton.build()`

```dart
// ANTES
return Container(
  color: Colors.transparent,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _StatusCtaButton(...),
      const SizedBox(height: 8),
      ColorFiltered(...),
    ],
  ),
);

// DEPOIS
return Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    _StatusCtaButton(...),
    const SizedBox(height: 8),
    ColorFiltered(...),
  ],
);
```

## ENTREGA ESPERADA

- 6 funções sem o parâmetro `context` — todos os call sites atualizados
- `Colors.white` substituído por `AppColors.secondaryBackground` nos 3 lugares
- `_ActionButton.build()` retorna `Column` diretamente, sem `Container` wrapper

## NÃO FAZER

- Não alterar a lógica de nenhuma função
- Não migrar dark mode (EanTrackTheme) — isso é outra task
- Não alterar outros arquivos além de `agency_status_screen.dart`
- Não renomear as funções
- Não alterar o `SizedBox(height: 8)` dentro do Column
