// DIBUJOS DE LOS ENEMIGOS y de lo que lanzan.
//
// Todos miran a la IZQUIERDA (el juego los voltea al ir a la derecha).
// Cada enemigo tiene un mapa base y sus otras poses cambian solo unas
// filas del mapa con parche(base, fila, filasNuevas).

import 'package:flutter/material.dart';

import 'herramientas.dart';

class DibujosEnemigos {
  // Duende
  final duende = desdeMapa(_goblin, _goblinPal);
  final duendeCamina = desdeMapa(_goblinWalk, _goblinPal);
  final duendeLanza = desdeMapa(_goblinThrow, _goblinPal);

  // Rata
  final rata = desdeMapa(_rat, _ratPal);
  final rataCamina = desdeMapa(_ratWalk, _ratPal);

  // Mago oscuro
  final mago = desdeMapa(_mage, _magePal);
  final magoCamina = desdeMapa(_mageWalk, _magePal);
  final magoLanza = desdeMapa(_mageCast, _magePal);

  // Arquero sombrío
  final arqueroSombrio = desdeMapa(_darkArcher, _darkArcherPal);
  final arqueroSombrioCamina = desdeMapa(_darkArcherWalk, _darkArcherPal);
  final arqueroSombrioDispara = desdeMapa(_darkArcherShoot, _darkArcherPal);

  // Lo que lanzan
  final piedra = desdeMapa(_rock, const {
    'O': Color(0xFF8A8A98),
    'W': Color(0xFFD0D0DC),
    'D': Color(0xFF4A4A58),
  });
  final bolaMagica = desdeMapa(_orb, const {
    'O': Color(0xFFB02CC8),
    'o': Color(0xFFFF6CE8),
    'W': Color(0xFFFFE8FC),
  }, retoque: false);
  final flechaEnemiga = desdeMapa(_enemyArrow, _darkArcherPal, retoque: false);
}

// ---------------------------------------------------------------------------
// Duende y rata (Stage 1)
// ---------------------------------------------------------------------------

const _goblin = [
  '................',
  '......gggg......',
  'g...gGGGGGGg...g',
  'Gg.gGGGGGGGGg.gG',
  '.GgGRKGGGRKGGgG.',
  '..GGRRGGGRRGGG..',
  '...GGGGGGGGGG...',
  '...GGKTKTKGGG...',
  '....GGGGGGGG....',
  '...BBBBBBBBBB...',
  '..GBBBBYBBBBBG..',
  '..GBBBBBBBBBBG..',
  '...BBBBBBBBBB...',
  '....gg....gg....',
  '...ggg....ggg...',
  '..KKKK....KKKK..',
];

final _goblinWalk = parche(_goblin, 13, const [
  '.....gg..gg.....',
  '.....ggg.ggg....',
  '....KKKK.KKKK...',
]);

final _goblinThrow = parche(_goblin, 5, const [
  '..GGRRGGGRRGGGOO',
  '...GGGGGGGGGG.OO',
  '...GGKTKTKGGGG..',
  '....GGGGGGGGGG..',
  '...BBBBBBBBBBG..',
  '..GBBBBYBBBBB...',
]);

const _goblinPal = {
  'G': Color(0xFF6BBF3A),
  'g': Color(0xFF2F6B1A),
  'R': Color(0xFFE82020),
  'K': Color(0xFF000000),
  'T': Color(0xFFFCFCFC),
  'B': Color(0xFF7A4A1E),
  'Y': Color(0xFFB8B8B8),
  'O': Color(0xFF9A9AA8),
};

const _rat = [
  '................',
  '...DD...........',
  '..DMMD..........',
  '.DMMMMMMMMD.....',
  'DKMMMMMMMMMD....',
  'PMMMMMMMMMMMD...',
  '.DMMMMMMMMMMMDTT',
  '..DMMMMMMMMMD..T',
  '...PP..PP.PP....',
];

final _ratWalk = parche(_rat, 8, const ['..PP..PP..PP....']);

const _ratPal = {
  'M': Color(0xFF8A8A9A),
  'D': Color(0xFF4A4A5A),
  'K': Color(0xFF000000),
  'P': Color(0xFFF0A0B0),
  'T': Color(0xFFE08898),
};

// ---------------------------------------------------------------------------
// Mago oscuro y arquero sombrío (Stage 2)
// ---------------------------------------------------------------------------

