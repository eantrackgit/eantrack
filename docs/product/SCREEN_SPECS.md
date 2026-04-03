# SCREEN_SPECS.md — EANTrack (FINAL)

> Spec suficiente para reconstruir qualquer tela sem depender de memória.
> Referência: storyboard FlutterFlow real.

---

## LOGIN SCREEN (`/login`)

### Widget Tree (simplificado)
```
Scaffold (bg: bgPrimary)
└── Center
    └── SingleChildScrollView
        └── ConstrainedBox (maxWidth: 420)
            └── Card (bg: bgCard, radius: radiusLg, shadow: shadowCard)
                └── Padding (xl: 32px)
                    └── Column (crossAxis: center)
                        ├── Align(topRight) → IconButton (headset_mic_outlined) [SUPORTE]
                        ├── SizedBox(h: sm)
                        ├── Image (logo EANTrack ~160x60)
                        ├── SizedBox(h: xs)
                        ├── Text "Smart Tracking" (logoSubtitle, textSecondary)
                        ├── SizedBox(h: lg: 24)
                        ├── Form (key: _formKey)
                        │   └── Column
                        │       ├── AppTextField (label: "E-mail", keyboardType: email)
                        │       ├── SizedBox(h: md: 16)
                        │       └── AppTextField (label: "Senha", obscure, suffix: eye toggle)
                        ├── SizedBox(h: lg: 24)
                        ├── AppButton.primary ("Entrar", full-width)
                        ├── SizedBox(h: md: 16)
                        ├── DividerOu (--- ou ---)
                        ├── SizedBox(h: md: 16)
                        ├── AppButton.social ("Entrar com Google", icon: G)
                        ├── SizedBox(h: md: 16)
                        ├── Row (mainAxis: center)
                        │   ├── Text "Esqueceu sua senha?" (bodySmall, textSecondary)
                        │   └── TextButton "Clique aqui" (linkText, link)
                        ├── SizedBox(h: md: 16)
                        ├── AppButton.secondary ("Criar conta", full-width)
                        ├── SizedBox(h: lg: 24)
                        └── Column (crossAxis: center)
                            ├── Icon (fingerprint, 32px, textSecondary)
                            ├── SizedBox(h: xs: 4)
                            └── Text "Entre com biometria" (bodySmall, textSecondary)
```

### Comportamento completo

**Validação:**
- `bool _submitted = false;` no State
- Form sem `autovalidateMode` (default disabled)
- Cada validator: `if (!_submitted) return null;` no início
- Botão "Entrar": `setState(() => _submitted = true)` → `validate()` → se ok, chama notifier

**Botão "Entrar":**
| Condição | Estado |
|----------|--------|
| Formulário não submetido | enabled, texto "Entrar" |
| Loading (após submit válido) | loading (spinner), campos disabled |
| Erro retornado | enabled novamente, erro visível |

**Botão "Entrar com Google":**
- `onPressed: () => debugPrint('[AUTH] Google tapped')`
- UI only — sem lógica OAuth

**Botão "Criar conta":**
- `onPressed: () => context.go('/register')`

**Link "Clique aqui":**
- `onPressed: () => context.go('/recover-password')`

**Biometria:**
- `onTap: () => debugPrint('[AUTH] Biometria tapped')`
- UI only — futuro

**Ícone suporte (headset):**
- `onPressed: () => debugPrint('[AUTH] Suporte tapped')`
- UI only — futuro

**Erros de auth:**
- Se `AuthError` no state → mostrar `ErrorBanner` entre o Form e o botão "Entrar"
- Mensagem vem do notifier (já mapeada em PT-BR)

---

## REGISTER SCREEN (`/register`)

### Widget Tree (simplificado)
```
Scaffold (bg: bgPrimary)
└── Center
    └── SingleChildScrollView
        └── ConstrainedBox (maxWidth: 480)
            └── Card (bg: bgCard, radius: radiusLg, shadow: shadowCard)
                └── Padding (xl: 32px)
                    └── Column
                        ├── TabBar (4 tabs — ver abaixo)
                        ├── SizedBox(h: lg: 24)
                        └── TabBarView / IndexedStack
                            ├── [0] TabInformacoes (ver abaixo)
                            ├── [1] TabFoto (placeholder)
                            ├── [2] TabPrivacidade (placeholder)
                            └── [3] TabDocumento (placeholder)
```

### TabBar
```
Tabs: "Informações" | "Sua foto" | "Privacidade" | "Documento"
Style:
  - selected: textPrimary, underline primary
  - unselected: textSecondary, sem underline
  - indicatorColor: primary
  - labelStyle: bodyMedium weight 600
```

