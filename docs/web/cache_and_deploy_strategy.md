# Web Cache And Deploy Strategy

## Objetivo

Garantir que um novo deploy do Flutter Web seja percebido pelos usuarios sem:

- limpar cache manualmente
- limpar site data
- desinstalar PWA
- usar hard reload

Prioridade: previsibilidade de atualizacao acima de cache offline agressivo.

## Diagnostico do problema anterior

- `web/index.html` tinha duplicidade de `manifest.json`, incluindo uma referencia absoluta (`/manifest.json`) que pode apontar para o lugar errado fora da pasta do app.
- `deploy/operational.htaccess` fazia cache longo por tipo de arquivo. Isso prendia arquivos criticos como `main.dart.js`, `flutter.js` e `manifest.json`, todos sem hash no nome.
- O projeto nao tinha uma limpeza explicita de service workers/caches legados no bootstrap. Usuarios que ja passaram por builds antigas podiam continuar com artefatos locais interferindo no carregamento.
- Os scripts de build nao declaravam explicitamente `--pwa-strategy=none`, deixando a estrategia de SW dependente do comportamento padrao do Flutter.

## Estrategia adotada

### 1. Shell principal sempre fresco

Arquivos abaixo sao entregues com:

`Cache-Control: no-store, no-cache, must-revalidate, max-age=0`

Arquivos:

- `index.html`
- `flutter_bootstrap.js`
- `flutter.js`
- `main.dart.js`
- `manifest.json`
- `version.json`
- `flutter_service_worker.js`

Motivo: esses arquivos controlam qual build o navegador vai iniciar. Como nao usam hash no nome, nao podem ficar presos em cache forte.

### 2. Restante do runtime sempre revalidado

Arquivos como imagens, fontes, JSON, WASM e demais JS/CSS passam a usar:

`Cache-Control: public, max-age=0, must-revalidate`

Motivo: o navegador pode reaproveitar copia local, mas precisa revalidar com o servidor antes de usar. Isso evita que assets sem hash sobrevivam a um deploy novo.

### 3. Service worker desabilitado como estrategia de produto

O build operacional agora usa:

`flutter build web --release --pwa-strategy=none`

Decisao: para este app, atualizacao confiavel tem prioridade sobre cache offline agressivo.

### 4. Limpeza automatica de legado

No bootstrap web:

- qualquer service worker legado do Flutter que ainda controle a pagina e desregistrado
- caches legados do Flutter/Workbox sao removidos
- se algo legado foi removido, a pagina faz um reload normal automatico uma vez

Resultado pratico: usuarios que ficaram com resquicio de versoes antigas sao migrados para o fluxo sem SW sem precisar limpar cache manualmente.

## Como fica o comportamento apos deploy

1. O usuario abre ou recarrega a aplicacao.
2. `index.html` e os arquivos de shell sao buscados novamente no servidor.
3. Se existir service worker/cache legado, o bootstrap remove isso e faz um reload normal automatico.
4. No reload seguinte, a pagina sobe com a build nova.

Meta operacional: no maximo um reload normal da aplicacao para cair na nova versao.

## Arquivos alterados nesta estrategia

- `web/index.html`
- `web/flutter_bootstrap.js`
- `deploy/operational.htaccess`
- `scripts/build_operational_web.sh`
- `scripts/build_operational_web.bat`

## Checklist de deploy futuro

1. Gerar build usando `scripts/build_operational_web.sh` ou `scripts/build_operational_web.bat`.
2. Confirmar que `build/web/.htaccess` foi copiado do `deploy/operational.htaccess`.
3. Publicar todo o conteudo de `build/web`.
4. Garantir que CDN/proxy/reverse proxy nao sobrescreva os headers definidos no `.htaccess`.
5. Nao reativar service worker/PWA offline sem revisar novamente a politica de update.

## O que nao fazer

- nao aplicar cache longo em `index.html`
- nao aplicar cache longo em `main.dart.js` ou `flutter.js`
- nao reintroduzir registro de service worker no bootstrap
- nao depender de clear cache manual como procedimento de deploy
