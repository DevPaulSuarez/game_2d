// PIEZA: perder vida, curarse y morir.

import 'ajustes.dart';
import 'arquero.dart';

/// Le quita un corazón y lo empuja lejos de [desdeX] (de donde vino el
/// golpe). Devuelve true si se quedó sin vida.
bool recibirGolpe(Arquero a, double desdeX) {
  a.vida--;
  if (a.vida <= 0) return true;
  a.invencible = AjustesArquero.tiempoInvencible;
  a.tiempoDano = AjustesArquero.duracionDano;
  final haciaAtras = a.cx < desdeX ? -1 : 1;
  a.vx = haciaAtras * AjustesArquero.empujeDano;
  a.vy = -AjustesArquero.saltitoDano;
  a.onGround = false;
  return false;
}

/// Suma un corazón. Devuelve false si ya tenía la vida llena.
bool curar(Arquero a) {
  if (a.vida >= AjustesArquero.vidaMaxima) return false;
  a.vida++;
  return true;
}

/// Lo deja sin vida y quieto (la animación de muerte la pone animacion.dart).
void morir(Arquero a) {
  a.vida = 0;
  a.vx = 0;
  a.vy = 0;
  a.tiempoDano = 0;
  a.invencible = 0;
}
