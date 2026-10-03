import 'dart:math' as math;

/// Ancho lógico de la escena de la intro (se centra en pantalla).
const double kSceneW = 400;

/// Altura del suelo en la escena.
const double kSceneGround = 208;

class Actor {
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

enum FxKind { smoke, shard, sparkle, ember }

class Fx {
  final FxKind kind;
  double x, y, vx, vy, life, t = 0;
  Fx(this.kind, this.x, this.y, this.vx, this.vy, this.life);
  double get k => (t / life).clamp(0.0, 1.0);
}

abstract class _Beat {
  void start(Cutscene c) {}
  bool update(Cutscene c, double dt, bool advance);
}

/// Diálogo: espera a que el jugador pulse para continuar.
class _Say extends _Beat {
  final String? who;
  final String text;
  _Say(this.who, this.text);

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
      c.textT = 999;
      return false;
    }
    c.text = '';
    c.speaker = null;
    return true;
  }
}

class _Wait extends _Beat {
  final double d;
  double t = 0;
  _Wait(this.d);

  @override
  bool update(Cutscene c, double dt, bool advance) => (t += dt) >= d;
}

class _Do extends _Beat {
  final void Function(Cutscene c) fn;
  _Do(this.fn);

  @override
  void start(Cutscene c) => fn(c);

  @override
  bool update(Cutscene c, double dt, bool advance) => true;
}

/// Animación durante [d] segundos: fn recibe el progreso 0..1 y dt.
class _Anim extends _Beat {
  final double d;
  final void Function(Cutscene c, double p, double dt) fn;
  double t = 0;
  _Anim(this.d, this.fn);

  @override
  void start(Cutscene c) => fn(c, 0, 0);

  @override
  bool update(Cutscene c, double dt, bool advance) {
    t += dt;
    fn(c, math.min(1, t / d), dt);
    return t >= d;
  }
}

/// Camina un actor hasta [toX].
class _Move extends _Beat {
  final String name;
  final double toX, speed;
  _Move(this.name, this.toX, this.speed);

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

class Cutscene {
  final actors = <String, Actor>{};
  final fx = <Fx>[];
  final _rnd = math.Random(11);
  String? speaker;
  String text = '';
  double textT = 0;
  String? card;
  String? cardSub;
  double flash = 0;
  double shake = 0;
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

  late final List<_Beat> _beats;
  int _i = 0;

  static const double doorX = 65;

  Cutscene() {
    const g = kSceneGround;
    actors['princess'] = Actor('princess', doorX, g);
    actors['man'] = Actor('man', 440, g);
    actors['potion'] = Actor('potionEvil', 0, 0);
    actors['heart'] = Actor('heartBig', 0, 0);
    actors['orb'] = Actor('bolaMagia', 0, 0);
    actors['ghost'] = Actor('ghost', 0, g);
    actors['archer'] = Actor('archer', -20, g);
    _beats = _script();
    _beats.first.start(this);
  }

  Actor a(String name) => actors[name]!;

  /// La princesa ya está cayendo o en el suelo (cuadros 'muerte_N').
  bool get princessFallen => a('princess').sprite.startsWith('muerte');

  /// Caracteres visibles del diálogo actual (efecto máquina de escribir).
  int get visibleChars => math.min(text.length, (textT * 40).floor());
  bool get textFull => visibleChars >= text.length;

  double _r(double a, double b) => a + _rnd.nextDouble() * (b - a);