### Tab "Informações" — Widget Tree
```
Form (key: _formKey)
└── Column
    ├── AppTextField (label: "Nome completo")
    ├── SizedBox(h: md: 16)
    ├── AppTextField (label: "E-mail", keyboardType: email)
    │   └── [abaixo, se debounce ativo] Texto "Verificando..." ou "E-mail disponível" ✓
    ├── SizedBox(h: md: 16)
    ├── AppTextField (label: "Senha", obscure, suffix: eye toggle)
    ├── SizedBox(h: sm: 8)
    ├── PasswordStrengthChecklist (3 items)
    ├── SizedBox(h: md: 16)
    ├── AppTextField (label: "Confirmar senha", obscure, suffix: eye toggle)
    ├── SizedBox(h: lg: 24)
    └── Row (mainAxis: spaceBetween)
        ├── AppButton.secondary ("Cancelar", width: ~45%)
        └── AppButton.primary ("Avançar", width: ~45%)
```

### Comportamento completo — Tab Informações

**Validação:**
- `bool _submitted = false;` no State
- Form sem `autovalidateMode`
- Cada validator: `if (!_submitted) return null;`
- Botão "Avançar": `setState(() => _submitted = true)` → `validate()`

**Validators por campo:**
| Campo | Validator (após _submitted) |
|-------|----------------------------|
| Nome | vazio → "Informe seu nome"; length < 2 → "Nome muito curto" |
| Email | vazio → "Informe seu e-mail"; regex inválido → "E-mail inválido" |
| Senha | vazio → "Informe sua senha"; < 8 → "Mínimo 8 caracteres"; sem maiúscula → "Inclua letra maiúscula"; sem minúscula → "Inclua letra minúscula" |
| Confirmar | vazio → "Confirme sua senha"; != senha → "Senhas não coincidem" |

**Password Strength Checklist:**
```dart
// Variáveis no State:
bool _hasMinLength = false;
bool _hasUppercase = false;
bool _hasLowercase = false;

// onChanged do campo senha:
onChanged: (value) {
  setState(() {
    _hasMinLength = value.length >= 8;
    _hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    _hasLowercase = RegExp(r'[a-z]').hasMatch(value);
  });
}
```
- NÃO é validator — NÃO impede submit se checklist incompleto
- O validator do campo senha já cobre as regras

**Email debounce check:**
- Após 800ms sem digitar → chama `checkEmailAvailable`
- Mostra "Verificando..." durante check
- Se disponível → ícone check verde + "E-mail disponível"
- Se indisponível → texto erro "E-mail já cadastrado"
- Esse check é independente do validator (acontece via onChanged + debounce)

**Botão "Avançar":**
| Condição | Estado |
|----------|--------|
| Formulário não submetido | enabled |
| Loading (após submit válido) | loading spinner |
| Erro retornado | enabled, erro visível |

**Botão "Cancelar":**
- `onPressed: () => context.go('/login')`

---

## EMAIL VERIFICATION SCREEN (`/email-verification`)

### Widget Tree
```
Scaffold (bg: bgPrimary)
└── Center
    └── ConstrainedBox (maxWidth: 420)
        └── Card (bg: bgCard, radius: radiusLg)
            └── Padding (xl: 32px)
                └── Column (crossAxis: center)
                    ├── Align(topRight) → IconButton (close) [volta ao login]
                    ├── SizedBox(h: md)
                    ├── Image (logo EANTrack menor ~120x45)
                    ├── SizedBox(h: lg)
                    ├── [CONFIRMADO] Text "Conta Confirmada!" (h1, success)
                    │   + LottieBuilder (checkmark, 80x80, 500ms)
                    ├── [AGUARDANDO] Text "Confirme sua conta" (h2, textPrimary)
                    ├── SizedBox(h: sm)
                    ├── Text "verifique seu e-mail..." (bodyMedium, textSecondary, center)
                    ├── Text "conta para começar a usar o EANTrack" (bodyMedium, textSecondary)
                    ├── SizedBox(h: lg)
                    ├── [SE COOLDOWN] LinearProgressIndicator (value: remaining/300)
                    ├── [SE COOLDOWN] SizedBox(h: sm)
                    ├── [SE COOLDOWN] Text "Reenviado! Aguarde X:XX" (bodySmall, textSecondary)
                    ├── SizedBox(h: md)
                    ├── [SE ERRO] ErrorBanner (mensagem)
                    ├── SizedBox(h: lg)
                    ├── Row (mainAxis: spaceBetween)
                    │   ├── AppButton.secondary ("← Voltar")
                    │   └── AppButton.primary ("Já confirmei" / spinner / "Continuar")
                    ├── SizedBox(h: md)
                    ├── TextButton "Reenviar verificação" (linkText)
                    └── SizedBox(h: sm)
                        └── Text "Já confirmei meu e-mail →" (linkText) [alternativo]
```

