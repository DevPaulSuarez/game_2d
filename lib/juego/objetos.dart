// LOS OBJETOS: hadas que curan, cofres, cristales y los efectos que duran
// un momento (chispas, cristales que saltan, puntos que suben).

import 'dart:math' as math;

import '../personajes/arquero/recibir_dano.dart';
import '../sonido/efecto.dart';
import 'juego.dart';

extension Objetos on Game {
  /// Las hadas flotan en su sitio; al tocarlas curan (o dan puntos si la
  /// vida ya está llena).
  void actualizarHadas(double dt) {
    for (final h in hadas) {
      h.t += dt;
      h.x = h.baseX + math.sin(h.t * 1.3) * 6;
      h.y = h.baseY + math.sin(h.t * 3) * 4;
    }
    hadas.removeWhere((h) {
      if (!arquero.overlaps(h)) return false;
      sonar(Efecto.hada);
      for (var i = 0; i < 4; i++) {
        sparks.add(Spark(h.cx - 6 + i * 4.0, h.cy - 4 + (i % 2) * 8.0));
      }
      if (curar(arquero)) {
        say('¡UN HADA TE HA CURADO!', force: true);
      } else {
        sumarPuntos(AjustesJuego.puntosHada, h.cx, h.y);
        say('EL HADA TE DA SU BENDICIÓN.', force: true);
      }
      return true;
    });
  }

  /// Un cofre se abre al tocarlo: da una poción o cristales.
  void actualizarCofres() {
    for (final c in cofres) {
      if (c.abierto || !arquero.overlaps(c)) continue;
      c.abierto = true;
      sparks.add(Spark(c.cx, c.y));
      sonar(c.pocion ? Efecto.curar : Efecto.cofre);
      if (c.pocion) {
        if (curar(arquero)) {
          say('¡UNA POCIÓN! TE SIENTES MEJOR.', force: true);
        } else {
          sumarPuntos(AjustesJuego.puntosPocion, c.cx, c.y - 8);
        }
      } else {
        // Salen los cristales en abanico.
        const n = AjustesJuego.cristalesPorCofre;
        for (var i = 0; i < n; i++) {
          cristalPops.add(CristalPop(c.cx - 5, c.y - 6, (i - n ~/ 2) * 35.0));
        }
        if (rnd.nextDouble() < 0.5) say('¡UN COFRE LLENO DE CRISTALES!');
      }
    }
  }

  void recogerCristales() {
    cristales.removeWhere((c) {
      if (!arquero.overlaps(c)) return false;
      sonar(Efecto.cristal);
      _sumarCristal();
      score += AjustesJuego.puntosCristal;
      return true;
    });
  }

  /// Cada [AjustesJuego.cristalesPorVida] cristales, una vida extra.
  void _sumarCristal() {
    numCristales++;
    if (numCristales >= AjustesJuego.cristalesPorVida) {
      numCristales -= AjustesJuego.cristalesPorVida;
      lives++;
    }
  }

  /// Chispas, cristales que saltan de los cofres y puntos que suben.
  void actualizarEfectos(double dt) {
    for (final c in cofres) {
      if (c.abierto) c.t += dt;
    }

    for (final s in sparks) {
      s.t += dt;
    }
    sparks.removeWhere((s) => s.t > 0.25);

    for (final c in cristalPops) {
      c.t += dt;
      c.vy += 1100 * dt;
      c.x += c.vx * dt;
      c.y += c.vy * dt;
    }
    cristalPops.removeWhere((c) {
      if (c.t > 0.55) {
        _sumarCristal();
        sumarPuntos(AjustesJuego.puntosCristal, c.x + 5, c.y);
        return true;
      }
      return false;
    });

    for (final s in scorePops) {
      s.t += dt;
      s.y -= 40 * dt;
    }
    scorePops.removeWhere((s) => s.t > 0.8);
  }
}
