// DIBUJOS DEL DECORADO: el portal de la meta, las plantas del suelo y la
// princesa de las hadas (que espera junto al portal del Stage 2).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'herramientas.dart';

class DibujosDecorado {
  // Portal de la meta de cada tema.
  final portalBosque = _buildPortal(
    hoja: const Color(0xFF4E9A2A),
    flor: const Color(0xFFFCE878),
  );
  final portalHadas = _buildPortal(
    hoja: const Color(0xFF3CC8A0),
    flor: const Color(0xFFFF8AD0),
  );

  // Plantas del Bosque de los Duendes.
  final helecho = _buildHelecho();
  final florBosque = _buildFlorBosque();
  final matoHierba = _buildMatoHierba();

  // Plantas del Reino de las Hadas.
  final florBrillante = _buildGlowFlower();
  final setita = _buildTinyMushroom();

  /// Princesa de las hadas: vestido lila y pelo dorado. Pendiente:
  /// cambiarla por imágenes como las de lib/personajes/.
  final princesaHada = desdeMapa(_princess, _fairyPrincessPal);
}

/// Portal antiguo de piedra: dos columnas con runas y un arco. El hueco
/// central (x 20..60) queda vacío para que se vea la magia de detrás.
ui.Image _buildPortal({required Color hoja, required Color flor}) =>
    dibujarImagen(80, 96, (c, p) {
      const piedra = Color(0xFFA8A0B8);
      const luz = Color(0xFFD0C8E0);
      const sombra = Color(0xFF6A6280);
      const contorno = Color(0xFF2A2438);
      const runa = Color(0xFF7CF8FF);
      void bloque(double x, double y, double w, double h) {
        rect(c, p, contorno, x, y, w, h);
        rect(c, p, piedra, x + 1, y + 1, w - 2, h - 2);
        rect(c, p, luz, x + 1, y + 1, w - 2, 1);
        rect(c, p, sombra, x + 1, y + h - 2, w - 2, 1);
      }

      // Columnas de bloques
      for (var y = 30.0; y < 96; y += 11) {
        bloque(6, y, 14, 11);
        bloque(60, y, 14, 11);
      }
      // Base ancha
      bloque(2, 88, 20, 8);
      bloque(58, 88, 20, 8);
      // Arco en semicírculo, hecho de dovelas
      for (var i = 0; i <= 12; i++) {
        final a = math.pi - i * math.pi / 12;
        final x = 40 + math.cos(a) * 27 - 6;
        final y = 34 - math.sin(a) * 26 - 5;
        bloque(x.roundToDouble(), y.roundToDouble(), 12, 11);
      }
      // Piedra clave con una gema
      bloque(33, 0, 14, 13);
      rect(c, p, runa, 38, 4, 4, 5);
      rect(c, p, Pal.white, 38, 4, 2, 2);
      // Runas en las columnas
      for (final y in [46.0, 68.0]) {
        rect(c, p, runa, 12, y, 2, 6);
        rect(c, p, runa, 10, y + 2, 6, 1);
        rect(c, p, runa, 66, y, 2, 6);
        rect(c, p, runa, 64, y + 3, 6, 1);
      }
      // Enredadera con flores
      for (var y = 20.0; y < 92; y += 5) {
        final dx = (y ~/ 5).isEven ? 0.0 : 2.0;
        rect(c, p, hoja, 4 + dx, y, 2, 3);
        rect(c, p, hoja, 72 - dx, y + 2, 2, 3);
      }
      for (var y = 26.0; y < 90; y += 14) {
        rect(c, p, flor, 3, y, 2, 2);
        rect(c, p, flor, 74, y + 7, 2, 2);
      }
    });

ui.Image _buildHelecho() => dibujarImagen(16, 12, (c, p) {
  const h = Color(0xFF3E8A2A);
  const hl = Color(0xFF7BC043);
  for (final (x0, dir) in [(8.0, -1.0), (8.0, 1.0), (7.0, -0.4), (9.0, 0.4)]) {
    for (var i = 0; i < 7; i++) {
      final x = x0 + dir * i;
      final y = 11.0 - i * 1.4 + (i * i) * 0.12;
      rect(c, p, h, x.roundToDouble(), y.roundToDouble(), 1, 2);
      if (i.isOdd) {
        rect(c, p, hl, x.roundToDouble(), y.roundToDouble(), 1, 1);
      }
    }
  }
});

