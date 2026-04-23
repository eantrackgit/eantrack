# DESIGN_SYSTEM.md — EANTrack

> Tokens visuais e especificação de componentes.
> Para regras comportamentais e padrões de tela → **UI_PLAYBOOK.md**
> Para animações → **ANIMATION_GUIDELINES.md**

---

## 1. CORES

### Dart tokens (app_colors.dart)

```dart
// Backgrounds
static const bgPrimary           = Color(0xFF0A0E27);  // fundo navy escuro
static const bgCard              = Color(0xFFFFFFFF);  // card auth
static const bgCardDark          = Color(0xFF0F1735);  // card interno dark
static const bgInput             = Color(0xFFFFFFFF);  // input em card branco
static const bgInputDark         = Color(0xFF1A1F3D);  // input em dark
static const bgHover             = Color(0xFFF5F5F5);  // hover em elementos

// Brand
static const brandRed            = Color(0xFFC62828);  // logo + botão Google
static const brandBlue           = Color(0xFF1A237E);  // logo parte azul

// Actions
static const primary             = Color(0xFF1A1F3D);  // botão CTA principal
static const primaryAction       = Color(0xFFC62828);  // botão Google/vermelho
static const actionBlue          = Color(0xFF1A56DB);  // botões de consulta API
static const success             = Color(0xFF2E7D32);  // checkmarks, badges
static const error               = Color(0xFFD32F2F);  // erros, bordas validação
static const warning             = Color(0xFFF9A825);  // alertas
static const link                = Color(0xFF1565C0);  // links

// Text
static const textPrimary         = Color(0xFF1A1A2E);  // texto principal
static const textSecondary       = Color(0xFF6B7280);  // labels, placeholder
static const textDisabled        = Color(0xFF9CA3AF);  // disabled
static const textOnDark          = Color(0xFFFFFFFF);  // sobre dark
static const textError           = Color(0xFFD32F2F);  // erro inline
static const textSuccess         = Color(0xFF2E7D32);  // checklist ok

// Borders
static const borderDefault       = Color(0xFFE0E0E0);  // borda padrão
static const borderFocus         = Color(0xFF1565C0);  // input com foco
static const borderError         = Color(0xFFD32F2F);  // input com erro
static const borderCard          = Color(0x1AFFFFFF);  // borda em card dark
```

### Matriz de estados por contexto

| Token | Default | Hover | Pressed | Disabled |
|-------|---------|-------|---------|----------|
| Botão primary | `primary` | `#2A2F4D` | `#10142D` | `primary` 50% |
| Botão Google | `primaryAction` | `#D63838` | `#B71C1C` | `primaryAction` 50% |
| Input borda | `borderDefault` | `#BDBDBD` | — | `borderDefault` 50% |
| Input foco | — | — | `borderFocus` 2px | — |
| Link | `link` | `#1976D2` | `link` | — |

---

### Tokens reais no código (usar sempre estes)

> Ao escrever código Dart, use os nomes abaixo — não os nomes de spec da coluna esquerda.

| Uso | Token real (AppColors.*) | Hex |
|-----|--------------------------|-----|
| Fundo de página (interno) | `primaryBackground` | `#F1F4F8` |
| Card / container branco | `secondaryBackground` | `#FFFFFF` |
| Scaffold auth (light) | `secondary` | `#0E0A36` |
| Texto principal | `primaryText` | `#14181B` |
| Texto secundário / labels | `secondaryText` | `#57636C` |
| Texto sobre fundo escuro | `info` | `#FFFFFF` |
| Borda padrão | `alternate` | `#E0E3E7` |
| Logo / botão Google | `primary` | `#F90716` |
| Botão CTA principal | `secondary` | `#0E0A36` |
| Botão consulta API (CNPJ, CEP) | `actionBlue` | `#1A56DB` |
| Sucesso | `success` | `#22C55E` |
| Erro | `error` | `#FF5963` |
| Aviso | `warning` | `#F9CF58` |

### ⚠️ Regra: cores context-aware → usar EanTrackTheme

Para cores que mudam entre light e dark (backgrounds, textos, bordas de campo, botões), **não usar `AppColors.*` diretamente**. Usar `EanTrackTheme.of(context)`:

