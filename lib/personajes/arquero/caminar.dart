// PIEZA: caminar y correr.
//
// No mueve al arquero directamente: cambia su velocidad (vx). El juego
// luego lo mueve y lo hace chocar con las paredes (ver caer() en
// saltar.dart).

import 'ajustes.dart';
import 'arquero.dart';

void caminar(Arquero a, Botones b, double dt) {
  if (b.direccion != 0) {
    a.mira = b.direccion;
    final maxima = b.correr
        ? AjustesArquero.velocidadCorrer
        : AjustesArquero.velocidadCaminar;

    // ¿Iba hacia el otro lado? Entonces frena fuerte (derrape).
    final derrapando = a.vx * b.direccion < 0;
    final aceleracion = derrapando
        ? AjustesArquero.frenadoGiro
        : (a.onGround
              ? AjustesArquero.aceleracionSuelo
              : AjustesArquero.aceleracionAire);
    a.vx += b.direccion * aceleracion * dt;

    // Si va más rápido que el máximo (p. ej. soltó "correr"), baja poco a
    // poco en vez de frenar de golpe.
    if (a.vx.abs() > maxima) {
      a.vx = acercar(a.vx, maxima * a.vx.sign, 300 * dt);
    }
  } else {
    // Sin flechas pulsadas: se va frenando hasta pararse.
    final frenado = a.onGround
        ? AjustesArquero.frenadoSuelo
        : AjustesArquero.frenadoAire;
    a.vx = acercar(a.vx, 0, frenado * dt);
  }
}

/// Mueve [valor] hacia [objetivo] como mucho [paso], sin pasarse.
/// Ejemplo: acercar(10, 0, 3) = 7; acercar(2, 0, 3) = 0.
double acercar(double valor, double objetivo, double paso) {
  if (valor < objetivo) return (valor + paso).clamp(valor, objetivo);
  return (valor - paso).clamp(objetivo, valor);
}
