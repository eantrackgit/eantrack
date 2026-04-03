# BACKLOG.md — EANTrack (FINAL)

> Tasks para Codex 5.4. Cada uma: arquivo único, objetivo claro, sem ambiguidade.
> Formato otimizado para execução mecânica.

---

## PRIORIDADE 1 — ONBOARDING (INICIAR AGORA)

---

### CODEX_TASK — ONB-001: Criar estrutura de pastas Onboarding

**Arquivo:** Nenhum (apenas criar pastas vazias + arquivos .gitkeep)

**Ação:**
```
mkdir -p lib/features/onboarding/data
mkdir -p lib/features/onboarding/domain
mkdir -p lib/features/onboarding/presentation/providers
mkdir -p lib/features/onboarding/presentation/screens
touch lib/features/onboarding/data/.gitkeep
touch lib/features/onboarding/domain/.gitkeep
touch lib/features/onboarding/presentation/providers/.gitkeep
touch lib/features/onboarding/presentation/screens/.gitkeep
```

**Não fazer:** criar arquivos Dart, alterar imports, tocar em qualquer outro arquivo.

---

### CODEX_TASK — ONB-002: ChooseModeScreen (UI pura)

**Arquivo:** `lib/features/onboarding/presentation/screens/choose_mode_screen.dart`

**Criar tela com:**
- StatefulWidget `ChooseModeScreen`
- Variável `String? _selectedMode;` (null, 'individual', 'agency')
- Layout: Scaffold bg `AppColors.bgPrimary` → Center → ConstrainedBox(maxWidth: 480) → Card branco → Padding(32) → Column
- Conteúdo:
  1. Icon `Icons.check_circle` 48px, `AppColors.success`
  2. SizedBox(24)
  3. Text "Defina seu estilo operacional" — `AppTextStyles.h1`, center
  4. SizedBox(8)
  5. Text "Essa configuração ajuda o EANTrack a personalizar sua experiência operacional." — `AppTextStyles.bodyMedium`, `AppColors.textSecondary`, center
  6. SizedBox(24)
  7. `_ModeCard(title: 'Individual', description: 'Agente ou promotor atuando de forma independente...', icon: Icons.person, selected: _selectedMode == 'individual', onTap: () => setState(() => _selectedMode = 'individual'))`
  8. SizedBox(16)
  9. `_ModeCard(title: 'Agência', description: 'Gerencia equipe, clientes e operações completas...', icon: Icons.business, selected: _selectedMode == 'agency', onTap: () => setState(() => _selectedMode = 'agency'))`
  10. SizedBox(24)
  11. Row spaceBetween: AppButton.secondary("← Voltar") + AppButton.primary("Avançar →", onPressed: _selectedMode == null ? null : _onAdvance)
- `_ModeCard`: private widget no mesmo arquivo — Container com borda (selected: 2px success, else: 1px borderDefault), padding 16, Row com Icon + Column(title + description)
- `_onAdvance`: `debugPrint('Mode: $_selectedMode');`

**Imports permitidos:** material.dart, app_colors, app_text_styles, app_spacing, app_button

**Não fazer:** criar notifier, chamar Supabase, criar arquivo separado para ModeCard, navegar de verdade.

---

### CODEX_TASK — ONB-003: Registrar rota /onboarding

**Arquivos (2):**
1. `lib/core/router/app_routes.dart`
2. `lib/core/router/app_router.dart`

**Em app_routes.dart:**
- Adicionar constante: `static const onboarding = '/onboarding';`

**Em app_router.dart:**
- Adicionar import de `ChooseModeScreen`
- Adicionar GoRoute no array de routes:
```dart
GoRoute(
  path: AppRoutes.onboarding,
  builder: (context, state) => const ChooseModeScreen(),
),
```
- No `redirect()` do RouterNotifier, onde checa `user_flow_state`:
  - Se onboarding incompleto → return `AppRoutes.onboarding`

**Não fazer:** alterar guards de auth, alterar lógica de email verification, criar novo provider.

---

## PRIORIDADE 2 — CORE UI WIDGETS

---

