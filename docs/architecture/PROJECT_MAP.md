# PROJECT_MAP.md — EANTrack

> Mapa de alto nível do projeto. Para estado detalhado → CURRENT_STATE.md. Para estrutura técnica → ARCHITECTURE.md.
> Última atualização: 2026-04-11

---

## Visão Geral

**Produto:** SaaS B2B para gestão de campo (PDVs, regiões, redes, categorias, indústrias)
**Stack:** Flutter + Supabase + Riverpod + GoRouter
**Origem:** Reconstrução code-first a partir de protótipo FlutterFlow (DEC-001)

---

## Status dos Módulos

| Módulo | Status | Observação |
|--------|--------|-----------|
| Fundação (router, tema, erros) | ✅ Completo | Dark mode, EanTrackTheme, RouterRedirectGuard |
| Auth | ✅ Completo | Login, register, email verify, recover, update password, cooldown, history |
| Onboarding — Perfil | ✅ Funcional | choose_mode, profile (identifier + sugestões), cnpj, company_data, legal_rep |
| Hub | 🔄 Layout ok | Responsivo desktop/mobile; sem dark mode; sem dados reais |
| Regiões | 🔄 Layout ok | Listagem, criação, toggle ativo; sem dark mode; sem testes de UI |
| Redes | ⏳ Pendente | — |
| Categorias | ⏳ Pendente | — |
| PDVs | ⏳ Pendente | — |
| Indústrias | ⏳ Pendente | — |
| Equipe | ⏳ Fase futura | — |

---

## Fluxo de Navegação

```
/splash
  └─ (auto) → FlowPage

FlowPage (decisão)
  ├─ unauthenticated → /login
  ├─ recovery        → /update-password
  ├─ onboardingRequired → /onboarding
  └─ authenticated   → /hub

Públicas (sem auth)
  /login
  /register
  /recover-password
  /email-verification

Onboarding (auth + email ok + onboarding incompleto)
  /onboarding           → ChooseModeScreen
  /onboarding/profile   → OnboardingProfileScreen
  /onboarding/cnpj      → CnpjScreen (agência)
  /onboarding/company   → CompanyDataScreen (agência)
  /onboarding/legal     → LegalRepresentativeScreen (agência)

Protegidas (auth + onboarding completo)
  /hub
  /regions
  /pdvs, /networks, /categories, /industries (fase futura)
```

---

## Domínio de Negócio

**Usuário Individual:** promotor ou agente autônomo — opera PDVs diretamente
**Usuário Agência:** gerencia equipe, clientes e operações completas — fluxo de onboarding adicional (CNPJ, dados empresa, representante legal)

**Entidades principais:**
- `user_flow_state` — rastreia progresso de onboarding e modo do usuário
- `tab_cadastroauxiliar` — dados complementares do cadastro
- `email_codes` — hashes SHA-256 de emails cadastrados
- Regiões, PDVs, Redes, Categorias, Indústrias (ver BACKEND_SCHEMA.md)

---

## Referência de Código Legado (FlutterFlow)

O projeto iniciou em FlutterFlow. O código gerado está em `lib/p_a_s_tpag_app_feed/` e `lib/flutter_flow/`.

**Status:** ignorar completamente — não compila no rebuild, não é referência arquitetural.
**Ação:** remover na Fase Hardening (futura). Até lá, manter para evitar conflito de git.

Para design visual de referência → storyboard FlutterFlow + SCREEN_SPECS.md.
