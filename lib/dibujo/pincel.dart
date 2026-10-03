// EL PINCEL: las herramientas que usan todas las piezas de dibujo.
//
// Cada pieza (fondo, enemigos, HUD...) recibe un Pincel con el lienzo
// (`c`), el juego (`game`), las imágenes de los personajes (`art`) y el
// pixel art hecho con código (`pixel`), y dibuja con estas funciones:
//
//   p.img(imagen, x, y)              una imagen con su esquina en (x, y)
//   p.imgCentered(imagen, cx, cy)    una imagen centrada (y girada/escalada)
//   p.sprite(imagen, caja)           una imagen apoyada abajo de una caja
//   p.frame(cuadro, pieX, pieY)      un personaje con los pies en (x, y)
//   p.frameFit(cuadro, rect)         un retrato ajustado a un rectángulo
//   p.glow(cx, cy, radio, color)     un brillo redondo que se difumina
//   p.box(rect)                      un cuadro con borde blanco

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../juego/juego.dart';
import '../personajes/imagenes.dart';
import '../pixel_art/pixel_art.dart';

/// Alto del mundo en píxeles (15 filas de 16).
const double worldH = kRows * T;

/// Colores de los títulos.
const colorDorado = Color(0xFFFCB850);
const colorCielo = Color(0xFFB8D8F8);

class Pincel {
  final Canvas c;
  final Game game;
  final Art art;
  final PixelArt pixel;
  Pincel(this.c, this.game, this.art, this.pixel);

  /// Pincel sin suavizado (pixel art nítido). Antes de pintar con él, pon
  /// su color: `p.paint.color = ...`.
  final paint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  /// Pincel con suavizado, para las imágenes grandes de los personajes.
  final _hq = Paint()..filterQuality = FilterQuality.medium;

  /// ¿Estamos en un escenario con el aspecto del Reino de las Hadas?
  bool get hadas => game.level.tema == Tema.hadas;

  void img(
    ui.Image img,
    double x,
    double y, {
    bool flipX = false,
    bool flipY = false,
    double alpha = 1,
  }) {
    paint.color = Color.fromRGBO(0, 0, 0, alpha);
    if (!flipX && !flipY) {
      c.drawImage(img, Offset(x, y), paint);
      return;
    }
    c.save();
    c.translate(x + (flipX ? img.width : 0), y + (flipY ? img.height : 0));
    c.scale(flipX ? -1 : 1, flipY ? -1 : 1);
    c.drawImage(img, Offset.zero, paint);
    c.restore();
  }

  /// Dibuja la imagen de un personaje con sus pies en (footX, footY).
  /// [silueta] la pinta entera de un solo color (la estela al correr).
  void frame(
    Sprite f,
    double footX,
    double footY, {
    bool flipX = false,
    double alpha = 1,
    double scale = 1,
    Color? silueta,
  }) {
    final k = scale / f.ppu;
    c.save();
    c.translate(footX, footY);
    c.scale(flipX ? -k : k, k);
    _hq.color = Color.fromRGBO(0, 0, 0, alpha);
    _hq.colorFilter = silueta == null
        ? null
        : ColorFilter.mode(silueta, BlendMode.srcIn);
    c.drawImageRect(
      f.image,
      f.src,
      Rect.fromLTWH(-f.ax, -f.ay, f.src.width, f.src.height),
      _hq,
    );
    _hq.colorFilter = null;
    c.restore();
  }

  /// Dibuja una imagen ajustada a un rectángulo (retratos).
  /// [tinte] la tiñe de un color (p. ej. azul para el fantasma).
  void frameFit(Sprite f, Rect dst, {Color? tinte}) {
    _hq.color = Colors.black;
    _hq.colorFilter = tinte == null
        ? null
        : ColorFilter.mode(tinte, BlendMode.modulate);
    c.drawImageRect(f.image, f.src, dst, _hq);
    _hq.colorFilter = null;
  }

  /// Dibuja una imagen alineada abajo y centrada respecto a su caja.
  void sprite(
    ui.Image image,
    Box b, {
    bool flipX = false,
    bool flipY = false,
    double alpha = 1,
  }) {
    img(
      image,
      (b.cx - image.width / 2).roundToDouble(),
      (b.bottom - image.height).roundToDouble(),
      flipX: flipX,
      flipY: flipY,
      alpha: alpha,
    );
  }

  /// Dibuja una imagen centrada en (cx, cy) con escala y rotación.
  void imgCentered(
    ui.Image img,
    double cx,
    double cy, {
    double scale = 1,
    double rot = 0,
    double alpha = 1,
    bool flipX = false,
  }) {
    c.save();
    c.translate(cx, cy);
    if (rot != 0) c.rotate(rot);
    c.scale(flipX ? -scale : scale, scale);
    paint.color = Color.fromRGBO(0, 0, 0, alpha);
    c.drawImage(img, Offset(-img.width / 2, -img.height / 2), paint);
    c.restore();
  }

  /// Brillo redondo: [color] en el centro que se desvanece hasta el borde.
  void glow(double cx, double cy, double r, Color color) {
    final p = Paint()
      ..shader = ui.Gradient.radial(Offset(cx, cy), r, [
        color,
        color.withValues(alpha: 0),
      ]);
    c.drawCircle(Offset(cx, cy), r, p);
  }

  /// Cuadro de color con un borde blanco de 1 píxel.
  void box(Rect r, {Color fill = const Color(0xE0101028)}) {
    paint.color = Colors.white;
    c.drawRect(r.inflate(1), paint);
    paint.color = fill;
    c.drawRect(r, paint);
  }

  /// Altura del suelo llano en la x del mundo, o null si ahí hay un hueco,
  /// una cuesta o una roca (para no poner decorado donde no toca).
  double? sueloLlano(double x) {
    final tx = (x / T).floor();
    final fila = game.level.filaSuelo(tx);
    if (fila == null || game.grid[fila][tx] != Tile.ground) return null;
    return fila * T;
  }
}
