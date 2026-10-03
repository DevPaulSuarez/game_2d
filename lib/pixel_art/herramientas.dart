// HERRAMIENTAS PARA DIBUJAR PIXEL ART CON CÓDIGO.
//
// Hay dos formas de hacer un dibujo:
//
// 1. Con un MAPA DE LETRAS (desdeMapa): cada letra es un color de una
//    paleta y '.' es transparente. Ejemplo, una piedra:
//
//      const _piedra = ['.OOOO.', 'OWOOOO', 'OOOOOD', 'OOOODD', '.ODDD.'];
//      final piedra = desdeMapa(_piedra, {
//        'O': Color(0xFF8A8A98),   // gris
//        'W': Color(0xFFD0D0DC),   // brillo
//        'D': Color(0xFF4A4A58),   // sombra
//      });
//
//    desdeMapa además le da volumen (luz arriba a la izquierda, sombra
//    abajo a la derecha) y un contorno oscuro. Para quitarlo (p. ej. en
//    casillas que deben encajar sin costura), usa retoque: false.
//
// 2. Con RECTÁNGULOS (dibujarImagen + rect): para dibujos con formas
//    repetidas o calculadas (la casa, el portal, la tierra...).
//
//      final farol = dibujarImagen(12, 44, (c, p) {
//        rect(c, p, Pal.black, 5, 10, 2, 34);   // poste: x, y, ancho, alto
//      });

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Colores que se repiten en varios dibujos.
class Pal {
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFCFCFC);
  static const gold = Color(0xFFFCD000);
  static const green = Color(0xFF00A800);
  static const greenLight = Color(0xFF80D010);
  static const pink = Color(0xFFFF7EB6);
  static const heartRed = Color(0xFFE01030);
  static const soul = Color(0xFF5CD8F8);
}

/// Rejilla de píxeles; `null` es transparente.
typedef _Grid = List<List<Color?>>;

/// Desplaza un tono hacia [target] por el camino angular más corto.
double _hueToward(double h, double target, double amt) {
  var d = target - h;
  if (d > 180) d -= 360;
  if (d < -180) d += 360;
  return (h + d * amt) % 360;
}

/// Sombra: además de oscurecer, enfría el tono hacia el violeta y satura.
/// El desplazamiento de tono es lo que separa una rampa creíble de un
/// simple degradado a negro.
Color _shadow(Color c, double f) {
  final hsl = HSLColor.fromColor(c);
  return HSLColor.fromAHSL(
    c.a,
    _hueToward(hsl.hue, 272, 0.16 * (1 - f)),
    (hsl.saturation + 0.10 * (1 - f)).clamp(0.0, 1.0),
    hsl.lightness * f,
  ).toColor();
}

/// Luz: aclara desplazando el tono hacia el ámbar y bajando saturación.
Color _highlight(Color c, double f) {
  final hsl = HSLColor.fromColor(c);
  return HSLColor.fromAHSL(
    c.a,
    _hueToward(hsl.hue, 48, 0.12 * f),
    (hsl.saturation - 0.05 * f).clamp(0.0, 1.0),
    (hsl.lightness + (1 - hsl.lightness) * f).clamp(0.0, 1.0),
  ).toColor();
}

/// Color de contorno derivado del píxel vecino, no negro plano: mantiene
/// la silueta legible sin aplanar el color del material.
Color _outlineColor(Color c) {
  final hsl = HSLColor.fromColor(c);
  return HSLColor.fromAHSL(
    1,
    _hueToward(hsl.hue, 272, 0.28),
    (hsl.saturation * 0.85 + 0.22).clamp(0.0, 1.0),
    math.min(hsl.lightness * 0.30, 0.13),
  ).toColor();
}

double _lum(Color c) => 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;

_Grid _gridFromMap(List<String> rows, Map<String, Color> pal) {
  var w = 0;
  for (final r in rows) {
    if (r.length > w) w = r.length;
  }
  return List.generate(
    rows.length,
    (y) => List.generate(w, (x) {
      final r = rows[y];
      return x < r.length ? pal[r[x]] : null;
    }),
  );
}

/// Modela el volumen asumiendo luz desde arriba-izquierda: oscurece el borde
/// interno inferior/derecho y realza el superior/izquierdo.
_Grid _model(_Grid g) {
  final h = g.length, w = g[0].length;
  Color? at(int x, int y) =>
      (x < 0 || y < 0 || x >= w || y >= h) ? null : g[y][x];
  return List.generate(h, (y) {
    return List.generate(w, (x) {
      final c = g[y][x];
      if (c == null) return null;
      if (at(x, y + 1) == null || at(x + 1, y) == null) {
        return _shadow(c, 0.80);
      }
      if (at(x, y - 1) == null || at(x - 1, y) == null) {
        return _highlight(c, 0.20);
      }
      return c;
    });
  });
}

/// Contorno selectivo. Añade 1px a los lados y arriba, nunca abajo: los
/// sprites se alinean por su base, así que un borde inferior los despegaría
/// del suelo.
_Grid _outline(_Grid g) {
  final h = g.length, w = g[0].length;
  final nh = h + 1, nw = w + 2;
  final out = List.generate(nh, (y) {
    return List.generate(nw, (x) {
      final sx = x - 1, sy = y - 1;
      return (sx < 0 || sy < 0 || sx >= w || sy >= h) ? null : g[sy][sx];
    });
  });
  Color? src(int x, int y) {
    final sx = x - 1, sy = y - 1;
    return (sx < 0 || sy < 0 || sx >= w || sy >= h) ? null : g[sy][sx];
  }

  for (var y = 0; y < nh; y++) {
    for (var x = 0; x < nw; x++) {
      if (out[y][x] != null) continue;
      Color? darkest;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          if (dx == 0 && dy == 0) continue;
          final n = src(x + dx, y + dy);
          if (n == null) continue;
          if (darkest == null || _lum(n) < _lum(darkest)) darkest = n;
        }
      }
      if (darkest != null) out[y][x] = _outlineColor(darkest);
    }
  }
  return out;
}

ui.Image _imageFromGrid(_Grid g) {
  final h = g.length, w = g[0].length;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final p = Paint()..isAntiAlias = false;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final col = g[y][x];
      if (col == null) continue;
      p.color = col;
      c.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), p);
    }
  }
  return rec.endRecording().toImageSync(w, h);
}

/// Construye una imagen a partir de un mapa de letras.
/// Cada letra se traduce a un color de la paleta ('.' = transparente).
/// [retoque] aplica volumen y contorno; se desactiva en dibujos que deben
/// encajar sin costura o que ya traen su propio borde.
ui.Image desdeMapa(
  List<String> rows,
  Map<String, Color> pal, {
  bool retoque = true,
}) {
  var g = _gridFromMap(rows, pal);
  if (retoque) g = _outline(_model(g));
  return _imageFromGrid(g);
}

/// Crea una imagen de [w] x [h] píxeles dibujándola con [draw].
ui.Image dibujarImagen(int w, int h, void Function(Canvas c, Paint p) draw) {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final p = Paint()..isAntiAlias = false;
  draw(c, p);
  return rec.endRecording().toImageSync(w, h);
}

void rect(
  Canvas c,
  Paint p,
  Color col,
  double x,
  double y,
  double w,
  double h,
) {
  p.color = col;
  c.drawRect(Rect.fromLTWH(x, y, w, h), p);
}

/// Reemplaza las filas [from] de un mapa base por [rows].
List<String> parche(List<String> base, int from, List<String> rows) => [
  ...base.sublist(0, from),
  ...rows,
  ...base.sublist(from + rows.length),
];