### ~~CODEX_TASK — UI-001: Estender AppCard com props interativas~~ ✅ CONCLUÍDO

**Sessão 7 (2026-04-01):** AppCard atualizado com `onTap?`, `selected?`, `borderColor?`.
Ripple via `Material + InkWell + Ink`. Borda success (2px) quando `selected = true`.

---

### CODEX_TASK — UI-002: AppEmptyState widget

**Arquivo:** `lib/shared/widgets/app_empty_state.dart`

**Widget:** `AppEmptyState` — StatelessWidget
- Props: `IconData icon`, `String title`, `String subtitle`, `String? actionLabel`, `VoidCallback? onAction`
- Column centrado:
  1. Icon(icon, size: 64, color: AppColors.secondaryText.withOpacity(0.4))
  2. SizedBox(16)
  3. Text title — `AppTextStyles.titleLarge`, color: `AppColors.primaryText`
  4. SizedBox(8)
  5. Text subtitle — `AppTextStyles.bodyMedium`, color: `AppColors.secondaryText`, center
  6. Se actionLabel != null → SizedBox(24) + AppButton.primary(actionLabel, onPressed: onAction)

---

### CODEX_TASK — UI-003: AppSearchBar widget

**Arquivo:** `lib/shared/widgets/app_search_bar.dart`

**Widget:** `AppSearchBar` — StatelessWidget
- Props: `String hint`, `ValueChanged<String> onChanged`, `TextEditingController? controller`
- TextField com:
  - decoration: InputDecoration com prefixIcon Icons.search, hint, border `AppRadius.smAll`, fillColor `AppColors.primaryBackground`, filled: true
  - onChanged: onChanged
  - style: `AppTextStyles.bodyMedium`, color `AppColors.primaryText`

---

### CODEX_TASK — UI-004: AppTabBar widget

**Arquivo:** `lib/shared/widgets/app_tab_bar.dart`

**Widget:** `AppTabBar` — StatelessWidget
- Props: `List<String> tabs`, `int selectedIndex`, `ValueChanged<int> onChanged`
- Row de GestureDetector chips:
  - Selected: bg `AppColors.secondary`, text `AppColors.info`, radius `AppRadius.mdAll`
  - Unselected: bg transparent, text `AppColors.accent2`, border `AppColors.tertiary`

---

### CODEX_TASK — UI-006: AppBottomNav widget

**Arquivo:** `lib/shared/widgets/app_bottom_nav.dart`

**Widget:** `AppBottomNav` — StatelessWidget
- Props: `int currentIndex`, `ValueChanged<int> onTap`
- BottomNavigationBar com 5 items:
  1. home_outlined "Início"
  2. store "PDVs"
  3. assignment_outlined "Operações"
  4. factory_outlined "Indústrias"
  5. calendar_today "Agenda"
- bg: `AppColors.secondary`, selectedItemColor: `AppColors.primary`, unselectedItemColor: `AppColors.accent2`

---

### CODEX_TASK — UI-007: AppSidebar widget

**Arquivo:** `lib/shared/widgets/app_sidebar.dart`

**Widget:** `AppSidebar` — StatelessWidget
- Props: `String userName`, `String userRole`, `String? avatarUrl`, `int selectedIndex`, `ValueChanged<int> onItemTap`
- Container width 240, bg `AppColors.secondary`
- Column:
  1. UserHeader (CircleAvatar + name + role)
  2. Divider
  3. ListTiles: Regiões, Redes, Categorias, PDVs, Equipe, Configurações

---

### CODEX_TASK — UI-008: AppStatusBadge widget

**Arquivo:** `lib/shared/widgets/app_status_badge.dart`

**Widget:** `AppStatusBadge` — StatelessWidget
- Props: `String label`, `AppStatusType type` (enum: active, inactive, pending, approved, rejected)
- Container com padding sm, radiusFull, bg = cor do tipo 15%
- Text label, bodySmall, cor = cor do tipo
- Cores: active=`AppColors.success`, inactive=`AppColors.secondaryText`, pending=`AppColors.warning`, approved=`AppColors.success`, rejected=`AppColors.error`

---

## PRIORIDADE 3 — HUB

---

