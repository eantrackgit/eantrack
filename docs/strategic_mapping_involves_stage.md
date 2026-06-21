# Mapeamento Estratégico — EANTrack × Involves Stage

> Referência visual: capturas do Involves Stage (Seara Loja · 25/05/2026)
> Objetivo: registro fiel do que foi observado na plataforma de referência para orientar o escopo futuro do EANTrack

---

## Nota de Escopo

O EANTrack **não é um clone** do Involves Stage. Este documento é um denominador estratégico: registra o que existe na plataforma de referência para que, no futuro, seja possível decidir conscientemente o que implementar, o que adaptar e o que descartar conforme o posicionamento do produto.

---

## Posicionamento EANTrack vs. Involves Stage

| Dimensão | Involves Stage | EANTrack (intenção) |
|----------|---------------|---------------------|
| Linguagem | Corporativa ("Colaborador superior", "Jornada de Trabalho", "É Temporário?") | Acessível, direta, sem jargão de RH |
| Complexidade | Alta — muitos filtros, hierarquias, ambientes | Simplificada — foco no essencial |
| Público | Grandes empresas de trade marketing | Times menores, promotores independentes, agências menores |
| Curva de aprendizado | Tour de 6 passos obrigatório para entender a UI | Deve ser autoexplicativo sem tour |

---

## Gaps de UX Observados no Involves Stage

Registrados como oportunidades de fazer melhor no EANTrack.

### Gap 1 — Dropdown de filtros sem feedback de seleção

**Tela:** `/colaboradores` → painel de filtros
**O que acontece:** ao abrir o dropdown "Filtros disponíveis" e marcar um item (ex: "Colaborador superior"), o trigger do dropdown continua exibindo o label "Selecione" — sem nenhum indicador visual de que há filtros ativos naquela dimensão.

**Impacto:** o usuário perde a noção do estado atual dos filtros; precisa reabrir o dropdown para lembrar o que selecionou.

**Como EANTrack deve tratar:**
- Trigger atualiza para o nome do filtro selecionado quando há 1 seleção
- Trigger mostra "N filtros" quando há múltiplas seleções
- Chip/badge visível fora do dropdown para cada filtro ativo (com `×` para remover individualmente)
- Estado "limpar tudo" acessível sem precisar entrar em cada dropdown

### Gap 2 — Linguagem corporativa nos filtros

**O que acontece:** os nomes dos filtros e colunas usam terminologia de RH corporativo: "Colaborador superior", "Possui Jornada de Trabalho?", "É Temporário?", "Perfil de Colaborador".

**Como EANTrack deve tratar:** nomear entidades pelo que o usuário já chama no dia a dia — "Supervisor", "Promotor fixo / eventual", "Cargo" — e validar com usuários reais antes de escolher os termos.

---

## 1. Dashboard Operacional (`/dashboard`)

### 1.1 KPI Cards (linha superior)

Quatro cards fixos observados, em ordem:

| # | Card | Valor observado | Breakdown |
|---|------|----------------|-----------|
| 1 | **Visitas do dia** | 81,38% | Justificadas: 0 · Pendentes: 46 · Concluídas: 201 · Total: 247 |
| 2 | **Tarefas do dia** | 0% | Pendentes: 0 · Concluídas: 0 · Total: 0 |
| 3 | **Equipe de campo** | 169 Online / 33 Offline | Dois valores lado a lado no mesmo card |
| 4 | **Colaboradores com roteiro e não logaram** | 5 | "Clique aqui para refinar sua pesquisa" (link de drill-down) |

**Cabeçalho do dashboard:** "Olá, MARCIO JOSE DOS SANTOS" + timestamp "Última atualização em 25/05/2026 às 11:15"

### 1.2 Área de Métricas Customizáveis

Abaixo dos 4 cards fixos existe uma área pontilhada com botão `+`:
> "Clique aqui para adicionar uma nova métrica de acompanhamento"

Indica que o sistema permite adicionar KPIs adicionais configuráveis por usuário/empresa.

---

## 2. Navegação Lateral (Sidebar)

Tour guiado ("Passo 1 de 6") descreve o menu: **"Este é o menu de navegação. Nele você pode acessar todas as funcionalidades do Involves Stage. Utilize Ctrl+K para buscar."**

Ícones observados na sidebar esquerda (top → bottom):
1. Logo / Home
2. Busca global (`Ctrl+K`)
3. Dashboard
4. Roteiros / Mapa
5. Pessoas / Colaboradores
6. Tarefas / Pesquisas
7. Relatórios / Analytics
8. Produtos / PDVs
9. Alertas / Notificações
10. Configurações
11. Avatar do usuário (rodapé)

---

## 3. Onboarding Tour (6 passos)

Tour embutido ativado no primeiro acesso. Referência para implementar tutoriais contextuais no EANTrack.

| Passo | Alvo na UI | Mensagem |
|-------|-----------|---------|
| 1/6 | Menu lateral | "Este é o menu de navegação... Utilize Ctrl+K para buscar." |
| 2/6 | Avatar (rodapé) | "Para alterar as preferências da sua conta, basta clicar no avatar e depois em Perfil." |
| 3/6 | Botão de ajuda (topo) | "Se estiver com alguma dúvida, você pode acessar nossa Central de Ajuda e também, habilitar dicas pontuais durante o uso do Involves Stage." |
| 4/6 | Menu de ambientes | "Caso utilize mais de um ambiente, você pode alterná-los nesse menu." |
| 5/6 | Ícone de chat | "Aqui fica o chat. Através dele você pode interagir com seus colegas de trabalho." |
| 6/6 | Área de métricas | "Ótimo trabalho! Agora você já pode usufruir do Involves Stage na sua rotina. Para mais dicas sobre o produto, visite a Central de Ajuda." · CTA: "Let's rock!" |

