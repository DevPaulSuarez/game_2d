// PIEZA: la estela al correr.
//
// Mientras corre, el arquero deja detrás copias de sí mismo que se van
// borrando (como siluetas difuminadas). Aquí solo se guarda DÓNDE y en qué
// pose estaba; el dibujo lo hace el juego (painter.dart) con el color y la
// transparencia de ajustes.dart.

import 'ajustes.dart';
import 'arquero.dart';

/// Una copia del arquero en un momento pasado.
class Huella {
  /// Cómo estaba el arquero (posición, pose, hacia dónde miraba).
  final Arquero pose;

  /// Segundos desde que se creó (al llegar a duracionEstela, desaparece).
  double edad = 0;

  Huella(this.pose);

  /// 1 recién creada, 0 a punto de desaparecer.
  double get fuerza => 1 - edad / AjustesArquero.duracionEstela;
}

void actualizarEstela(Arquero a, double dt) {
  // Las huellas viejas se van borrando.
  for (final h in a.estela) {
    h.edad += dt;
  }
  a.estela.removeWhere((h) => h.fuerza <= 0);

  // Corriendo: deja una huella nueva cada poco tiempo.
  a.esperaEstela -= dt;
  final corriendo = a.vx.abs() > AjustesArquero.velocidadAnimCorrer;
  if (corriendo && a.esperaEstela <= 0) {
    a.estela.add(Huella(a.copia()));
    a.esperaEstela = AjustesArquero.separacionEstela;
  }
}
