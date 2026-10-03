import 'package:flutter_test/flutter_test.dart';
import 'package:game_2d/escenarios/escenarios.dart';
import 'package:game_2d/juego/juego.dart';

void main() {
  Game juego(int n) {
    final g = Game()
      ..irAEscenario(n)
      ..tarjeta = 0;
    g.enemies.clear();
    return g;
  }

  void paso(Game g, Input i) => g.update(1 / 120, i);

  test('sube y baja la colina caminando, sin saltar', () {
    final g = juego(0);
    final y0 = g.arquero.bottom;
    var masAlto = y0;
    // La primera colina del Stage 1 está entre las columnas 11 y 18.
    while (g.arquero.x < 20 * T) {
      paso(g, Input()..right = true);
      masAlto = masAlto < g.arquero.bottom ? masAlto : g.arquero.bottom;
      expect(g.clock, lessThan(10), reason: 'se quedó atascado');
    }
    expect(masAlto, lessThan(y0 - 10), reason: 'no subió la colina');
    expect(g.arquero.bottom, closeTo(y0, 0.5), reason: 'no volvió a bajar');
  });

  test('las ramas se atraviesan desde abajo y se pisan desde arriba', () {
    final g = juego(0);
    // Rama del Stage 1 en la columna 38, fila 7, sobre suelo en la fila 10.
    final a = g.arquero
      ..x = 38 * T
      ..y = 10 * T - 22
      ..onGround = true;
    for (var i = 0; i < 120; i++) {
      paso(g, Input()..jump = true);
    }
    for (var i = 0; i < 60; i++) {
      paso(g, Input());
    }
    expect(a.onGround, isTrue);
    expect(a.bottom, closeTo(7 * T, 0.5), reason: 'no quedó sobre la rama');
  });

  test('un cofre da cristales', () {
    final g = juego(0);
    final cofre = g.cofres.firstWhere((c) => !c.pocion);
    g.arquero
      ..x = cofre.x
      ..y = cofre.bottom - 22;
    for (var i = 0; i < 120; i++) {
      paso(g, Input());
    }
    expect(cofre.abierto, isTrue);
    expect(g.numCristales, 5);
  });

  for (var n = 0; n < escenarios.length; n++) {
    test('un jugador robot puede llegar a la meta del stage ${n + 1}', () {
      final g = juego(n);
      final a = g.arquero;
      var sujetar = 0.0;
      while (g.state == GameState.playing) {
        g.enemies.clear();
        g.proyectiles.clear();
        a.invencible = 1;
        // Salta si delante hay un hueco o algo más alto que sus pies
        // (las cuestas no cuentan: se suben caminando).
        final delante = ((a.right + 10) / T).floor();
        final fila = g.level.filaSuelo(delante);
        final obstaculo =
            fila == null ||
            (!Tile.isSlope(g.grid[fila][delante]) && fila * T < a.bottom - 8);
        // Salto corto para escalones y largo para huecos.
        if (a.onGround && obstaculo) sujetar = fila == null ? 0.5 : 0.15;
        sujetar -= 1 / 120;
        paso(
          g,
          Input()
            ..right = true
            ..run = true
            ..jump = sujetar > 0,
        );
        expect(g.clock, lessThan(120), reason: 'no llegó (x=${a.x ~/ T})');
      }
      expect(g.state, GameState.reward, reason: 'x=${a.x ~/ T}');
    });
  }
}
