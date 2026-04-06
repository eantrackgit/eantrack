# DEPLOY_GUARDRAILS.md — EANTrack

> Regras obrigatórias para todo deploy web. Sem exceções.
> Detalhes técnicos da estratégia de cache: ver docs/web/cache_and_deploy_strategy.md

---

## Checklist pré-deploy

```
[ ] 1. Atualizar assets/config/version.json
[ ] 2. Usar o script oficial de build
[ ] 3. Confirmar que .htaccess foi copiado para build/web/
[ ] 4. Publicar todo o conteúdo de build/web/
[ ] 5. Confirmar que CDN/proxy não sobrescreve headers de cache
```

---

## 1. Sempre usar o script oficial

```bash
# Windows
scripts\build_operational_web.bat

# Linux/Mac
scripts/build_operational_web.sh
```

**Nunca usar `flutter build web` diretamente.**

O script inclui obrigatoriamente:

```
--dart-define=SUPABASE_URL=...
--dart-define=SUPABASE_ANON_KEY=...
--dart-define=APP_ORIGIN=...
--pwa-strategy=none
--release
```

**Por quê `APP_ORIGIN` é crítico:** sem ele, os links de recovery de senha redirecionam para `localhost` em produção — o fluxo de reset quebra completamente.

---

## 2. Sempre atualizar version.json antes do build

Arquivo: `assets/config/version.json`

```json
{ "version": "1.0.1" }
```

Regra semântica:
- `patch` (1.0.0 → 1.0.1): bugfix, ajuste visual
- `minor` (1.0.0 → 1.1.0): nova feature
- `major` (1.0.0 → 2.0.0): quebra de compatibilidade ou redesign

**Referência:** docs/engineering/app_versioning.md

---

## 3. Cache — arquivos críticos nunca podem ficar em cache forte

Os arquivos abaixo devem ter `Cache-Control: no-store`:

- `index.html`
- `flutter_bootstrap.js`
- `flutter.js`
- `main.dart.js`
- `manifest.json`
- `version.json`

Configuração no `deploy/operational.htaccess` — já implementado.

**Por quê:** esses arquivos não têm hash no nome. Se ficarem em cache após deploy, o usuário continua rodando a build antiga indefinidamente.

---

## 4. Service worker desabilitado

```
--pwa-strategy=none
```

O build operacional **nunca** registra service worker.

**Por quê:** service worker com cache agressivo impede que novos deploys sejam percebidos pelo usuário. Para este app, atualização confiável tem prioridade sobre offline caching.

O bootstrap (`web/flutter_bootstrap.js`) detecta e remove automaticamente qualquer service worker legado que ainda possa existir de builds anteriores.

---

## 5. Bootstrap limpa legado automaticamente

O `flutter_bootstrap.js` executa no carregamento:

1. Detecta service workers registrados pelo Flutter/Workbox
2. Desregistra todos
3. Remove caches legados
4. Se removeu algo → faz um reload automático (apenas uma vez)

**Resultado:** usuário que ficou preso em build antiga migra automaticamente no próximo acesso, sem precisar limpar cache manualmente.

---

## 6. O que nunca fazer

- Nunca aplicar cache longo em `index.html` ou `main.dart.js`
- Nunca reativar service worker/PWA sem revisar a política de update
- Nunca rodar `flutter build web` manualmente sem os `dart-define`
- Nunca depender de "o usuário limpa o cache" como procedimento de deploy
- Nunca fazer build sem atualizar `version.json`

---

## Referências

| Documento | Conteúdo |
|---|---|
| docs/web/cache_and_deploy_strategy.md | Diagnóstico e estratégia detalhada de cache |
| docs/engineering/app_versioning.md | Formato e regras de versionamento |
| scripts/build_operational_web.bat | Script de build (Windows) |
| scripts/build_operational_web.sh | Script de build (Linux/Mac) |
| deploy/operational.htaccess | Configuração de cache para o servidor |
