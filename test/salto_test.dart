import 'package:flutter_test/flutter_test.dart';
import 'package:game_2d/juego/juego.dart';

void main() {
  test('suelo estable al caminar y saltos seguidos', () {
    final g = Game()..state = GameState.playing;
    final input = Input();
    // Igual que main.dart: pasos de 1/120 con un resto diminuto.
    void frame() {
      var dt = 1 / 60 + 1e-7;
      while (dt > 0) {
        final step = dt > 1 / 120 ? 1 / 120 : dt;
        g.update(step, input);
        dt -= step;
      }
    }

    for (var i = 0; i < 20; i++) {
      frame(); // asentarse
    }
    input.right = true;
    var enAire = 0;
    for (var i = 0; i < 30; i++) {
      frame();
      if (!g.arquero.onGround || g.arquero.tiempoAterrizaje > 0) enAire++;
    }
    expect(enAire, 0, reason: 'caminando no debe "aterrizar" cada cuadro');

    input.right = false;
    var saltos = 0;
    var antes = true;
    for (var i = 0; i < 240; i++) {
      // Mantener pulsado 3 cuadros, soltar, repetir.
      input.jump = i % 20 < 3;
      frame();
      if (antes && !g.arquero.onGround && g.arquero.vy < 0) saltos++;
      antes = g.arquero.onGround;
    }
    expect(saltos, greaterThanOrEqualTo(4));
  });
}
