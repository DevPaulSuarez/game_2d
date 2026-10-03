// LAS PANTALLAS que se ponen encima del juego: título, fin del juego,
// stage completado y la tarjeta "STAGE N" antes de jugar.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../juego/juego.dart';
import '../pixel_art/pixel_art.dart';
import 'letras.dart';
import 'pincel.dart';

/// [touch] = móvil (los textos hablan de tocar en vez de teclas).
void dibujarPantallas(Pincel p, double viewW, {required bool touch}) {
  switch (p.game.state) {
    case GameState.title:
      _titulo(p, viewW, touch: touch);
    case GameState.gameOver:
      _finDelJuego(p, viewW);
    case GameState.clear:
      _stageCompletado(p, viewW);
    default:
      break;
  }
}

/// Franja oscura de lado a lado donde va el texto.
void _panel(Pincel p, double viewW, double y, double h) {
  p.paint.color = const Color(0xEE0A0A24);
  p.c.drawRect(Rect.fromLTWH(0, y, viewW, h), p.paint);
}

/// Parpadeo: true medio segundo, false medio segundo.
bool _parpadeo(Pincel p) => (p.game.clock * 2).floor().isEven;

void _titulo(Pincel p, double viewW, {required bool touch}) {
  final c = p.c, o = p.pixel.objetos;
  final cx = viewW / 2;
  _panel(p, viewW, 40, 130);
  drawPixelText(
    c,
    'EL ARQUERO',
    cx,
    52,
    px: 4,
    color: colorDorado,
    center: true,
  );
  drawPixelText(
    c,
    'Y LA PRINCESA CELESTIAL',
    cx,
    80,
    px: 2,
    color: colorCielo,
    center: true,
  );
  drawPixelText(
    c,
    touch
        ? 'FLECHAS: MOVER   DIAGONAL: DISPARAR   ARRIBA: SALTAR'
        : 'FLECHAS: MOVER  ESPACIO: SALTAR  X: FLECHA  SHIFT: CORRER',
    cx,
    106,
    center: true,
  );
  p.imgCentered(o.fragmentoCorazon, cx - 20, 126, scale: 1.2);
  p.imgCentered(o.alma, cx + 20, 126);
  if (_parpadeo(p)) {
    drawPixelText(
      c,
      touch ? 'TOCA LA PANTALLA PARA COMENZAR' : 'PULSA ESPACIO PARA COMENZAR',
      cx,
      146,
      px: 1.5,
      center: true,
    );
  }
}

void _finDelJuego(Pincel p, double viewW) {
  final c = p.c;
  final cx = viewW / 2;
  _panel(p, viewW, 80, 70);
  drawPixelText(c, 'FIN DEL JUEGO', cx, 94, px: 3, center: true);
  if (_parpadeo(p) && p.game.stateTimer > 1) {
    drawPixelText(
      c,
      'PULSA PARA INTENTARLO DE NUEVO',
      cx,
      126,
      px: 1.5,
      center: true,
    );
  }
}

void _stageCompletado(Pincel p, double viewW) {
  final c = p.c, game = p.game, o = p.pixel.objetos;
  final cx = viewW / 2;
  _panel(p, viewW, 34, 172);
  final n = game.escenario.numero;
  drawPixelText(
    c,
    '¡STAGE $n COMPLETADO!',
    cx,
    44,
    px: 3,
    color: colorDorado,
    center: true,
  );

  // Las dos recompensas: fragmento de corazón y de alma.
  final pulse = 1 + math.sin(game.clock * 4) * 0.06;
  final iy = 100.0;
  p.glow(cx - 70, iy, 36, const Color(0x66FF7EB6));
  p.imgCentered(o.fragmentoCorazon, cx - 70, iy, scale: 3 * pulse);
  drawPixelText(c, 'FRAGMENTO DE', cx - 70, iy + 28, center: true);
  drawPixelText(
    c,
    'CORAZÓN $n',
    cx - 70,
    iy + 36,
    center: true,
    color: Pal.pink,
  );

  p.glow(cx + 70, iy, 36, const Color(0x665CD8F8));
  p.imgCentered(o.alma, cx + 70, iy, scale: 2.5 * pulse);
  drawPixelText(c, 'FRAGMENTO DE', cx + 70, iy + 28, center: true);
  drawPixelText(c, 'ALMA $n', cx + 70, iy + 36, center: true, color: Pal.soul);

  drawPixelText(c, 'PUNTOS: ${game.score}', cx, 152, px: 2, center: true);
  if (game.bonusDone && game.stateTimer > 2) {
    final blink = _parpadeo(p);
    if (game.hayOtroEscenario) {
      if (blink) {
        drawPixelText(c, 'PULSA PARA CONTINUAR', cx, 180, center: true);
      }
    } else {
      drawPixelText(
        c,
        'CONTINUARÁ...',
        cx,
        172,
        px: 1.5,
        color: colorCielo,
        center: true,
      );
      if (blink) {
        drawPixelText(c, 'PULSA PARA VOLVER AL INICIO', cx, 188, center: true);
      }
    }
  }
}

/// Tarjeta en negro antes de empezar a jugar: el arquero y el fantasma de
/// la princesa, [titulo] ("STAGE 1") y [subtitulo] (nombre del escenario).
/// La usan el juego y el final de la intro.
void dibujarTarjetaStage(
  Pincel p,
  double viewW,
  String titulo,
  String subtitulo,
) {
  final c = p.c;
  p.paint.color = Colors.black;
  c.drawRect(Rect.fromLTWH(0, 0, viewW, worldH), p.paint);
  final cx = viewW / 2;
  p.frame(p.art.arquero.frame('quieto_frente'), cx - 60, 200, scale: 2);
  p.glow(cx + 60, 168, 30, const Color(0x6678C8FF));
  p.frame(
    p.art.princesa.frame('fantasma_azul_frente'),
    cx + 60,
    200,
    scale: 2,
    alpha: 0.8,
  );
  drawPixelText(c, titulo, cx, 70, px: 4, color: colorDorado, center: true);
  drawPixelText(c, subtitulo, cx, 104, px: 2, center: true);
}
