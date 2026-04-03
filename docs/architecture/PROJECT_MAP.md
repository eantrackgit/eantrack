# EANTrack — Project Map

> **Versão:** 2.0 — Reconstrução iniciada (2026-03-29)
> **Decisão:** RECONSTRUÇÃO TOTAL em Flutter puro. FlutterFlow mantido como referência apenas.
> **Nova stack:** Flutter + Supabase + Riverpod + GoRouter (sem FlutterFlow)
> **Arquitetura:** Feature-first com data/domain/presentation por módulo
> **Documentação principal:** ARCHITECTURE.md | DESIGN_SYSTEM.md | REBUILD_ROADMAP.md

---

## Status da Reconstrução

| Fase | Módulo | Status |
|------|--------|--------|
| 0 | Fundação + Documentação | ✅ Completo |
| 1 | Auth | 🔄 Em progresso (fundação ok, telas pendentes) |
| 2+ | Demais módulos | ⏳ Pendente |

Veja [CURRENT_STATE.md](CURRENT_STATE.md) para estado exato.

---

## Código FlutterFlow (referência)

O código abaixo documenta o projeto FlutterFlow exportado, mantido como **referência de comportamento, fluxos e regras de negócio**. NÃO deve ser usado como base estrutural.

---

---

## 1. Estrutura do Projeto

```
eantrack/
├── lib/
│   ├── main.dart                          # Entry point
│   ├── app_state.dart                     # Estado global (FFAppState)
│   ├── index.dart                         # Barrel de exports
│   ├── auth/                              # Sistema de autenticação
│   │   └── supabase_auth/                 # Email, Google, Apple Sign-In
│   ├── backend/                           # Integrações de dados
│   │   ├── api_requests/                  # Chamadas REST externas
│   │   ├── firebase/                      # Config Firebase
│   │   ├── schema/                        # Enums, Structs de dados
│   │   │   ├── enums/
│   │   │   └── structs/                   # 25+ structs de resposta de API
│   │   └── supabase/                      # Acesso ao banco
│   │       └── database/tables/           # 28 tabelas mapeadas
│   ├── flutter_flow/                      # Código gerado pelo FlutterFlow
│   │   ├── flutter_flow_theme.dart        # Tema visual
│   │   ├── custom_functions.dart          # ~950 linhas de funções utilitárias
│   │   ├── internationalization.dart      # Localização PT-BR
│   │   └── nav/nav.dart                   # Roteamento (GoRouter, ~20KB)
│   ├── custom_code/                       # Código customizado fora do FlutterFlow
│   │   ├── actions/                       # 40 custom actions
│   │   └── widgets/                       # 1 widget customizado (NetworkDropdown)
│   ├── components/                        # Componentes reutilizáveis principais (6)
│   ├── compgeral/                         # Componentes gerais/utilitários (13)
│   └── p_a_s_tpag_app_feed/               # Páginas organizadas por feature
│       ├── folderauth/                    # Onboarding e autenticação (14 páginas)
│       ├── folderloginentry/              # Login, Home, Search, Flow
│       ├── foldermenuhub/                 # Hub principal
│       ├── foldermenucategory/            # Categorias e subcategorias
│       ├── foldermenuredes/               # Redes (networks)
│       ├── foldermodalregion/             # Regiões e cidades
│       ├── foldermodalpdvs/               # PDVs (Pontos de Venda)
│       └── foldermodalindustry/           # Indústrias e mix de produtos
├── assets/
│   ├── fonts/                             # Poppins, Roboto, Ubuntu + ícones customizados
│   ├── images/                            # 8 imagens (logos, ícones, avatares)
│   ├── jsons/                             # 7 animações Lottie
│   ├── pdfs/, videos/, audios/            # Mídia (diretórios presentes, uso indireto)
│   └── rive_animations/                   # Animações Rive
├── android/, ios/, web/                   # Plataformas nativas
├── firebase/                              # Regras, Functions, Hosting
└── pubspec.yaml
```

**Totais:**
- Diretórios: ~105
- Arquivos Dart: ~293
- Tabelas Supabase: 28
- Telas: 25+
- Componentes: 50+
- Custom Actions: 40

---

## 2. Módulos Identificados

