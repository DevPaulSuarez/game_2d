import 'package:flutter_test/flutter_test.dart';
import 'package:game_2d/game/game.dart';
import 'package:game_2d/game/level.dart';
import 'package:game_2d/personajes/arquero/arquero.dart';

void main() {
  Game juego() {
    final g = Game()..state = GameState.playing;
    for (var i = 0; i < 60; i++) {
      g.update(1 / 120, Input());
    }
    return g;
  }

  void pulsarDisparo(Game g) {
    g.update(1 / 120, Input()..shoot = true);
    g.update(1 / 120, Input());
  }

  test('sin enemigos cerca, el botón lanza una flecha', () {
    final g = juego();
    g.enemies.clear();
    pulsarDisparo(g);
    expect(g.flechas.length, 1);
    expect(g.arquero.tiempoDisparo, greaterThan(0));
  });

  test('con un enemigo pegado delante, da un golpe', () {
    final g = juego();
    final a = g.arquero;
    final e = Enemy(EnemyKind.rat, a.right + 4, a.bottom - 8, 14, 8, 1, 0)
      ..active = true;
    g.enemies
      ..clear()
      ..add(e);
    pulsarDisparo(g);
    expect(g.flechas, isEmpty);
    expect(a.tiempoAtaque, greaterThan(0));
    expect(e.dead, isTrue);
  });

  test('camina hacia la derecha', () {
    final g = juego();
    final x0 = g.arquero.x;
    for (var i = 0; i < 60; i++) {
      g.update(1 / 120, Input()..right = true);
    }
    expect(g.arquero.x, greaterThan(x0));
    expect(g.arquero.mira, 1);
    expect(g.arquero, isA<Arquero>());
  });

  test('al correr deja una estela que se borra; caminando no', () {
    final g = juego();
    g.enemies.clear();
    for (var i = 0; i < 60; i++) {
      g.update(1 / 120, Input()..right = true);
    }
    expect(g.arquero.estela, isEmpty, reason: 'caminando no hay estela');
    for (var i = 0; i < 120; i++) {
      g.update(
        1 / 120,
        Input()
          ..right = true
          ..run = true,
      );
    }
    expect(g.arquero.estela, isNotEmpty);
    for (var i = 0; i < 120; i++) {
      g.update(1 / 120, Input());
    }
    expect(g.arquero.estela, isEmpty, reason: 'al parar se borra');
  });
}
