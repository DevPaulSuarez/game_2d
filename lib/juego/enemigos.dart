// LOS ENEMIGOS: caminan, se dan la vuelta, atacan de lejos y se pueden
// pisar. También sus proyectiles (piedras, bolas mágicas y flechas).
//
// Los números de cada enemigo (vida, velocidad, puntos, alcance) están en
// la tabla fichasEnemigos de ajustes.dart. Los dibujos, en
// lib/pixel_art/enemigos.dart.

import 'dart:math' as math;

import '../personajes/arquero/saltar.dart';
import '../sonido/efecto.dart';
import 'juego.dart';

/// Crea el enemigo que marca el mapa en la casilla de [s].
Enemy crearEnemigo(EnemySpawn s, math.Random rnd) {
  final f = fichasEnemigos[s.kind]!;
  final x = s.x * T + 1, suelo = (s.y + 1) * T;
  final primerAtaque = 1.2 + rnd.nextDouble() * 1.5;
  return Enemy(
    s.kind,
    x,
    suelo - f.alto,
    f.ancho,
    f.alto,
    f.vida,
    f.alcance == null ? 0 : primerAtaque,
  );
}

extension Enemigos on Game {
  /// Enemigos en pantalla que siguen vivos.
  Iterable<Enemy> get enemigosVivos =>
      enemies.where((e) => e.active && !e.dead);

  /// Quita un punto de vida a [e]; [fromDir] es hacia dónde lo empuja.
  void danarEnemigo(Enemy e, int fromDir) {
    e.hp--;
    e.hitFlash = 0.15;
    if (e.hp <= 0) {
      _matar(e, fromDir);
    } else {
      e.x += fromDir * 4;
      sonar(Efecto.golpe);
    }
  }

  void _matar(Enemy e, int fromDir, {Efecto sonido = Efecto.enemigoMuere}) {
    sonar(sonido);
    e.dead = true;
    e.vy = -220;
    e.vx = fromDir * 50.0;
    sumarPuntos(e.ficha.puntos, e.cx, e.y);
    if (rnd.nextDouble() < 0.45) {
      say(frasesFelicitar[rnd.nextInt(frasesFelicitar.length)]);
    }
  }

  void actualizarEnemigos(double dt) {
    final p = arquero;
    for (final e in enemies) {
      if (!e.active) {
        if (e.x < camX + viewW + 32) {
          e.active = true;
        } else {
          continue;
        }
      }
      if (e.dead) {
        // Cae dando vueltas fuera de la pantalla.
        e.vy += AjustesJuego.gravedad * dt;
        e.x += e.vx * dt;
        e.y += e.vy * dt;
        continue;
      }
      e.anim += dt;
      e.hitFlash -= dt;
      e.throwPose -= dt;

      var walking = true;
      final alcance = e.ficha.alcance;
      if (alcance != null) {
        final dx = p.cx - e.cx;
        final near = dx.abs() < alcance.x && (p.cy - e.cy).abs() < alcance.y;
        if (near && state == GameState.playing) {
          // Se detiene, mira al arquero y le ataca de lejos.
          walking = false;
          e.dir = dx < 0 ? -1 : 1;
          e.throwTimer -= dt;
          if (e.throwTimer <= 0) {
            e.throwTimer = alcance.espera + rnd.nextDouble() * 1.2;
            e.throwPose = 0.3;
            _lanzar(e);
          }
        }
      }

      e.vx = walking ? e.dir * e.speed : 0;
      e.vy = math.min(
        e.vy + AjustesJuego.gravedad * dt,
        AjustesJuego.caidaMaxima,
      );
      if (mover(e, dt).pared) e.dir = -e.dir;
    }

    // Enemigos que chocan entre sí se dan la vuelta
    for (var i = 0; i < enemies.length; i++) {
      final a = enemies[i];
      if (!a.active || a.dead) continue;
      for (var j = i + 1; j < enemies.length; j++) {
        final b = enemies[j];
        if (!b.active || b.dead) continue;
        if (a.overlaps(b)) {
          a.dir = a.x < b.x ? -1 : 1;
          b.dir = -a.dir;
        }
      }
    }

    // Contacto con el jugador
    for (final e in enemies) {
      if (!e.active || e.dead || !p.overlaps(e)) continue;
      final side = e.cx > p.cx ? 1 : -1;
      if (p.vy > 0 && p.bottom - e.y < 10) {
        // Pisotón
        rebotarAlPisar(p);
        _matar(e, side, sonido: Efecto.pisoton);
      } else if (p.invencible <= 0) {
        herir(e.cx);
        if (state != GameState.playing) return;
      }
    }

    enemies.removeWhere(
      (e) => e.y > kRows * T + 64 || (e.active && e.right < camX - 64),
    );
  }

  void _lanzar(Enemy e) {
    switch (e.kind) {
      case EnemyKind.goblin:
        proyectiles.add(
          Proyectil(TipoProyectil.piedra, e.cx - 3, e.y + 2, e.dir * 120, -170),
        );
      case EnemyKind.mage:
        sonar(Efecto.magia);
        proyectiles.add(
          Proyectil(TipoProyectil.magia, e.cx - 4, e.y + 2, e.dir * 95, 0),
        );
      case EnemyKind.darkArcher:
        sonar(Efecto.flecha);
        final x = e.dir > 0 ? e.right : e.x - 10;
        proyectiles.add(
          Proyectil(TipoProyectil.flecha, x, e.y + 7, e.dir * 190, 0),
        );
      case EnemyKind.rat:
        break;
    }
  }

  /// Mueve piedras, bolas y flechas enemigas; si tocan al arquero, le
  /// quitan vida.
  void actualizarProyectiles(double dt) {
    final p = arquero;
    proyectiles.removeWhere((r) {
      r.t += dt;
      switch (r.tipo) {
        case TipoProyectil.piedra:
          r.vy += 500 * dt;
        case TipoProyectil.magia:
          r.vy = math.cos(r.t * 7) * 30;
        case TipoProyectil.flecha:
          break;
      }
      r.x += r.vx * dt;
      r.y += r.vy * dt;
      if (r.y > kRows * T || r.x < camX - 32 || r.x > camX + viewW + 32) {
        return true;
      }
      if (esSolido(r.cx, r.cy)) return true;
      if (r.overlaps(p)) {
        if (p.invencible <= 0) {
          herir(r.cx);
        }
        return true;
      }
      return false;
    });
  }
}
