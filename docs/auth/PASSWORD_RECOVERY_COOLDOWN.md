# Password Recovery Cooldown

## Estado atual

O fluxo de recuperação de senha permanece na própria tela após o envio inicial do link.

Depois de um envio bem-sucedido:

- o CTA principal muda para `Reenviar link`
- o botão fica desabilitado durante o cooldown
- o texto exibe o tempo restante em formato `mm:ss`
- a UI reutiliza a mesma linguagem visual do fluxo de confirmação de e-mail, incluindo barra de progresso
- não há snackbar

## Cooldown

- duração: `15 minutos`
- formato visual: `Reenviar em 14:59`
- o estado visual é derivado de `lockedUntil` + `DateTime.now()`

## Persistência

O fluxo de recuperação persiste apenas o timestamp `lockedUntil`.

No Flutter Web:

- storage: `localStorage`
- chave: `auth.password_recovery.locked_until_ms`

Comportamento de restauração:

- ao entrar ou reentrar na tela, o provider lê `lockedUntil`
- se o valor ainda estiver no futuro, o cooldown continua normalmente
- se o valor já tiver expirado, o storage é limpo e o botão volta ao estado liberado

## Arquitetura

- não existe AppState global para esse fluxo
- a persistência é pontual e isolada ao fluxo de recuperação
- o fluxo de confirmação de e-mail continua independente e não compartilha storage
- o componente visual do botão pode ser reutilizado, mas o estado persistido da recuperação permanece separado

## UX e mensagens

Durante bloqueio por rate limit no recovery, a mensagem amigável em português é:

`Já enviamos um link recentemente.

Para sua segurança, aguarde alguns minutos antes de solicitar outro.`
