// FONDO DEL REINO DE LAS HADAS: cielo al anochecer con estrellas, luna,
// castillos lejanos, setas gigantes y lucecitas.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../juego/juego.dart';
import 'pincel.dart';

/// Cielo al anochecer con estrellas, luna y castillos lejanos. Se dibuja
/// en coordenadas de pantalla; las capas lejanas se mueven más despacio
/// que el arquero (efecto de profundidad).
void dibujarCieloHadas(Pincel p, double cam, double viewW) {
  final c = p.c, game = p.game;
  final sky = Rect.fromLTWH(0, 0, viewW, worldH);
  c.drawRect(
    sky,
    Paint()
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(0, worldH),
        const [Color(0xFF1E1240), Color(0xFF5A2E80), Color(0xFFC77DBA)],
        const [0, 0.55, 1],
      ),
  );

  // Estrellas que titilan (posiciones fijas "al azar").
  for (var i = 0; i < 60; i++) {
    final x = ((i * 97.13 + 13) % 1) * viewW + (i * 53) % viewW;
    final y = 26 + (i * 37 % 110).toDouble();
    final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(game.clock * 2 + i * 1.7));
    p.paint.color = Color.fromRGBO(255, 250, 230, tw);
    c.drawRect(Rect.fromLTWH(x % viewW, y, i % 7 == 0 ? 2 : 1, 1), p.paint);
  }

  // Luna
  final mx = viewW * 0.78 - cam * 0.02;
  p.glow(mx, 52, 40, const Color(0x44FFF4D0));
  p.paint.color = const Color(0xFFFFF4D8);
  c.drawCircle(Offset(mx, 52), 14, p.paint);
  p.paint.color = const Color(0xFFE8D8B8);
  c.drawCircle(Offset(mx - 4, 48), 3, p.paint);
  c.drawCircle(Offset(mx + 5, 56), 2, p.paint);

  // Castillos y montañas lejanas (se mueven al 20 %).
  _castillos(p, cam * 0.2, viewW, 150, const Color(0xFF3A2468), 260);
  // Bosque de setas (se mueve al 45 %).
  _setasGigantes(p, cam * 0.45, viewW, const Color(0xFF2A1A50));
}

void _castillos(
  Pincel p,
  double off,
  double viewW,
  double base,
  Color col,
  double period,
) {
  final c = p.c;
  p.paint.color = col;
  final first = (off / period).floor() - 1;
  final last = ((off + viewW) / period).ceil();
  for (var k = first; k <= last; k++) {
    final x0 = k * period - off;
    // Colinas
    c.drawOval(Rect.fromLTWH(x0 - 40, base + 10, 200, 90), p.paint);
    c.drawOval(Rect.fromLTWH(x0 + 120, base + 20, 180, 80), p.paint);
    // Castillo: torres con tejado en punta
    for (final (dx, w, h) in [
      (60.0, 14.0, 60.0),
      (78.0, 20.0, 80.0),
      (102.0, 14.0, 50.0),
    ]) {
      final tx = x0 + dx;
      c.drawRect(Rect.fromLTWH(tx, base + 30 - h, w, h + 20), p.paint);
      c.drawPath(
        Path()
          ..moveTo(tx - 3, base + 30 - h)
          ..lineTo(tx + w / 2, base + 30 - h - w * 1.3)
          ..lineTo(tx + w + 3, base + 30 - h)
          ..close(),
        p.paint,
      );
    }
    // Ventanas encendidas
    p.paint.color = const Color(0xAAFCE890);
    c.drawRect(Rect.fromLTWH(x0 + 86, base - 30, 3, 5), p.paint);
    c.drawRect(Rect.fromLTWH(x0 + 64, base - 10, 2, 4), p.paint);
    p.paint.color = col;
  }
}

void _setasGigantes(Pincel p, double off, double viewW, Color col) {
  final c = p.c;
  const period = 180.0;
  p.paint.color = col;
  final first = (off / period).floor() - 1;
  final last = ((off + viewW) / period).ceil();
  for (var k = first; k <= last; k++) {
    final x0 = k * period - off;
    c.drawRect(Rect.fromLTWH(x0 - 10, 190, period + 20, 50), p.paint);
    for (final (dx, h, r) in [
      (20.0, 40.0, 22.0),
      (95.0, 58.0, 30.0),
      (150.0, 30.0, 16.0),
    ]) {
      c.drawRect(Rect.fromLTWH(x0 + dx - 4, 200 - h, 8, h), p.paint);
      c.drawOval(
        Rect.fromLTWH(x0 + dx - r, 200 - h - r * 0.6, r * 2, r * 1.2),
        p.paint,
      );
    }
  }
}

/// Flores que brillan, setitas y lucecitas de hada sobre el suelo (en
/// coordenadas del mundo).
void dibujarDecoradoHadas(Pincel p, double cam, double viewW) {
  final c = p.c, game = p.game, deco = p.pixel.decorado;
  const period = 40 * T;
  final first = (cam / period).floor() - 1;
  final last = ((cam + viewW) / period).ceil();
  for (var k = first; k <= last; k++) {
    final base = k * period;
    for (final tx in [3.0, 9.5, 17.0, 24.0, 31.5, 36.0]) {
      final x = base + tx * T;
      final suelo = p.sueloLlano(x);
      if (suelo == null || p.sueloLlano(x + 10) != suelo) continue;
      final flower = tx.floor().isOdd;
      final img = flower ? deco.florBrillante : deco.setita;
      if (flower) {
        final pulse = 0.5 + 0.5 * math.sin(game.clock * 2 + tx);
        p.glow(x + 4, suelo - 10, 8 + pulse * 3, const Color(0x557CE0F8));
      }
      p.img(img, x, suelo - img.height + 1);
    }
  }
  // Lucecitas que flotan
  for (var i = 0; i < 14; i++) {
    final bx = (cam / 300).floor() * 300 + (i * 131) % 600 - 150;
    final x = bx + math.sin(game.clock * 0.7 + i) * 18;
    final y = 60 + (i * 47) % 120 + math.cos(game.clock * 0.9 + i * 2) * 10;
    final a = 0.5 + 0.5 * math.sin(game.clock * 3 + i);
    p.glow(x, y, 5, Color.fromRGBO(200, 255, 170, 0.35 * a));
    p.paint.color = Color.fromRGBO(230, 255, 200, a);
    c.drawRect(Rect.fromLTWH(x, y, 1, 1), p.paint);
  }
}
