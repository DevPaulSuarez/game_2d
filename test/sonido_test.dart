import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_2d/escenarios/escenarios.dart';
import 'package:game_2d/juego/juego.dart';
import 'package:game_2d/sonido/efecto.dart';

void main() {
  Game jugando() {
    final g = Game()
      ..irAEscenario(0)
      ..tarjeta = 0;
    g.enemies.clear();
    return g;
  }

  test('cada efecto tiene su archivo .wav', () {
    for (final e in Efecto.values) {
      expect(
        File('lib/sonido/efectos/${e.archivo}.wav').existsSync(),
        isTrue,
        reason: e.archivo,
      );
    }
  });

  test('cada escenario tiene su música', () {
    for (final e in escenarios) {
      expect(File('lib/sonido/musica/${e.musica}.m4a').existsSync(), isTrue);
    }
    expect(File('lib/sonido/musica/titulo.m4a').existsSync(), isTrue);
  });

  test('saltar y disparar piden su sonido', () {
    final g = jugando();
    g.update(1 / 120, Input()..jump = true);
    expect(g.sonidos, contains(Efecto.salto));
    g.sonidos.clear();
    for (var i = 0; i < 120; i++) {
      g.update(1 / 120, Input());
    }
    g.update(1 / 120, Input()..shoot = true);
    expect(g.sonidos, contains(Efecto.flecha));
  });

  test('la música cambia con la pantalla', () {
    final g = Game();
    expect(g.musica, 'titulo');
    g.irAEscenario(0);
    expect(g.musica, 'bosque');
    g.irAEscenario(1);
    expect(g.musica, 'hadas');
  });
}