### Comportamento por estado
(Detalhado em AUTH_FLOW.md — seção Email Verification)

---

## RECOVER PASSWORD SCREEN (`/recover-password`)

### Widget Tree
```
Scaffold (bg: bgPrimary)
└── Center
    └── ConstrainedBox (maxWidth: 420)
        └── Card (bg: bgCard, radius: radiusLg)
            └── Padding (xl: 32px)
                └── Column (crossAxis: center)
                    ├── Text "Recuperar senha" (h2)
                    ├── SizedBox(h: sm)
                    ├── Text "Informe seu e-mail..." (bodyMedium, textSecondary)
                    ├── SizedBox(h: lg)
                    ├── Form
                    │   └── AppTextField (label: "E-mail")
                    ├── SizedBox(h: lg)
                    ├── [SE SUCESSO] SuccessBanner "Link enviado!"
                    ├── [SE ERRO] ErrorBanner (mensagem)
                    ├── SizedBox(h: md)
                    ├── AppButton.primary ("Enviar", full-width)
                    ├── SizedBox(h: md)
                    └── TextButton "← Voltar ao login" (linkText)
```

### Comportamento
- Mesma validação `_submitted` dos outros forms
- Submit → `AuthRepository.resetPassword(email)`
- Sucesso → mostra banner verde, botão volta ao normal
- Erro → mostra ErrorBanner
- "Voltar" → `context.go('/login')`

---

## CHOOSE MODE SCREEN (`/onboarding`)

### Widget Tree
```
Scaffold (bg: bgPrimary)
└── Center
    └── SingleChildScrollView
        └── ConstrainedBox (maxWidth: 480)
            └── Card (bg: bgCard, radius: radiusLg)
                └── Padding (xl: 32px)
                    └── Column (crossAxis: center)
                        ├── Icon (badge EANTrack ou check_circle, 48px, success)
                        ├── SizedBox(h: lg)
                        ├── Text "Defina seu estilo operacional" (h1, center)
                        ├── SizedBox(h: sm)
                        ├── Text "Essa configuração ajuda..." (bodyMedium, textSecondary, center)
                        ├── SizedBox(h: lg)
                        ├── ModeCard ("Individual")
                        │   ├── Icon (person, 32px)
                        │   ├── Text "Individual" (h3)
                        │   └── Text "Agente ou promotor..." (bodySmall, textSecondary)
                        ├── SizedBox(h: md)
                        ├── ModeCard ("Agência")
                        │   ├── Icon (business, 32px)
                        │   ├── Text "Agência" (h3)
                        │   └── Text "Gerencia equipe..." (bodySmall, textSecondary)
                        ├── SizedBox(h: lg)
                        └── Row (mainAxis: spaceBetween)
                            ├── AppButton.secondary ("← Voltar")
                            └── AppButton.primary ("Avançar →")
```

### ModeCard estados
| Estado | Border | Background | Ícone extra |
|--------|--------|------------|-------------|
| Unselected | 1px `borderDefault` | `bgCard` | — |
| Selected | 2px `success` | `success` 5% | Check verde no canto |
| Hover | 1px `borderHover` | `bgHover` | — |

### Comportamento
- Tap em card → setState seleciona (toggle entre os dois)
- Apenas 1 selecionado por vez
- "Avançar" disabled até selecionar (opacity 0.5, onPressed null)
- "Avançar" → persiste modo → navega para próximo step
- "Voltar" → volta ao login / tela anterior

---

## TELAS INTERNAS — PADRÃO GERAL

### Shell Layout (Hub e features internas)
```
Scaffold (bg: bgPrimary)
├── [DESKTOP] Row
│   ├── AppSidebar (width: 240, bg: bgCardDark)
│   │   ├── UserHeader (avatar + nome + role)
│   │   ├── Divider
│   │   └── MenuItems (Regiões, Redes, Categorias, PDVs, ...)
│   └── Expanded → content
├── [MOBILE] Column
│   ├── Expanded → content
│   └── AppBottomNav (5 items)
└── [TABLET] igual desktop mas sidebar colapsável
```

### List Screen padrão (Regions, Networks, PDVs)
```
Column
├── Header Row
│   ├── IconButton (back)
│   ├── Text título (h2, textOnDark)
│   └── IconButton (add)
├── SizedBox(h: md)
├── AppTabBar ("Todos" | "Ativos" | "Inativos")
├── SizedBox(h: md)
├── AppSearchBar (hint: "Buscar...")
├── SizedBox(h: md)
└── Expanded
    └── ListView.builder / [AppEmptyState se vazio]
```
