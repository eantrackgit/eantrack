# Release Candidate 9.7 — Sign-off de Produção

> Registro de verificação final antes da entrada em produção limitada.
> Data: 2026-06-20. Branch: `main`.
> Este documento é o **registro de go/no-go**. Não substitui o snapshot de auditoria
> (`docs/audits/project_review_current_state.md`), que é histórico e não deve ser reescrito.

---

## Resumo

Auditoria final executada sobre os fluxos já implementados (auth, onboarding, hub, mobile,
desktop, deploy). **Nenhum problema crítico ou alto em aberto.** Todos os bugs listados no
checklist de RC já haviam sido corrigidos em commits anteriores; esta rodada **verificou** o
estado e confirmou a coerência, sem necessidade de novas correções de código.

Escopo desta task foi de verificação e documentação — **não** foram iniciados módulos novos
(Regiões, PDVs, visitas, tarefas, offline-first permanecem fora de escopo, como planejado).

---

## Verificação por área

### 1. Auth / Rotas / Flow ✅
- **Fonte única de redirect:** `_redirect` em `app_router.dart` (AUDIT-FIX-002 — `RouterRedirectGuard.redirect()` morto foi removido; a classe permanece só como `refreshListenable`).
- **Erro real não vira onboarding:** `getUserFlowState` (AUDIT-FIX-001) propaga `AppException` em falha real; `null` significa apenas "sem contexto". Erro real → `AuthError` → fallback seguro.
- `/flow` sem sessão → login; com sessão e contexto não confirmado → revalida 1x → `AuthFallbackScreen`. Timer de segurança de 10s evita loading infinito.
- Rotas protegidas (`AppRoutes.protectedRoutes`) com guarda no `_redirect`. `/hub/validity` é **público por design** (botão "Testar Validade" no login) — não é regressão.

### 2. Google OAuth / Link expirado ✅
- `RecoveryLinkParser.hasExpiredParams` **não** dispara em `error=access_denied` puro (código OAuth2 genérico de login cancelado/negado); só conta como link expirado com `type=recovery`, `error_code=otp_expired` ou descrição explícita de expiração.
- Cobre: Google cancelado, Google concluído, back do navegador após Google, recovery expirado real, recovery válido, LinkExpired → login. A flag `_expiredLinkJustified` reinicia a cada load, então histórico/URL manual não reabrem a tela indevidamente.

### 3. Remember Me / Lembrar-me ✅
- Banco salva **apenas** `keep_connected`; e-mail/displayName ficam em cache local (UX, nunca credenciais).
- Logout com `keep_connected = true` preserva o cache; com `false` limpa. "Trocar" limpa só o local, sem tocar o banco. Card de conta salva + iniciais/avatar funcionam. Doc `docs/architecture/remember_me.md` coerente.

### 4. CNPJ / Onboarding ✅
- Copy de saída contextual na etapa CNPJ: "Sair da consulta de CNPJ?" + texto sobre dados não concluídos + "Continuar nesta tela" / "Voltar para o login".
- Botão "Consultar CNPJ" oculto após sucesso (card de preview com X → reaparece ao fechar). Campo CNPJ editável; "Avançar" só com `canAdvance`. Erros/"não encontrado" preservados.

### 5. Foto de perfil ✅
- Typo "fto" → **"foto"** (já corrigido). Foto é opcional; erro nunca prende o usuário ("Pular por enquanto" em ambos os ramos; "Pular" chama `_finishFlow`).
- Diagnóstico mínimo distinto via `AppException`: sem sessão (`NotAuthenticatedException`), arquivo inválido (`InvalidFileException`), muito grande (`FileTooLargeException`), bucket ausente/permissão/upload (`StorageBucketMissing`/`StoragePermissionDenied`/`UploadFailed`), update de perfil (`ProfileUpdateFailedException`), desconhecido (`NetworkException`).

