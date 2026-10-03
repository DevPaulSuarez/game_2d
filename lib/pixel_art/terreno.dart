// DIBUJOS DEL TERRENO: tierra, cuestas, ramas y rocas de cada tema.
//
// La tierra tiene 8 versiones (con o sin hierba arriba, con o sin borde a
// cada lado): el juego elige cuál según lo que haya alrededor de cada
// casilla (ver lib/dibujo/terreno.dart).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'herramientas.dart';

/// Todos los dibujos del terreno de un tema.
class Terreno {
  /// Tierra: índice = arriba libre (1) + izquierda libre (2) + derecha
  /// libre (4). Así cada casilla se dibuja con hierba y bordes donde toca.
  final List<ui.Image> tierra;
  final ui.Image cuestaSube, cuestaBaja;

  /// Rama: índice = sin rama a la izquierda (1) + sin rama a la derecha (2).
  final List<ui.Image> rama;

  /// Roca con algo encima / roca con cielo encima.
  final ui.Image roca, rocaArriba;
  Terreno({
    required this.tierra,
    required this.cuestaSube,
    required this.cuestaBaja,
    required this.rama,
    required this.roca,
    required this.rocaArriba,
  });
}

/// Bosque de los Duendes: hierba verde, ramas de árbol y rocas con musgo.
Terreno crearTerrenoBosque() => Terreno(
  tierra: [for (var i = 0; i < 8; i++) _buildTierra(_coloresBosque, i)],
  cuestaSube: _buildCuesta(_coloresBosque, sube: true),
  cuestaBaja: _buildCuesta(_coloresBosque, sube: false),
  rama: [for (var i = 0; i < 4; i++) _buildRama(i)],
  roca: _buildRoca(musgo: false),
  rocaArriba: _buildRoca(musgo: true),
);

/// Reino de las Hadas: hierba turquesa, raíces que brillan y piedras con
/// runas.
Terreno crearTerrenoHadas() {
  final runa = _buildRuneStone();
  return Terreno(
    tierra: [for (var i = 0; i < 8; i++) _buildTierra(_coloresHadas, i)],
    cuestaSube: _buildCuesta(_coloresHadas, sube: true),
    cuestaBaja: _buildCuesta(_coloresHadas, sube: false),
    rama: [for (var i = 0; i < 4; i++) _buildRaiz(i)],
    roca: runa,
    rocaArriba: runa,
  );
}

/// Colores del terreno de cada tema.
class _ColoresTerreno {
  final Color hierba, hierbaLuz, hierbaSombra;
  final Color tierra, tierraSombra, tierraLuz, contorno, mota;
  const _ColoresTerreno({
    required this.hierba,
    required this.hierbaLuz,
    required this.hierbaSombra,
    required this.tierra,
    required this.tierraSombra,
    required this.tierraLuz,
    required this.contorno,
    required this.mota,
  });
}

const _coloresBosque = _ColoresTerreno(
  hierba: Color(0xFF6AB83A),
  hierbaLuz: Color(0xFFB5E061),
  hierbaSombra: Color(0xFF3E7A20),
  tierra: Color(0xFF7A4A24),
  tierraSombra: Color(0xFF55301A),
  tierraLuz: Color(0xFF9A6434),
  contorno: Color(0xFF2A160A),
  mota: Color(0xFF9A9AA8),
);

const _coloresHadas = _ColoresTerreno(
  hierba: Color(0xFF3CC8A0),
  hierbaLuz: Color(0xFF8AF0C8),
  hierbaSombra: Color(0xFF1E7A6A),
  tierra: Color(0xFF3A2458),
  tierraSombra: Color(0xFF26163E),
  tierraLuz: Color(0xFF4E3470),
  contorno: Color(0xFF140A24),
  mota: Color(0xFF7CE0F8),
);

