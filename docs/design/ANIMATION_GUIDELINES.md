# ANIMATION_GUIDELINES.md — EANTrack

> Padrão obrigatório de animações. Produto B2B — sutil, funcional, profissional.

---

## PRINCÍPIOS

1. **Funcional, não decorativa.** Toda animação deve comunicar algo: feedback de ação, mudança de estado, ou orientação espacial. Se não comunica nada, remover.
2. **Sutil e rápida.** Usuário não deve "esperar" uma animação terminar. Se percebe conscientemente, está lenta demais.
3. **Consistente.** Mesma ação = mesma animação em todo o app. Botão pressed em Login = botão pressed em PDVs.
4. **Sem surpresas.** Nada deve pular, quicar ou piscar. Produto corporativo exige sobriedade.

---

## DURAÇÕES PADRÃO

| Faixa | Uso | Exemplos |
|-------|-----|----------|
| **100ms** | Interação imediata | Button pressed, toggle, checkbox |
| **150ms** | Transição micro | Input focus, border change, icon swap |
| **200ms** | Feedback visual | Error appear, success check, label float |
| **300ms** | Transição de tela/conteúdo | Screen fade, card appear, modal open |
| **500ms** | Animação de destaque (raro) | Lottie checkmark (email confirmed) |

**Regra:** nunca ultrapassar 500ms. Se precisa de mais, o design está errado.

---

## CURVAS

| Curva | Quando usar | Flutter |
|-------|-------------|---------|
| **easeInOut** | Padrão geral, transições | `Curves.easeInOut` |
| **easeIn** | Saída/pressed (elemento "afundando") | `Curves.easeIn` |
| **easeOut** | Entrada/appear (elemento "chegando") | `Curves.easeOut` |
| **linear** | Progress bars, countdowns | `Curves.linear` |
| **elasticOut** | APENAS Lottie checkmark (email confirm) | `Curves.elasticOut` |

**Proibido:** `bounceIn`, `bounceOut`, `bounceInOut` — nunca usar em nenhum contexto.

---

## CATÁLOGO DE ANIMAÇÕES

### 1. Button Pressed
```
Trigger: onTapDown
Efeito: scale 0.97 + opacity 0.85
Duração: 100ms
Curva: easeIn
Retorno: 100ms easeOut (volta ao normal no onTapUp)
```
Implementação: `AnimatedScale` + `AnimatedOpacity` ou `GestureDetector` + `Transform.scale`.

### 2. Button Loading Transition
```
Trigger: state muda para Loading
Efeito: texto fade out (100ms) → spinner fade in (100ms)
Duração total: 200ms
Curva: easeInOut
Tamanho spinner: 18px, branco
Botão mantém exatamente o mesmo tamanho (não encolher)
```
Implementação: `AnimatedSwitcher` com `FadeTransition` ou `AnimatedCrossFade`.

### 3. Input Focus
```
Trigger: FocusNode.hasFocus muda
Efeito: border color transition (borderDefault → borderFocus) + width (1px → 2px)
Duração: 150ms
Curva: easeInOut
```
Implementação: handled nativamente pelo `InputDecoration` com `focusedBorder`. Transição é automática do Flutter.

### 4. Input Label Float
```
Trigger: campo recebe foco ou tem valor
Efeito: label move de placeholder para topo, scale 0.85
Duração: 150ms
Curva: easeInOut
```
Implementação: nativo do `FloatingLabelBehavior.auto` no `InputDecoration`.

### 5. Error Appear
```
Trigger: validator retorna mensagem (após _submitted = true)
Efeito: fade in + slide down 4px
Duração: 200ms
Curva: easeOut
```
Implementação: `AnimatedSize` + `AnimatedOpacity` no wrapper do error text. Ou aceitar o comportamento padrão do Flutter Form error (que já faz slide).

### 6. Error Disappear
```
Trigger: validator retorna null (campo corrigido)
Efeito: fade out
Duração: 150ms
Curva: easeIn
```

### 7. Card Appear (Auth screens)

**REMOVIDO.** Animações de entrada de tela/card não são mais permitidas.
Transições de tela são responsabilidade exclusiva do GoRouter (item 8).

### 8. Screen Transition ⚠️ PADRÃO ÚNICO
```
Trigger: GoRouter navega entre rotas
Efeito: fade simples (opacity 0→1)
Duração: 200ms entrada e saída
Curva: easeInOut
Slide: NÃO usar
```
Implementação: `CustomTransitionPage` via helper `_fadePage()` em `app_router.dart`.
**REGRA:** nenhuma tela pode definir animação de entrada própria. Zero exceções.