### 6. Mobile ✅
- Drawer mobile (corpo único reaproveitado do sidebar desktop) com barra de perfil + fallbacks de nome/agência/cargo. Navbar inferior com BEEP, notch raso, `SafeArea`, `FittedBox` contra overflow.
- **Ícones em build release:** uso deliberado de Material Icons clássicos (codepoints baixos: `Icons.home`, `Icons.qr_code`) em vez de variantes `_rounded`/`_outlined` (codepoints altos que falham no tree-shaking do web). Nenhum `IconData(` dinâmico no projeto. Documentado em `app_bottom_nav.dart`.

### 7. Desktop / Web ✅
- Sidebar/hub desktop preservados; modais centralizados; dark/light em todas as telas-chave. Nenhuma mudança mobile vazou para desktop.

### 8. Deploy / Cache / Hostinger ✅
- Estratégia já madura e correta: `--pwa-strategy=none`, shell com `no-store`, bootstrap limpa SW/cache legado com 1 reload. `version.json` presente; `deploy/operational.htaccess` e scripts de build/deploy existentes.
- **Atenção (procedimento de deploy limpo):** seguir `docs/deploy/DEPLOY_GUARDRAILS.md`. Em particular, **nunca** rodar `flutter build web` direto — usar `scripts/build_operational_web.{sh,bat}`, que injeta `--dart-define=APP_ORIGIN` (sem ele os links de recovery vão para `localhost` em produção). Atualizar `version.json` antes de cada build. Validar pós-deploy em aba anônima / hard refresh.

### 9. Documentação viva ✅
- `PROJECT_MAP.md`, `CURRENT_STATE.md`, `BACKEND_SCHEMA.md` reconciliados (Hub dark/light + dados reais, legado removido, testes de Regiões, RPC `get_agency_status_full` documentada, fonte real do gate). `remember_me.md` coerente. Snapshot de auditoria mantido como histórico.

---

## Notas por categoria

| Categoria | Nota | Observação |
|-----------|:----:|-----------|
| Auth | 9.7 | Fonte única de redirect, erro real propagado, fallback seguro, OAuth/link expirado separados. |
| Onboarding | 9.5 | CNPJ/foto/representante coerentes; copy contextual; sem aprisionamento. |
| Mobile | 9.5 | Drawer/navbar/BEEP sólidos; ícones seguros em release. |
| Desktop | 9.5 | Shell preservado, modais centralizados, dark/light. |
| Deploy | 9.5 | SW off, no-store no shell, guardrails documentados; ponto de atenção: usar script oficial. |
| Docs | 9.3 | Vivos reconciliados; snapshot histórico preservado. |
| Segurança | 8.0 | Sem `service_role` no client; RLS ainda a auditar no servidor antes de escala; colisão Google pendente (não bloqueia demo/produção limitada). |
| Escalabilidade | 7.0 | Leituras limitadas; não comprovada para 100k (sem load test / offline). Fora do escopo de produção limitada. |
| Produto | 6.0 | Fundação pronta; valor operacional (Regiões/PDVs/visitas) ainda não iniciado — próximo passo. |

## Nota geral (fluxos implementados)

**9.4** — os fluxos existentes (auth, onboarding, hub, mobile, desktop, deploy) estão em
estado RC 9.7 nos itens de auth; a média geral é puxada por segurança/escala/produto, que
dependem de trabalho futuro fora do escopo de produção limitada.

---

## Veredito

**Pronto para produção limitada / demo real.**

Critérios atendidos: sem crítico, sem alto em aberto, rotas/auth previsíveis, usuário nunca
preso, fallback seguro em produção, fluxos existentes coerentes, docs vivos alinhados, git
limpo, módulos não iniciados claramente fora de escopo.

Condições conhecidas (não bloqueantes para produção limitada, recomendadas antes de escala):
auditoria de RLS no Supabase; tratamento de colisão de conta no Google Auth; entrega do
primeiro módulo operacional (Regiões — próxima task).