### CODEX_TASK — HUB-001: Estrutura de pastas Hub

**Ação:** Criar pastas (mesmo padrão de ONB-001):
```
lib/features/hub/data/
lib/features/hub/domain/
lib/features/hub/presentation/providers/
lib/features/hub/presentation/screens/
```

---

### CODEX_TASK — HUB-002: HubScreen layout básico

**Arquivo:** `lib/features/hub/presentation/screens/hub_screen.dart`

**Criar tela com:**
- Scaffold bg `AppColors.primaryBackground`
- LayoutBuilder → se desktop: Row(AppSidebar + Expanded(content)) / se mobile: Column(content + AppBottomNav)
- Content: Column → header (avatar + nome, mock) + Grid de cards (4 ícones de ferramentas, mock)
- Tudo mock/placeholder — sem provider, sem Supabase

---

### CODEX_TASK — HUB-003: Rota /hub

**Arquivos:** `app_routes.dart` + `app_router.dart`
- Adicionar `static const hub = '/hub';`
- Adicionar GoRoute apontando para HubScreen
- No redirect: onboarding completo → `/hub`

---

## PRIORIDADE 4 — ONBOARDING COMPLETO

---

### CODEX_TASK — ONB-004: OnboardingState sealed

**Arquivo:** `lib/features/onboarding/domain/onboarding_state.dart`

```dart
sealed class OnboardingState {}
class OnboardingInitial extends OnboardingState {}
class OnboardingLoading extends OnboardingState {}
class OnboardingModeSelected extends OnboardingState {
  final String mode; // 'individual' ou 'agency'
  OnboardingModeSelected({required this.mode});
}
class OnboardingError extends OnboardingState {
  final String message;
  OnboardingError({required this.message});
}
```

---

### CODEX_TASK — ONB-005: OnboardingNotifier + Provider

**Arquivo:** `lib/features/onboarding/presentation/providers/onboarding_provider.dart`

- `OnboardingNotifier extends StateNotifier<OnboardingState>`
- Métodos: `selectMode(String mode)`, `advance()` (futuro)
- `selectMode`: apenas seta `OnboardingModeSelected(mode: mode)`
- Provider: `StateNotifierProvider<OnboardingNotifier, OnboardingState>`
- Não chamar Supabase ainda

---

### CODEX_TASK — ONB-006: OnboardingRepository + persistir modo

**Arquivo:** `lib/features/onboarding/data/onboarding_repository.dart`

- `OnboardingRepository` com `SupabaseClient`
- Método: `Future<void> saveMode(String mode)` → update `user_flow_state` table
- Provider: `onboardingRepositoryProvider`
- Integrar no OnboardingNotifier: `advance()` chama repository + navega

---

### CODEX_TASK — ONB-007: CnpjScreen (UI)

**Arquivo:** `lib/features/onboarding/presentation/screens/cnpj_screen.dart`

- Campo CNPJ com máscara (XX.XXX.XXX/XXXX-XX)
- Botão "Consultar CNPJ" (azul, ícone lupa)
- Checkbox aceite
- Status messages coloridas (placeholder)
- Botões "← Voltar" + "Avançar →"
- Tudo UI — sem Supabase

---

### CODEX_TASK — ONB-008: CompanyDataScreen (UI)

**Arquivo:** `lib/features/onboarding/presentation/screens/company_data_screen.dart`

- Campos preenchidos (mock): Razão Social, Fantasia, CNPJ, Endereço
- Readonly ou editáveis
- Botões navegação

---

### CODEX_TASK — ONB-009: LegalRepresentativeScreen (UI)

**Arquivo:** `lib/features/onboarding/presentation/screens/legal_representative_screen.dart`

- Campos: CPF, RG, Nascimento, Órgão expedidor
- Upload docs (placeholder)
- Checkbox termos
- Botões navegação

---

## PRIORIDADE 5 — FEATURES (REGIONS, NETWORKS, CATEGORIES, PDVs)

---

