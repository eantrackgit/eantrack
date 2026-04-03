# DEFINITION_OF_DONE.md — EANTrack

> Checklist obrigatório. Uma tela/feature só está PRONTA quando todos os items aplicáveis estão marcados.
> Usar como validação final antes de considerar qualquer task completa.

---

## CHECKLIST GERAL (aplica a TODA entrega)

### UI — Fidelidade visual
- [ ] Layout conforme SCREEN_SPECS.md (ordem dos elementos, hierarquia)
- [ ] Cores exclusivamente de AppColors (nenhum hex inline)
- [ ] Tipografia exclusivamente de AppTextStyles (nenhum TextStyle inline)
- [ ] Espaçamentos de AppSpacing (nenhum valor numérico solto)
- [ ] Radius de AppRadius (AppRadius.sm, AppRadius.md, AppRadius.lg)
- [ ] Ícones exclusivamente Material Icons (nenhum CupertinoIcons)
- [ ] Card auth: max-width 420px (480 para onboarding), centralizado, bg branco
- [ ] Card internal: bg bgCardDark, border borderCard

### Responsividade
- [ ] Mobile (< 600px): layout full-width, sem overflow
- [ ] Tablet (600-1200px): card centralizado ou sidebar colapsável
- [ ] Desktop (> 1200px): card centralizado ou sidebar fixa
- [ ] Testado no Chrome com viewport 375px (iPhone SE)
- [ ] Testado no Chrome com viewport 1440px (desktop)
- [ ] Nenhuma largura fixa sem fallback responsivo

### Estados obrigatórios
- [ ] Loading: spinner visível (botão ou overlay conforme contexto)
- [ ] Disabled: opacity 0.5, onPressed null, cursor default
- [ ] Error: mensagem PT-BR user-friendly, ErrorBanner ou validator message
- [ ] Empty (se lista): AppEmptyState com ícone + texto + CTA
- [ ] Success (se ação): feedback visual (snackbar ou redirect)

### Formulários (se aplicável)
- [ ] `bool _submitted = false;` declarado no State
- [ ] Form SEM `autovalidateMode` (usar default disabled)
- [ ] Cada validator com `if (!_submitted) return null;` no início
- [ ] Submit handler: `setState(() => _submitted = true)` ANTES de `validate()`
- [ ] Mensagens de erro em português, concisas (max 1 linha)
- [ ] Feedback positivo em tempo real separado da validação (se aplicável)
- [ ] Botão submit com loading interno durante operação

### Animações / Microinterações
- [ ] Botões: pressed feedback (scale 0.97, 100ms) — ou aceitar Flutter default
- [ ] Inputs: focus transition nativa do Flutter (OK por padrão)
- [ ] Erros: aparecem com fade (OK por padrão com Form)
- [ ] Nenhuma animação bounce, shake ou exagerada
- [ ] Nenhuma animação > 500ms (exceto Lottie checkmark aprovado)
- [ ] Transição entre telas: fade padrão GoRouter

### Código
- [ ] Arquivo ≤ 200 linhas (se maior, quebrar em widgets privados `_NomeParte` no mesmo arquivo)
- [ ] Sem lógica de negócio no build()
- [ ] Sem chamada Supabase direta no widget (vai no repository)
- [ ] Sem `setState()` para estado que afeta múltiplos widgets (usar notifier)
- [ ] Imports organizados (dart → flutter → packages → project)
- [ ] Nenhum import não utilizado
- [ ] Nenhum `print()` em produção (usar `debugPrint()` se necessário)
- [ ] Nomenclatura conforme GLOBAL_PATTERNS.md seção 10

### Navegação
- [ ] Rotas usando AppRoutes (constantes), nenhum path literal
- [ ] Redirect guards funcionando (não acessar tela protegida sem auth)
- [ ] Botão voltar funcional (context.go ou context.pop)

---

## CHECKLIST ESPECÍFICO: TELA AUTH

### Login
- [ ] Logo + "Smart Tracking" no topo
- [ ] 2 campos: Email + Senha (com eye toggle)
- [ ] Botão "Entrar" (primary, loading interno)
- [ ] Divider "ou" + Botão Google (vermelho, UI only)
- [ ] Link "Esqueceu sua senha?" → /recover-password
- [ ] Botão "Criar conta" (outlined) → /register
- [ ] Biometria (ícone + texto, UI only)
- [ ] Ícone suporte (headset, canto superior direito)
- [ ] Validação apenas no submit
- [ ] Erro de auth: ErrorBanner visível

