// EL MOTOR DE LA INTRO: los actores, los efectos (humo, chispas...) y los
// tipos de paso con los que se escribe la historia.
//
// La historia en sí (qué pasa y qué dice cada uno) está en guion.dart.
// Cómo se dibuja, en dibujar_escena.dart, dibujar_actores.dart y
// dibujar_dialogo.dart.

import 'dart:math' as math;

import 'guion.dart';

/// Ancho lógico de la escena de la intro (se centra en pantalla).
const double kSceneW = 400;

/// Altura del suelo en la escena.
const double kSceneGround = 208;

/// Un personaje u objeto de la intro.
class Actor {
  /// Qué imagen lleva ahora (p. ej. 'ataque_2'; ver dibujar_actores.dart).
  String sprite;
  double x; // centro
  double y; // base (pies)
  double alpha = 1;
  bool flip = false;
  bool visible = false;
  bool walking = false;

  /// Distancia caminada (para elegir el cuadro de caminar).
  double pasos = 0;
  Actor(this.sprite, this.x, this.y);
}

enum FxKind {
  /// Humo morado del villano.
  smoke,

  /// Pedazo del corazón roto.
  shard,

  /// Destello blanco.
  sparkle,

  /// Chispa dorada que sube (luz de la promesa).
  ember,
}

/// Un efecto que dura [life] segundos.
class Fx {
  final FxKind kind;
  double x, y, vx, vy, life, t = 0;
  Fx(this.kind, this.x, this.y, this.vx, this.vy, this.life);

  /// Lo que lleva de vida: 0 = recién nacido, 1 = a punto de desaparecer.
  double get k => (t / life).clamp(0.0, 1.0);
}

// ---------------------------------------------------------------------------
// LOS PASOS con los que se escribe la historia (ver guion.dart)
// ---------------------------------------------------------------------------

abstract class Paso {
  /// Se llama una vez, cuando empieza el paso.
  void start(Cutscene c) {}

  /// Se llama en cada instante; devuelve true cuando el paso terminó.
  bool update(Cutscene c, double dt, bool advance);
}

/// Diálogo: [who] dice [text] (null = el narrador). Espera a que el
/// jugador pulse para continuar.
class Dice extends Paso {
  final String? who;
  final String text;
  Dice(this.who, this.text);

  @override
  void start(Cutscene c) {
    c.speaker = who;
    c.text = text;
    c.textT = 0;
  }

  @override
  bool update(Cutscene c, double dt, bool advance) {
    if (!advance) return false;
    if (!c.textFull) {
      // Primera pulsación: enseña el texto entero de golpe.
      c.textT = 999;
      return false;
    }
    c.text = '';
    c.speaker = null;
    return true;
  }
}

/// No pasa nada durante [d] segundos.
class Espera extends Paso {
  final double d;
  double t = 0;
  Espera(this.d);

  @override
  bool update(Cutscene c, double dt, bool advance) => (t += dt) >= d;
}

/// Hace algo una vez, al instante (mostrar un actor, un destello...).
class Haz extends Paso {
  final void Function(Cutscene c) fn;
  Haz(this.fn);

  @override
  void start(Cutscene c) => fn(c);

  @override
  bool update(Cutscene c, double dt, bool advance) => true;
}

/// Animación durante [d] segundos: fn recibe el progreso p (0..1) y dt.
class Anima extends Paso {
  final double d;
  final void Function(Cutscene c, double p, double dt) fn;
  double t = 0;
  Anima(this.d, this.fn);

  @override
  void start(Cutscene c) => fn(c, 0, 0);

  @override
  bool update(Cutscene c, double dt, bool advance) {
    t += dt;
    fn(c, math.min(1, t / d), dt);
    return t >= d;
  }
}

/// Un actor camina hasta [toX] a [speed] píxeles por segundo.
class Camina extends Paso {
  final String name;
  final double toX, speed;
  Camina(this.name, this.toX, this.speed);

  @override
  void start(Cutscene c) {
    final a = c.a(name);
    a.visible = true;
    a.walking = true;
  }

  @override
  bool update(Cutscene c, double dt, bool advance) {
    final a = c.a(name);
    final d = toX - a.x;
    final step = speed * dt;
    if (d.abs() <= step) {
      a.x = toX;
      a.walking = false;
      return true;
    }
    a.x += d.sign * step;
    a.pasos += step;
    return false;
  }
}

// ---------------------------------------------------------------------------
// LA ESCENA: guarda cómo está todo y va avanzando paso a paso
// ---------------------------------------------------------------------------

class Cutscene {
  final actors = <String, Actor>{};
  final fx = <Fx>[];

  /// Azar con semilla fija: la intro sale igual cada vez.
  final rnd = math.Random(11);

  /// Quién habla y qué dice ahora (text vacío = no hay diálogo).
  String? speaker;
  String text = '';
  double textT = 0;

  /// Tarjeta final ("STAGE 1" y el nombre del escenario).
  String? card;
  String? cardSub;

