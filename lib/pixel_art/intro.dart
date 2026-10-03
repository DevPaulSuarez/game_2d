// DIBUJOS DE LA INTRO: la casa de la princesa, el jardín, el farol, los
// pinos del fondo, la poción curativa y el corazón robado.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'herramientas.dart';

class DibujosIntro {
  final casa = _buildHouse();
  final pasto = _buildGrass();
  final tierra = _buildDirt();
  final farol = _buildLamp();
  final pino = _buildPine();
  final cerca = _buildFence();
  final rosa = desdeMapa(_rose, const {
    'R': Color(0xFFE02848),
    'r': Color(0xFF9A1028),
    'G': Pal.greenLight,
    'g': Pal.green,
  });
  final rosaBlanca = desdeMapa(_rose, const {
    'R': Color(0xFFF8F8FF),
    'r': Color(0xFFC8D0E8),
    'G': Pal.greenLight,
    'g': Pal.green,
  });

  /// La poción curativa que el arquero lanza a la princesa (verde).
  final pocion = desdeMapa(_potion, const {
    'K': Color(0xFF000000),
    'B': Color(0xFF8B5A2B),
    'W': Color(0xFFD8ECFF),
    'R': Color(0xFF3CD890),
  }, retoque: false);

  /// El corazón que el villano le roba a la princesa.
  final corazonGrande = desdeMapa(_heartBig, const {
    'R': Color(0xFFE81030),
    'W': Color(0xFFFFB0C0),
    'd': Color(0xFF8A0818),
  });
}

/// Casa de la princesa para la intro: cabaña de piedra con tejado azul.
ui.Image _buildHouse() => dibujarImagen(88, 76, (c, p) {
  const wall = Color(0xFFEFE2C0);
  const wallDark = Color(0xFFC8B890);
  const beam = Color(0xFF6A3E1E);
  const roof = Color(0xFF3A6BD0);
  const roofDark = Color(0xFF23449A);
  const roofLight = Color(0xFF6A9AF0);
  const stone = Color(0xFF8A8A98);
  const stoneDark = Color(0xFF5A5A68);
  const glow = Color(0xFFFCD878);
  // Chimenea
  rect(c, p, Pal.black, 60, 6, 12, 24);
  rect(c, p, stone, 61, 7, 10, 23);
  for (var y = 9.0; y < 30; y += 4) {
    rect(c, p, stoneDark, 61, y, 10, 1);
  }
  // Tejado a dos aguas con tejas
  for (var y = 0; y < 30; y++) {
    final half = 8.0 + y * 1.45;
    final yy = 8.0 + y;
    rect(c, p, Pal.black, 44 - half - 1, yy, half * 2 + 2, 1);
    final col = y % 4 == 3 ? roofDark : (y < 3 ? roofLight : roof);
    rect(c, p, col, 44 - half, yy, half * 2, 1);
    if (y % 4 == 1) {
      for (var x = 44 - half + (y % 8 == 1 ? 0 : 3); x < 44 + half; x += 6) {
        rect(c, p, roofDark, x.floorToDouble(), yy, 1, 3);
      }
    }
  }
  rect(c, p, roofLight, 43, 8, 2, 1);
  // Ventana redonda en el tejado (vidriera)
  rect(c, p, Pal.black, 39, 20, 10, 10);
  rect(c, p, const Color(0xFF8AC8FF), 40, 21, 8, 8);
  rect(c, p, Pal.gold, 43, 21, 2, 8);
  rect(c, p, Pal.gold, 40, 24, 8, 2);
  // Paredes con vigas de madera
  rect(c, p, Pal.black, 8, 38, 72, 38);
  rect(c, p, wall, 9, 38, 70, 30);
  for (var y = 42.0; y < 68; y += 5) {
    rect(c, p, wallDark, 9, y, 70, 1);
  }
  for (final x in [9.0, 30.0, 57.0, 77.0]) {
    rect(c, p, beam, x, 38, 2, 30);
  }
  rect(c, p, beam, 9, 38, 70, 2);
  // Zócalo de piedra
  rect(c, p, stone, 9, 68, 70, 8);
  for (var x = 9.0; x < 79; x += 7) {
    rect(c, p, stoneDark, x, 68, 1, 8);
  }
  rect(c, p, stoneDark, 9, 72, 70, 1);
  // Puerta en arco
  rect(c, p, Pal.black, 36, 48, 16, 28);
  rect(c, p, Pal.black, 38, 45, 12, 3);
  rect(c, p, const Color(0xFF7A4A1E), 37, 49, 14, 27);
  rect(c, p, const Color(0xFF7A4A1E), 39, 47, 10, 2);
  rect(c, p, const Color(0xFF5A3210), 44, 47, 1, 29);
  rect(c, p, Pal.gold, 48, 62, 2, 2);
  // Ventanas iluminadas con jardinera de rosas
  for (final wx in [14.0, 62.0]) {
    rect(c, p, Pal.black, wx, 46, 12, 12);
    rect(c, p, glow, wx + 1, 47, 10, 10);
    rect(c, p, const Color(0xFFFFF0B0), wx + 2, 48, 3, 3);
    rect(c, p, beam, wx + 5.5, 47, 1, 10);
    rect(c, p, beam, wx + 1, 51.5, 10, 1);
    rect(c, p, beam, wx - 1, 58, 14, 3);
    for (var i = 0; i < 4; i++) {
      rect(c, p, const Color(0xFFE02848), wx + i * 3.5, 56, 2, 2);
      rect(c, p, Pal.green, wx + 1 + i * 3.5, 57, 1, 1);
    }
  }
});

