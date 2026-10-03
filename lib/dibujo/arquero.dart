// EL ARQUERO: su imagen (la elige lib/personajes/arquero/animacion.dart),
// la estela al correr y sus flechas.

import 'package:flutter/material.dart';

import '../juego/juego.dart';
import '../personajes/arquero/ajustes.dart';
import '../personajes/arquero/animacion.dart';
import '../personajes/arquero/arquero.dart';
import 'pincel.dart';

void dibujarFlechas(Pincel p) {
  for (final a in p.game.flechas) {
    p.frame(p.art.arquero.frame('flecha'), a.cx, a.y + 4, flipX: a.vx < 0);
  }
}

void dibujarArquero(Pincel p) {
  final game = p.game;
  final a = game.arquero;
  if (!a.visible) return;
  // Parpadea mientras es invencible tras un golpe.
  if (a.invencible > 0 &&
      a.tiempoDano <= 0 &&
      (game.clock * 20).floor().isEven) {
    return;
  }
  if (game.state == GameState.playing) {
    _estela(p, a);
  }
  final f = imagenDelArquero(
    a,
    p.art.arquero,
    muriendo: game.state == GameState.dying,
    tiempoMuerte: game.stateTimer,
  );
  p.frame(f.img, a.cx, a.bottom, flipX: f.flip);
}

/// Siluetas difuminadas que deja al correr (las viejas, más tenues).
void _estela(Pincel p, Arquero a) {
  const color = Color(AjustesArquero.colorEstela);
  for (final h in a.estela) {
    final f = imagenDelArquero(h.pose, p.art.arquero);
    p.frame(
      f.img,
      h.pose.cx,
      h.pose.bottom,
      flipX: f.flip,
      alpha: h.fuerza * AjustesArquero.opacidadEstela,
      silueta: color,
    );
  }
}