| Módulo | Pasta | Descrição |
|--------|-------|-----------|
| **Autenticação** | `folderauth/`, `auth/` | Cadastro, login, verificação de e-mail, recuperação de conta |
| **Onboarding de Agência** | `folderauth/` | Fluxo multi-etapa de cadastro completo de agência |
| **Hub Principal** | `foldermenuhub/` | Ponto de entrada pós-login com acesso aos módulos |
| **PDVs** | `foldermodalpdvs/` | Cadastro, listagem e gestão de Pontos de Venda |
| **Regiões** | `foldermodalregion/` | Gestão de regiões e cidades vinculadas |
| **Redes** | `foldermenuredes/` | Gestão de redes de distribuição |
| **Categorias** | `foldermenucategory/` | Categorias e subcategorias de produtos |
| **Indústrias** | `foldermodalindustry/` | Indústrias, produtos e mix |
| **Feed/Flow** | `folderloginentry/` | Dashboard principal, busca, home |
| **Perfil/Conta** | `folderauth/` | Foto de perfil, senha, dados pessoais |
| **Legal** | `folderauth/` | Termos de uso, política de privacidade |

---

## 3. Telas

### Autenticação e Onboarding
| Tela | Pasta | Descrição |
|------|-------|-----------|
| `pag_login` | folderloginentry | Login com e-mail ou Google |
| `pag2_cadastro_principal` | folderauth | Início do cadastro de conta |
| `pag2_0_pt_cnpj_cadastro_agencia` | folderauth | Validação e entrada de CNPJ |
| `pag2_1_pt_cadastro_agencia` | folderauth | Dados da agência (passo 1) |
| `pag2_2_pt_cadastro_representante_legal` | folderauth | Dados do representante legal |
| `pag2_estilo_operacional` | folderauth | Configuração de estilo operacional |
| `pag2_pt_cadastro` | folderauth | Passo genérico de cadastro |
| `pag2_status_agency` | folderauth | Status da agência no onboarding |
| `pag2_verificar_email` | folderauth | Verificação de e-mail |
| `pag_alterar_senha` | folderauth | Alteração de senha |
| `pag_recuperar_conta` | folderauth | Recuperação de conta |
| `pag_photo_profile` | folderauth | Upload de foto de perfil |
| `pag_politica_de_privacidade` | folderauth | Política de privacidade |
| `pag_termosdeuso` | folderauth | Termos de uso |

### App Principal
| Tela | Pasta | Descrição |
|------|-------|-----------|
| `pag_flow` | folderloginentry | Dashboard / feed principal |
| `pag_home` | folderloginentry | Home do app |
| `pag_buscar` | folderloginentry | Busca geral |
| `pag_no_connection` | folderloginentry | Sem internet (offline fallback) |
| `pag2_menu_hub` | foldermenuhub | Hub central de navegação |

### Gestão Operacional
| Tela | Pasta | Descrição |
|------|-------|-----------|
| `pag2_menu_region` | foldermodalregion | Lista de regiões |
| `pag2_menu_cityies` | foldermodalregion | Lista de cidades por região |
| `pag2_menu_list_city` | foldermodalregion | Detalhes/edição de cidades |
| `pag2_menu_pdvs` | foldermodalpdvs | Lista de PDVs |
| `pag2_menu_register_pdv` | foldermodalpdvs | Cadastro de novo PDV |
| `pag2_menu_list_work` | foldermenuredes | Lista de redes |
| `pag2_menu_list_category` | foldermenucategory | Lista de categorias |
| `pag2_menu_list_subcategory` | foldermenucategory | Lista de subcategorias |
| `pag2_menu_industry` | foldermodalindustry | Lista de indústrias |
| `pag2_menu_industry_register` | foldermodalindustry | Cadastro de indústria |
| `pag2_menu_list_mix` | foldermodalindustry | Mix de produtos |

---

## 4. Entidades de Negócio

### Modelo de Domínio (inferido das tabelas Supabase)

