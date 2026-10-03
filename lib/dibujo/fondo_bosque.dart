// FONDO DEL BOSQUE DE LOS DUENDES: cielo de día, montañas, pinos y las
// plantas del suelo.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../juego/juego.dart';
import 'pincel.dart';

/// Cielo de día con capas de montañas y bosque. Se dibuja en coordenadas
/// de pantalla; las capas lejanas se mueven más despacio que el arquero
/// (efecto de profundidad).
void dibujarCieloBosque(Pincel p, double cam, double viewW) {
  final c = p.c, game = p.game;
  c.drawRect(
    Rect.fromLTWH(0, 0, viewW, worldH),
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(0, worldH),
        const [Color(0xFF6EB4E8), Color(0xFFBFE3F4), Color(0xFFF6EFD8)],
        const [0, 0.6, 1],
      ),
  );
  // Sol suave
  p.glow(viewW * 0.18, 40, 70, const Color(0x66FFF4C0));

  // Nubes suaves que se desplazan despacio
  p.paint.color = const Color(0xB0FFFFFF);
  for (var i = 0; i < 5; i++) {
    final w = 60.0 + (i * 37) % 50;
    var x = (i * 173.0 - cam * 0.08 + game.clock * 4) % (viewW + 160);
    x -= 80;
    final y = 30.0 + (i * 23) % 50;
    c.drawOval(Rect.fromLTWH(x, y, w, 14), p.paint);
    c.drawOval(Rect.fromLTWH(x + w * 0.2, y - 6, w * 0.5, 14), p.paint);
  }

  // Montañas lejanas (al 12 %)
  _cordillera(p, cam * 0.12, viewW, 150, 70, 220, const Color(0xFF9CC0DA));
  // Colinas con pinos (al 30 %)
  _cordillera(p, cam * 0.30, viewW, 175, 30, 160, const Color(0xFF6FA88A));
  _pinos(p, cam * 0.30, viewW, 178, const Color(0xFF5A9478), 1.0);
  // Bosque cercano (al 55 %)
  _pinos(p, cam * 0.55, viewW, 205, const Color(0xFF3F7A5E), 1.6);
  // Rayos de luz entre los árboles
  for (var i = 0; i < 3; i++) {
    final x = (i * 260.0 - cam * 0.2) % (viewW + 200) - 60;
    c.drawPath(
      Path()
        ..moveTo(x, 0)
        ..lineTo(x + 40, 0)
        ..lineTo(x + 140, worldH)
        ..lineTo(x + 80, worldH)
        ..close(),
      Paint()..color = const Color(0x14FFF8D0),
    );
  }
}

/// Sierra de montañas o colinas: picos suaves que se repiten.
void _cordillera(
  Pincel p,
  double off,
  double viewW,
  double base,
  double alto,
  double periodo,
  Color col,
) {
  final path = Path()..moveTo(0, worldH);
  for (var x = 0.0; x <= viewW + 8; x += 8) {
    final u = (x + off) / periodo * 2 * math.pi;
    final y =
        base - alto * (0.55 + 0.3 * math.sin(u) + 0.15 * math.sin(u * 2.7 + 1));
    path.lineTo(x, y);
  }
  path
    ..lineTo(viewW, worldH)
    ..close();
  p.c.drawPath(path, Paint()..color = col);
}

/// Fila de pinos en silueta.
void _pinos(
  Pincel p,
  double off,
  double viewW,
  double base,
  Color col,
  double escala,
) {
  p.paint.color = col;
  final paso = 26 * escala;
  final first = (off / paso).floor() - 1;
  final last = ((off + viewW) / paso).ceil() + 1;
  p.c.drawRect(Rect.fromLTWH(0, base, viewW, worldH - base), p.paint);
  for (var k = first; k <= last; k++) {
    final h = (28 + (k * 7919 % 5) * 7) * escala;
    final x = k * paso - off + (k * 31 % 9);
    p.c.drawPath(
      Path()
        ..moveTo(x - 9 * escala, base)
        ..lineTo(x, base - h)
        ..lineTo(x + 9 * escala, base)
        ..close(),
      p.paint,
    );
  }
}

/// Helechos, flores, hierbas y motas de polen sobre el suelo (en
/// coordenadas del mundo).
void dibujarDecoradoBosque(Pincel p, double cam, double viewW) {
  final c = p.c, game = p.game, deco = p.pixel.decorado;
  const period = 36 * T;
  final first = (cam / period).floor() - 1;
  final last = ((cam + viewW) / period).ceil();
  for (var k = first; k <= last; k++) {
    final base = k * period;
    for (final (tx, img) in [
      (2.0, deco.helecho),
      (6.5, deco.matoHierba),
      (11.0, deco.florBosque),
      (15.0, deco.helecho),
      (19.5, deco.matoHierba),
      (24.0, deco.florBosque),
      (28.0, deco.matoHierba),
      (32.5, deco.helecho),
    ]) {
      final x = base + tx * T;
      final suelo = p.sueloLlano(x);
      if (suelo == null || p.sueloLlano(x + img.width) != suelo) continue;
      p.img(img, x, suelo - img.height + 1);
    }
  }
  // Polen que flota con la luz
  for (var i = 0; i < 12; i++) {
    final bx = (cam / 300).floor() * 300 + (i * 149) % 600 - 150;
    final x = bx + math.sin(game.clock * 0.5 + i) * 20;
    final y = 50 + (i * 53) % 130 + math.cos(game.clock * 0.7 + i * 2) * 8;
    p.paint.color = Color.fromRGBO(
      255,
      250,
      200,
      0.5 + 0.3 * math.sin(i + game.clock),
    );
    c.drawRect(Rect.fromLTWH(x, y, 1, 1), p.paint);
  }
}
