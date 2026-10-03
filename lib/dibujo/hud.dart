// EL HUD: la barra de arriba (vida, puntos, cristales, stage, vidas y
// tiempo).

import '../juego/juego.dart';
import '../personajes/arquero/ajustes.dart';
import 'letras.dart';
import 'pincel.dart';

void dibujarHud(Pincel p, double viewW) {
  final c = p.c, game = p.game, o = p.pixel.objetos;
  const px = 1.5;
  final cols = [
    ('PUNTOS', game.score.toString().padLeft(6, '0')),
    ('CRISTALES', 'X${game.numCristales.toString().padLeft(2, '0')}'),
    ('STAGE', '${game.escenario.numero}'),
    ('VIDAS', 'X${game.lives}'),
    (
      'TIEMPO',
      game.state == GameState.title
          ? ''
          : game.time.ceil().toString().padLeft(3, '0'),
    ),
  ];
  // Vida (corazones)
  drawPixelText(c, 'VIDA', 8, 5, px: px);
  for (var i = 0; i < AjustesArquero.vidaMaxima; i++) {
    final img = i < game.arquero.vida ? o.corazonLleno : o.corazonVacio;
    p.imgCentered(img, 12 + i * 11, 18, scale: 1.3);
  }
  // El resto, repartido a lo ancho.
  final start = 50.0;
  final span = viewW - start - 8;
  for (var i = 0; i < cols.length; i++) {
    final x = start + span * i / cols.length;
    drawPixelText(c, cols[i].$1, x, 5, px: px);
    drawPixelText(c, cols[i].$2, x, 14, px: px);
  }
}
