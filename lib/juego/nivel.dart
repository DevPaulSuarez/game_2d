// EL NIVEL YA CONSTRUIDO: la cuadrícula de casillas, los tipos de casilla
// y dónde empieza cada enemigo, cofre, cristal y hada.
//
// Los mapas se escriben con letras en lib/escenarios/; escenario.dart los
// convierte en un LevelData.

import 'dart:math';

/// Tamaño de un tile en píxeles del mundo.
const double T = 16;

/// Filas visibles de la pantalla (15 x 16 = 240 px de alto).
const int kRows = 15;

class Tile {
  static const empty = 0;

  /// Tierra: sólida por todos lados. El dibujo (hierba, bordes) se elige
  /// solo según lo que tenga alrededor.
  static const ground = 1;

  /// Roca: sólida, como la tierra, pero con otro dibujo.
  static const rock = 2;

  /// Cuesta que sube hacia la derecha ( / ).
  static const slopeUp = 3;

  /// Cuesta que baja hacia la derecha ( \ ).
  static const slopeDown = 4;

  /// Rama: solo se pisa desde arriba; desde abajo se atraviesa al saltar.
  static const platform = 5;

  /// Bloquea el paso por los lados y por abajo (tierra y roca).
  static bool isSolid(int t) => t == ground || t == rock;

  static bool isSlope(int t) => t == slopeUp || t == slopeDown;

  /// Altura de la superficie de una cuesta dentro de su casilla (0 = arriba
  /// del todo, T = abajo del todo), a [lx] píxeles de su borde izquierdo.
  static double slopeSurface(int t, double lx) {
    final x = lx.clamp(0.0, T);
    return t == slopeUp ? T - x : x;
  }
}

enum EnemyKind { goblin, rat, mage, darkArcher }

/// Aspecto de un escenario: colores del cielo, del terreno y decorado.
enum Tema {
  /// Bosque de día: hierba verde, tierra marrón, ramas y rocas con musgo.
  bosque,

  /// Bosque encantado al anochecer: hierba turquesa, raíces que brillan y
  /// piedras con runas.
  hadas,
}

class EnemySpawn {
  final int x, y;
  final EnemyKind kind;
  const EnemySpawn(this.x, this.y, this.kind);
}

/// Cofre en el suelo: da cristales o una poción.
class CofreSpawn {
  final int x, y;
  final bool pocion;
  const CofreSpawn(this.x, this.y, {required this.pocion});
}

class LevelData {
  final int width;
  final List<List<int>> grid; // grid[y][x]
  final List<EnemySpawn> enemies;
  final List<Point<int>> cristales;
  final List<Point<int>> hadas;
  final List<CofreSpawn> cofres;

  /// Columna donde empieza el portal de la meta.
  final int metaX;
  final Tema tema;

  LevelData({
    required this.width,
    required this.grid,
    required this.enemies,
    required this.cristales,
    this.hadas = const [],
    this.cofres = const [],
    required this.metaX,
    this.tema = Tema.bosque,
  });

  /// Primera fila (desde arriba) con suelo en la columna [x], o null si
  /// ahí hay un precipicio.
  int? filaSuelo(int x) {
    if (x < 0 || x >= width) return null;
    for (var y = 0; y < kRows; y++) {
      final t = grid[y][x];
      if (Tile.isSolid(t) || Tile.isSlope(t)) return y;
    }
    return null;
  }
}