/// Casilla de tierra. [bordes]: 1 = cielo arriba, 2 = hueco a la
/// izquierda, 4 = hueco a la derecha. Donde hay cielo sale hierba; donde
/// hay hueco, un borde oscuro; y las esquinas se redondean.
ui.Image _buildTierra(_ColoresTerreno c, int bordes) => dibujarImagen(16, 16, (
  cv,
  p,
) {
  final arriba = bordes & 1 != 0;
  final izq = bordes & 2 != 0;
  final der = bordes & 4 != 0;
  rect(cv, p, c.tierra, 0, 0, 16, 16);
  // Textura: vetas y piedrecitas.
  rect(cv, p, c.tierraSombra, 2, 9, 3, 1);
  rect(cv, p, c.tierraSombra, 9, 13, 4, 1);
  rect(cv, p, c.tierraLuz, 11, 7, 2, 1);
  rect(cv, p, c.tierraLuz, 4, 13, 1, 1);
  rect(cv, p, c.mota, 12, 10, 1, 1);
  rect(cv, p, c.mota, 6, 5, 1, 1);
  if (izq) {
    rect(cv, p, c.contorno, 0, 0, 1, 16);
    rect(cv, p, c.tierraSombra, 1, 0, 1, 16);
  }
  if (der) {
    rect(cv, p, c.contorno, 15, 0, 1, 16);
    rect(cv, p, c.tierraSombra, 14, 0, 1, 16);
  }
  if (arriba) {
    rect(cv, p, c.hierbaSombra, 0, 0, 16, 5);
    rect(cv, p, c.hierba, 0, 0, 16, 4);
    rect(cv, p, c.hierbaLuz, 0, 0, 16, 1);
    // Hierba que cuelga sobre la tierra.
    for (final (x, h) in [(1, 2), (4, 3), (6, 1), (9, 2), (12, 3), (14, 1)]) {
      rect(cv, p, c.hierbaSombra, x.toDouble(), 5, 1, h.toDouble());
    }
    if (izq) {
      rect(cv, p, c.hierbaSombra, 0, 0, 2, 8);
      rect(cv, p, c.hierba, 1, 1, 1, 5);
      p.blendMode = BlendMode.clear;
      rect(cv, p, Pal.black, 0, 0, 2, 1);
      rect(cv, p, Pal.black, 0, 1, 1, 1);
      p.blendMode = BlendMode.srcOver;
      rect(cv, p, c.contorno, 2, 0, 1, 1);
      rect(cv, p, c.contorno, 1, 1, 1, 1);
    }
    if (der) {
      rect(cv, p, c.hierbaSombra, 14, 0, 2, 8);
      rect(cv, p, c.hierba, 14, 1, 1, 5);
      p.blendMode = BlendMode.clear;
      rect(cv, p, Pal.black, 14, 0, 2, 1);
      rect(cv, p, Pal.black, 15, 1, 1, 1);
      p.blendMode = BlendMode.srcOver;
      rect(cv, p, c.contorno, 13, 0, 1, 1);
      rect(cv, p, c.contorno, 14, 1, 1, 1);
    }
  }
});

/// Cuesta de 45°: tierra por debajo de la diagonal y hierba encima.
ui.Image _buildCuesta(_ColoresTerreno c, {required bool sube}) =>
    dibujarImagen(16, 16, (cv, p) {
      for (var i = 0; i < 16; i++) {
        final x = (sube ? i : 15 - i).toDouble();
        final top = 15.0 - i;
        rect(cv, p, c.tierra, x, top, 1, 16 - top);
        rect(cv, p, c.hierbaSombra, x, top, 1, math.min(5, 16 - top));
        rect(cv, p, c.hierba, x, top, 1, math.min(3, 16 - top));
        rect(cv, p, c.hierbaLuz, x, top, 1, 1);
      }
      rect(cv, p, c.mota, sube ? 12 : 3, 12, 1, 1);
      rect(cv, p, c.tierraSombra, sube ? 9 : 4, 14, 3, 1);
    });

/// Rama de árbol (bosque). [fin]: 1 = acaba a la izquierda, 2 = a la
/// derecha. Solo ocupa la parte de arriba de la casilla.
ui.Image _buildRama(int fin) => dibujarImagen(16, 16, (c, p) {
  const corteza = Color(0xFF7A4A24);
  const oscura = Color(0xFF4A2A10);
  const luz = Color(0xFFA86A34);
  const hoja = Color(0xFF5AAA32);
  const hojaLuz = Color(0xFF9AD84A);
  final izq = fin & 1 != 0, der = fin & 2 != 0;
  final x0 = izq ? 2.0 : 0.0, x1 = der ? 14.0 : 16.0;
  rect(c, p, oscura, x0, 0, x1 - x0, 7);
  rect(c, p, corteza, x0, 1, x1 - x0, 5);
  rect(c, p, luz, x0, 1, x1 - x0, 1);
  rect(c, p, oscura, x0 + 3, 3, 4, 1);
  rect(c, p, oscura, x0 + 9, 4, 2, 1);
  // Extremos cortados: se ve el anillo de la madera.
  if (izq) {
    rect(c, p, oscura, 0, 1, 2, 5);
    rect(c, p, const Color(0xFFD8B078), 1, 2, 1, 3);
  }
  if (der) {
    rect(c, p, oscura, 14, 1, 2, 5);
    rect(c, p, const Color(0xFFD8B078), 14, 2, 1, 3);
  }
  // Hojitas encima y colgando.
  rect(c, p, hoja, 5, 0, 3, 1);
  rect(c, p, hojaLuz, 6, 0, 1, 1);
  if (!der) {
    rect(c, p, hoja, 11, 7, 2, 3);
    rect(c, p, hojaLuz, 11, 7, 1, 1);
  }
});

