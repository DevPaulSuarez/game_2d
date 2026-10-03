// LOS ENEMIGOS y lo que lanzan. Los dibujos están en
// lib/pixel_art/enemigos.dart (miran a la izquierda; aquí se voltean).

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../juego/juego.dart';
import 'pincel.dart';

void dibujarEnemigos(Pincel p) {
  final d = p.pixel.enemigos;
  for (final e in p.game.enemies) {
    if (!e.active) continue;
    // Cambia de pie 5 veces por segundo (la rata, 10).
    final paso = (e.anim * 5).floor().isOdd;
    final ui.Image img = switch (e.kind) {
      EnemyKind.goblin =>
        e.throwPose > 0 ? d.duendeLanza : (paso ? d.duendeCamina : d.duende),
      EnemyKind.rat => (e.anim * 10).floor().isOdd ? d.rataCamina : d.rata,
      EnemyKind.mage =>
        e.throwPose > 0 ? d.magoLanza : (paso ? d.magoCamina : d.mago),
      EnemyKind.darkArcher =>
        e.throwPose > 0
            ? d.arqueroSombrioDispara
            : (paso ? d.arqueroSombrioCamina : d.arqueroSombrio),
    };
    if (e.kind == EnemyKind.mage && !e.dead) {
      // Brillo del orbe del bastón.
      final ox = e.dir > 0 ? e.right - 2 : e.x + 2;
      final r = e.throwPose > 0 ? 14.0 : 7.0;
      p.glow(ox, e.y - 1, r, const Color(0x88FF5CE0));
    }
    // Transparente un momento al recibir un golpe; boca abajo al morir.
    final alpha = e.hitFlash > 0 ? 0.4 : 1.0;
    p.sprite(img, e, flipX: e.dir > 0, flipY: e.dead, alpha: alpha);
  }
}

void dibujarProyectiles(Pincel p) {
  final d = p.pixel.enemigos;
  for (final r in p.game.proyectiles) {
    switch (r.tipo) {
      case TipoProyectil.piedra:
        p.img(d.piedra, r.x, r.y);
      case TipoProyectil.magia:
        p.glow(r.cx, r.cy, 12, const Color(0x99FF5CE0));
        p.imgCentered(d.bolaMagica, r.cx, r.cy, rot: r.t * 6);
      case TipoProyectil.flecha:
        p.img(d.flechaEnemiga, r.x, r.y, flipX: r.vx > 0);
    }
  }
}
