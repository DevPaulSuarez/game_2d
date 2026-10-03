// LA FÍSICA: cómo se mueve una caja ([Box]) por el mapa y choca con la
// tierra, las rocas, las cuestas y las ramas.
//
// Sirve para todos: el arquero, los enemigos... Se usa así:
//   nivel.mover(caja, dt)   mueve la caja según su velocidad (vx, vy)
//   nivel.esSolido(x, y)    ¿hay algo sólido en ese punto?
// (Game tiene atajos: mundo.mover(...) y mundo.esSolido(...)).

import 'ajustes.dart';
import 'entidades.dart';
import 'nivel.dart';

/// Con qué chocó una caja al moverse (lo devuelve [Fisica.mover]).
class Choque {
  bool pared = false;
}

extension Fisica on LevelData {
  /// ¿Hay algo sólido en el punto (x, y) del mundo? Cuenta la tierra, la
  /// roca y lo que queda por debajo de una cuesta; las ramas no.
  bool esSolido(double x, double y) {
    final tx = (x / T).floor(), ty = (y / T).floor();
    final t = _tile(tx, ty);
    if (Tile.isSlope(t)) return y - ty * T >= Tile.slopeSurface(t, x - tx * T);
    return Tile.isSolid(t);
  }

  int _tile(int tx, int ty) {
    if (tx < 0 || ty < 0 || tx >= width || ty >= kRows) {
      return Tile.empty;
    }
    return grid[ty][tx];
  }

  /// Casillas que cortan el paso por los lados y por arriba.
  bool _solid(int tx, int ty) {
    if (ty < 0 || ty >= kRows) return false;
    if (tx < 0 || tx >= width) return true;
    return Tile.isSolid(grid[ty][tx]);
  }

  /// Mueve la caja [b] según su velocidad y la para al chocar.
  Choque mover(Box b, double dt) {
    const escalon = AjustesJuego.escalon;
    final hit = Choque();
    final enSuelo = b.onGround;

    // 1. De lado. En el suelo se ignoran los pies (escalon) para poder
    //    subir cuestas.
    b.x += b.vx * dt;
    final top = (b.y / T).floor();
    final bot = ((b.bottom - (enSuelo ? escalon : 0.01)) / T).floor();
    if (b.vx > 0) {
      final tx = ((b.right - 0.01) / T).floor();
      for (var ty = top; ty <= bot; ty++) {
        if (_solid(tx, ty)) {
          b.x = tx * T - b.w;
          b.vx = 0;
          hit.pared = true;
          break;
        }
      }
    } else if (b.vx < 0) {
      final tx = (b.x / T).floor();
      for (var ty = top; ty <= bot; ty++) {
        if (_solid(tx, ty)) {
          b.x = (tx + 1) * T;
          b.vx = 0;
          hit.pared = true;
          break;
        }
      }
    }

    // 2. Arriba o abajo.
    b.y += b.vy * dt;
    b.onGround = false;
    if (b.vy >= 0) {
      final antes = b.bottom - b.vy * dt;
      final suelo = _suelo(
        b,
        desde: antes - (enSuelo ? escalon : 0),
        hasta: b.bottom + (enSuelo ? escalon : 0.05),
        antes: antes,
      );
      if (suelo != null) {
        b.y = suelo - b.h;
        b.vy = 0;
        b.onGround = true;
      }
    } else {
      // Subiendo: se para si da con la cabeza en un techo.
      final ty = (b.y / T).floor();
      final l = (b.x / T).floor(), r = ((b.right - 0.01) / T).floor();
      for (var tx = l; tx <= r; tx++) {
        if (_solid(tx, ty)) {
          b.y = (ty + 1) * T;
          b.vy = 0;
          break;
        }
      }
    }
    return hit;
  }

  /// La superficie más alta que pisaría [b] entre las alturas [desde] y
  /// [hasta], o null si no hay ninguna. [antes] es dónde tenía los pies
  /// antes de moverse (para las ramas: solo se pisan viniendo de arriba).
  double? _suelo(
    Box b, {
    required double desde,
    required double hasta,
    required double antes,
  }) {
    // Si el centro está sobre una cuesta, manda la cuesta. Se acepta
    // aunque quede hasta una casilla por encima: así, si llega por un lado,
    // sube a la superficie en vez de colarse dentro.
    final tc = (b.cx / T).floor();
    for (var ty = ((desde - T) / T).floor(); ty <= (hasta / T).floor(); ty++) {
      final t = _tile(tc, ty);
      if (!Tile.isSlope(t)) continue;
      final s = ty * T + Tile.slopeSurface(t, b.cx - tc * T);
      if (s >= desde - T && s <= hasta) return s;
    }

    double? mejor;
    final l = (b.x / T).floor(), r = ((b.right - 0.01) / T).floor();
    for (var ty = (desde / T).ceil(); ty <= (hasta / T).floor(); ty++) {
      final s = ty * T;
      for (var tx = l; tx <= r; tx++) {
        final t = _tile(tx, ty);
        final encima = _tile(tx, ty - 1);
        final pisable =
            (Tile.isSolid(t) &&
                !Tile.isSolid(encima) &&
                !Tile.isSlope(encima)) ||
            (t == Tile.platform && s >= antes - 0.5);
        if (pisable && (mejor == null || s < mejor)) mejor = s;
      }
    }
    return mejor;
  }
}