### Register
- [ ] TabBar (Informações ativa, demais placeholder)
- [ ] 4 campos: Nome, Email, Senha, Confirmar senha
- [ ] Checklist de força de senha (tempo real, 3 items)
- [ ] Email debounce check (800ms, "Verificando..." → resultado)
- [ ] Botões: Cancelar + Avançar
- [ ] Validação apenas no submit
- [ ] Loading no botão Avançar

### Email Verification
- [ ] Título dinâmico: "Confirme sua conta" / "Conta Confirmada!"
- [ ] Polling 3s silencioso (ativo, sem UI feedback)
- [ ] Botão "Já confirmei" (com spinner quando checking)
- [ ] Botão/link "Reenviar" (com cooldown 5min + barra progresso)
- [ ] Controle de tentativas (max 3 reenvios)
- [ ] Lottie checkmark quando confirmado
- [ ] Redirect automático para /onboarding após confirmação

### Recover Password
- [ ] Campo email + botão Enviar
- [ ] Validação apenas no submit
- [ ] Sucesso: banner verde "Link enviado"
- [ ] Link voltar ao login

---

## CHECKLIST ESPECÍFICO: TELA ONBOARDING

### Choose Mode
- [ ] 2 cards: Individual + Agência
- [ ] Apenas 1 selecionável por vez
- [ ] Card selecionado: borda verde + bg success 5%
- [ ] "Avançar" disabled até selecionar
- [ ] "Voltar" funcional

### CNPJ (modo Agência)
- [ ] Campo CNPJ com máscara (XX.XXX.XXX/XXXX-XX)
- [ ] Botão "Consultar CNPJ"
- [ ] Status messages coloridas
- [ ] Checkbox aceite
- [ ] Validação de formato CNPJ

### Company Data
- [ ] Campos preenchidos (vindos do step anterior)
- [ ] Campos editáveis ou readonly conforme spec
- [ ] Navegação voltar/avançar

### Legal Representative
- [ ] Campos: CPF, RG, Nascimento, Órgão
- [ ] Upload docs (placeholder)
- [ ] Checkbox termos
- [ ] Navegação voltar/avançar

---

## CHECKLIST ESPECÍFICO: TELA INTERNA (CRUD)

### List Screen (Regions, Networks, PDVs, Categories)
- [ ] Header com título + botão "+"
- [ ] TabBar: Todos | Ativos | Inativos
- [ ] SearchBar funcional (filtro local ou RPC)
- [ ] Lista de cards com dados relevantes
- [ ] Empty state com orientação e CTA
- [ ] Loading skeleton ou shimmer durante fetch
- [ ] Pull to refresh (se mobile)

### Create/Edit Dialog/Screen
- [ ] Formulário com validação _submitted
- [ ] Verificação de nome duplicado (RPC, se aplicável)
- [ ] Botões: Cancelar + Salvar
- [ ] Loading no botão Salvar
- [ ] Sucesso: snackbar + fechar dialog / voltar
- [ ] Erro: ErrorBanner inline

### Detail Screen
- [ ] Dados carregados via provider
- [ ] Loading/Error/Empty states tratados
- [ ] Ações: Editar, Desativar/Ativar (se aplicável)
- [ ] Confirmação para ações destrutivas

---

## TESTE MANUAL (OBRIGATÓRIO)

### Fluxo completo
- [ ] Abrir no Chrome (`flutter run -d chrome`)
- [ ] Testar com viewport mobile (375px) E desktop (1440px)
- [ ] Navegar por todo o fluxo da feature (início → fim)
- [ ] Testar happy path (tudo correto)
- [ ] Testar sad path (campos vazios → submit → erros)

### Edge cases
- [ ] Duplo clique no botão de submit (não deve disparar 2x)
- [ ] Campos com espaços em branco (trim)
- [ ] Input muito longo (>200 chars) — não quebra layout
- [ ] Voltar e avançar repetidamente (estado mantido)
- [ ] Refresh da página (session persistida, não perde contexto)

### Resultado final
- [ ] Nenhum overflow visual
- [ ] Nenhum erro no console do Chrome (exceto warnings esperados)
- [ ] Nenhum texto cortado ou ilegível
- [ ] Tudo em português (mensagens, labels, botões)

---

## QUANDO USAR ESTE CHECKLIST

1. **Codex terminou uma task** → revisar items aplicáveis antes de aceitar
2. **Claude gerou uma CODEX_TASK** → referenciar este doc como critério de pronto
3. **Revisão de sprint** → usar como benchmark de qualidade
4. **Dúvida sobre "está pronto?"** → se algum item aplicável está desmarcado, NÃO está pronto

---

## NOTA FINAL

Nem todos os items se aplicam a toda task. Uma task que cria apenas um widget shared não precisa dos items de formulário. Use bom senso — mas na dúvida, marque como aplicável e verifique.
