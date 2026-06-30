import 'beep_player_stub.dart'
    if (dart.library.html) 'beep_player_web.dart' as impl;

/// Toca um beep curto de "leitura confirmada" -- o som do conceito
/// "beepou, liberou" usado no carregamento do /flow.
///
/// É puramente decorativo: a implementação concreta engole qualquer falha e
/// nunca interrompe o fluxo. Em plataformas sem Web Audio recai num som de
/// sistema leve (ver [beep_player_stub.dart]); na web é sintetizado via Web
/// Audio API (ver [beep_player_web.dart]).
void playBeep() => impl.playBeep();
