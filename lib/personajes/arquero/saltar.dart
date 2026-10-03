// PIEZA: saltar, caer y aterrizar.

import 'dart:math' as math;

import '../../game/game.dart';
import 'ajustes.dart';
import 'arquero.dart';
import '../../sonido/efecto.dart';

/// Si se pulsó saltar y puede hacerlo, le da impulso hacia arriba.
void saltar(Arquero a, Botones b, double dt, Game mundo) {
  // El salto se "guarda" un momento: si lo pulsas justo antes de tocar el
  // suelo, sale igual al aterrizar.
  if (b.saltoPulsado) a.saltoGuardado = AjustesArquero.saltoGuardado;
  a.saltoGuardado -= dt;

  // También se puede saltar un instante después de salir de un borde.
  final acabaDeSalirDeUnBorde =
      a.tiempoEnAire < AjustesArquero.tiempoCoyote && a.vy >= 0;
  final puede = a.onGround || acabaDeSalirDeUnBorde;

  if (a.saltoGuardado > 0 && puede) {
    // vy negativa = hacia arriba. Corriendo salta un poco más.
    a.vy =
        -(AjustesArquero.fuerzaSalto +
            a.vx.abs() * AjustesArquero.saltoExtraPorVelocidad);
    a.onGround = false;
    a.saltoGuardado = 0;
    mundo.sonar(Efecto.salto);
  }
}

/// La gravedad lo tira hacia abajo, el juego lo mueve chocando con suelo,
/// cuestas, ramas y paredes, y aquí se detecta si acaba de aterrizar.
void caer(Arquero a, Botones b, double dt, Game mundo) {
  // Mantener el botón mientras sube = gravedad más suave = salto más alto.
  final gravedad = b.saltoApretado && a.vy < 0
      ? AjustesArquero.gravedadManteniendo
      : Game.gravity;
  a.vy = math.min(a.vy + gravedad * dt, Game.maxFall);

  final estabaEnSuelo = a.onGround;
  mundo.mover(a, dt);

  if (a.onGround) {
    final aterrizo =
        !estabaEnSuelo &&
        a.tiempoEnAire > AjustesArquero.aireMinimoParaAterrizar;
    if (aterrizo) a.tiempoAterrizaje = AjustesArquero.duracionAterrizaje;
    a.tiempoEnAire = 0;
  } else {
    a.tiempoEnAire += dt;
  }
}

/// Rebote al caer encima de un enemigo.
void rebotarAlPisar(Arquero a) => a.vy = -AjustesArquero.reboteAlPisar;
