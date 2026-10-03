import 'package:flutter_test/flutter_test.dart';
import 'package:game_2d/escenarios/escenarios.dart';
import 'package:game_2d/juego/juego.dart';

void main() {
  /// Juego en el Reino de las Hadas, ya sin la tarjeta "STAGE 2".
  Game reino() => Game()
    ..irAEscenario(1)
    ..tarjeta = 0;

  void esperar(Game g, double segundos, [Input? input]) {
    for (var i = 0; i < segundos * 120; i++) {
      g.update(1 / 120, input ?? Input());
    }
  }

  /// Deja solo un enemigo de [tipo] a [distancia] del arquero.
  Enemy soloUno(Game g, EnemyKind tipo, double distancia) {
    final e = g.enemies.firstWhere((e) => e.kind == tipo);
    g.enemies
      ..clear()
      ..add(e);
    final a = g.arquero;
    e
      ..x = a.x + distancia
      ..y = a.bottom - e.h
      ..active = true
      ..throwTimer = 0.1;
    return e;
  }

  test('todos los escenarios se construyen sin errores', () {
    for (final e in escenarios) {
      final nivel = e.construir();
      expect(nivel.width, greaterThan(100), reason: e.nombre);
    }
  });

  test('el reino de las hadas tiene magos, arqueros sombríos y hadas', () {
    final nivel = escenarios[1].construir();
    expect(nivel.tema, Tema.hadas);
    expect(nivel.enemies.where((e) => e.kind == EnemyKind.mage), isNotEmpty);
    expect(
      nivel.enemies.where((e) => e.kind == EnemyKind.darkArcher),
      isNotEmpty,
    );
    expect(nivel.hadas, isNotEmpty);
  });

  test('el mago lanza una bola mágica que quita vida', () {
    final g = reino();
    soloUno(g, EnemyKind.mage, 100);
    esperar(g, 0.3);
    expect(g.proyectiles.single.tipo, TipoProyectil.magia);
    esperar(g, 1.5);
    expect(g.arquero.vida, 2);
  });

  test('la flecha del arquero sombrío quita vida si no la esquiva', () {
    final g = reino();
    soloUno(g, EnemyKind.darkArcher, 120);
    esperar(g, 1.5);
    expect(g.arquero.vida, 2);
  });

  test('un hada cura al arquero', () {
    final g = reino();
    g.enemies.clear();
    g.arquero.vida = 1;
    final h = g.hadas.first;
    g.arquero
      ..x = h.x
      ..y = h.y;
    esperar(g, 0.05);
    expect(g.arquero.vida, 2);
    expect(g.hadas.length, escenarios[1].construir().hadas.length - 1);
  });

  test('al terminar el stage 1 se pasa al stage 2', () {
    final g = Game()..irAEscenario(0);
    g
      ..score = 1234
      ..state = GameState.clear
      ..time = 0
      ..stateTimer = 3;
    g.update(1 / 120, Input()..start = true);
    expect(g.stage, 1);
    expect(g.state, GameState.playing);
    expect(g.tarjeta, greaterThan(0));
    expect(g.score, 1234);
  });
}
