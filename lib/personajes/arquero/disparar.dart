// PIEZA: lanzar flechas.

import '../../juego/juego.dart';
import 'ajustes.dart';
import 'arquero.dart';
import '../../sonido/efecto.dart';

/// Una flecha en vuelo.
class Flecha extends Box {
  /// Distancia que lleva recorrida.
  double recorrido = 0;

  Flecha(double x, double y, double vx) : super(x, y, 14, 3) {
    this.vx = vx;
  }
}

/// Crea una flecha delante del arquero (si no hay demasiadas ya).
void dispararFlecha(Arquero a, Game mundo) {
  if (mundo.flechas.length >= AjustesArquero.maxFlechas) return;
  final x = a.mira > 0 ? a.right - 2 : a.x - 12;
  final y = a.y + 8; // a la altura del arco
  mundo.flechas.add(Flecha(x, y, a.mira * AjustesArquero.velocidadFlecha));
  a.recarga = AjustesArquero.recargaDisparo;
  a.tiempoDisparo = AjustesArquero.duracionDisparo;
  mundo.sonar(Efecto.flecha);
}

/// Mueve todas las flechas. Una flecha desaparece al llegar lejos, al
/// chocar con un bloque o al dar a un enemigo (que pierde vida).
void actualizarFlechas(Game mundo, double dt) {
  mundo.flechas.removeWhere((f) {
    f.x += f.vx * dt;
    f.recorrido += f.vx.abs() * dt;
    if (f.recorrido > AjustesArquero.alcanceFlecha) return true;

    final punta = f.vx > 0 ? f.right : f.x;
    if (mundo.esSolido(punta, f.cy)) {
      mundo.sparks.add(Spark(punta, f.cy));
      return true;
    }
    for (final e in mundo.enemigosVivos) {
      if (f.overlaps(e)) {
        mundo.danarEnemigo(e, f.vx.sign.toInt());
        return true;
      }
    }
    return false;
  });
}
