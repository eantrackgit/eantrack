# UX_GUIDELINES.md — EANTrack

> Decisões de experiência do usuário. Complementa GLOBAL_PATTERNS.md (que define implementação) com o raciocínio por trás das escolhas.

---

## 1. Filosofia central

Feedback deve ser:

- **Claro** — o usuário entende o que aconteceu sem ler duas vezes
- **Direto** — sem jargão técnico, sem código de erro, sem "tente novamente" sem motivo
- **Acionável** — se algo deu errado, o usuário sabe o que fazer

Referência de tom: Google Material Design — simples, humano, sem tecnicismo.

---

## 2. Loading — regra global

| Contexto | Padrão | Proibido |
|---|---|---|
| Submit de formulário | Spinner dentro do botão | Overlay de tela inteira |
| Ação pontual (salvar, excluir) | Spinner no botão da ação | Tela bloqueada |
| Carregamento de lista | Skeleton / shimmer | Spinner centralizado |
| Busca inline (debounce) | Texto "Verificando..." ou spinner 14px | Nada (silêncio) |

**Regra:** loading global (overlay, spinner de tela inteira) é proibido no fluxo de auth e em ações pontuais. O usuário sempre sabe exatamente qual ação está em andamento.

**Por quê:** overlay bloqueia toda a tela para uma ação que afeta apenas um botão. É desproporcional e desorientador.

---

## 3. Feedback de sucesso

### Ações de formulário com consequência (ex: trocar senha, salvar dados)

Usar feedback inline na própria tela: banner verde + mensagem + redirecionamento automático após delay curto (800ms).

```
✓ Senha alterada! Redirecionando...
```

### Ações rápidas sem mudança de contexto (ex: copiar link, favoritar)

SnackBar com duração curta (2–3s).

### Ações críticas que encerram um fluxo (ex: cadastro concluído, pagamento aprovado)

Modal centralizado com CTA clara.

---

## 4. Feedback de erro

### Erros de formulário

Inline, abaixo do campo ou via `AppErrorBox` antes do botão de submit.

Nunca usar SnackBar para erro de validação — o usuário precisa ver o erro enquanto corrige o campo.

### Erros de autenticação (credenciais, sessão expirada)

`AppErrorBox` inline na tela de auth. Mensagem em PT-BR, sem código HTTP.

```
// CORRETO
"E-mail ou senha incorretos."
"Sua sessão expirou. Faça login novamente."

// ERRADO
"AuthException: invalid_credentials (401)"
"Erro de autenticação. Tente novamente."  ← genérico demais
```

### Erros de regra de negócio (ex: senha reutilizada, email em uso)

`AppErrorBox` inline com mensagem específica da regra.

```
"A nova senha deve ser diferente da atual."
"Você já usou essa senha antes. Escolha uma diferente."
"Este e-mail já está em uso."
```

### Erros de servidor / rede

`AppErrorBox` inline com mensagem genérica amigável:

```
"Não foi possível completar essa ação. Verifique sua conexão e tente novamente."
```

---

## 5. Navegação substitui loading quando possível

Se uma ação bem-sucedida leva naturalmente para outra tela, navegar é o feedback de sucesso. Não mostrar banner verde E depois navegar — escolher um.

```
// Exemplo: login bem-sucedido
// NÃO: mostrar "Login efetuado!" por 2s e depois redirecionar
// SIM: redirecionar diretamente — o usuário já está na tela seguinte
```

Exceção: quando a transição é ambígua (ex: a mesma tela pode indicar sucesso ou erro), um estado intermediário de sucesso com redirecionamento automático é aceitável.

---

## 6. Mensagens de erro — tom e estrutura

| Tipo | Tom | Exemplo |
|---|---|---|
| Validação | Instrucional | "Informe um e-mail válido." |
| Regra de negócio | Explicativo | "Você já usou essa senha antes. Escolha uma diferente." |
| Autenticação | Neutro, sem culpa | "E-mail ou senha incorretos." |
| Servidor/rede | Empático | "Não foi possível conectar. Verifique sua internet." |
| Limite de tentativas | Informativo | "Muitas tentativas. Aguarde alguns minutos." |

**Nunca:**
- Expor código HTTP ("Erro 422")
- Expor mensagem raw do Supabase
- Usar "Erro inesperado" sem fallback explicativo
- Culpar o usuário ("Você errou a senha")

---

## 7. Consistência entre fluxos de auth

Todos os fluxos de auth (login, registro, recovery, update password) usam `AuthScaffold` como base. Garantias:

- Logo no topo em todos os fluxos
- Mesma estrutura de card centralizado
- `AppErrorBox` sempre acima do botão primary
- Loading sempre no botão primary, nunca overlay
- Estados: idle → loading → success/error, nunca pular

---

## 8. Links expirados e estados de erro de navegação

Links de recovery/verificação expirados não devem gerar erro genérico de rota ("Page Not Found").

O GoRouter detecta parâmetros de erro na URL (`error=access_denied`, `error_code=otp_expired`) e redireciona para tela amigável com explicação e CTA para nova ação.

**Referência:** app_router.dart — bloco de detecção de erro no topo do redirect.

---

## 9. Referências complementares

| Documento | Conteúdo |
|---|---|
| GLOBAL_PATTERNS.md seção 8 | Implementação de loading (botão, overlay, skeleton) |
| GLOBAL_PATTERNS.md seção 9 | Implementação de SnackBar (quando usar, variantes) |
| DESIGN_SYSTEM.md | Tokens de cor, tipografia, espaçamento |
| COMPONENT_LIBRARY.md | AppErrorBox, AppButton, AppTextField |