---

## 4. Módulo de Colaboradores (`/colaboradores`)

### 4.1 Hierarquia de Tipos

Modal "Cadastrando colaboradores" exibe o diagrama:

```
Colaboradores
├── Equipe de campo
│   ├── Visita PDVs
│   └── Responde pesquisas
└── Backoffice
    ├── Cadastros no sistema
    └── Importação
        └── via tela
```

**Descrição oficial do modal:**
> "O cadastro dos colaboradores no Involves Stage pode ocorrer de duas maneiras: por meio da importação das informações ou de forma manual, recomendado para inserção em pequeno número ou edição de colaboradores já cadastrados. Os colaboradores serão distribuídos em regionais e aqueles que pertencerem à equipe de campo irão receber os roteiros e tarefas."

### 4.2 Filtros Disponíveis

| Filtro | Tipo |
|--------|------|
| Nome do colaborador | texto livre |
| CPF | texto livre |
| Login | texto livre |
| Status | dropdown (Ativo/Inativo) |
| Possui Jornada de Trabalho? | dropdown |
| É Temporário? | dropdown |
| Está em Equipe de Campo? | dropdown |
| Regional | dropdown (0/1 selecionado) |
| Estado | dropdown |
| Cidade | dropdown |

### 4.3 Listagem

- Colunas: Nome do colaborador, E-mail, Status, Está em Equipe de Campo? (Sim/Não)
- Volume observado: **311 registros** · 32 páginas · 10 por página
- Ação no rodapé: botão "Opções" (ações em lote)

---

## 5. Multi-Ambiente

Passo 4/6 do tour menciona a troca de **ambientes** — a plataforma suporta que uma conta acesse múltiplas empresas/workspaces via menu no header. Equivalente a multi-tenant com troca de contexto sem re-login.

---

## 6. Chat Integrado

Passo 5/6 do tour revela um **chat embutido** para comunicação entre membros da equipe dentro da própria plataforma (ícone de flag/bandeira no header direito).

---

## 7. Módulos Inferidos (não capturados diretamente)

Baseado na sidebar e nos dados dos KPI cards:

| Módulo | Evidência |
|--------|-----------|
| Roteiros | Ícone na sidebar + "roteiro" mencionado no módulo de colaboradores |
| Visitas / Check-in | KPI "Visitas do dia" com status detalhado |
| Tarefas / Pesquisas | KPI "Tarefas do dia" + ícone na sidebar + "Responde pesquisas" na hierarquia de colaboradores |
| Relatórios | Ícone na sidebar |
| PDVs / Pontos de Venda | "Visita PDVs" na hierarquia + ícone na sidebar |
| Alertas | Ícone de sino na sidebar |
| Configurações | Ícone de engrenagem na sidebar |
| Regionais | Filtro de regionais no módulo de colaboradores |

---

## 8. Padrões de UX Observados

| Padrão | Descrição |
|--------|-----------|
| Cards KPI com drill-down | Clique no card → filtra lista detalhada |
| Tour contextual (tooltip) | 6 passos step-by-step no primeiro acesso |
| Métricas customizáveis | Grade expansível abaixo dos cards fixos |
| Filtros em painel | Múltiplos filtros expostos antes da listagem, com botão "Pesquisar" |
| Paginação configurável | Usuário escolhe registros por página |
| Import + manual | Cadastro em massa via arquivo OU manual unitário |
| Multi-ambiente | Troca de workspace sem re-login |
| Timestamp de atualização | Header do dashboard mostra última atualização |
| Header com boas-vindas | "Olá, NOME DO USUÁRIO" |

---

## 9. Estado Atual do EANTrack (referência)

| Camada | Status |
|--------|--------|
| Auth completo (login, registro, recuperação, verificação) | ✅ Pronto |
| Onboarding (individual + agência, CNPJ, foto, representante) | ✅ Pronto |
| Hub (shell do dashboard, sidebar, settings dialog) | ✅ Pronto |
| Router (GoRouter, guards, deep links) | ✅ Pronto |
| Tema (dark/light, persistência local + remota) | ✅ Pronto |
| Regions (lista) | ✅ Pronto (básico) |
| Validity (lista) | ✅ Pronto (básico) |
| Visitas / Roteiros | ❌ Não iniciado |
| Tarefas / Checklists | ❌ Não iniciado |
| Dashboard KPIs | ❌ Não iniciado |
| Colaboradores / Equipe | ❌ Não iniciado |
| Relatórios | ❌ Não iniciado |
| PDVs (Pontos de Venda) | ❌ Não iniciado |
| Scanning EAN / Produtos | ❌ Não iniciado |
| Multi-ambiente | ❌ Não iniciado |
| Chat / Comunicação interna | ❌ Não iniciado |
| Tour / Onboarding contextual | ❌ Não iniciado |

---

## 10. Referências

- **Involves Stage (Seara Loja):** plataforma de referência — capturas em 25/05/2026
- **URLs observadas:** `/dashboard`, `/colaboradores`
- **Infra existente EANTrack:** GoRouter, Riverpod, Supabase, Sentry, Barcode Widget, Image Picker, PDF, File Picker, Permission Handler, Shared Preferences