### 9. Success Checkmark (Email Verification)
```
Trigger: email confirmado
Efeito: Lottie asset — checkmark verde com scale bounce
Duração: 500ms
Curva: elasticOut (dentro do Lottie)
Após: aguardar 1.5s → redirect
```
Implementação: `Lottie.asset()` com `repeat: false`.

### 10. Cooldown Progress Bar
```
Trigger: reenvio de email
Efeito: LinearProgressIndicator value decrementa de 1.0 → 0.0
Duração: 300 segundos (5 min)
Curva: linear
Cor: link (azul)
Background: borderDefault
```

### 11. Password Strength Item
```
Trigger: onChanged do campo senha
Efeito: ícone e texto mudam de cor (textSecondary → textSuccess ou vice-versa)
Duração: 150ms
Curva: easeInOut
```
Implementação: `AnimatedDefaultTextStyle` + `AnimatedSwitcher` para ícone. Ou simples rebuild sem animação (aceitável dado que é feedback real-time).

### 12. Card Selection (Onboarding mode)
```
Trigger: tap no card Individual/Agência
Efeito: troca imediata de cores (background + border + text/icon)
Duração: nenhuma — setState() direto
```
Implementação: `Container` simples. `AnimatedContainer` removido (inconsistência com padrão global).

### 13. Snackbar
```
Entrada: slide up from bottom, 250ms, easeOut
Saída: slide down, 200ms, easeIn
```
Implementação: `ScaffoldMessenger.showSnackBar` com `SnackBarBehavior.floating`. Animação nativa do Flutter.

### 14. Modal / Bottom Sheet
```
Entrada: slide up + fade, 300ms, easeOut
Saída: slide down + fade, 200ms, easeIn
```
Implementação: padrão `showModalBottomSheet`. Não customizar.

### 15. Hover (Web/Desktop)
```
Trigger: mouse enter/exit
Efeito: background color transition (transparent → bgHover)
Duração: 150ms
Curva: easeInOut
```
Implementação: `InkWell` com `hoverColor` ou `MouseRegion` + `AnimatedContainer`.

---

## PROIBIÇÕES

| Efeito | Por quê |
|--------|---------|
| Bounce (qualquer curva bounce) | Infantil, não combina com B2B |
| Shake (error shake) | Agressivo, causa ansiedade |
| Slide horizontal de telas | Confuso em web (não é mobile nativo) |
| Parallax | Desnecessário, distração |
| Delay antes de animação (>50ms) | Usuário percebe lag |
| Animação em loop (exceto loading spinner) | Distração |
| Escala > 1.05 ou < 0.95 | Exagerado |
| Duração > 500ms (exceto Lottie pontual) | Lento demais |
| Animação que bloqueia interação | Frustração |

---

## DECISÃO: QUANDO ANIMAR vs NÃO ANIMAR

| Situação | Animar? |
|----------|---------|
| Botão pressionado | Sim (pressed feedback) |
| Input ganha foco | Sim (border transition) |
| Erro aparece | Sim (fade in + slide) |
| Tela carrega | Sim (card appear 300ms) |
| Lista carrega items | Não (render direto, sem stagger) |
| Scroll | Não (nativo do Flutter) |
| Toggle dark/light | Não (não temos dark/light toggle) |
| Mudança de tab | Não (troca imediata de conteúdo) |
| Drawer/sidebar abre | Não (desktop: fixo / mobile: não tem drawer) |

---

## IMPLEMENTAÇÃO — REGRAS PARA CODEX

1. **Transições de tela:** exclusivamente via `_fadePage()` em `app_router.dart`. Nunca adicionar `AnimationController`, `FadeTransition`, `ScaleTransition` ou `TweenAnimationBuilder` em widgets de tela.
2. **Componentes:** `AnimatedSwitcher` (loading↔label), `AnimatedScale` (press), `AnimatedOpacity` (disabled) são permitidos **apenas em widgets reutilizáveis** (`AppButton`, etc.) — não em telas.
3. **Lottie:** apenas para loading global (`flow_loading.json`). Usar com `animate: true, repeat: true`. Duração controlada pelo JSON — nunca por controller externo.
4. Nunca adicionar pacote de animação novo sem aprovação.
5. Se em dúvida entre animar ou não: **não animar**. Simplicidade > sofisticação.
