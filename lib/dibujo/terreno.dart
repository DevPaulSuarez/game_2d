// EL TERRENO: dibuja cada casilla del mapa (tierra, cuestas, rocas y
// ramas) con los dibujos del tema del escenario (lib/pixel_art/terreno.dart).

import 'dart:math' as math;
import 'dart:ui' as ui;

import '../juego/juego.dart';
import 'pincel.dart';

/// Cada casilla elige su dibujo mirando a sus vecinas: la tierra lleva
/// hierba si tiene cielo encima y borde si tiene un hueco al lado.
void dibujarTerreno(Pincel p, double cam, double viewW) {
  final game = p.game;
  final t = p.hadas ? p.pixel.terrenoHadas : p.pixel.terrenoBosque;
  final x0 = math.max(0, (cam / T).floor());
  final x1 = math.min(game.level.width - 1, ((cam + viewW) / T).ceil());

  // Casilla (tx, ty); fuera del mapa por los lados cuenta como tierra.
  int tile(int tx, int ty) {
    if (tx < 0 || tx >= game.level.width) return Tile.ground;
    if (ty < 0 || ty >= kRows) return Tile.empty;
    return game.grid[ty][tx];
  }

  bool hueco(int tile) => tile == Tile.empty || tile == Tile.platform;
  for (var ty = 0; ty < kRows; ty++) {
    for (var tx = x0; tx <= x1; tx++) {
      final ui.Image? img = switch (game.grid[ty][tx]) {
        Tile.ground =>
          t.tierra[(hueco(tile(tx, ty - 1)) ? 1 : 0) +
              (hueco(tile(tx - 1, ty)) ? 2 : 0) +
              (hueco(tile(tx + 1, ty)) ? 4 : 0)],
        Tile.slopeUp => t.cuestaSube,
        Tile.slopeDown => t.cuestaBaja,
        Tile.rock => tile(tx, ty - 1) == Tile.rock ? t.roca : t.rocaArriba,
        Tile.platform =>
          t.rama[(tile(tx - 1, ty) != Tile.platform ? 1 : 0) +
              (tile(tx + 1, ty) != Tile.platform ? 2 : 0)],
        _ => null,
      };
      if (img != null) p.img(img, tx * T, ty * T);
    }
  }
}
