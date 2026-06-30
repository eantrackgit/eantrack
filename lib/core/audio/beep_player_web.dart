import 'dart:web_audio' as web_audio;

web_audio.AudioContext? _ctx;

/// Beep sintetizado via Web Audio API (sem asset binário): um oscilador
/// quadrado agudo com ataque/decay muito rápidos -> timbre seco de leitor de
/// código de barras. Reusa um único [web_audio.AudioContext] entre chamadas.
void playBeep() {
  try {
    final ctx = _ctx ??= web_audio.AudioContext();
    // Navegadores podem suspender o contexto até um gesto do usuário; como o
    // /flow vem logo após o login (que teve cliques), basta retomá-lo.
    if (ctx.state == 'suspended') {
      ctx.resume();
    }

    final now = ctx.currentTime ?? 0;
    final osc = ctx.createOscillator();
    final gain = ctx.createGain();

    osc.type = 'square';
    osc.frequency?.value = 1850;

    // Envelope: sobe quase instantâneo e cai em ~120ms (um "bip" curto).
    // exponentialRamp exige valores > 0, por isso o piso em 0.0001.
    gain.gain
      ?..setValueAtTime(0.0001, now)
      ..exponentialRampToValueAtTime(0.07, now + 0.005)
      ..exponentialRampToValueAtTime(0.0001, now + 0.13);

    osc.connectNode(gain);
    gain.connectNode(ctx.destination!);
    // No dart:web_audio o disparo é start2(); a parada é stop() (sem sufixo).
    osc.start2(now);
    osc.stop(now + 0.14);
  } catch (_) {
    // Áudio é decorativo; engole qualquer erro de API/política de autoplay.
  }
}
