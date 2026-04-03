# EANTrack — Rebuild Roadmap

> Sequência oficial de reconstrução. Cada fase deve ser estabilizada antes da próxima.

---

## Status Geral

| Fase | Módulo | Status |
|------|--------|--------|
| 0 | Documentação + Fundação | ✅ Em andamento |
| 1 | Auth | 🔄 Em progresso |
| 2 | Onboarding de Agência | ⏳ Pendente |
| 3 | Hub + Navegação Principal | ⏳ Pendente |
| 4 | Categorias + Redes | ⏳ Pendente |
| 5 | Regiões + Cidades | ⏳ Pendente |
| 6 | PDVs | ⏳ Pendente |
| 7 | Indústrias + Mix | ⏳ Pendente |
| 8 | Feed / Flow | ⏳ Pendente |
| 9 | Lançamento de Produto | ⏳ Pendente |
| 10 | Edição de Produto | ⏳ Pendente |
| 11 | Busca | ⏳ Pendente |
| 12 | Perfil + Conta | ⏳ Pendente |
| 13 | Limpeza e Hardening | ⏳ Pendente |

---

## Fase 0 — Documentação + Fundação

**Objetivo:** Base técnica completa antes de qualquer tela.

**Entregáveis:**
- [x] PROJECT_MAP.md
- [x] ARCHITECTURE.md
- [x] DESIGN_SYSTEM.md
- [x] REBUILD_GUIDELINES.md
- [x] REBUILD_ROADMAP.md (este arquivo)
- [x] MODULE_TEMPLATE.md
- [x] TEST_STRATEGY.md
- [x] BUILD_LOG.md / DECISIONS_LOG.md / CURRENT_STATE.md
- [x] pubspec.yaml atualizado (+ riverpod + crypto)
- [x] lib/main.dart
- [x] lib/app/app.dart
- [x] lib/core/ (config, router, error)
- [x] lib/shared/theme/ (4 arquivos)
- [x] lib/shared/layout/breakpoints.dart
- [x] lib/features/auth/ (data, domain, providers)

**Risco:** Baixo
**Benefício:** Fundação sólida, sem herança FlutterFlow

---

## Fase 1 — Auth

**Objetivo:** Módulo de autenticação completo, funcional, testado.

**Escopo — preservado do FlutterFlow:**
- Login (email + senha)
- Cadastro (email + senha + confirmação + termos)
- Verificação de e-mail (com cooldown de reenvio)
- Recuperação de senha
- Persistência de sessão (auto-login)
- Guards de rota (público / verificação / protegido)
- Redirecionamento pós-login (baseado em user_flow_state)

**Entregáveis:**
- [ ] shared/widgets/app_button.dart
- [ ] shared/widgets/app_text_field.dart
- [ ] shared/widgets/app_loading_overlay.dart
- [ ] features/auth/presentation/screens/login_screen.dart
- [ ] features/auth/presentation/screens/register_screen.dart
- [ ] features/auth/presentation/screens/email_verification_screen.dart
- [ ] features/auth/presentation/screens/recover_password_screen.dart
- [ ] Testes unitários: AuthRepository
- [ ] Testes widget: todas as telas de auth
- [ ] Comparação visual com FlutterFlow

**Dependências:** Fase 0 completa
**Risco:** Médio (fluxo de email verification é complexo)

---

## Fase 2 — Onboarding de Agência

**Objetivo:** Fluxo multi-etapa de cadastro de agência.

**Escopo:**
- CNPJ validation + API externa
- Dados da agência
- Representante legal
- Estilo operacional
- Status de aprovação
- Foto de perfil

**Complexidade:** Alta (8 telas, regras implícitas, retomada de etapa)
**Dependências:** Fase 1 completa

---

## Fase 3 — Hub + Navegação Principal

**Objetivo:** Estrutura pós-login com bottom nav e hub central.

**Escopo:**
- PagFlow (dashboard)
- PagHome
- PagBuscar
- Hub de navegação
- Bottom nav bar

**Dependências:** Fase 2 completa

---

## Fase 4 — Categorias + Redes

**Objetivo:** Módulos de configuração mais simples.

**Escopo:**
- CRUD de Categorias
- CRUD de Subcategorias
- CRUD de Redes

**Complexidade:** Baixa
**Dependências:** Fase 3 completa

---

## Fase 5 — Regiões + Cidades

**Objetivo:** Gestão de regiões geográficas e cidades vinculadas.

**Escopo:**
- CRUD de Regiões
- Vinculação de cidades por região
- Resolução de conflitos de cidades
- Bulk insert de cidades

**Complexidade:** Média (lógica de conflito entre regiões)
**Dependências:** Fase 3 completa

---

## Fase 6 — PDVs

**Objetivo:** Pontos de Venda — cadastro, listagem, filtros.

**Escopo:**
- Listagem com filtros
- Cadastro de PDV com validação CNPJ
- Ativação/inativação

**Complexidade:** Alta (validação CNPJ + API externa)
**Dependências:** Fase 4 + Fase 5

---

## Fase 7 — Indústrias + Mix

**Objetivo:** Gestão de indústrias e mix de produtos.

**Escopo:**
- CRUD de Indústrias
- Registro de Indústria
- Mix de produtos

**Dependências:** Fase 4

---

## Fase 8 — Lançamento + Edição de Produto

**Objetivo:** Os dois maiores componentes do sistema.

**Escopo:**
- Wizard de lançamento de produto (substituição do comp 2435 linhas)
- Edição de produto (substituição do comp 1862 linhas)
- Upload de foto (câmera/galeria)
- Geração de EAN/GTIN
- Geração de barcode

**Complexidade:** Muito alta
**Dependências:** Fases 4, 5, 6, 7

---

## Fase 9 — Perfil + Conta

**Objetivo:** Gestão de conta do usuário.

**Escopo:**
- Foto de perfil
- Alterar senha
- Dados pessoais

**Dependências:** Fase 1

---

## Fase 10 — Hardening Final

**Objetivo:** Preparação para produção.

**Escopo:**
- Remoção do código FlutterFlow residual
- Cleanup do pubspec.yaml (remover deps não usadas)
- Auditoria de segurança
- Testes de regressão end-to-end
- Performance profiling
- Configuração de ambientes (dev/staging/prod)
- Build APK + PWA validados

---

## Critérios de Conclusão por Fase

Uma fase só está concluída quando:
1. Todas as telas/features do escopo implementadas
2. Comparação visual com FlutterFlow feita e aprovada
3. Testes passando (unit + widget)
4. Sem `TODO` ou `FIXME` críticos
5. CURRENT_STATE.md e BUILD_LOG.md atualizados