```dart
final et = EanTrackTheme.of(context);
// et.primaryText, et.secondaryText, et.cardSurface, et.inputBorder, etc.
```

Ver seção completa de tokens dark mode em `ARCHITECTURE.md`.

**Tokens de texto reais (`AppTextStyles.*`):**

| Uso | Token real | Tamanho |
|-----|-----------|---------|
| Título de tela | `headlineSmall` | 24px, w500 |
| Título grande | `headlineLarge` | 32px, w600 |
| Subtítulo de card | `titleLarge` | 22px, w500 |
| Subtítulo médio | `titleMedium` | 18px, Poppins |
| Corpo padrão | `bodyMedium` | 14px, Poppins |
| Caption / erro | `bodySmall` | 12px, Poppins |
| Label UI | `labelSmall` | 12px, Poppins |

> Não existem: `h1`, `h2`, `h3`, `buttonText`, `linkText`, `logoTitle` — usar os tokens reais acima.

---

## 2. TIPOGRAFIA

**Família primária:** Poppins (body, labels, titles)
**Família secundária:** Roboto (display, headlines)

### Dart tokens (app_text_styles.dart)

| Token | Font | Weight | Size | Uso |
|-------|------|--------|------|-----|
| `headlineLarge` | Roboto | 600 | 32px | Títulos grandes |
| `headlineSmall` | Roboto | 500 | 24px | Títulos de tela |
| `titleLarge` | Roboto | 500 | 22px | Subtítulos de card |
| `titleMedium` | Poppins | 400 | 18px | Subtítulos médios |
| `bodyLarge` | Poppins | 400 | 16px | Corpo grande |
| `bodyMedium` | Poppins | 400 | 14px | Corpo padrão, campos |
| `bodySmall` | Poppins | 400 | 12px | Labels, captions, erro |
| `labelSmall` | Poppins | 400 | 12px | Label floating input |
| `buttonText` | Poppins | 600 | 16px | Texto de botões |
| `linkText` | Roboto | 500 | 14px | Links |
| `logoTitle` | Poppins | 700 | 28px | "EANTrack" logo |
| `logoSubtitle` | Roboto | 400 | 14px | "Smart Tracking" |

---

## 3. ESPAÇAMENTO

```dart
// app_spacing.dart
AppSpacing.xs  =  4px   // gap mínimo, ícone-texto
AppSpacing.sm  =  8px   // gap label-input, badge padding
AppSpacing.md  = 16px   // gap entre campos, padding padrão
AppSpacing.lg  = 24px   // gap entre seções do form
AppSpacing.xl  = 32px   // padding card auth
```

---

## 4. BORDER RADIUS

```dart
// app_spacing.dart — AppRadius
AppRadius.sm   =  8px    // inputs, botões, chips  → AppRadius.smAll (BorderRadius.circular(8))
AppRadius.md   = 16px    // cards secundários      → AppRadius.mdAll
AppRadius.lg   = 24px    // modais, bottom sheets  → AppRadius.lgAll
AppRadius.full = 9999px  // pílulas, avatares circulares
```

> `AppRadius.smAll / mdAll / lgAll` retornam `BorderRadius.circular(valor)` prontos para uso em `BoxDecoration` e `RoundedRectangleBorder`.

---

## 5. SOMBRAS

```dart
// app_spacing.dart — AppShadows  (todas usam preto 10%)
AppShadows.sm  → blur  3px, offset (0,  1)   // elevação sutil (inputs, chips)
AppShadows.md  → blur  6px, offset (0,  3)   // cards normais
AppShadows.lg  → blur 15px, offset (0,  8)   // cards em destaque
AppShadows.xl  → blur 25px, offset (0, 16)   // modais e overlays
```

---

## 6. COMPONENTES — ESPECIFICAÇÃO COMPLETA

### 6.1 AppButton

#### Primary (navy)
| Propriedade | Valor |
|-------------|-------|
| Background | `primary` |
| Text | branco, `buttonText` Poppins 600 16px |
| Height | 48px fixo |
| Width | `double.infinity` (full-width) |
| Radius | `AppRadius.sm` (8px) |
| Padding H | 24px |