  void _emit(FxKind k, double x, double y, double vx, double vy, double life) =>
      fx.add(Fx(k, x, y, vx, vy, life));

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
        _rnd.nextDouble() < dt * 6) {
      _emit(FxKind.sparkle, pr.x + _r(-12, 12), pr.y - _r(4, 30), 0, -8, 0.8);
    }
    final gh = a('ghost');
    if (gh.visible && gh.alpha > 0.2 && _rnd.nextDouble() < dt * 10) {
      _emit(
        FxKind.sparkle,
        gh.x + _r(-14, 14),
        gh.y - _r(0, 34),
        _r(-4, 4),
        -14,
        1.0,
      );
    }
    if (glory > 0 && _rnd.nextDouble() < dt * 14 * glory) {
      _emit(
        FxKind.ember,
        _r(80, 260),
        kSceneGround,
        _r(-5, 5),
        _r(-40, -20),
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

    while (!done) {
      if (!_beats[_i].update(this, dt, advance)) break;
      advance = false;
      dt = 0;
      _i++;
      if (_i >= _beats.length) {
        done = true;
        break;
      }
      _beats[_i].start(this);
    }
  }

  void skip() => done = true;

  /// Una bocanada de humo que sale del cuerpo del actor [a] hacia fuera,
  /// con velocidad entre [vMin] y [vMax].
  void _smokePuff(Actor a, double vMin, double vMax) {
    final ang = _r(0, math.pi * 2);
    final sp = _r(vMin, vMax);
    _emit(
      FxKind.smoke,
      a.x + math.cos(ang) * _r(0, 28),
      a.y - 40 + math.sin(ang) * _r(0, 36),
      math.cos(ang) * sp,
      math.sin(ang) * sp * 0.6 - 15,
      _r(0.8, 1.6),
    );
  }

  List<_Beat> _script() {
    const g = kSceneGround;
    return [
      // ---------------------------------------------------------------
      // 1. EL REINO EN PAZ
      // ---------------------------------------------------------------
      _Wait(0.8),
      _Say(
        null,
        'HACE MUCHO TIEMPO, EN UN REINO ENTRE LAS NUBES, VIVÍA UNA PRINCESA CELESTIAL.',
      ),
      _Do(
        (c) => c.a('princess')
          ..visible = true
          ..alpha = 0,
      ),
      _Anim(1.5, (c, p, dt) {
        c.a('princess').alpha = p;
        c.glory = p * 0.35;
      }),
      _Move('princess', 175, 38),
      _Say(
        null,
        'DONDE ELLA PASABA, LAS FLORES SE ABRÍAN Y LA GENTE VOLVÍA A SONREÍR. SU LUZ LLENABA EL REINO DE PAZ Y ALEGRÍA.',
      ),
      _Anim(1.0, (c, p, dt) => c.glory = 0.35 * (1 - p)),

      // ---------------------------------------------------------------
      // 2. LLEGA SU AMIGO... Y LA TRAICIONA
      // ---------------------------------------------------------------
      _Do((c) => c.a('man').flip = true),
      _Move('man', 250, 55),
      _Say('HOMBRE', '¡PRINCESA! ¡MI AMOR, POR FIN ESTOY DE VUELTA!'),
      _Say(
        'PRINCESA',
        '¡AMOR MÍO, HAS VUELTO! TE EXTRAÑÉ TANTO... ¿DÓNDE ESTUVISTE TODO ESTE TIEMPO?',
      ),
      _Say(
        'HOMBRE',
        'VIAJÉ MUY LEJOS, PERO NUNCA DEJÉ DE PENSAR EN TI. Y HOY VENGO A HACERTE UNA PROMESA...',
      ),
      _Say(
        'HOMBRE',
        'TE DARÉ UN REINO SIN FIN, JOYAS QUE BRILLAN COMO ESTRELLAS... ¡TODO LO QUE DESEES!',
      ),
      _Say(
        'PRINCESA',
        'NO NECESITO NADA DE ESO. ME BASTA CON VER FELIZ AL REINO... Y CON TENERTE A MI LADO.',
      ),
      _Anim(1.2, (c, p, dt) => c.darkness = p * 0.2),
      _Say('HOMBRE', 'TAN BUENA... Y TAN INGENUA.'),
      _Say('PRINCESA', '¿QUÉ...? ¿POR QUÉ ME MIRAS ASÍ?'),
      _Say(
        'HOMBRE',
        'TU LUZ SIEMPRE FUE LO ÚNICO QUE YO QUERÍA. Y AHORA... ¡SERÁ MÍA!',
      ),
      // El poder oscuro lo envuelve: humo, rayos y oscuridad
      _Anim(2.0, (c, p, dt) {
        final m = c.a('man');
        m.sprite = 'poder';
        c.shake = p < 1 ? 1 + p * 1.5 : 0;
        c.darkness = 0.2 + p * 0.3;
        for (var i = 0; i < 2; i++) {
          final ang = c._r(0, math.pi * 2);
          final r = c._r(6, 20);
          c._emit(
            FxKind.smoke,
            m.x + math.cos(ang) * r,
            g - c._r(0, 34),
            math.cos(ang) * 10,
            c._r(-45, -20),
            c._r(0.7, 1.3),
          );
        }
        if (c.bolt <= 0 && c._rnd.nextDouble() < dt * 2) {
          c.bolt = 0.18;
          c.boltX = m.x + c._r(-10, 10);
          c.flash = 0.6;
        }
      }),
      // LANZAR MAGIA: carga la bola y se la lanza a la princesa
      _Anim(0.8, (c, p, dt) {
        c.a('man').sprite = 'lanzar_magia_${(p * 3).floor().clamp(0, 2) + 1}';
      }),
      _Do((c) {
        final m = c.a('man');
        m.sprite = 'lanzar_magia_4';
        c.a('orb')
          ..visible = true
          ..x = m.x - 19
          ..y = g - 25;
      }),
      _Anim(0.5, (c, p, dt) {
        final m = c.a('man');
        if (p > 0.5) m.sprite = 'lanzar_magia_5';
        c.a('orb')
          ..x = m.x - 19 + (175 - (m.x - 19)) * p
          ..y = g - 25 + 7 * p;
      }),
      _Do((c) {
        c.a('orb').visible = false;
        c.flash = 1;
        c.shake = 3;
      }),
      // La princesa cae (cuadros de MUERTE de su hoja)
      _Anim(0.9, (c, p, dt) {
        c.a('princess').sprite = 'muerte_${(p * 4).floor().clamp(0, 3) + 1}';
        if (p >= 1) c.shake = 0;
      }),
      // ATAQUE (ROBA EL CORAZÓN): el rayo rojo le saca el corazón
      _Anim(
        0.6,
        (c, p, dt) => c.a('man').sprite = p < 0.5 ? 'ataque_1' : 'ataque_2',
      ),
      _Anim(0.6, (c, p, dt) {
        c.a('man').sprite = p < 0.35
            ? 'ataque_3'
            : p < 0.7
            ? 'ataque_4'
            : 'ataque_5';
        c.beam = p;
        c.beamAlpha = 1;
      }),
      _Do((c) {
        c.flash = 0.6;
        c.a('heart')
          ..visible = true
          ..x = 175
          ..y = g - 6;
      }),
      // El corazón viaja por el rayo hasta su mano
      _Anim(1.4, (c, p, dt) {
        final h = c.a('heart');
        final m = c.a('man');
        final hx = m.x - 18, hy = g - 17;
        h.x = 175 + (hx - 175) * p;
        h.y = g - 6 + (hy - (g - 6)) * p + math.sin(p * math.pi * 6) * 1.5;
      }),
      _Anim(0.3, (c, p, dt) {
        c.beamAlpha = 1 - p;
        if (p >= 1) c.beam = 0;
      }),
      _Do((c) {
        c.a('heart').visible = false;
        c.a('man').sprite = 'con_corazon';
      }),
      _Say(
        'HOMBRE',
        '¿AMOR? NUNCA TE AMÉ, PRINCESA. Y ESTE CORAZÓN... ¡YA NO TE SIRVE DE NADA!',
      ),
      // Lo aprieta en su mano y el corazón estalla en pedazos
      _Do((c) {
        final m = c.a('man');
        m.sprite = 'man';
        for (var i = 0; i < 16; i++) {
          final ang = -math.pi * c._r(0.05, 0.95);
          final sp = c._r(60, 150);
          c._emit(
            FxKind.shard,
            m.x - 16,
            g - 24,
            math.cos(ang) * sp,
            math.sin(ang) * sp,
            3,
          );
        }
        c.flash = 0.8;
        c.shake = 2;
      }),
      _Anim(0.4, (c, p, dt) {
        if (p >= 1) c.shake = 0;
      }),
      _Wait(0.6),
      // SALTO para retirarse; en el aire se transforma en demonio alado
      _Do((c) => c.a('man').sprite = 'saltar_1'),
      _Wait(0.35),
      _Anim(0.9, (c, p, dt) {
        final m = c.a('man');
        m.sprite = p < 0.45 ? 'saltar_2' : 'saltar_3';
        m.x = 250 + p * 30;
        m.y = g - math.sin(p * math.pi / 2) * 80;
      }),
      _Anim(1.2, (c, p, dt) {
        final m = c.a('man');
        c.shake = p < 1 ? 2 : 0;
        c.darkness = 0.5 + p * 0.1;
        m.sprite = p >= 0.75
            ? 'demonio'
            : p < 0.25
            ? 'demonio_1'
            : p < 0.5
            ? 'demonio_2'
            : 'demonio_3';
        if (p < 0.02) {
          c.flash = 1;
          c.bolt = 0.25;
          c.boltX = m.x;
        }
        for (var i = 0; i < 3; i++) {
          final ang = c._r(0, math.pi * 2);
          c._emit(
            FxKind.smoke,
            m.x + math.cos(ang) * 18,
            m.y - c._r(0, 40),
            math.cos(ang) * 20,
            c._r(-30, 10),
            c._r(0.6, 1.1),
          );
        }
      }),
      _Say('DEMONIO', '¡JA, JA, JA! ¡CON TU LUZ SERÉ UN DEMONIO INVENCIBLE!'),
      // Desaparece en una nube de humo
      _Do((c) {
        final d = c.a('man');
        c.flash = 0.7;
        c.shake = 2;
        for (var i = 0; i < 90; i++) {
          c._smokePuff(d, 60, 90);
        }
      }),
      _Anim(1.2, (c, p, dt) {
        final d = c.a('man');
        d.alpha = 1 - p;
        if (p < 0.7) {
          for (var i = 0; i < 8; i++) {
            c._smokePuff(d, 30, 50);
          }
        }
        if (p >= 1) {
          c.shake = 0;
          d.visible = false;
        }
      }),
      // ---------------------------------------------------------------
      // 3. EL LIMBO: la princesa se pregunta por qué
      // ---------------------------------------------------------------
      _Wait(0.6),
      _Anim(2.0, (c, p, dt) {
        c.limbo = p;
        c.darkness = 0.6 * (1 - p);
      }),
      _Say('PRINCESA', '¿DÓNDE ESTOY...? TODO ES TAN FRÍO Y SILENCIOSO...'),
      _Say(
        'PRINCESA',
        'ERA MI AMOR... LE DI MI CORAZÓN ENTERO. ¿POR QUÉ NO VI LO QUE ESCONDÍA?',
      ),
      _Say('PRINCESA', '¿FUE MI CULPA? ¿ACASO MI LUZ NUNCA FUE SUFICIENTE...?'),
      _Say(
        'PRINCESA',
        'MI CORAZÓN ESTÁ HECHO MIL PEDAZOS... ¿QUEDA ALGO DE MÍ?',
      ),

      // ---------------------------------------------------------------
      // 4. EL ARQUERO: pasa, se detiene y la reconoce
      // ---------------------------------------------------------------
      _Anim(1.5, (c, p, dt) => c.limbo = 1 - p * 0.6),
      _Move('archer', 260, 45),
      _Wait(0.8),
      _Say('ARQUERO', '...'),
      _Do((c) => c.a('archer').flip = true),
      _Wait(0.5),
      _Say('ARQUERO', 'ESPERA... ESE CABELLO... ESA ESPADA...'),
      _Say(
        'ARQUERO',
        '¡NO PUEDE SER! ES ELLA... LA PRINCESA. MI AMIGA, LA QUE SIEMPRE TENÍA UNA SONRISA PARA TODOS.',
      ),
      _Move('archer', 212, 60),
      _Say(
        'ARQUERO',
        'AGUANTA, PRINCESA. ESTA POCIÓN ES TODO LO QUE TENGO... ¡POR FAVOR, QUE FUNCIONE!',
      ),
      // Le lanza la poción: vuela en arco hasta ella
      _Do((c) {
        c.a('potion')
          ..sprite = 'potionGood'
          ..visible = true
          ..x = 206
          ..y = g - 18;
      }),
      _Anim(0.7, (c, p, dt) {
        c.a('potion')
          ..x = 206 - 31 * p
          ..y = g - 18 + 12 * p - math.sin(p * math.pi) * 22;
      }),
      _Do((c) {
        c.a('potion').visible = false;
        c.flash = 0.5;
        c.healFlash = 1;
        for (var i = 0; i < 30; i++) {
          final ang = c._r(0, math.pi * 2);
          final sp = c._r(20, 70);
          c._emit(
            FxKind.sparkle,
            175,
            g - 6,
            math.cos(ang) * sp,
            math.sin(ang) * sp - 20,
            c._r(0.8, 1.6),
          );
        }
      }),
      // Sale el fantasma de la princesa y el limbo se disipa
      _Do((c) {
        c.princessIsGhost = true;
        c.a('ghost')
          ..visible = true
          ..alpha = 0
          ..x = 175;
      }),
      _Anim(2.0, (c, p, dt) {
        c.limbo = 0.4 * (1 - p);
        c.a('ghost')
          ..alpha = 0.78 * p
          ..y = g - p * 18;
      }),
      _Say(
        'PRINCESA',
        '¿ARQUERO...? ¿ERES TÚ? TU VOZ ME SACÓ DE LA OSCURIDAD...',
      ),
      _Say(
        'PRINCESA',
        'PERO MI CUERPO NO DESPIERTA. ÉL ME TRAICIONÓ... Y MI CORAZÓN QUEDÓ HECHO MIL PEDAZOS.',
      ),
      _Say('ARQUERO', 'ENTONCES YO ME ENCARGARÉ DE SANARTE.'),
      _Anim(1.5, (c, p, dt) => c.glory = p),
      _Say(
        'ARQUERO',
        'BUSCARÉ CADA PEDAZO DE TU CORAZÓN, UNO POR UNO, HASTA SANARLO... Y TE DEVOLVERÉ LA ESPERANZA. TE LO PROMETO.',
      ),
      _Say(
        'PRINCESA',
        'ENTONCES NO ESTOY SOLA... GRACIAS, AMIGO. NO PUEDO LUCHAR, PERO SIEMPRE ESTARÉ A TU LADO.',
      ),
      _Say(
        null,
        'ASÍ COMENZÓ EL VIAJE DE UN ARQUERO Y UNA PRINCESA PARA DEVOLVERLE LA LUZ AL REINO.',
      ),
      _Anim(3.2, (c, p, dt) {
        c.card = 'STAGE 1';
        c.cardSub = 'EL BOSQUE DE LOS DUENDES';
      }),
    ];
  }
}
