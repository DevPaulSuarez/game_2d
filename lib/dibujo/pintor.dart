// EL PINTOR: dibuja la pantalla entera llamando a cada pieza en orden
// (lo que se dibuja después queda encima).
//
//   pincel.dart        herramientas comunes (imagen, brillo, retrato...)
//   fondo_bosque.dart  cielo y plantas del Bosque de los Duendes
//   fondo_hadas.dart   cielo y plantas del Reino de las Hadas
//   terreno.dart       las casillas del mapa
//   meta.dart          el portal, la princesa hada y la recompensa
//   objetos.dart       cristales, cofres, hadas, chispas y puntos
//   enemigos.dart      enemigos y lo que lanzan
//   arquero.dart       el arquero, su estela y sus flechas
//   fantasma.dart      el fantasma de la princesa y su globo
//   hud.dart           la barra de arriba
//   pantallas.dart     título, fin, stage completado y tarjeta "STAGE N"
//   letras.dart        la fuente pixel
//
// La intro se dibuja aparte, en lib/intro/.

import 'package:flutter/material.dart';

import '../intro/dibujar_escena.dart';
import '../juego/juego.dart';
import '../personajes/imagenes.dart';
import '../pixel_art/pixel_art.dart';
import 'arquero.dart';
import 'enemigos.dart';
import 'fantasma.dart';
import 'fondo_bosque.dart';
import 'fondo_hadas.dart';
import 'hud.dart';
import 'meta.dart';
import 'objetos.dart';
import 'pantallas.dart';
import 'pincel.dart';
import 'terreno.dart';

class GamePainter extends CustomPainter {
  final Game game;
  final PixelArt pixel;
  final Art art;

  /// Móvil: los textos hablan de tocar la pantalla en vez de teclas.
  final bool touch;

  GamePainter(
    this.game,
    this.pixel,
    this.art,
    Listenable repaint, {
    this.touch = false,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    // El mundo mide 240 de alto: se escala para llenar la pantalla.
    final scale = size.height / worldH;
    final viewW = size.width / scale;
    final p = Pincel(canvas, game, art, pixel);

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(scale);

    if (game.state == GameState.intro && game.intro != null) {
      dibujarIntro(p, game.intro!, viewW);
      canvas.restore();
      return;
    }

    // Cielo (fijo en pantalla).
    final cam = (game.camX * scale).roundToDouble() / scale;
    if (p.hadas) {
      dibujarCieloHadas(p, cam, viewW);
    } else {
      dibujarCieloBosque(p, cam, viewW);
    }

    // El mundo (se mueve con la cámara).
    canvas.save();
    canvas.translate(-cam, 0);
    if (p.hadas) {
      dibujarDecoradoHadas(p, cam, viewW);
    } else {
      dibujarDecoradoBosque(p, cam, viewW);
    }
    dibujarMeta(p);
    dibujarTerreno(p, cam, viewW);
    dibujarCofres(p);
    dibujarCristales(p);
    dibujarHadas(p);
    dibujarEnemigos(p);
    dibujarProyectiles(p);
    dibujarFlechas(p);
    dibujarArquero(p);
    dibujarEfectos(p);
    if (game.state != GameState.title) dibujarFantasma(p, cam, viewW);
    if (game.state == GameState.reward) dibujarVueloRecompensa(p);
    canvas.restore();

    // Encima de todo (fijo en pantalla).
    dibujarHud(p, viewW);
    dibujarPantallas(p, viewW, touch: touch);
    if (game.tarjeta > 0) {
      dibujarTarjetaStage(
        p,
        viewW,
        'STAGE ${game.escenario.numero}',
        game.escenario.nombre,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => false;
}
