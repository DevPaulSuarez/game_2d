import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Colores base de la paleta estilo NES.
class Pal {
  static const sky = Color(0xFF6B8CFF);
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFCFCFC);
  static const brick = Color(0xFFC84C0C);
  static const brickLight = Color(0xFFFCBCB0);
  static const brickDark = Color(0xFF7C2800);
  static const gold = Color(0xFFFCD000);
  static const green = Color(0xFF00A800);
  static const greenLight = Color(0xFF80D010);
  static const greenDark = Color(0xFF005000);
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

/// Construye una imagen a partir de un mapa de caracteres.
/// Cada carácter se traduce a un color de la paleta ('.' = transparente).
/// [dress] aplica modelado de volumen y contorno selectivo; se desactiva en
/// tiles que deben encajar sin costura.
ui.Image _fromMap(
  List<String> rows,
  Map<String, Color> pal, {
  bool dress = true,
}) {
  var g = _gridFromMap(rows, pal);
  if (dress) g = _outline(_model(g));
  return _imageFromGrid(g);
}

ui.Image _fromDraw(int w, int h, void Function(Canvas c, Paint p) draw) {
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  final p = Paint()..isAntiAlias = false;
  draw(c, p);
  return rec.endRecording().toImageSync(w, h);
}

void _rect(
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
List<String> _patch(List<String> base, int from, List<String> rows) => [
  ...base.sublist(0, from),
  ...rows,
  ...base.sublist(from + rows.length),
];

// ---------------------------------------------------------------------------
// Figura de la princesa de las hadas (los colores van en _fairyPrincessPal).
// La princesa celestial y su fantasma usan las imágenes de su hoja
// (lib/personajes/princesa/).
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Enemigos (miran a la izquierda)
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

final _goblinWalk = _patch(_goblin, 13, const [
  '.....gg..gg.....',
  '.....ggg.ggg....',
  '....KKKK.KKKK...',
]);

final _goblinThrow = _patch(_goblin, 5, const [
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

final _ratWalk = _patch(_rat, 8, const ['..PP..PP..PP....']);

const _ratPal = {
  'M': Color(0xFF8A8A9A),
  'D': Color(0xFF4A4A5A),
  'K': Color(0xFF000000),
  'P': Color(0xFFF0A0B0),
  'T': Color(0xFFE08898),
};

// ---------------------------------------------------------------------------
// Objetos
// ---------------------------------------------------------------------------

const _rock = ['.OOOO.', 'OWOOOO', 'OOOOOD', 'OOOODD', '.ODDD.'];

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

// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Stage 2: Reino de las Hadas
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

final _mageWalk = _patch(_mage, 20, const [
  '..S.pppppppppp..',
  '..S.KK......KK..',
]);

final _mageCast = _patch(_mage, 0, const [
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

final _darkArcherWalk = _patch(_darkArcher, 16, const [
  '....KK.....KK.',
  '....KK.....KK.',
  '...bb......bb.',
  '..bbb.....bbb.',
]);

final _darkArcherShoot = _patch(_darkArcher, 7, const [
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

final _fairyDown = _patch(_fairyUp, 0, const [
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

/// Princesa de las hadas: vestido lila y pelo dorado.
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

/// Colores del terreno de cada tema.
class _Terreno {
  final Color hierba, hierbaLuz, hierbaSombra;
  final Color tierra, tierraSombra, tierraLuz, contorno, mota;
  const _Terreno({
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

const _terrenoBosque = _Terreno(
  hierba: Color(0xFF6AB83A),
  hierbaLuz: Color(0xFFB5E061),
  hierbaSombra: Color(0xFF3E7A20),
  tierra: Color(0xFF7A4A24),
  tierraSombra: Color(0xFF55301A),
  tierraLuz: Color(0xFF9A6434),
  contorno: Color(0xFF2A160A),
  mota: Color(0xFF9A9AA8),
);

const _terrenoHadas = _Terreno(
  hierba: Color(0xFF3CC8A0),
  hierbaLuz: Color(0xFF8AF0C8),
  hierbaSombra: Color(0xFF1E7A6A),
  tierra: Color(0xFF3A2458),
  tierraSombra: Color(0xFF26163E),
  tierraLuz: Color(0xFF4E3470),
  contorno: Color(0xFF140A24),
  mota: Color(0xFF7CE0F8),
);

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

class Sprites {
  // Historia
  late final ui.Image potionEvil, potionGood, heartBig, rose, whiteRose;
  late final ui.Image grass, dirt, lamp, pine, fence;
  // Enemigos
  late final ui.Image goblin, goblinWalk, goblinThrow, rat, ratWalk;
  // Proyectiles y objetos
  late final ui.Image rock, heartFragment, heartFull, heartEmpty, soul;
  // Terreno, objetos y meta de cada tema
  late final Terreno terrenoBosque, terrenoHadas;
  late final List<ui.Image> cristal;
  late final ui.Image cofre, cofreAbierto;
  late final ui.Image portalBosque, portalHadas;
  late final ui.Image helecho, florBosque, matoHierba;
  // Decoración
  late final ui.Image house;
  // Stage 2: Reino de las Hadas
  late final ui.Image mage, mageWalk, mageCast;
  late final ui.Image darkArcher, darkArcherWalk, darkArcherShoot;
  late final ui.Image orb, enemyArrow, fairyPrincess;
  late final List<ui.Image> fairy;
  late final ui.Image glowFlower, tinyMushroom;

  Sprites() {
    heartBig = _fromMap(_heartBig, const {
      'R': Color(0xFFE81030),
      'W': Color(0xFFFFB0C0),
      'd': Color(0xFF8A0818),
    });
    rose = _fromMap(_rose, const {
      'R': Color(0xFFE02848),
      'r': Color(0xFF9A1028),
      'G': Pal.greenLight,
      'g': Pal.green,
    });
    whiteRose = _fromMap(_rose, const {
      'R': Color(0xFFF8F8FF),
      'r': Color(0xFFC8D0E8),
      'G': Pal.greenLight,
      'g': Pal.green,
    });

    goblin = _fromMap(_goblin, _goblinPal);
    goblinWalk = _fromMap(_goblinWalk, _goblinPal);
    goblinThrow = _fromMap(_goblinThrow, _goblinPal);
    rat = _fromMap(_rat, _ratPal);
    ratWalk = _fromMap(_ratWalk, _ratPal);

    rock = _fromMap(_rock, const {
      'O': Color(0xFF8A8A98),
      'W': Color(0xFFD0D0DC),
      'D': Color(0xFF4A4A58),
    });
    const potionBase = {
      'K': Color(0xFF000000),
      'B': Color(0xFF8B5A2B),
      'W': Color(0xFFD8ECFF),
    };
    potionEvil = _fromMap(_potion, {
      ...potionBase,
      'R': const Color(0xFF8A20C8),
    }, dress: false);
    // La poción curativa del arquero (verde)
    potionGood = _fromMap(_potion, {
      ...potionBase,
      'R': const Color(0xFF3CD890),
    }, dress: false);

    heartFragment = _fromMap(_heartFragment, const {
      'P': Pal.pink,
      '1': Pal.heartRed,
      '2': Color(0xFF101014),
    });
    heartFull = _fromMap(_heartSmall, const {
      'R': Pal.heartRed,
      'W': Color(0xFFFFC0C8),
    });
    heartEmpty = _fromMap(_heartSmall, const {
      'R': Color(0xFF3A3A48),
      'W': Color(0xFF5A5A68),
    });
    soul = _fromMap(_soul, const {
      'C': Pal.soul,
      'W': Color(0xFFE8FCFF),
      'D': Color(0xFF2890C8),
      'L': Color(0xFF9CECFC),
    });

    house = _buildHouse();
    grass = _buildGrass();
    dirt = _buildDirt();
    lamp = _buildLamp();
    pine = _buildPine();
    fence = _buildFence();

    mage = _fromMap(_mage, _magePal);
    mageWalk = _fromMap(_mageWalk, _magePal);
    mageCast = _fromMap(_mageCast, _magePal);
    darkArcher = _fromMap(_darkArcher, _darkArcherPal);
    darkArcherWalk = _fromMap(_darkArcherWalk, _darkArcherPal);
    darkArcherShoot = _fromMap(_darkArcherShoot, _darkArcherPal);
    enemyArrow = _fromMap(_enemyArrow, _darkArcherPal, dress: false);
    orb = _fromMap(_orb, const {
      'O': Color(0xFFB02CC8),
      'o': Color(0xFFFF6CE8),
      'W': Color(0xFFFFE8FC),
    }, dress: false);
    fairy = [_fromMap(_fairyUp, _fairyPal), _fromMap(_fairyDown, _fairyPal)];
    fairyPrincess = _fromMap(_princess, _fairyPrincessPal);
    glowFlower = _buildGlowFlower();
    tinyMushroom = _buildTinyMushroom();

    final runa = _buildRuneStone();
    terrenoBosque = Terreno(
      tierra: [for (var i = 0; i < 8; i++) _buildTierra(_terrenoBosque, i)],
      cuestaSube: _buildCuesta(_terrenoBosque, sube: true),
      cuestaBaja: _buildCuesta(_terrenoBosque, sube: false),
      rama: [for (var i = 0; i < 4; i++) _buildRama(i)],
      roca: _buildRoca(musgo: false),
      rocaArriba: _buildRoca(musgo: true),
    );
    terrenoHadas = Terreno(
      tierra: [for (var i = 0; i < 8; i++) _buildTierra(_terrenoHadas, i)],
      cuestaSube: _buildCuesta(_terrenoHadas, sube: true),
      cuestaBaja: _buildCuesta(_terrenoHadas, sube: false),
      rama: [for (var i = 0; i < 4; i++) _buildRaiz(i)],
      roca: runa,
      rocaArriba: runa,
    );
    cristal = [for (var i = 0; i < 4; i++) _buildCristal(i)];
    cofre = _buildCofre(abierto: false);
    cofreAbierto = _buildCofre(abierto: true);
    portalBosque = _buildPortal(
      hoja: const Color(0xFF4E9A2A),
      flor: const Color(0xFFFCE878),
    );
    portalHadas = _buildPortal(
      hoja: const Color(0xFF3CC8A0),
      flor: const Color(0xFFFF8AD0),
    );
    helecho = _buildHelecho();
    florBosque = _buildFlorBosque();
    matoHierba = _buildMatoHierba();
  }

  // ---- Terreno natural ----------------------------------------------------

  /// Casilla de tierra. [bordes]: 1 = cielo arriba, 2 = hueco a la
  /// izquierda, 4 = hueco a la derecha. Donde hay cielo sale hierba; donde
  /// hay hueco, un borde oscuro; y las esquinas se redondean.
  ui.Image _buildTierra(_Terreno c, int bordes) => _fromDraw(16, 16, (cv, p) {
    final arriba = bordes & 1 != 0;
    final izq = bordes & 2 != 0;
    final der = bordes & 4 != 0;
    _rect(cv, p, c.tierra, 0, 0, 16, 16);
    // Textura: vetas y piedrecitas.
    _rect(cv, p, c.tierraSombra, 2, 9, 3, 1);
    _rect(cv, p, c.tierraSombra, 9, 13, 4, 1);
    _rect(cv, p, c.tierraLuz, 11, 7, 2, 1);
    _rect(cv, p, c.tierraLuz, 4, 13, 1, 1);
    _rect(cv, p, c.mota, 12, 10, 1, 1);
    _rect(cv, p, c.mota, 6, 5, 1, 1);
    if (izq) {
      _rect(cv, p, c.contorno, 0, 0, 1, 16);
      _rect(cv, p, c.tierraSombra, 1, 0, 1, 16);
    }
    if (der) {
      _rect(cv, p, c.contorno, 15, 0, 1, 16);
      _rect(cv, p, c.tierraSombra, 14, 0, 1, 16);
    }
    if (arriba) {
      _rect(cv, p, c.hierbaSombra, 0, 0, 16, 5);
      _rect(cv, p, c.hierba, 0, 0, 16, 4);
      _rect(cv, p, c.hierbaLuz, 0, 0, 16, 1);
      // Hierba que cuelga sobre la tierra.
      for (final (x, h) in [(1, 2), (4, 3), (6, 1), (9, 2), (12, 3), (14, 1)]) {
        _rect(cv, p, c.hierbaSombra, x.toDouble(), 5, 1, h.toDouble());
      }
      if (izq) {
        _rect(cv, p, c.hierbaSombra, 0, 0, 2, 8);
        _rect(cv, p, c.hierba, 1, 1, 1, 5);
        p.blendMode = BlendMode.clear;
        _rect(cv, p, Pal.black, 0, 0, 2, 1);
        _rect(cv, p, Pal.black, 0, 1, 1, 1);
        p.blendMode = BlendMode.srcOver;
        _rect(cv, p, c.contorno, 2, 0, 1, 1);
        _rect(cv, p, c.contorno, 1, 1, 1, 1);
      }
      if (der) {
        _rect(cv, p, c.hierbaSombra, 14, 0, 2, 8);
        _rect(cv, p, c.hierba, 14, 1, 1, 5);
        p.blendMode = BlendMode.clear;
        _rect(cv, p, Pal.black, 14, 0, 2, 1);
        _rect(cv, p, Pal.black, 15, 1, 1, 1);
        p.blendMode = BlendMode.srcOver;
        _rect(cv, p, c.contorno, 13, 0, 1, 1);
        _rect(cv, p, c.contorno, 14, 1, 1, 1);
      }
    }
  });

  /// Cuesta de 45°: tierra por debajo de la diagonal y hierba encima.
  ui.Image _buildCuesta(_Terreno c, {required bool sube}) =>
      _fromDraw(16, 16, (cv, p) {
        for (var i = 0; i < 16; i++) {
          final x = (sube ? i : 15 - i).toDouble();
          final top = 15.0 - i;
          _rect(cv, p, c.tierra, x, top, 1, 16 - top);
          _rect(cv, p, c.hierbaSombra, x, top, 1, math.min(5, 16 - top));
          _rect(cv, p, c.hierba, x, top, 1, math.min(3, 16 - top));
          _rect(cv, p, c.hierbaLuz, x, top, 1, 1);
        }
        _rect(cv, p, c.mota, sube ? 12 : 3, 12, 1, 1);
        _rect(cv, p, c.tierraSombra, sube ? 9 : 4, 14, 3, 1);
      });

  /// Rama de árbol (bosque). [fin]: 1 = acaba a la izquierda, 2 = a la
  /// derecha. Solo ocupa la parte de arriba de la casilla.
  ui.Image _buildRama(int fin) => _fromDraw(16, 16, (c, p) {
    const corteza = Color(0xFF7A4A24);
    const oscura = Color(0xFF4A2A10);
    const luz = Color(0xFFA86A34);
    const hoja = Color(0xFF5AAA32);
    const hojaLuz = Color(0xFF9AD84A);
    final izq = fin & 1 != 0, der = fin & 2 != 0;
    final x0 = izq ? 2.0 : 0.0, x1 = der ? 14.0 : 16.0;
    _rect(c, p, oscura, x0, 0, x1 - x0, 7);
    _rect(c, p, corteza, x0, 1, x1 - x0, 5);
    _rect(c, p, luz, x0, 1, x1 - x0, 1);
    _rect(c, p, oscura, x0 + 3, 3, 4, 1);
    _rect(c, p, oscura, x0 + 9, 4, 2, 1);
    // Extremos cortados: se ve el anillo de la madera.
    if (izq) {
      _rect(c, p, oscura, 0, 1, 2, 5);
      _rect(c, p, const Color(0xFFD8B078), 1, 2, 1, 3);
    }
    if (der) {
      _rect(c, p, oscura, 14, 1, 2, 5);
      _rect(c, p, const Color(0xFFD8B078), 14, 2, 1, 3);
    }
    // Hojitas encima y colgando.
    _rect(c, p, hoja, 5, 0, 3, 1);
    _rect(c, p, hojaLuz, 6, 0, 1, 1);
    if (!der) {
      _rect(c, p, hoja, 11, 7, 2, 3);
      _rect(c, p, hojaLuz, 11, 7, 1, 1);
    }
  });

  /// Raíz que brilla (Reino de las Hadas): hace de rama.
  ui.Image _buildRaiz(int fin) => _fromDraw(16, 16, (c, p) {
    const raiz = Color(0xFF5A3A6A);
    const oscura = Color(0xFF2E1A3A);
    const luz = Color(0xFF8A62A0);
    const vena = Color(0xFF7CF8FF);
    final izq = fin & 1 != 0, der = fin & 2 != 0;
    final x0 = izq ? 2.0 : 0.0, x1 = der ? 14.0 : 16.0;
    _rect(c, p, oscura, x0, 0, x1 - x0, 7);
    _rect(c, p, raiz, x0, 1, x1 - x0, 5);
    _rect(c, p, luz, x0, 1, x1 - x0, 1);
    _rect(c, p, vena, x0 + 2, 3, 5, 1);
    _rect(c, p, vena, x0 + 7, 4, 3, 1);
    if (izq) _rect(c, p, oscura, 1, 2, 1, 3);
    if (der) _rect(c, p, oscura, 14, 2, 1, 3);
    // Florecita y zarcillo colgando
    _rect(c, p, const Color(0xFFFF8AD0), 6, 0, 2, 1);
    if (!izq) {
      _rect(c, p, const Color(0xFF3CC8A0), 3, 7, 1, 4);
      _rect(c, p, vena, 3, 11, 1, 1);
    }
  });

  /// Roca del bosque: piedra gris redondeada, con musgo si da al cielo.
  ui.Image _buildRoca({required bool musgo}) => _fromDraw(16, 16, (c, p) {
    const piedra = Color(0xFF8A8A98);
    const luz = Color(0xFFB8B8C8);
    const sombra = Color(0xFF5A5A6A);
    const contorno = Color(0xFF2A2A38);
    _rect(c, p, contorno, 1, 0, 14, 16);
    _rect(c, p, contorno, 0, 1, 16, 14);
    _rect(c, p, piedra, 1, 1, 14, 14);
    _rect(c, p, luz, 2, 2, 5, 2);
    _rect(c, p, luz, 2, 4, 2, 3);
    _rect(c, p, sombra, 1, 12, 14, 3);
    _rect(c, p, sombra, 12, 2, 3, 12);
    _rect(c, p, sombra, 6, 8, 3, 1);
    if (musgo) {
      _rect(c, p, const Color(0xFF3E7A20), 1, 0, 14, 4);
      _rect(c, p, const Color(0xFF6AB83A), 2, 0, 11, 2);
      _rect(c, p, const Color(0xFF3E7A20), 4, 4, 1, 2);
      _rect(c, p, const Color(0xFF3E7A20), 10, 4, 1, 3);
    }
  });

  /// Cristal para recoger; [brillo] mueve el destello (animación).
  ui.Image _buildCristal(int brillo) {
    final filas = [..._cristal];
    final y = 2 + brillo * 2, x = 3 + brillo;
    filas[y] = filas[y].replaceRange(x, x + 1, 'W');
    return _fromMap(filas, const {
      'C': Color(0xFF5CD8F8),
      'c': Color(0xFF2890C8),
      'L': Color(0xFFB8F4FF),
      'W': Color(0xFFFFFFFF),
      'D': Color(0xFF1A5A98),
    });
  }

  /// Cofre de madera con herrajes dorados.
  ui.Image _buildCofre({required bool abierto}) =>
      _fromMap(abierto ? _cofreAbierto : _cofre, const {
        'M': Color(0xFF8A5A2A),
        'm': Color(0xFF5A3614),
        'L': Color(0xFFB07A3A),
        'G': Color(0xFFFCC838),
        'g': Color(0xFFB8860B),
        'K': Color(0xFF1A0E06),
        'Y': Color(0xFFFFF4A0),
      });

  /// Portal antiguo de piedra: dos columnas con runas y un arco. El hueco
  /// central (x 20..60) queda vacío para que se vea la magia de detrás.
  ui.Image _buildPortal({required Color hoja, required Color flor}) =>
      _fromDraw(80, 96, (c, p) {
        const piedra = Color(0xFFA8A0B8);
        const luz = Color(0xFFD0C8E0);
        const sombra = Color(0xFF6A6280);
        const contorno = Color(0xFF2A2438);
        const runa = Color(0xFF7CF8FF);
        void bloque(double x, double y, double w, double h) {
          _rect(c, p, contorno, x, y, w, h);
          _rect(c, p, piedra, x + 1, y + 1, w - 2, h - 2);
          _rect(c, p, luz, x + 1, y + 1, w - 2, 1);
          _rect(c, p, sombra, x + 1, y + h - 2, w - 2, 1);
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
        _rect(c, p, runa, 38, 4, 4, 5);
        _rect(c, p, Pal.white, 38, 4, 2, 2);
        // Runas en las columnas
        for (final y in [46.0, 68.0]) {
          _rect(c, p, runa, 12, y, 2, 6);
          _rect(c, p, runa, 10, y + 2, 6, 1);
          _rect(c, p, runa, 66, y, 2, 6);
          _rect(c, p, runa, 64, y + 3, 6, 1);
        }
        // Enredadera con flores
        for (var y = 20.0; y < 92; y += 5) {
          final dx = (y ~/ 5).isEven ? 0.0 : 2.0;
          _rect(c, p, hoja, 4 + dx, y, 2, 3);
          _rect(c, p, hoja, 72 - dx, y + 2, 2, 3);
        }
        for (var y = 26.0; y < 90; y += 14) {
          _rect(c, p, flor, 3, y, 2, 2);
          _rect(c, p, flor, 74, y + 7, 2, 2);
        }
      });

  ui.Image _buildHelecho() => _fromDraw(16, 12, (c, p) {
    const h = Color(0xFF3E8A2A);
    const hl = Color(0xFF7BC043);
    for (final (x0, dir) in [
      (8.0, -1.0),
      (8.0, 1.0),
      (7.0, -0.4),
      (9.0, 0.4),
    ]) {
      for (var i = 0; i < 7; i++) {
        final x = x0 + dir * i;
        final y = 11.0 - i * 1.4 + (i * i) * 0.12;
        _rect(c, p, h, x.roundToDouble(), y.roundToDouble(), 1, 2);
        if (i.isOdd) {
          _rect(c, p, hl, x.roundToDouble(), y.roundToDouble(), 1, 1);
        }
      }
    }
  });

  ui.Image _buildFlorBosque() => _fromDraw(7, 10, (c, p) {
    _rect(c, p, const Color(0xFF3E7A20), 3, 3, 1, 7);
    _rect(c, p, const Color(0xFF6AB83A), 4, 6, 2, 1);
    _rect(c, p, const Color(0xFFF8F8FF), 1, 1, 5, 3);
    _rect(c, p, const Color(0xFFF8F8FF), 2, 0, 3, 5);
    _rect(c, p, const Color(0xFFFCD000), 3, 2, 1, 1);
  });

  ui.Image _buildMatoHierba() => _fromDraw(10, 6, (c, p) {
    const h = Color(0xFF4E9A2A);
    const hl = Color(0xFF9AD84A);
    for (final (x, top) in [(1, 3), (3, 0), (5, 2), (7, 1), (8, 3)]) {
      _rect(c, p, h, x.toDouble(), top.toDouble(), 1, 6 - top.toDouble());
      _rect(c, p, hl, x.toDouble(), top.toDouble(), 1, 1);
    }
  });

  // ---- Stage 2: Reino de las Hadas ---------------------------------------

  /// Bloque duro: piedra azulada con una runa que brilla.
  ui.Image _buildRuneStone() => _fromDraw(16, 16, (c, p) {
    const base = Color(0xFF4A5A8A);
    const light = Color(0xFF8A9ACA);
    const dark = Color(0xFF2A3258);
    _rect(c, p, base, 0, 0, 16, 16);
    for (var i = 0; i < 2; i++) {
      final d = i.toDouble();
      _rect(c, p, light, d, d, 16 - d * 2, 1);
      _rect(c, p, light, d, d, 1, 16 - d * 2);
      _rect(c, p, dark, d, 15 - d, 16 - d * 2, 1);
      _rect(c, p, dark, 15 - d, d, 1, 16 - d * 2);
    }
    const rune = Color(0xFF7CF8FF);
    _rect(c, p, rune, 7, 4, 2, 8);
    _rect(c, p, rune, 5, 6, 6, 1);
    _rect(c, p, rune, 5, 10, 2, 1);
    _rect(c, p, rune, 9, 10, 2, 1);
  });

  /// Flor que brilla (decorado del suelo).
  ui.Image _buildGlowFlower() => _fromDraw(9, 12, (c, p) {
    _rect(c, p, const Color(0xFF1E7A6A), 4, 4, 1, 8);
    _rect(c, p, const Color(0xFF3CC8A0), 1, 8, 3, 2);
    _rect(c, p, const Color(0xFF3CC8A0), 5, 6, 3, 2);
    _rect(c, p, const Color(0xFF7CE0F8), 2, 0, 5, 5);
    _rect(c, p, const Color(0xFF7CE0F8), 3, -1, 3, 7);
    _rect(c, p, const Color(0xFFFFFFFF), 4, 2, 1, 1);
  });

  /// Setita (decorado del suelo).
  ui.Image _buildTinyMushroom() => _fromDraw(10, 9, (c, p) {
    _rect(c, p, Pal.black, 0, 1, 10, 4);
    _rect(c, p, Pal.black, 2, 0, 6, 1);
    _rect(c, p, const Color(0xFFD83A78), 1, 1, 8, 3);
    _rect(c, p, const Color(0xFFFFF4F8), 3, 1, 2, 1);
    _rect(c, p, const Color(0xFFFFF4F8), 6, 2, 1, 1);
    _rect(c, p, Pal.black, 3, 5, 4, 4);
    _rect(c, p, const Color(0xFFF0E0C8), 4, 5, 2, 4);
  });

  /// Casa de la princesa para la intro: cabaña de piedra con tejado azul.
  ui.Image _buildHouse() => _fromDraw(88, 76, (c, p) {
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
    _rect(c, p, Pal.black, 60, 6, 12, 24);
    _rect(c, p, stone, 61, 7, 10, 23);
    for (var y = 9.0; y < 30; y += 4) {
      _rect(c, p, stoneDark, 61, y, 10, 1);
    }
    // Tejado a dos aguas con tejas
    for (var y = 0; y < 30; y++) {
      final half = 8.0 + y * 1.45;
      final yy = 8.0 + y;
      _rect(c, p, Pal.black, 44 - half - 1, yy, half * 2 + 2, 1);
      final col = y % 4 == 3 ? roofDark : (y < 3 ? roofLight : roof);
      _rect(c, p, col, 44 - half, yy, half * 2, 1);
      if (y % 4 == 1) {
        for (var x = 44 - half + (y % 8 == 1 ? 0 : 3); x < 44 + half; x += 6) {
          _rect(c, p, roofDark, x.floorToDouble(), yy, 1, 3);
        }
      }
    }
    _rect(c, p, roofLight, 43, 8, 2, 1);
    // Ventana redonda en el tejado (vidriera)
    _rect(c, p, Pal.black, 39, 20, 10, 10);
    _rect(c, p, const Color(0xFF8AC8FF), 40, 21, 8, 8);
    _rect(c, p, Pal.gold, 43, 21, 2, 8);
    _rect(c, p, Pal.gold, 40, 24, 8, 2);
    // Paredes con vigas de madera
    _rect(c, p, Pal.black, 8, 38, 72, 38);
    _rect(c, p, wall, 9, 38, 70, 30);
    for (var y = 42.0; y < 68; y += 5) {
      _rect(c, p, wallDark, 9, y, 70, 1);
    }
    for (final x in [9.0, 30.0, 57.0, 77.0]) {
      _rect(c, p, beam, x, 38, 2, 30);
    }
    _rect(c, p, beam, 9, 38, 70, 2);
    // Zócalo de piedra
    _rect(c, p, stone, 9, 68, 70, 8);
    for (var x = 9.0; x < 79; x += 7) {
      _rect(c, p, stoneDark, x, 68, 1, 8);
    }
    _rect(c, p, stoneDark, 9, 72, 70, 1);
    // Puerta en arco
    _rect(c, p, Pal.black, 36, 48, 16, 28);
    _rect(c, p, Pal.black, 38, 45, 12, 3);
    _rect(c, p, const Color(0xFF7A4A1E), 37, 49, 14, 27);
    _rect(c, p, const Color(0xFF7A4A1E), 39, 47, 10, 2);
    _rect(c, p, const Color(0xFF5A3210), 44, 47, 1, 29);
    _rect(c, p, Pal.gold, 48, 62, 2, 2);
    // Ventanas iluminadas con jardinera de rosas
    for (final wx in [14.0, 62.0]) {
      _rect(c, p, Pal.black, wx, 46, 12, 12);
      _rect(c, p, glow, wx + 1, 47, 10, 10);
      _rect(c, p, const Color(0xFFFFF0B0), wx + 2, 48, 3, 3);
      _rect(c, p, beam, wx + 5.5, 47, 1, 10);
      _rect(c, p, beam, wx + 1, 51.5, 10, 1);
      _rect(c, p, beam, wx - 1, 58, 14, 3);
      for (var i = 0; i < 4; i++) {
        _rect(c, p, const Color(0xFFE02848), wx + i * 3.5, 56, 2, 2);
        _rect(c, p, Pal.green, wx + 1 + i * 3.5, 57, 1, 1);
      }
    }
  });

  /// Pasto para la escena de la intro.
  ui.Image _buildGrass() => _fromDraw(16, 16, (c, p) {
    _rect(c, p, const Color(0xFF6A4020), 0, 0, 16, 16);
    _rect(c, p, const Color(0xFF3E7A20), 0, 0, 16, 5);
    _rect(c, p, const Color(0xFF6AB030), 0, 0, 16, 2);
    for (var x = 0; x < 16; x += 3) {
      _rect(c, p, const Color(0xFF3E7A20), x.toDouble(), 5, 1, 2.0 + x % 2);
      _rect(c, p, const Color(0xFF8AD040), x + 1.0, 0, 1, 1);
    }
    _rect(c, p, const Color(0xFF4A2A10), 3, 10, 3, 2);
    _rect(c, p, const Color(0xFF8A8A98), 11, 12, 2, 2);
  });

  ui.Image _buildDirt() => _fromDraw(16, 16, (c, p) {
    _rect(c, p, const Color(0xFF5A3418), 0, 0, 16, 16);
    _rect(c, p, const Color(0xFF3E220C), 5, 3, 3, 2);
    _rect(c, p, const Color(0xFF7A7A88), 12, 9, 2, 2);
    _rect(c, p, const Color(0xFF3E220C), 1, 12, 2, 2);
  });

  /// Farol encendido.
  ui.Image _buildLamp() => _fromDraw(12, 44, (c, p) {
    _rect(c, p, Pal.black, 5, 10, 2, 34);
    _rect(c, p, const Color(0xFF3A3A48), 3, 42, 6, 2);
    _rect(c, p, Pal.black, 2, 2, 8, 10);
    _rect(c, p, const Color(0xFFFCE890), 3, 4, 6, 7);
    _rect(c, p, const Color(0xFFFFFFE0), 5, 5, 2, 4);
    _rect(c, p, Pal.black, 1, 1, 10, 2);
    _rect(c, p, Pal.black, 5, 0, 2, 1);
  });

  /// Pino en silueta (fondo).
  ui.Image _buildPine() => _fromDraw(28, 48, (c, p) {
    const col = Color(0xFF1A1A38);
    const hi = Color(0xFF26264A);
    _rect(c, p, col, 12, 40, 4, 8);
    for (var tier = 0; tier < 3; tier++) {
      final top = tier * 11.0;
      for (var y = 0; y < 18; y++) {
        final half = 2.0 + y * 0.65 + tier * 1.5;
        _rect(c, p, col, 14 - half, top + y, half * 2, 1);
        _rect(c, p, hi, 14 - half, top + y, 1, 1);
      }
    }
  });

  /// Cerca de madera.
  ui.Image _buildFence() => _fromDraw(16, 14, (c, p) {
    const wood = Color(0xFFE8E0D0);
    const shade = Color(0xFFA8A090);
    for (final x in [1.0, 9.0]) {
      _rect(c, p, Pal.black, x - 1, 0, 6, 14);
      _rect(c, p, wood, x, 1, 4, 13);
      _rect(c, p, shade, x + 3, 1, 1, 13);
    }
    _rect(c, p, Pal.black, 0, 4, 16, 3);
    _rect(c, p, wood, 0, 5, 16, 1);
    _rect(c, p, Pal.black, 0, 9, 16, 3);
    _rect(c, p, wood, 0, 10, 16, 1);
  });
}