```
Agency (Agência)
  ├── tem members (AgencyMember)
  │     └── tem regions (AgencyMemberRegion)
  ├── tem categories (AgencyCategory)
  │     └── tem subcategories (AgencySubcategory)
  ├── tem subscription (AgencySubscription)
  └── tem legal representatives (LegalRepresentative)

Region (Região)
  ├── pertence a Agency
  ├── tem cities (RegionCity → City)
  └── tem responsibles (RegionResponsible)

Network (Rede)
  └── pertence ao domínio de trabalho/distribuição

PDV (Ponto de Venda)
  ├── pertence a Region (presumido)
  └── identificado por CNPJ

Industry (Indústria)
  └── tem products (IndustryProduct)

User
  ├── tem profile (UserProfileView)
  ├── tem identifier (UserIdentifier)
  └── tem flow state (UserFlowState)

City (Cidade)
  └── referência via IBGE
```

**Entidades principais:** Agency, PDV, Region, Network, Category, Industry, User

---

## 5. Fluxos de Navegação

### Fluxo de Onboarding de Agência (multi-etapa)
```
Login/Cadastro
  → Verificação de E-mail
  → Cadastro Principal (dados pessoais)
  → CNPJ da Agência
  → Dados da Agência
  → Representante Legal
  → Estilo Operacional
  → Status da Agência
  → Hub Principal
```

### Fluxo de Login
```
PagLogin
  → (se aprovado) → PagFlow / PagHome
  → (se novo)     → Fluxo de Onboarding
  → (sem internet)→ PagNoConnection
```

### Navegação Principal (pós-login)
```
PagFlow (Dashboard)
  ├── PagHome
  ├── PagBuscar (Search)
  └── Pag2MenuHub
        ├── Regiões → Cidades
        ├── PDVs → Cadastro PDV
        ├── Redes
        ├── Categorias → Subcategorias
        └── Indústrias → Produtos → Mix
```

---

## 6. Componentes Reutilizáveis

### Componentes Principais (`/components/`)
| Componente | Linhas | Descrição |
|------------|--------|-----------|
| `comp_lancamentodeproduto` | ~2435 | Wizard de lançamento de produto (maior componente) |
| `comp_edicaodoproduto` | ~1862 | Edição de produto com multi-campo |
| `comp_modal_work` | ~470 | Modal de rede/work |
| `comp_nav_bar` | ~381 | Barra de navegação inferior |
| `comp_card_ean_gtin` | ~189 | Card de código EAN/GTIN |
| `comp_arraste_foto` | ~142 | Upload de foto via arraste |

### Componentes Gerais (`/compgeral/`)
| Componente | Descrição |
|------------|-----------|
| `comp_camera_or_gallery` | Seletor câmera/galeria |
| `comp_camera_or_galleryorfile` | Seletor câmera/galeria/arquivo |
| `comp_card_confirm_cnpj` | Confirmação de CNPJ |
| `comp_carregando_alteracao_senha` | Loading de troca de senha |
| `comp_carregando_botao_verificacao` | Loading de verificação |
| `comp_carregando_upload_midia` | Loading de upload |
| `comp_conta_criada_com_sucesso` | Sucesso no cadastro |
| `comp_continuar_conectado` | "Manter conectado" |
| `comp_ean_gtin` | Exibição de EAN/GTIN |
| `comp_erro_connection` | Erro de conexão |
| `comp_pw_confirm_email` | Confirmação de e-mail |
| `comp_photo_picker` | Seletor de foto |
| `comp_preservar_login` | Preservar sessão |