ui.Image _buildFlorBosque() => dibujarImagen(7, 10, (c, p) {
  rect(c, p, const Color(0xFF3E7A20), 3, 3, 1, 7);
  rect(c, p, const Color(0xFF6AB83A), 4, 6, 2, 1);
  rect(c, p, const Color(0xFFF8F8FF), 1, 1, 5, 3);
  rect(c, p, const Color(0xFFF8F8FF), 2, 0, 3, 5);
  rect(c, p, const Color(0xFFFCD000), 3, 2, 1, 1);
});

ui.Image _buildMatoHierba() => dibujarImagen(10, 6, (c, p) {
  const h = Color(0xFF4E9A2A);
  const hl = Color(0xFF9AD84A);
  for (final (x, top) in [(1, 3), (3, 0), (5, 2), (7, 1), (8, 3)]) {
    rect(c, p, h, x.toDouble(), top.toDouble(), 1, 6 - top.toDouble());
    rect(c, p, hl, x.toDouble(), top.toDouble(), 1, 1);
  }
});

/// Flor que brilla (decorado del suelo).
ui.Image _buildGlowFlower() => dibujarImagen(9, 12, (c, p) {
  rect(c, p, const Color(0xFF1E7A6A), 4, 4, 1, 8);
  rect(c, p, const Color(0xFF3CC8A0), 1, 8, 3, 2);
  rect(c, p, const Color(0xFF3CC8A0), 5, 6, 3, 2);
  rect(c, p, const Color(0xFF7CE0F8), 2, 0, 5, 5);
  rect(c, p, const Color(0xFF7CE0F8), 3, -1, 3, 7);
  rect(c, p, const Color(0xFFFFFFFF), 4, 2, 1, 1);
});

/// Setita (decorado del suelo).
ui.Image _buildTinyMushroom() => dibujarImagen(10, 9, (c, p) {
  rect(c, p, Pal.black, 0, 1, 10, 4);
  rect(c, p, Pal.black, 2, 0, 6, 1);
  rect(c, p, const Color(0xFFD83A78), 1, 1, 8, 3);
  rect(c, p, const Color(0xFFFFF4F8), 3, 1, 2, 1);
  rect(c, p, const Color(0xFFFFF4F8), 6, 2, 1, 1);
  rect(c, p, Pal.black, 3, 5, 4, 4);
  rect(c, p, const Color(0xFFF0E0C8), 4, 5, 2, 4);
});

// Figura de la princesa de las hadas (los colores van en _fairyPrincessPal).
const _princess = [
  '......y..y..y.......',
  '....y.YYYYYYYY.y....',
  '....YY........YY....',
  '......nMMMMMMn......',
  '.....nMMMMMMMMn.....',
  '....nMMwWWWWwMMn....',
  '....MMwWHHHHWwMM....',
  '....MMWHSSSSHWMM....',
  '...mMMWSKSSKSWMMm...',
  '...mMMWSSSSSSWMMm...',
  '...mMMWsSRRSsWMMm...',
  '...mMMMWsSSsWMMMm...',
  '..mMMMMWWSSWWMMMMm..',
  '..mMMnWWWWWWWWnMMm..',
  '..mMMnWWWSSWWWnMMm..',
  '..mMMnWWSSSSWWnMMm..',
  '..mMMnWWWSSWWWnMMm..',
  '.mMMMnWWWGGWWWnMMMm.',
  '.mMMMnWWWWWWWWnMMMm.',
  '.mMMMnWWWwWWWWnMMMm.',
  '.mMMMnWWWwWWwWnMMMm.',
  '.mMMMnWWwWWWwWnMMMm.',
  'mMMMMnWWwWWWwWWnMMMm',
  'mMMMMnWWwWWWwWWnMMMm',
  'mMMMMnWwWWWWWwWnMMMm',
  'mMMMMnWwWWWWWwWWnMMm',
  'mMMMnWWwWWWWWwWWnMMm',
  'mMMMnWwWWWWWWWwWnMMm',
  'mmMMnWwWWWWWWWwWnMmm',
  '.mmmGGGGGGGGGGGGGmm.',
];

const _fairyPrincessPal = {
  'Y': Color(0xFFFCD000),
  'y': Color(0xFFFFF4A0),
  'M': Color(0xFFB070E0),
  'm': Color(0xFF7040A8),
  'n': Color(0xFFD8A8F8),
  'W': Color(0xFFFFE8F4),
  'w': Color(0xFFF0B8D8),
  'S': Color(0xFFF8D8C0),
  's': Color(0xFFE0B090),
  'K': Color(0xFF402060),
  'R': Color(0xFFE06080),
  'H': Color(0xFFF0C040),
  'G': Color(0xFF7CF0C0),
};
