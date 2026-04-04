# Deploy Flutter Web - Operational

## Pre-requisitos

- `fvm` instalado
- `ssh` e `scp` disponiveis na maquina
- variaveis `SUPABASE_URL` e `SUPABASE_ANON_KEY`
- variaveis `HOSTINGER_USER` e `HOSTINGER_HOST`
- opcional: `HOSTINGER_PORT` se a SSH da Hostinger nao usar a porta padrao

## Build

Windows:

```bat
scripts\build_operational_web.bat
```

macOS / Linux:

```bash
./scripts/build_operational_web.sh
```

## Deploy

Windows:

```bat
scripts\deploy_operational_web.bat
```

macOS / Linux:

```bash
./scripts/deploy_operational_web.sh
```

## Destino no servidor

Subir o conteudo de `build/web` para:

```text
/home/u165659716/domains/eantrack.com/public_html/operational
```

## URL de recovery por ambiente

- dev: `http://localhost:55368/#/update-password`
- production: `https://operational.eantrack.com/#/update-password`

## Checklist final

- build concluido sem erro
- `build/web/.htaccess` presente
- arquivos enviados para `/home/u165659716/domains/eantrack.com/public_html/operational`
- `https://operational.eantrack.com` abre o app
- refresh nao quebra a aplicacao
- recovery envia link com `redirect_to=https://operational.eantrack.com/#/update-password`