/// Raíz que brilla (Reino de las Hadas): hace de rama.
ui.Image _buildRaiz(int fin) => dibujarImagen(16, 16, (c, p) {
  const raiz = Color(0xFF5A3A6A);
  const oscura = Color(0xFF2E1A3A);
  const luz = Color(0xFF8A62A0);
  const vena = Color(0xFF7CF8FF);
  final izq = fin & 1 != 0, der = fin & 2 != 0;
  final x0 = izq ? 2.0 : 0.0, x1 = der ? 14.0 : 16.0;
  rect(c, p, oscura, x0, 0, x1 - x0, 7);
  rect(c, p, raiz, x0, 1, x1 - x0, 5);
  rect(c, p, luz, x0, 1, x1 - x0, 1);
  rect(c, p, vena, x0 + 2, 3, 5, 1);
  rect(c, p, vena, x0 + 7, 4, 3, 1);
  if (izq) rect(c, p, oscura, 1, 2, 1, 3);
  if (der) rect(c, p, oscura, 14, 2, 1, 3);
  // Florecita y zarcillo colgando
  rect(c, p, const Color(0xFFFF8AD0), 6, 0, 2, 1);
  if (!izq) {
    rect(c, p, const Color(0xFF3CC8A0), 3, 7, 1, 4);
    rect(c, p, vena, 3, 11, 1, 1);
  }
});

/// Roca del bosque: piedra gris redondeada, con musgo si da al cielo.
ui.Image _buildRoca({required bool musgo}) => dibujarImagen(16, 16, (c, p) {
  const piedra = Color(0xFF8A8A98);
  const luz = Color(0xFFB8B8C8);
  const sombra = Color(0xFF5A5A6A);
  const contorno = Color(0xFF2A2A38);
  rect(c, p, contorno, 1, 0, 14, 16);
  rect(c, p, contorno, 0, 1, 16, 14);
  rect(c, p, piedra, 1, 1, 14, 14);
  rect(c, p, luz, 2, 2, 5, 2);
  rect(c, p, luz, 2, 4, 2, 3);
  rect(c, p, sombra, 1, 12, 14, 3);
  rect(c, p, sombra, 12, 2, 3, 12);
  rect(c, p, sombra, 6, 8, 3, 1);
  if (musgo) {
    rect(c, p, const Color(0xFF3E7A20), 1, 0, 14, 4);
    rect(c, p, const Color(0xFF6AB83A), 2, 0, 11, 2);
    rect(c, p, const Color(0xFF3E7A20), 4, 4, 1, 2);
    rect(c, p, const Color(0xFF3E7A20), 10, 4, 1, 3);
  }
});

/// Bloque duro: piedra azulada con una runa que brilla.
ui.Image _buildRuneStone() => dibujarImagen(16, 16, (c, p) {
  const base = Color(0xFF4A5A8A);
  const light = Color(0xFF8A9ACA);
  const dark = Color(0xFF2A3258);
  rect(c, p, base, 0, 0, 16, 16);
  for (var i = 0; i < 2; i++) {
    final d = i.toDouble();
    rect(c, p, light, d, d, 16 - d * 2, 1);
    rect(c, p, light, d, d, 1, 16 - d * 2);
    rect(c, p, dark, d, 15 - d, 16 - d * 2, 1);
    rect(c, p, dark, 15 - d, d, 1, 16 - d * 2);
  }
  const rune = Color(0xFF7CF8FF);
  rect(c, p, rune, 7, 4, 2, 8);
  rect(c, p, rune, 5, 6, 6, 1);
  rect(c, p, rune, 5, 10, 2, 1);
  rect(c, p, rune, 9, 10, 2, 1);
});
