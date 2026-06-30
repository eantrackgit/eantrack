import 'package:flutter/services.dart';

/// Implementação para plataformas sem Web Audio (mobile/desktop): recorre ao
/// som de sistema disponível. Mantida simples de propósito -- o efeito sonoro é
/// um detalhe do conceito "beepou, liberou", não um requisito do fluxo.
void playBeep() {
  SystemSound.play(SystemSoundType.click);
}