/// Pasto para la escena de la intro.
ui.Image _buildGrass() => dibujarImagen(16, 16, (c, p) {
  rect(c, p, const Color(0xFF6A4020), 0, 0, 16, 16);
  rect(c, p, const Color(0xFF3E7A20), 0, 0, 16, 5);
  rect(c, p, const Color(0xFF6AB030), 0, 0, 16, 2);
  for (var x = 0; x < 16; x += 3) {
    rect(c, p, const Color(0xFF3E7A20), x.toDouble(), 5, 1, 2.0 + x % 2);
    rect(c, p, const Color(0xFF8AD040), x + 1.0, 0, 1, 1);
  }
  rect(c, p, const Color(0xFF4A2A10), 3, 10, 3, 2);
  rect(c, p, const Color(0xFF8A8A98), 11, 12, 2, 2);
});

ui.Image _buildDirt() => dibujarImagen(16, 16, (c, p) {
  rect(c, p, const Color(0xFF5A3418), 0, 0, 16, 16);
  rect(c, p, const Color(0xFF3E220C), 5, 3, 3, 2);
  rect(c, p, const Color(0xFF7A7A88), 12, 9, 2, 2);
  rect(c, p, const Color(0xFF3E220C), 1, 12, 2, 2);
});

/// Farol encendido.
ui.Image _buildLamp() => dibujarImagen(12, 44, (c, p) {
  rect(c, p, Pal.black, 5, 10, 2, 34);
  rect(c, p, const Color(0xFF3A3A48), 3, 42, 6, 2);
  rect(c, p, Pal.black, 2, 2, 8, 10);
  rect(c, p, const Color(0xFFFCE890), 3, 4, 6, 7);
  rect(c, p, const Color(0xFFFFFFE0), 5, 5, 2, 4);
  rect(c, p, Pal.black, 1, 1, 10, 2);
  rect(c, p, Pal.black, 5, 0, 2, 1);
});

/// Pino en silueta (fondo).
ui.Image _buildPine() => dibujarImagen(28, 48, (c, p) {
  const col = Color(0xFF1A1A38);
  const hi = Color(0xFF26264A);
  rect(c, p, col, 12, 40, 4, 8);
  for (var tier = 0; tier < 3; tier++) {
    final top = tier * 11.0;
    for (var y = 0; y < 18; y++) {
      final half = 2.0 + y * 0.65 + tier * 1.5;
      rect(c, p, col, 14 - half, top + y, half * 2, 1);
      rect(c, p, hi, 14 - half, top + y, 1, 1);
    }
  }
});

/// Cerca de madera.
ui.Image _buildFence() => dibujarImagen(16, 14, (c, p) {
  const wood = Color(0xFFE8E0D0);
  const shade = Color(0xFFA8A090);
  for (final x in [1.0, 9.0]) {
    rect(c, p, Pal.black, x - 1, 0, 6, 14);
    rect(c, p, wood, x, 1, 4, 13);
    rect(c, p, shade, x + 3, 1, 1, 13);
  }
  rect(c, p, Pal.black, 0, 4, 16, 3);
  rect(c, p, wood, 0, 5, 16, 1);
  rect(c, p, Pal.black, 0, 9, 16, 3);
  rect(c, p, wood, 0, 10, 16, 1);
});

// Corazón robado (rojo brillante).
const _heartBig = [
  '..RRR...RRR..',
  '.RWWRR.RRRRd.',
  'RWWRRRRRRRRRd',
  'RWRRRRRRRRRRd',
  'RRRRRRRRRRRRd',
  '.RRRRRRRRRRd.',
  '..RRRRRRRRd..',
  '...RRRRRRd...',
  '....RRRRd....',
  '.....RRd.....',
  '......d......',
];

// Rosa (flor mariana) para el jardín.
const _rose = ['.RR.', 'RrRR', '.RR.', '.gG.', 'Gg..', '.g..'];

const _potion = [
  '....KKKK....',
  '....BBBB....',
  '....KWWK....',
  '....KWWK....',
  '...KWWWWK...',
  '..KRRRRRRK..',
  '.KRRWRRRRRK.',
  '.KRWWRRRRRK.',
  '.KRRRRRRRRK.',
  '.KRRRRRRRRK.',
  '..KRRRRRRK..',
  '...KKKKKK...',
];
