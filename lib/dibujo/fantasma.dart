// EL FANTASMA DE LA PRINCESA durante el juego, con el globo de lo que
// dice. Sus frases y cómo se mueve están en lib/juego/fantasma.dart.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../personajes/imagenes.dart';
import 'letras.dart';
import 'pincel.dart';

void dibujarFantasma(Pincel p, double cam, double viewW) {
  final c = p.c, game = p.game;
  final g = game.ghost;
  final bob = math.sin(game.clock * 3) * 1.5;
  final cx = g.x, cy = g.y + bob;
  p.glow(cx, cy, 22, const Color(0x5578C8FF));
  // Pies a media altura por debajo del centro: (cx, cy) es su centro.
  p.frame(
    p.art.princesa.frame('fantasma_azul_derecha'),
    cx,
    cy + Art.alturaPrincesa / 2,
    alpha: 0.8,
    flipX: game.arquero.mira < 0,
  );

  final text = g.speech;
  if (text == null) return;

  // Globo blanco con el texto, sin salirse de la pantalla.
  const px = 1.5;
  final lines = wrapText(text, 22);
  var maxLen = 0;
  for (final l in lines) {
    maxLen = math.max(maxLen, l.length);
  }
  final w = pixelTextWidth('X' * maxLen, px) + 10;
  final h = lines.length * 10.0 + 6;
  var bx = cx - w / 2;
  bx = bx.clamp(cam + 4, cam + viewW - w - 4).toDouble();
  final by = math.max(24.0, cy - 18 - h);
  // Cola del globo
  p.paint.color = Colors.white;
  c.drawPath(
    Path()
      ..moveTo(cx - 4, by + h - 1)
      ..lineTo(cx + 4, by + h - 1)
      ..lineTo(cx, by + h + 6)
      ..close(),
    p.paint,
  );
  p.paint.color = Colors.black;
  c.drawRect(Rect.fromLTWH(bx - 1, by - 1, w + 2, h + 2), p.paint);
  p.paint.color = Colors.white;
  c.drawRect(Rect.fromLTWH(bx, by, w, h), p.paint);
  for (var i = 0; i < lines.length; i++) {
    drawPixelText(
      c,
      lines[i],
      bx + w / 2,
      by + 4 + i * 10,
      px: px,
      center: true,
      color: const Color(0xFF2A4A9A),
      shadow: null,
    );
  }
}