  /// Destello rojo de la pantalla (baja solo hasta 0).
  double flash = 0;

  /// Temblor de la pantalla.
  double shake = 0;

  /// Segundos desde que empezó la intro.
  double t = 0;

  /// Oscuridad rojiza de la escena (0..1).
  double darkness = 0;

  /// Luz dorada de la promesa (0..1).
  double glory = 0;

  /// El limbo: todo se vuelve gris y frío alrededor de la princesa (0..1).
  double limbo = 0;

  /// Destello verde de la poción curativa (baja solo hasta 0).
  double healFlash = 0;

  /// Rayo: tiempo restante y posición.
  double bolt = 0;
  double boltX = 0;

  /// Rayo rojo del ataque: avance (0..1) y opacidad.
  double beam = 0;
  double beamAlpha = 0;

  bool princessIsGhost = false;
  bool done = false;

  late final List<Paso> _pasos;
  int _i = 0;

  /// Puerta de la casa de la princesa.
  static const double doorX = 65;

  Cutscene() {
    const g = kSceneGround;
    actors['princess'] = Actor('princess', doorX, g);
    actors['man'] = Actor('man', 440, g);
    actors['potion'] = Actor('potionGood', 0, 0);
    actors['heart'] = Actor('heartBig', 0, 0);
    actors['orb'] = Actor('bolaMagia', 0, 0);
    actors['ghost'] = Actor('ghost', 0, g);
    actors['archer'] = Actor('archer', -20, g);
    _pasos = guionIntro();
    _pasos.first.start(this);
  }

  Actor a(String name) => actors[name]!;

  /// La princesa ya está cayendo o en el suelo (cuadros 'muerte_N').
  bool get princessFallen => a('princess').sprite.startsWith('muerte');

  /// Caracteres visibles del diálogo actual (efecto máquina de escribir).
  int get visibleChars => math.min(text.length, (textT * 40).floor());
  bool get textFull => visibleChars >= text.length;

  /// Un número al azar entre [a] y [b].
  double azar(double a, double b) => a + rnd.nextDouble() * (b - a);

  /// Crea un efecto (humo, chispa...) que dura [life] segundos.
  void emitir(
    FxKind k,
    double x,
    double y,
    double vx,
    double vy,
    double life,
  ) => fx.add(Fx(k, x, y, vx, vy, life));

  /// [advance] = el jugador acaba de pulsar (para pasar los diálogos).
  void update(double dt, bool advance) {
    if (done) return;
    t += dt;
    textT += dt;
    flash = math.max(0, flash - dt * 2.5);
    healFlash = math.max(0, healFlash - dt * 0.8);
    bolt = math.max(0, bolt - dt);

    // Destellos alrededor de los seres celestiales
    final pr = a('princess');
    if (pr.visible &&
        pr.alpha > 0.5 &&
        !princessFallen &&
        rnd.nextDouble() < dt * 6) {
      emitir(
        FxKind.sparkle,
        pr.x + azar(-12, 12),
        pr.y - azar(4, 30),
        0,
        -8,
        0.8,
      );
    }
    final gh = a('ghost');
    if (gh.visible && gh.alpha > 0.2 && rnd.nextDouble() < dt * 10) {
      emitir(
        FxKind.sparkle,
        gh.x + azar(-14, 14),
        gh.y - azar(0, 34),
        azar(-4, 4),
        -14,
        1.0,
      );
    }
    if (glory > 0 && rnd.nextDouble() < dt * 14 * glory) {
      emitir(
        FxKind.ember,
        azar(80, 260),
        kSceneGround,
        azar(-5, 5),
        azar(-40, -20),
        2.2,
      );
    }

    for (final f in fx) {
      f.t += dt;
      f.x += f.vx * dt;
      f.y += f.vy * dt;
      if (f.kind == FxKind.smoke) f.vx *= 1 - dt;
    }
    fx.removeWhere((f) => f.t >= f.life);

    // Avanza al siguiente paso cuando el actual termina.
    while (!done) {
      if (!_pasos[_i].update(this, dt, advance)) break;
      advance = false;
      dt = 0;
      _i++;
      if (_i >= _pasos.length) {
        done = true;
        break;
      }
      _pasos[_i].start(this);
    }
  }

  /// Botón OMITIR: termina la intro.
  void skip() => done = true;

  /// Una bocanada de humo que sale del cuerpo del actor [a] hacia fuera,
  /// con velocidad entre [vMin] y [vMax].
  void bocanadaHumo(Actor a, double vMin, double vMax) {
    final ang = azar(0, math.pi * 2);
    final sp = azar(vMin, vMax);
    emitir(
      FxKind.smoke,
      a.x + math.cos(ang) * azar(0, 28),
      a.y - 40 + math.sin(ang) * azar(0, 36),
      math.cos(ang) * sp,
      math.sin(ang) * sp * 0.6 - 15,
      azar(0.8, 1.6),
    );
  }
}
