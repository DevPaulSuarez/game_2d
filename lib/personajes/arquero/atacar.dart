// PIEZA: golpe cuerpo a cuerpo (con la espada de fuego).
//
// Se usa el mismo botón que para disparar: arquero.dart decide cuál toca.

import '../../game/game.dart';
import 'ajustes.dart';
import 'arquero.dart';
import '../../sonido/efecto.dart';

/// Enemigos vivos justo delante del arquero, a distancia de golpe.
List<Enemy> enemigosAlAlcance(Arquero a, Game mundo) {
  const alcance = AjustesArquero.alcanceGolpe;
  // Una caja imaginaria desde el centro del arquero hacia donde mira.
  final zona = Box(
    a.mira > 0 ? a.cx : a.cx - alcance - a.w / 2,
    a.y,
    alcance + a.w / 2,
    a.h,
  );
  return [
    for (final e in mundo.enemigosVivos)
      if (zona.overlaps(e)) e,
  ];
}

/// Golpea a todos los [enemigos] y empieza la animación de ataque.
void atacar(Arquero a, List<Enemy> enemigos, Game mundo) {
  mundo.sonar(Efecto.espada);
  for (final e in enemigos) {
    for (var i = 0; i < AjustesArquero.danoGolpe; i++) {
      mundo.danarEnemigo(e, a.mira);
    }
  }
  a.recarga = AjustesArquero.recargaGolpe;
  a.tiempoAtaque = AjustesArquero.duracionAtaque;
  a.tiempoDisparo = 0;
}