### CODEX_TASK — REG-001: Estrutura de pastas Regions
### CODEX_TASK — REG-002: RegionListScreen (UI com mock data)
### CODEX_TASK — REG-003: RegionRepository (RPCs: `has_regions_for_current_user`, `list_regions_for_dropdown`, `is_region_name_available_for_current_user`)
### CODEX_TASK — REG-004: CreateRegionDialog (modal com validação nome)
### CODEX_TASK — REG-005: RegionDetailScreen
### CODEX_TASK — REG-006: City assignment (RPCs: `list_cities_for_region_dropdown`, `get_conflicting_city_ids`, `replace_region_cities`)

---

### CODEX_TASK — NET-001: Estrutura de pastas Networks
### CODEX_TASK — NET-002: NetworkListScreen (RPC: `list_networks_for_management`)
### CODEX_TASK — NET-003: CreateNetworkDialog (RPC: `network_name_exists_in_agency`)
### CODEX_TASK — NET-004: NetworkRepository

---

### CODEX_TASK — CAT-001: Estrutura + CategoryListScreen (RPC: `list_categories_for_management`)
### CODEX_TASK — CAT-002: SubcategoryListScreen (RPC: `list_subcategories_for_management`)
### CODEX_TASK — CAT-003: CreateCategoryDialog (RPC: `category_name_exists`)

---

### CODEX_TASK — PDV-001: Estrutura + PdvListScreen (UI com empty state)
### CODEX_TASK — PDV-002: PdvFilterSheet (modal de filtro)
### CODEX_TASK — PDV-003: RegisterPdvScreen (formulário completo)
### CODEX_TASK — PDV-004: PdvRepository (RPCs: `get_pdv_for_edit`, `pdv_cnpj_exists_in_agency`)

---

### CODEX_TASK — AGN-001: AgencyStatusScreen (RPC: `check_agency_pdvs_regions_exist`)

---

## PRIORIDADE 6 — AUTH POLISH

---

### CODEX_TASK — AUTH-001: Botão Google na LoginScreen
- **Arquivo:** `login_screen.dart`
- Divider "ou" + ElevatedButton vermelho + icon G + `debugPrint`

### CODEX_TASK — AUTH-002: Biometria na LoginScreen
- **Arquivo:** `login_screen.dart`
- Icon fingerprint 32px + text "Entre com biometria" + `debugPrint`

### CODEX_TASK — AUTH-003: Ícone suporte na LoginScreen
- **Arquivo:** `login_screen.dart`
- IconButton headset_mic_outlined no canto superior direito do card

### CODEX_TASK — AUTH-004: Tabs no RegisterScreen
- **Arquivo:** `register_screen.dart`
- TabBar 4 tabs (Informações ativa, demais placeholder)

### CODEX_TASK — AUTH-005: Cooldown barra visual
- **Arquivo:** `email_verification_screen.dart`
- LinearProgressIndicator + texto timer durante cooldown

---

## ORDEM DE EXECUÇÃO

```
SEMANA 1:
  ONB-001 → ONB-002 → ONB-003           Onboarding visível

SEMANA 2:
  UI-001 → UI-002 → UI-006 → UI-007     Core widgets
  HUB-001 → HUB-002 → HUB-003           Hub funcional

SEMANA 3:
  ONB-004 → ONB-005 → ONB-006           Onboarding com state
  ONB-007 → ONB-008 → ONB-009           Telas CNPJ/Empresa/Legal

SEMANA 4:
  REG-001 → REG-004                      Regions completo
  NET-001 → NET-004                      Networks completo

SEMANA 5:
  CAT-001 → CAT-003                      Categories
  PDV-001 → PDV-004                      PDVs
  AGN-001                                Agency Status

SEMANA 6:
  AUTH-001 → AUTH-005                     Auth polish
  UI-003 → UI-004 → UI-008              Core UI restante
```

---

## REGRA PARA TODA TASK

Cada CODEX_TASK deve:
1. Alterar no máximo 3 arquivos
2. Ter objetivo único e verificável
3. Não depender de contexto externo (tudo que precisa está na task)
4. Não executar `flutter analyze`, `dart format` ou testes
5. Não criar abstrações desnecessárias
6. Seguir padrões de GLOBAL_PATTERNS.md e DESIGN_SYSTEM.md