### Componentes por Feature (em subpastas de `p_a_s_tpag_app_feed/`)
- **categorycomp/**: 9 componentes (add, edit, inactive, skeleton, modais)
- **r_e_d_es_c_o_m_p/**: 4 componentes (add, camera, skeleton, modal card)
- **regioncomp/**: 9 componentes (add, edit, inactive, skeleton, show info)
- **p_d_vs_c_o_m_p/**: 6 componentes (filtrar, inactive, list, skeleton, modal edit)

---

## 7. Padrões de UI Identificados

### Tipografia
- **Fonte primária:** Poppins (Medium, Regular)
- **Fonte secundária:** Roboto (Medium, Regular)
- **Fonte auxiliar:** Ubuntu (Regular)
- **Fontes de ícones customizados:** `icones.ttf`, `iconesRH.ttf`, `MyFlutterApp.ttf`

### Animações
- Lottie para loading states (múltiplos: azul, insider, remix)
- Lottie para feedback de sucesso
- `flutter_animate` para transições de UI

### Padrões Visuais
- Bottom navigation bar presente em telas principais
- Modais para operações de adição/edição (padrão recorrente)
- Skeleton loading em todas as listagens
- Estado "empty" específico por lista (ex: `comp_list_empty_pdv`)
- Cards como padrão de exibição de entidades
- Indicador de progresso em formulários multi-etapa

### Indicadores Visuais de Estado
- `percent_indicator` para barras de progresso
- `photo_view` para visualização de imagens
- Telas de erro específicas para offline
- Estados de carregamento por tipo de operação

---

## 8. Padrões Técnicos

### Padrões de Arquitetura (FlutterFlow)
- **State Management:** `FFAppState` (ChangeNotifier + SharedPreferences) + Provider
- **Routing:** GoRouter com rotas nomeadas e parâmetros
- **Auth:** Stream-based auth com `BaseAuthUser` + `SupabaseUserProvider`
- **Modelo de componente:** sempre par `*_widget.dart` + `*_model.dart`

### Padrões de Código (FlutterFlow Export)
- Nomes de arquivos e variáveis com padrão de abreviação em maiúsculas (ex: `d_ta_p_i_c_i_t_y_e_s_struct.dart`, `pag2_m_e_n_u_p_d_v_s/`)
- Structs gerados automaticamente para cada resposta de API
- `custom_functions.dart` monolítico (~950 linhas) concentrando todas as funções utilitárias
- `nav.dart` monolítico (~20KB) concentrando toda a configuração de rotas

### Problemas Recorrentes Observados
- Nomes ilegíveis por todo o codebase (herança do FlutterFlow)
- Componentes enormes (2435 e 1862 linhas) que misturam UI e lógica
- Arquivos `custom_functions.dart` e `nav.dart` excessivamente grandes
- Ausência de separação clara entre camadas (UI/lógica/dados)
- Estado global (`FFAppState`) usado para tudo, incluindo dados de domínio

### Backend / Dados
- 28 tabelas Supabase mapeadas em arquivos individuais
- 4 views materializadas para contextos de onboarding e sessão
- Structs duplicados para resposta de API vs. dados de formulário
- Firebase usado apenas para analytics/performance (não é o banco principal)

### Custom Code
- 40 custom actions bem isolados e com responsabilidade única
- 1 custom widget (`network_dropdown`)
- Boa separação das actions: validação, autenticação, dados geográficos, mídia, utilitários

---

## 9. Observações Gerais

### O que aparenta ser estável
- Esquema de banco de dados Supabase (bem estruturado, com views)
- Custom actions (código isolado, focado, reaproveitável)
- Fluxo de onboarding (multi-etapa com regras claras)
- Regras de negócio de validação (CPF, CNPJ, e-mail, senha)
- Separação por módulo em pastas (mesmo com nomes ruins)

### O que aparenta ser problemático
- Nomenclatura ilegível em todo o projeto (prioridade alta na reconstrução)
- Componentes monolíticos (`comp_lancamentodeproduto` com 2435 linhas)
- `custom_functions.dart` e `nav.dart` como arquivos "deus"
- `FFAppState` sendo usado como repositório de dados de domínio
- Ausência de camada de serviço clara — lógica misturada com UI

### O que parece crítico para reconstrução futura
- **Fluxo de onboarding de agência:** complexo, multi-etapa, com regras de negócio implícitas
- **Módulo de PDVs:** cadastro com validação de CNPJ e integração com dados externos
- **Sistema de regiões e cidades:** conflitos, bulk insert, lógica de sobreposição de cidades
- **Autenticação:** fluxo customizado (email + Google + Apple + verificação manual)
- **Lançamento e edição de produto:** os maiores componentes do sistema

---

## 10. Backlog de Análise Futura

> Seções a aprofundar em próximas iterações

- [ ] Ler `flutter_flow_theme.dart` → extrair paleta de cores e tokens de design
- [ ] Ler `nav.dart` → mapear guards de rota e lógica de redirecionamento
- [ ] Ler `app_state.dart` → inventário completo de estado global
- [ ] Ler `custom_functions.dart` → catalogar funções por categoria
- [ ] Ler `comp_lancamentodeproduto_widget.dart` → mapear fluxo de lançamento
- [ ] Ler `comp_edicaodoproduto_widget.dart` → mapear fluxo de edição
- [ ] Analisar structs → identificar modelo de dados real do domínio
- [ ] Analisar `enums.dart` → catalogar enums de negócio
