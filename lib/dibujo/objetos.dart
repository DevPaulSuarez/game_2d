// LOS OBJETOS: cristales, cofres, hadas que curan, chispas y puntos que
// suben.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'letras.dart';
import 'pincel.dart';

void dibujarCristales(Pincel p) {
  final game = p.game;
  final frames = p.pixel.objetos.cristal;
  for (final k in game.cristales) {
    // Cada cristal destella a su ritmo y flota un poco.
    final f = ((game.clock * 6 + k.x / 23).floor()) % frames.length;
    final dy = math.sin(game.clock * 3 + k.x / 40) * 1.5;
    p.glow(k.cx, k.cy + dy, 9, const Color(0x445CD8F8));
    p.img(frames[f], k.x - 1, k.y + dy);
  }
  // Los que saltan de un cofre recién abierto.
  for (final pop in game.cristalPops) {
    p.img(frames[0], pop.x, pop.y);
  }
}

void dibujarCofres(Pincel p) {
  final o = p.pixel.objetos;
  for (final k in p.game.cofres) {
    // Brillo al abrirse.
    if (k.abierto && k.t < 1) {
      p.glow(k.cx, k.y, 18 * (1 - k.t), const Color(0xAAFCE878));
    }
    p.sprite(k.abierto ? o.cofreAbierto : o.cofre, k);
  }
}

void dibujarHadas(Pincel p) {
  final c = p.c, game = p.game;
  final frame = p.pixel.objetos.hada[(game.clock * 8).floor() % 2];
  for (final h in game.hadas) {
    p.glow(h.cx, h.cy, 16, const Color(0x7778F0C8));
    p.imgCentered(frame, h.cx, h.cy);
    // Chispitas que caen
    for (var i = 0; i < 3; i++) {
      final t = (game.clock * 1.5 + i / 3) % 1;
      p.paint.color = Color.fromRGBO(252, 232, 120, 1 - t);
      c.drawRect(
        Rect.fromLTWH(h.cx - 4 + i * 4, h.bottom + t * 12, 1, 1),
        p.paint,
      );
    }
  }
}

/// Chispas blancas (al chocar una flecha, abrir un cofre...) y los puntos
/// que suben flotando.
void dibujarEfectos(Pincel p) {
  final c = p.c, game = p.game;
  p.paint.color = Colors.white;
  for (final s in game.sparks) {
    final r = 2 + s.t * 16;
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 + math.pi / 4;
      c.drawRect(
        Rect.fromLTWH(
          s.x + math.cos(a) * r - 1,
          s.y + math.sin(a) * r - 1,
          2,
          2,
        ),
        p.paint,
      );
    }
  }
  for (final s in game.scorePops) {
    drawPixelText(c, s.text, s.x, s.y, center: true);
  }
}
