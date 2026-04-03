# EANTrack — Instruções para Claude Code / Codex

## PROIBIDO — Nunca executar

- `dart format` — trava a execução no ambiente atual
- `flutter format` — mesma razão
- Qualquer comando de formatação automática de código

## Validação de código

Para verificar se o código está correto, use apenas:
- `flutter analyze <arquivo>` — análise estática
- `flutter test <arquivo_de_teste>` — execução de testes

Nunca rodar o formatador como etapa de validação ou pós-mudança.