| Estado | Background | Text | Extra |
|--------|------------|------|-------|
| Default | `primary` | branco | — |
| Hover | `#2A2F4D` | branco | 150ms transition |
| Pressed | `#10142D` + scale 0.97 | branco | 100ms easeIn |
| Loading | `primary` | oculto | spinner branco 18px centralizado |
| Disabled | `primary` 50% opacity | branco 50% | `onPressed: null` |

#### Outlined / Secondary
| Estado | Background | Border | Text |
|--------|------------|--------|------|
| Default | transparente | 1px `borderDefault` | `textPrimary` |
| Hover | `bgHover` | 1px `#BDBDBD` | `textPrimary` |
| Pressed | `#EEEEEE` + scale 0.97 | 1px `#BDBDBD` | `textPrimary` |
| Disabled | transparente | 1px `borderDefault` 50% | `textDisabled` |

#### Social / Google
| Estado | Background | Extra |
|--------|------------|-------|
| Default | `primaryAction` (#C62828) | ícone G esquerda |
| Hover | `#D63838` | — |
| Pressed | `#B71C1C` + scale 0.97 | — |

#### Action (consulta API)
| Estado | Background |
|--------|------------|
| Default | `actionBlue` (#1A56DB) |
| Hover | `#1E63F0` |
| Pressed | scale 0.97 |

---

### 6.2 AppTextField

| Propriedade | Token real |
|-------------|-----------|
| Fill (habilitado) | `et.inputFill` |
| Fill (desabilitado) | `et.inputFillDisabled` |
| Border idle | `et.inputBorder`, `AppRadius.smAll` (8px) |
| Border focado | `et.inputBorderFocused`, 1.5px |
| Border erro | `AppColors.error` |
| Label cor | `et.secondaryText` (idle/disabled) · `et.inputBorderFocused` (focused) |
| Texto | `et.primaryText` |
| Height | ~52px |
| Padding | H 16px, V 14px |

| Estado | Border | Fill |
|--------|--------|------|
| Default | `et.inputBorder` 1px | `et.inputFill` |
| Focused | `et.inputBorderFocused` 1.5px | `et.inputFill` |
| Error | `AppColors.error` 1.5px | `et.inputFill` |
| Disabled | `et.inputBorder` 1px | `et.inputFillDisabled` |

**Convenção obrigatória:** `label` sempre preenchido com o nome do campo — nunca `AppTextField(label: '')`. O floating label é a única referência visual do campo em estado preenchido.

**Suffix icons:**
- Senha: `Icons.visibility_off` / `Icons.visibility` — cor `et.secondaryText`
- CNPJ válido: `Icons.check` verde, `Icons.close` para limpar

---

### 6.3 Password Strength Checklist

| Estado | Ícone | Cor real (código) |
|--------|-------|-------------------|
| Não digitando | `radio_button_unchecked` 16px | `EanTrackTheme.of(context).secondaryText` — adapta light/dark |
| Atendido | `check_circle` 16px | `AppColors.success` |
| Não atendido (digitando) | `cancel` 16px | `AppColors.error` |

- Animação: `AnimatedSwitcher` 150ms no ícone + `AnimatedDefaultTextStyle` na cor
- Layout: Column de Rows (ícone + texto), gap `xs` entre items
- **Theming:** o estado idle usa token semântico — correto em dark mode. Estados success/error usam `AppColors` fixo (semântico de estado, não de tema — correto).

---

### 6.4 Checkbox (Terms)

| Estado | Visual |
|--------|--------|
| Unchecked | 20×20, border 1px `borderDefault` |
| Checked | 20×20, bg `success`, check branco |
| Error | border 1px `error` |
| Hover | border `#BDBDBD` |
| Disabled | opacity 0.5 |

---

### 6.5 AppErrorBox / ErrorBanner

| Propriedade | Valor |
|-------------|-------|
| Background | `error` 10% |
| Border-left | 3px solid `error` |
| Border-radius | `AppRadius.sm` direita |
| Text | `textError`, `bodySmall` |
| Padding | `AppSpacing.md` |
| Ícone | `Icons.error_outline` 18px |
| Animação | fade in + slide down 4px, 200ms easeOut |

---

### 6.6 Divider "ou"

```
Row: Expanded(Divider) + Padding("ou", sm H) + Expanded(Divider)
Divider color: borderDefault
Text: bodySmall, textSecondary
Margin V: md acima e abaixo
```

---

### 6.7 SelectionCard (onboarding modes)

| Estado | Border | Background | Extra |
|--------|--------|------------|-------|
| Unselected | 1px `borderDefault` | `bgCard` | — |
| Hover | 1px `#BDBDBD` | `bgHover` | — |
| Selected | 2px `success` | `success` 5% | check verde canto 200ms |

---

### 6.8 AppStatusBadge

| Tipo | Background | Text color |
|------|-----------|-----------|
| active | `success` 15% | `success` |
| inactive | `textSecondary` 15% | `textSecondary` |
| pending | `warning` 15% | `#E65100` |
| approved | `success` 15% | `success` |
| rejected | `error` 15% | `error` |

Container: padding `sm` H `xs` V, radius `AppRadius.full`.

---

## 7. LAYOUT RESPONSIVO

### Auth Screens (Login, Register, Email Verification, Recover Password)

| | Mobile <600 | Tablet 600–1200 | Desktop >1200 |
|-|-------------|-----------------|----------------|
| Bg | `bgPrimary` | `bgPrimary` | `bgPrimary` |
| Card width | ~90% | 420px | 420px |
| Card shadow | nenhuma | `AppShadows.card` | `AppShadows.card` |
| Card padding | 24px | 32px | 32px |
| Card radius | `AppRadius.lg` | `AppRadius.lg` | `AppRadius.lg` |
| Card align | center H+V | center | center |

Register screen: maxWidth 480px.

### Internal Screens

| | Mobile | Tablet | Desktop |
|-|--------|--------|---------|
| Nav | bottom nav 5 items | sidebar colapsável | sidebar fixa 240px |
| Content bg | `bgPrimary` | `bgPrimary` | `bgPrimary` |
| Cards | full-width | ~90% | max-width por tela |

```dart
class Breakpoints {
  static const double mobile = 600;
  static const double tablet = 1200;
}
```

---

## 8. ÍCONES

> Regra: **somente Material Icons**. Proibido CupertinoIcons, FontAwesomeIcons.
> Se não existe no Material: criar SVG em `assets/icons/`.

| Contexto | Icon | Size |
|----------|------|------|
| Email | `Icons.email_outlined` | 24px |
| Senha | `Icons.lock_outlined` | 24px |
| Ver senha | `Icons.visibility` | 24px |
| Esconder | `Icons.visibility_off` | 24px |
| Voltar | `Icons.arrow_back` | 24px |
| Google (placeholder) | `Icons.g_mobiledata` | 24px |
| Biometria | `Icons.fingerprint` | 32px |
| Suporte | `Icons.headset_mic_outlined` | 24px |
| Individual | `Icons.person` | 32px |
| Agência | `Icons.business` | 32px |
| Search | `Icons.search` | 24px |
| Adicionar | `Icons.add` | 24px |
| Fechar | `Icons.close` | 24px |
| Check confirmado | `Icons.check_circle` | 16–24px |
| Pendente | `Icons.radio_button_unchecked` | 16px |
| Erro item | `Icons.cancel` | 16px |
| Warning | `Icons.warning_amber` | 24px |
| Editar | `Icons.edit` | 24px |
| Deletar | `Icons.delete_outline` | 24px |
| Settings | `Icons.settings` | 24px |
| Logout | `Icons.logout` | 24px |
| QR/Barcode | `Icons.qr_code_scanner` | 24px |
| Home | `Icons.home_outlined` | 24px |
| PDV/Loja | `Icons.store` | 24px |
| Rede | `Icons.hub` | 24px |
| Região | `Icons.map_outlined` | 24px |
| Categoria | `Icons.category_outlined` | 24px |
| Indústria | `Icons.factory_outlined` | 24px |
| Câmera | `Icons.camera_alt_outlined` | 24px |
| Upload | `Icons.upload_file` | 24px |

---

## 9. ASSETS

```
assets/images/eantrack.svg          → logo principal ("EAN" navy + "Track" vermelho)
assets/images/app_launcher_icon.png → ícone do app
assets/jsons/Insider-loading.json   → loading overlay geral
assets/jsons/Loading_animation_blue.json → loading alternativo
assets/jsons/Success_(1).json       → checkmark confirmação email
assets/jsons/dance_stars.json       → celebração (onboarding final)
```
