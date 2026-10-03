// LA META: el portal de piedra con su magia, la princesa de las hadas
// (en el Reino de las Hadas) y el fragmento que vuela hacia el arquero.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../juego/juego.dart';
import 'pincel.dart';

/// Suelo bajo el portal de la meta.
double _sueloMeta(Pincel p) =>
    (p.game.level.filaSuelo(p.game.level.metaX) ?? 13) * T;

/// Portal de la meta: la magia gira dentro del arco de piedra.
void dibujarMeta(Pincel p) {
  final c = p.c, game = p.game, deco = p.pixel.decorado;
  final x = game.level.metaX * T, suelo = _sueloMeta(p);
  final img = p.hadas ? deco.portalHadas : deco.portalBosque;
  final y = suelo - img.height;
  final color = p.hadas ? const Color(0xFFFF9AD0) : const Color(0xFF9AF0A0);
  final cx = x + 40, cy = y + 58;
  p.glow(cx, cy, 46, color.withValues(alpha: 0.35));
  c.drawOval(
    Rect.fromCenter(center: Offset(cx, cy), width: 38, height: 64),
    Paint()
      ..shader = ui.Gradient.radial(
        Offset(cx, cy),
        32,
        [
          Colors.white.withValues(alpha: 0.9),
          color.withValues(alpha: 0.7),
          color.withValues(alpha: 0.1),
        ],
        [0, 0.4, 1],
      ),
  );
  // Chispas girando en espiral
  for (var i = 0; i < 10; i++) {
    final a = game.clock * 2 + i * math.pi / 5;
    final r = 6 + (i % 5) * 3.0;
    p.paint.color = Colors.white.withValues(alpha: 0.8);
    c.drawRect(
      Rect.fromLTWH(cx + math.cos(a) * r, cy + math.sin(a) * r * 1.6, 1, 1),
      p.paint,
    );
  }
  p.img(img, x, y);
  if (p.hadas) _princesaHada(p, x + 92, suelo);
}

/// La princesa de las hadas espera junto al portal, con sus alas.
void _princesaHada(Pincel p, double px, double feet) {
  final c = p.c, game = p.game;
  final img = p.pixel.decorado.princesaHada;
  final bob = math.sin(game.clock * 2) * 1.5;
  final wing = 0.75 + math.sin(game.clock * 9) * 0.25;
  p.paint.color = const Color(0x88D8F4FF);
  for (final side in [-1, 1]) {
    c.drawOval(
      Rect.fromCenter(
        center: Offset(px + side * 11, feet - 22 + bob),
        width: 14 * wing,
        height: 20,
      ),
      p.paint,
    );
  }
  p.glow(px, feet - 16, 26, const Color(0x55FCE878));
  p.img(img, px - img.width / 2, feet - img.height + bob);
}

/// Fragmento de corazón y alma saliendo del portal hacia el arquero.
void dibujarVueloRecompensa(Pincel p) {
  final game = p.game, o = p.pixel.objetos;
  final t = game.rewardProgress;
  final a = game.arquero;
  final sx = game.puertaMetaX, sy = _sueloMeta(p) - 40;
  final tx = a.cx, ty = a.y - 26;
  final e = 1 - math.pow(1 - t, 3).toDouble();
  final x = sx + (tx - sx) * e;
  final y = sy + (ty - sy) * e - math.sin(t * math.pi) * 40;
  final pulse = 1 + math.sin(game.clock * 6) * 0.08;
  p.glow(x - 10, y, 20, const Color(0x88FF7EB6));
  p.glow(x + 12, y, 20, const Color(0x885CD8F8));
  p.imgCentered(o.fragmentoCorazon, x - 10, y, scale: pulse);
  p.imgCentered(o.alma, x + 12, y, scale: pulse);
}