/// Mago oscuro: sombrero puntiagudo, cara en sombra con ojos que brillan y
/// bastón con un orbe mágico. Mira a la izquierda.
const _mage = [
  '.oO.............',
  'oOOo.....PP.....',
  '.OO.....PPPp....',
  '..S....PPPPp....',
  '..S...PPPPPPp...',
  '..S..PPPPPPPPp..',
  '..S.GGGGGGGGGGG.',
  '..S..KKKKKKKKp..',
  '..S..KEKKKEKKp..',
  '..S..KKKKKKKKp..',
  '..SHHPPPPPPPPp..',
  '..SHPPVPPPPPPPp.',
  '..S.PPVPPGPPPPp.',
  '..S.PPVPPGPPPPp.',
  '..S.PPVPPGPPPPp.',
  '..S.PPVPPGPPPPPp',
  '..SPPPVPPGPPPPPp',
  '..SPPVVPPGPPPPPp',
  '..SPPVPPPGPPPPPp',
  '..SPPPPPPGPPPPPp',
  '..S.pppppppppp..',
  '..S..KK....KK...',
];

final _mageWalk = parche(_mage, 20, const [
  '..S.pppppppppp..',
  '..S.KK......KK..',
]);

final _mageCast = parche(_mage, 0, const [
  '.oWo............',
  'oWWWo....PP.....',
  '.oWo....PPPp....',
]);

const _magePal = {
  'P': Color(0xFF4A2A7A),
  'p': Color(0xFF2E1A52),
  'V': Color(0xFF7A50C0),
  'G': Color(0xFFE8B030),
  'K': Color(0xFF140A24),
  'E': Color(0xFF7CF8FF),
  'S': Color(0xFF7A4A1E),
  'H': Color(0xFFB0C8A0),
  'O': Color(0xFFFF5CE0),
  'o': Color(0xFFFFB8F4),
  'W': Color(0xFFFFFFFF),
};

/// Arquero sombrío: capucha, ojos rojos, arco delante. Mira a la izquierda.
const _darkArcher = [
  '.......CCC....',
  '......CCCCc...',
  '.....CCCCCCc..',
  '.B...CKKKKCc..',
  'B.W..CKRKRKcQ.',
  'B.W..CKKKKCcQQ',
  'B..W.cCCCCcQQ.',
  'BSSCCCCLCCCcQ.',
  'BSS.WCCLCCCcQ.',
  'B..W.CCLCCCCc.',
  'B..W.CCLCCCCc.',
  'B.W..CCLCCCCc.',
  'B.W.CCCLCCCCc.',
  '.B..CCCLCCCCCc',
  '....CCLCCCCCCc',
  '....cccccccccc',
  '.....KK...KK..',
  '.....KK...KK..',
  '.....bb...bb..',
  '....bbb..bbb..',
];

final _darkArcherWalk = parche(_darkArcher, 16, const [
  '....KK.....KK.',
  '....KK.....KK.',
  '...bb......bb.',
  '..bbb.....bbb.',
]);

final _darkArcherShoot = parche(_darkArcher, 7, const [
  'AAAAAAWLCCCcQ.',
  'BSS..WCLCCCcQ.',
]);

const _darkArcherPal = {
  'C': Color(0xFF3A3F5A),
  'c': Color(0xFF22263A),
  'L': Color(0xFF5A6488),
  'K': Color(0xFF0A0A14),
  'R': Color(0xFFFF3040),
  'B': Color(0xFF8A5A2A),
  'W': Color(0xFFD8D8E8),
  'A': Color(0xFFB8B8C8),
  'S': Color(0xFFC8C0B0),
  'Q': Color(0xFF6A3E1E),
  'b': Color(0xFF2A1A10),
};

// ---------------------------------------------------------------------------
// Proyectiles
// ---------------------------------------------------------------------------

/// Piedra que lanza el duende.
const _rock = ['.OOOO.', 'OWOOOO', 'OOOOOD', 'OOOODD', '.ODDD.'];

/// Flecha enemiga (apunta a la izquierda).
const _enemyArrow = ['.A.......F', 'AABBBBBBFF', '.A.......F'];

/// Bola mágica.
const _orb = [
  '..OOOO..',
  '.OooooO.',
  'OooWWooO',
  'OoWWWWoO',
  'OoWWWWoO',
  'OooWWooO',
  '.OooooO.',
  '..OOOO..',
];
