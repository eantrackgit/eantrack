# EANTrack

**Gestão B2B de agências** — PDVs, Regiões, Redes, Categorias, Indústrias, Produtos.

Stack: Flutter + Supabase + Riverpod + GoRouter

---

## Documentação → `/docs`

```
docs/
├── architecture/
│   ├── ARCHITECTURE.md        Stack, folder structure, padrões técnicos
│   ├── BACKEND_SCHEMA.md      Tabelas, views, triggers e 41 RPCs do Supabase
│   └── PROJECT_MAP.md         Mapa do projeto FlutterFlow (referência visual)
│
├── product/
│   ├── SCREEN_SPECS.md        Widget tree + comportamento de cada tela
│   └── REBUILD_ROADMAP.md     Roadmap de fases (0–10)
│
├── engineering/
│   ├── GLOBAL_PATTERNS.md     Padrões obrigatórios: state, forms, nav, erros
│   ├── DEFINITION_OF_DONE.md  Checklist de aceite por tipo de entrega
│   ├── CODE_RULES.md          Regras de código (tamanho, separação, naming)
│   ├── MODULE_TEMPLATE.md     Template para criação de novos módulos
│   ├── TEST_STRATEGY.md       Estratégia de testes
│   └── COMPONENT_LIBRARY.md   Inventário de widgets e utils implementados
│
├── design/
│   ├── DESIGN_SYSTEM.md       Tokens visuais, componentes, especificações completas
│   └── ANIMATION_GUIDELINES.md Catálogo de animações, durações, curvas, proibições
│
├── auth/
│   └── AUTH_FLOW.md           Fluxos de auth com diagramas, edge cases, method signatures
│
├── logs/
│   ├── DECISIONS_LOG.md       Decisões técnicas com contexto e impacto
│   └── BUILD_LOG.md           Registro cronológico do que foi construído
│
└── planning/
    ├── CURRENT_STATE.md       Estado atual do projeto — ler primeiro ao retomar
    ├── BACKLOG.md             CODEX_TASKs prontas para execução
    └── AGENTS.md              Regras de execução para Codex
```

---

## Setup

```bash
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=<url> \
  --dart-define=SUPABASE_ANON_KEY=<key>
```

---

## Fase Atual

**Fase 1 — Auth** ✅ completa | **Fase 2 — Onboarding** 🔄 pendente

Ver [docs/planning/CURRENT_STATE.md](docs/planning/CURRENT_STATE.md) para estado exato.
