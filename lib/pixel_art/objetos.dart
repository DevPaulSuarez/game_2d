// DIBUJOS DE LOS OBJETOS: cristales, cofres, corazones, el alma y las
// hadas que curan.

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'herramientas.dart';

class DibujosObjetos {
  /// Cristal para recoger: 4 cuadros con el destello en otro sitio.
  final cristal = [for (var i = 0; i < 4; i++) _buildCristal(i)];
  final cofre = _buildCofre(abierto: false);
  final cofreAbierto = _buildCofre(abierto: true);

  /// Fragmento del corazón de la princesa (la recompensa de cada stage).
  final fragmentoCorazon = desdeMapa(_heartFragment, const {
    'P': Pal.pink,
    '1': Pal.heartRed,
    '2': Color(0xFF101014),
  });

  /// Fragmento del alma (la otra recompensa).
  final alma = desdeMapa(_soul, const {
    'C': Pal.soul,
    'W': Color(0xFFE8FCFF),
    'D': Color(0xFF2890C8),
    'L': Color(0xFF9CECFC),
  });

  /// Corazones de la vida (arriba a la izquierda).
  final corazonLleno = desdeMapa(_heartSmall, const {
    'R': Pal.heartRed,
    'W': Color(0xFFFFC0C8),
  });
  final corazonVacio = desdeMapa(_heartSmall, const {
    'R': Color(0xFF3A3A48),
    'W': Color(0xFF5A5A68),
  });

  /// Hada que cura: alas arriba y alas abajo.
  final hada = [
    desdeMapa(_fairyUp, _fairyPal),
    desdeMapa(_fairyDown, _fairyPal),
  ];
}

/// Cristal para recoger; [brillo] mueve el destello (animación).
ui.Image _buildCristal(int brillo) {
  final filas = [..._cristal];
  final y = 2 + brillo * 2, x = 3 + brillo;
  filas[y] = filas[y].replaceRange(x, x + 1, 'W');
  return desdeMapa(filas, const {
    'C': Color(0xFF5CD8F8),
    'c': Color(0xFF2890C8),
    'L': Color(0xFFB8F4FF),
    'W': Color(0xFFFFFFFF),
    'D': Color(0xFF1A5A98),
  });
}

/// Cofre de madera con herrajes dorados.
ui.Image _buildCofre({required bool abierto}) =>
    desdeMapa(abierto ? _cofreAbierto : _cofre, const {
      'M': Color(0xFF8A5A2A),
      'm': Color(0xFF5A3614),
      'L': Color(0xFFB07A3A),
      'G': Color(0xFFFCC838),
      'g': Color(0xFFB8860B),
      'K': Color(0xFF1A0E06),
      'Y': Color(0xFFFFF4A0),
    });

/// Corazón roto: negro con bordes rosas incompletos.
/// '1' es el fragmento recuperado (rojo), 'q' son huecos del borde.
const _heartFragment = [
  '..PPqP....PPPP..',
  '.P1111P..q2222P.',
  'P111111PP222222P',
  'P1111112222222qP',
  'P11111122222222P',
  'P11111222222222P',
  '.P111222222222P.',
  '..q2222222222P..',
  '...P22222222P...',
  '....q222222P....',
  '.....P2222P.....',
  '......P22q......',
  '.......PP.......',
];

const _heartSmall = [
  '.RR.RR.',
  'RWRRRRR',
  'RRRRRRR',
  '.RRRRR.',
  '..RRR..',
  '...R...',
];

/// Alma: diamante hexagonal celeste.
const _soul = [
  '.....WC.....',
  '....WWCC....',
  '...WWCCCC...',
  '..WWCCCCCD..',
  '.WWCCCCCCDD.',
  'WWCCCCCCCDDD',
  'WCCCCCCCCCDD',
  'WCCCCCCCCCDD',
  'WCCCCCCCCCDD',
  'WCCCCCCCCCDD',
  'LCCCCCCCCDDD',
  '.LCCCCCCDDD.',
  '..LCCCCDDD..',
  '...LCCDDD...',
  '....LCDD....',
  '.....DD.....',
];

/// Hada: alas arriba y alas abajo.
const _fairyUp = [
  '.WW.HHHH.WW.',
  'WWWwHHHHwWWW',
  'WWWwSKKSwWWW',
  '.WWwSSSSwWW.',
  '..wwDDDDww..',
  '...DDDDDD...',
  '....DDDD....',
  '...DDDDDD...',
  '...dDDDDd...',
  '....S..S....',
];

final _fairyDown = parche(_fairyUp, 0, const [
  '....HHHH....',
  '....HHHH....',
  '.WWwSKKSwWW.',
  'WWWwSSSSwWWW',
  'WWWwDDDDwWWW',
  '.WWDDDDDDWW.',
]);

const _fairyPal = {
  'W': Color(0xFFD8F4FF),
  'w': Color(0xFF8AD0F0),
  'H': Color(0xFFFF9AD0),
  'S': Color(0xFFF8D8C0),
  'K': Color(0xFF203050),
  'D': Color(0xFF7CF0C0),
  'd': Color(0xFF3CB890),
};

/// Cristal (el destello se sustituye en cada cuadro de la animación).
const _cristal = [
  '....CC....',
  '...CLCc...',
  '..CLLCcc..',
  '.CLLCCccc.',
  'CLLCCCcccD',
  'CLCCCCcccD',
  'CCCCCcccDD',
  '.CCCcccDD.',
  '..CccccD..',
  '...cccD...',
  '....cD....',
  '..........',
];

const _cofre = [
  '.KKKKKKKKKKKK.',
  'KLLLLGGLLLLLLK',
  'KMMMMGGMMMMMMK',
  'KmmmmGGmmmmmmK',
  'KKKKKGGKKKKKKK',
  'KMMMMgYgMMMMMK',
  'KMMMMgggMMMMMK',
  'KMMMMMGMMMMMMK',
  'KmmmmmGmmmmmmK',
  'KmmmmmGmmmmmmK',
  'KKKKKKKKKKKKKK',
];

const _cofreAbierto = [
  '.KKKKKKKKKKKK.',
  'KmmmmGGmmmmmmK',
  'KMMMMGGMMMMMMK',
  'KLLLLGGLLLLLLK',
  '.KKKKKKKKKKKK.',
  'KYYYYYYYYYYYYK',
  'KKKKKKKKKKKKKK',
  'KMMMMMGMMMMMMK',
  'KMMMMMGMMMMMMK',
  'KmmmmmGmmmmmmK',
  'KmmmmmGmmmmmmK',
  'KKKKKKKKKKKKKK',
];
