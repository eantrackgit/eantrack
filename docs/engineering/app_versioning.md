# App Versioning

## Arquivo manual

Edite este arquivo antes do deploy:

`assets/config/version.json`

Formato:

```json
{
  "version": "1.0.0"
}
```

## Regra de uso

- patch: `1.0.0` -> `1.0.1`
- minor: `1.0.0` -> `1.1.0`
- major: `1.0.0` -> `2.0.0`

## Quando alterar

- altere a versao sempre que gerar um novo build que precise ser identificado visualmente
- atualize o arquivo antes de rodar o build/deploy web

## Como o app usa essa versao

- o app carrega `assets/config/version.json` no startup
- a versao fica disponivel em `AppVersion.current`
- a label visual usada na interface e `AppVersion.label`

## Onde a versao aparece

- no rodape das telas de auth/onboarding
- no app apos login:
  - rodape da sidebar no desktop
  - canto inferior direito da hub no mobile

## Observacao para Flutter Web

O arquivo entra no build final como asset, entao mudar `assets/config/version.json` e gerar novo build faz a nova versao aparecer no app publicado.
