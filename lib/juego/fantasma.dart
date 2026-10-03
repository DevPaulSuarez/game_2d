// EL FANTASMA DE LA PRINCESA: sigue al arquero flotando y le habla.
//
// Aquí están sus frases. Las de cada escenario (al empezar, cerca de la
// meta, consejos...) están en el archivo del escenario, en
// lib/escenarios/.

import 'dart:math' as math;

import 'juego.dart';

/// Para dar ánimos cuando lleva un rato callada.
const frasesAnimar = [
  '¡TÚ PUEDES, ARQUERO!',
  'CREO EN TI.',
  '¡SIGUE ADELANTE!',
  'SIENTO MI CORAZÓN CERCA...',
  'NO TE RINDAS, POR FAVOR.',
  'ERES MI ÚNICA ESPERANZA.',
];

/// Al vencer a un enemigo (no siempre).
const frasesFelicitar = [
  '¡BIEN HECHO!',
  '¡GRAN DISPARO!',
  '¡ERES INCREÍBLE!',
  '¡UNO MENOS!',
  '¡QUÉ VALIENTE!',
];

/// Cuando al arquero le hacen daño.
const frasesPreocupada = [
  '¡CUIDADO!',
  '¡RESISTE, ARQUERO!',
  '¡SALTA PARA ESQUIVAR!',
  '¡NO TE RINDAS!',
];

extension Fantasma on Game {
  /// La princesa dice [text]. Si ya está hablando, se calla esta frase
  /// salvo que [force] sea true.
  void say(String text, {bool force = false}) {
    if (!force && ghost.speech != null) return;
    ghost.speech = text;
    ghost.speechT = AjustesJuego.duracionFrase;
    ghost.idle = 0;
  }

  /// Flota detrás del arquero y, si lleva un rato callada, le anima.
  void actualizarFantasma(double dt) {
    final p = arquero;
    final gh = ghost;
    final tx = p.cx - p.mira * 24;
    final ty = p.y - 14 + math.sin(clock * 2.5) * 4;
    final k = 1 - math.exp(-3.5 * dt);
    gh.x += (tx - gh.x) * k;
    gh.y += (ty - gh.y) * k;
    if (gh.y > 12 * T - 20) gh.y = 12 * T - 20;

    if (gh.speech != null) {
      gh.speechT -= dt;
      if (gh.speechT <= 0) gh.speech = null;
    } else if (state == GameState.playing) {
      gh.idle += dt;
      if (gh.idle > AjustesJuego.silencioFantasma) {
        final frases = [...frasesAnimar, ...escenario.consejos];
        say(frases[rnd.nextInt(frases.length)]);
      }
    }
  }
}
