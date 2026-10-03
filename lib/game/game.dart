import 'dart:math' as math;

import '../escenarios/escenario.dart';
import '../escenarios/escenarios.dart';
import '../personajes/arquero/ajustes.dart';
import '../personajes/arquero/arquero.dart';
import '../personajes/arquero/disparar.dart';
import '../personajes/arquero/recibir_dano.dart';
import '../personajes/arquero/saltar.dart';
import '../sonido/efecto.dart';
import 'cutscene.dart';
import 'level.dart';

enum GameState { title, intro, playing, dying, reward, clear, gameOver }

class Input {
  bool left = false;
  bool right = false;
  bool jump = false;
  bool run = false;
  bool shoot = false;
  bool start = false;
  bool skip = false;
}

class Box {
  double x, y, w, h;
  double vx = 0, vy = 0;
  bool onGround = false;
  Box(this.x, this.y, this.w, this.h);

  double get right => x + w;
  double get bottom => y + h;
  double get cx => x + w / 2;
  double get cy => y + h / 2;

  bool overlaps(Box o) =>
      x < o.x + o.w && x + w > o.x && y < o.y + o.h && y + h > o.y;
}

class Enemy extends Box {
  final EnemyKind kind;
  int dir = -1;
  int hp;
  bool active = false;
  bool dead = false;
  double hitFlash = 0;
  double throwTimer;
  double throwPose = 0;
  double anim = 0;
  Enemy(
    this.kind,
    double x,
    double y,
    double w,
    double h,
    this.hp,
    this.throwTimer,
  ) : super(x, y, w, h);

  double get speed => switch (kind) {
    EnemyKind.rat => 65,
    EnemyKind.goblin => 25,
    EnemyKind.mage => 18,
    EnemyKind.darkArcher => 30,
  };
}

enum TipoProyectil {
  /// Piedra de duende: cae en curva.
  piedra,

  /// Bola mágica de mago oscuro: vuela recta ondulando.
  magia,

  /// Flecha de arquero sombrío: recta y rápida.
  flecha,
}

/// Algo que lanza un enemigo contra el arquero.
class Proyectil extends Box {
  final TipoProyectil tipo;
  double t = 0;
  Proyectil(this.tipo, double x, double y, double vx, double vy)
    : super(
        x,
        y,
        switch (tipo) {
          TipoProyectil.piedra => 6,
          TipoProyectil.magia => 8,
          TipoProyectil.flecha => 10,
        },
        switch (tipo) {
          TipoProyectil.piedra => 5,
          TipoProyectil.magia => 8,
          TipoProyectil.flecha => 3,
        },
      ) {
    this.vx = vx;
    this.vy = vy;
  }
}

/// Hada que flota en su sitio; al tocarla cura al arquero.
class Hada extends Box {
  final double baseX, baseY;
  double t = 0;
  Hada(this.baseX, this.baseY) : super(baseX, baseY, 12, 12);
}

/// Cofre: se abre al tocarlo y da cristales o una poción.
class Cofre extends Box {
  final bool pocion;
  bool abierto = false;
  double t = 0;
  Cofre(double x, double y, {required this.pocion}) : super(x, y, 14, 11);
}

class Spark {
  double x, y, t = 0;
  Spark(this.x, this.y);
}

/// Cristal que salta de un cofre al abrirlo.
class CristalPop {
  double x, y, vx, vy = -300, t = 0;
  CristalPop(this.x, this.y, this.vx);
}

class ScorePop {
  final String text;
  double x, y, t = 0;
  ScorePop(this.text, this.x, this.y);
}

/// El fantasma de la princesa: sigue al arquero y le da ánimos.
class Ghost {
  double x, y;
  String? speech;
  double speechT = 0;
  double idle = 0;
  Ghost(this.x, this.y);
}

/// Con qué chocó una caja al moverse (lo devuelve [Game.mover]).
class Choque {
  bool pared = false;
  bool techo = false;
}

class Game {
  static const double gravity = 1600;
  static const double gravityHold = 700;
  static const double maxFall = 450;

  static const _cheer = [
    '¡TÚ PUEDES, ARQUERO!',
    'CREO EN TI.',
    '¡SIGUE ADELANTE!',
    'SIENTO MI CORAZÓN CERCA...',
    'NO TE RINDAS, POR FAVOR.',
    'ERES MI ÚNICA ESPERANZA.',
  ];
  static const _praise = [
    '¡BIEN HECHO!',
    '¡GRAN DISPARO!',
    '¡ERES INCREÍBLE!',
    '¡UNO MENOS!',
    '¡QUÉ VALIENTE!',
  ];
  static const _worried = [
    '¡CUIDADO!',
    '¡RESISTE, ARQUERO!',
    '¡SALTA PARA ESQUIVAR!',
    '¡NO TE RINDAS!',
  ];

  final _rnd = math.Random();

  late LevelData level;
  late List<List<int>> grid;
  late Arquero arquero;
  late Ghost ghost;
  Cutscene? intro;
  final enemies = <Enemy>[];
  final flechas = <Flecha>[];
  final proyectiles = <Proyectil>[];
  final hadas = <Hada>[];
  final cristales = <Box>[];
  final cofres = <Cofre>[];
  final sparks = <Spark>[];
  final cristalPops = <CristalPop>[];
  final scorePops = <ScorePop>[];

  double camX = 0;
  double viewW = 400;
  int score = 0;
  int numCristales = 0;
  int lives = 3;
  double time = 300;
  double clock = 0;
  GameState state = GameState.title;
  double stateTimer = 0;
  bool _avisoMeta = false;

  /// Número del escenario actual en la lista `escenarios` (0 = el primero).
  int stage = empezarEnEscenario;
  Escenario get escenario => escenarios[stage];
  bool get hayOtroEscenario => stage < escenarios.length - 1;

  /// Segundos que queda en pantalla la tarjeta "STAGE N" antes de jugar.
  double tarjeta = 0;

  /// Sonidos pedidos en este cuadro (ver lib/sonido/efecto.dart). Quien
  /// dibuja el juego los reproduce y vacía la lista.
  final sonidos = <Efecto>[];

  void sonar(Efecto e) {
    if (sonidos.length < 32) sonidos.add(e);
  }

  bool _prevJump = false;
  bool _prevStart = false;
  bool _prevShoot = false;
  bool _startRequested = false;

  Game() {
    _loadLevel();
  }

  /// Centro del portal de la meta: al llegar aquí se completa el stage.
  double get puertaMetaX => level.metaX * T + 40;
  bool get bonusDone => state == GameState.clear && time <= 0;

  void _loadLevel() {
    level = escenario.construir();
    grid = level.grid;
    final suelo = (level.filaSuelo(3) ?? 13) * T;
    arquero = Arquero(3 * T, suelo - AjustesArquero.alto)..onGround = true;
    ghost = Ghost(arquero.x - 20, arquero.y - 10);
    enemies
      ..clear()
      ..addAll(level.enemies.map(_crearEnemigo));
    hadas
      ..clear()
      ..addAll(level.hadas.map((h) => Hada(h.x * T + 2, h.y * T + 2)));
    cristales
      ..clear()
      ..addAll(
        level.cristales.map((p) => Box(p.x * T + 3, p.y * T + 2, 10, 12)),
      );
    cofres
      ..clear()
      ..addAll(
        level.cofres.map(
          (c) => Cofre(c.x * T + 1, (c.y + 1) * T - 11, pocion: c.pocion),
        ),
      );
    flechas.clear();
    proyectiles.clear();
    sparks.clear();
    cristalPops.clear();
    scorePops.clear();
    camX = 0;
    time = escenario.tiempo.toDouble();
    stateTimer = 0;
    _avisoMeta = false;
  }

  /// Tamaño, vida y primer ataque de cada tipo de enemigo.
  Enemy _crearEnemigo(EnemySpawn s) {
    final x = s.x * T + 1, suelo = (s.y + 1) * T;
    final primerAtaque = 1.2 + _rnd.nextDouble() * 1.5;
    return switch (s.kind) {
      EnemyKind.goblin => Enemy(s.kind, x, suelo - 15, 14, 15, 2, primerAtaque),
      EnemyKind.rat => Enemy(s.kind, x, suelo - 8, 14, 8, 1, 0),
      EnemyKind.mage => Enemy(s.kind, x, suelo - 20, 14, 20, 2, primerAtaque),
      EnemyKind.darkArcher => Enemy(
        s.kind,
        x,
        suelo - 20,
        12,
        20,
        1,
        primerAtaque,
      ),
    };
  }

  /// Llamado desde un toque en pantalla.
  void requestStart() => _startRequested = true;

  void say(String text, {bool force = false}) {
    if (!force && ghost.speech != null) return;
    ghost.speech = text;
    ghost.speechT = 2.8;
    ghost.idle = 0;
  }

  void update(double dt, Input input) {
    clock += dt;
    final jumpPressed = input.jump && !_prevJump;
    _prevJump = input.jump;
    final shootPressed = input.shoot && !_prevShoot;
    _prevShoot = input.shoot;
    final startPressed =
        (input.start && !_prevStart) ||
        jumpPressed ||
        shootPressed ||
        _startRequested;
    _prevStart = input.start;
    _startRequested = false;

    switch (state) {
      case GameState.title:
        if (startPressed) {
          sonar(Efecto.inicio);
          if (stage == 0) {
            intro = Cutscene();
            state = GameState.intro;
          } else {
            _beginStage();
          }
        }
        break;
      case GameState.intro:
        final c = intro!;
        if (input.skip) c.skip();
        c.update(dt, startPressed);
        if (c.done) {
          intro = null;
          // La intro ya enseña su propia tarjeta de "STAGE 1".
          _beginStage(conTarjeta: false);
        }
        break;
      case GameState.playing:
        if (tarjeta > 0) {
          tarjeta -= dt;
          break;
        }
        _updatePlaying(dt, input, jumpPressed, shootPressed);
        _updateCommon(dt);
        break;
      case GameState.dying:
        _updateDying(dt);
        _updateGhost(dt);
        break;
      case GameState.reward:
        stateTimer += dt;
        _updateCommon(dt);
        if (stateTimer > 4.5) {
          state = GameState.clear;
          stateTimer = 0;
        }
        break;
      case GameState.clear:
        stateTimer += dt;
        _updateCommon(dt);
        if (time > 0) {
          final step = math.min(time, 1.0);
          time -= step;
          score += (step * 50).round();
        } else if (startPressed && stateTimer > 2) {
          if (hayOtroEscenario) {
            // Al siguiente escenario, conservando puntos, monedas y vidas.
            stage++;
            _loadLevel();
            _beginStage();
          } else {
            score = 0;
            numCristales = 0;
            lives = 3;
            stage = empezarEnEscenario;
            _loadLevel();
            state = GameState.title;
          }
        }
        break;
      case GameState.gameOver:
        stateTimer += dt;
        if (startPressed && stateTimer > 1) {
          score = 0;
          numCristales = 0;
          lives = 3;
          _loadLevel();
          _beginStage();
        }
        break;
    }
  }

  /// Qué música toca ahora (archivo de lib/sonido/musica/; null = nada).
  String? get musica => switch (state) {
    GameState.title || GameState.intro => 'titulo',
    GameState.playing || GameState.dying => escenario.musica,
    GameState.reward || GameState.clear || GameState.gameOver => null,
  };

  /// Empieza a jugar directamente el escenario número [n] de la lista.
  void irAEscenario(int n) {
    stage = n;
    _loadLevel();
    _beginStage();
  }

  void _beginStage({bool conTarjeta = true}) {
    state = GameState.playing;
    tarjeta = conTarjeta ? 2.5 : 0;
    say(escenario.fraseInicio, force: true);
  }

  // -------------------------------------------------------------------------
  // Jugando
  // -------------------------------------------------------------------------

  void _updatePlaying(
    double dt,
    Input input,
    bool jumpPressed,
    bool shootPressed,
  ) {
    time -= dt * 2.5;
    if (time <= 0) {
      time = 0;
      _die();
      return;
    }

    final p = arquero;
    p.actualizar(
      dt,
      Botones(
        direccion: (input.right ? 1 : 0) - (input.left ? 1 : 0),
        correr: input.run,
        saltoApretado: input.jump,
        saltoPulsado: jumpPressed,
        disparoPulsado: shootPressed,
      ),
      this,
    );

    // La cámara no retrocede: el arquero no puede salirse por la izquierda.
    if (p.x < camX) {
      p.x = camX;
      if (p.vx < 0) p.vx = 0;
    }

    if (p.y > kRows * T + 16) {
      _die();
      return;
    }

    actualizarFlechas(this, dt);
    _updateEnemies(dt);
    if (state != GameState.playing) return;
    _updateProyectiles(dt);
    if (state != GameState.playing) return;
    _updateHadas(dt);
    _updateCofres();
    _recogerCristales();

    if (!_avisoMeta && p.x > (level.metaX - 14) * T) {
      _avisoMeta = true;
      say(escenario.fraseMetaCerca, force: true);
    }
    if (p.cx >= puertaMetaX) {
      _llegarMeta();
      return;
    }

    _updateCamera();
  }

  void _updateCamera() {
    final target = arquero.cx - viewW * 0.4;
    camX = math.max(camX, target);
    camX = camX.clamp(0, math.max(0, level.width * T - viewW)).toDouble();
  }

  /// Enemigos en pantalla que siguen vivos.
  Iterable<Enemy> get enemigosVivos =>
      enemies.where((e) => e.active && !e.dead);

  /// Quita un punto de vida a [e]; [fromDir] es hacia dónde lo empuja.
  void danarEnemigo(Enemy e, int fromDir) {
    e.hp--;
    e.hitFlash = 0.15;
    if (e.hp <= 0) {
      _killEnemy(e, fromDir);
    } else {
      e.x += fromDir * 4;
      sonar(Efecto.golpe);
    }
  }

  void _killEnemy(Enemy e, int fromDir, {Efecto sonido = Efecto.enemigoMuere}) {
    sonar(sonido);
    e.dead = true;
    e.vy = -220;
    e.vx = fromDir * 50.0;
    final pts = switch (e.kind) {
      EnemyKind.rat => 100,
      EnemyKind.goblin || EnemyKind.darkArcher => 200,
      EnemyKind.mage => 300,
    };
    _addScore(pts, e.cx, e.y);
    if (_rnd.nextDouble() < 0.45) {
      say(_praise[_rnd.nextInt(_praise.length)]);
    }
  }

  void _updateEnemies(double dt) {
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
        e.vy += gravity * dt;
        e.x += e.vx * dt;
        e.y += e.vy * dt;
        continue;
      }
      e.anim += dt;
      e.hitFlash -= dt;
      e.throwPose -= dt;

      var walking = true;
      final alcance = _alcanceAtaque(e);
      if (alcance != null) {
        final dx = p.cx - e.cx;
        final near = dx.abs() < alcance.x && (p.cy - e.cy).abs() < alcance.y;
        if (near && state == GameState.playing) {
          // Se detiene, mira al arquero y le ataca de lejos.
          walking = false;
          e.dir = dx < 0 ? -1 : 1;
          e.throwTimer -= dt;
          if (e.throwTimer <= 0) {
            e.throwTimer = alcance.espera + _rnd.nextDouble() * 1.2;
            e.throwPose = 0.3;
            _lanzar(e);
          }
        }
      }

      e.vx = walking ? e.dir * e.speed : 0;
      e.vy = math.min(e.vy + gravity * dt, maxFall);
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
        _killEnemy(e, side, sonido: Efecto.pisoton);
      } else if (p.invencible <= 0) {
        _hurt(e.cx);
        if (state != GameState.playing) return;
      }
    }

    enemies.removeWhere(
      (e) => e.y > kRows * T + 64 || (e.active && e.right < camX - 64),
    );
  }

  /// A qué distancia ve al arquero (x horizontal, y vertical) y cuántos
  /// segundos espera como mínimo entre ataques. null = no ataca de lejos.
  ({double x, double y, double espera})? _alcanceAtaque(Enemy e) =>
      switch (e.kind) {
        EnemyKind.goblin => (x: 150, y: 48, espera: 1.8),
        EnemyKind.mage => (x: 170, y: 56, espera: 2.4),
        // La flecha va recta: solo dispara si está más o menos a su altura.
        EnemyKind.darkArcher => (x: 200, y: 20, espera: 2.0),
        EnemyKind.rat => null,
      };

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

  void _updateProyectiles(double dt) {
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
          _hurt(r.cx);
        }
        return true;
      }
      return false;
    });
  }

  void _updateHadas(double dt) {
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
        _addScore(500, h.cx, h.y);
        say('EL HADA TE DA SU BENDICIÓN.', force: true);
      }
      return true;
    });
  }

  void _updateCofres() {
    for (final c in cofres) {
      if (c.abierto || !arquero.overlaps(c)) continue;
      c.abierto = true;
      sparks.add(Spark(c.cx, c.y));
      sonar(c.pocion ? Efecto.curar : Efecto.cofre);
      if (c.pocion) {
        if (curar(arquero)) {
          say('¡UNA POCIÓN! TE SIENTES MEJOR.', force: true);
        } else {
          _addScore(1000, c.cx, c.y - 8);
        }
      } else {
        // Salen 5 cristales en abanico.
        for (var i = 0; i < 5; i++) {
          cristalPops.add(CristalPop(c.cx - 5, c.y - 6, (i - 2) * 35.0));
        }
        if (_rnd.nextDouble() < 0.5) say('¡UN COFRE LLENO DE CRISTALES!');
      }
    }
  }

  void _recogerCristales() {
    cristales.removeWhere((c) {
      if (!arquero.overlaps(c)) return false;
      sonar(Efecto.cristal);
      _sumarCristal();
      score += 100;
      return true;
    });
  }

  /// Cada 100 cristales, una vida extra.
  void _sumarCristal() {
    numCristales++;
    if (numCristales >= 100) {
      numCristales -= 100;
      lives++;
    }
  }

  void _addScore(int pts, double x, double y) {
    score += pts;
    scorePops.add(ScorePop('$pts', x, y));
  }

  void _hurt(double fromX) {
    if (recibirGolpe(arquero, fromX)) {
      _die();
      return;
    }
    sonar(Efecto.dano);
    say(_worried[_rnd.nextInt(_worried.length)], force: true);
  }

  void _die() {
    state = GameState.dying;
    stateTimer = 0;
    morir(arquero);
    sonar(Efecto.muerte);
    say('¡NOOO! ¡ARQUERO!', force: true);
  }

  void _updateDying(double dt) {
    stateTimer += dt;
    final p = arquero;
    // Cae con gravedad hasta el suelo (o al fondo de un hueco).
    if (p.y < kRows * T + 64) {
      p.vx = 0;
      p.vy = math.min(p.vy + gravity * dt, maxFall);
      mover(p, dt);
    }
    if (stateTimer > 3) {
      lives--;
      if (lives <= 0) {
        state = GameState.gameOver;
        stateTimer = 0;
      } else {
        _loadLevel();
        _beginStage();
      }
    }
  }

  // -------------------------------------------------------------------------
  // Final del stage
  // -------------------------------------------------------------------------

  void _llegarMeta() {
    final p = arquero;
    state = GameState.reward;
    stateTimer = 0;
    p.vx = 0;
    p.mira = 1;
    proyectiles.clear();
    sonar(Efecto.victoria);
    say(escenario.fraseRecompensa, force: true);
  }

  /// Progreso (0..1) de los objetos que salen del castillo hacia el arquero.
  double get rewardProgress =>
      state == GameState.reward ? math.min(1, stateTimer / 2.5) : 1;

  // -------------------------------------------------------------------------
  // Efectos y fantasma
  // -------------------------------------------------------------------------

  void _updateCommon(double dt) {
    _updateGhost(dt);

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
        _addScore(100, c.x + 5, c.y);
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

  void _updateGhost(double dt) {
    final p = arquero;
    final gh = ghost;
    final tx = p.cx - p.mira * 24;
    final ty = p.y - 14 + math.sin(clock * 2.5) * 4;
    final k = 1 - math.exp(-3.5 * dt);
    gh.x += (tx - gh.x) * k;
    gh.y += (ty - gh.y) * k;
    if (gh.y > 12 * T - 20) gh.y = 12 * T - 20;

    if (gh.speech != null) {
      gh.speechT -= dt;
      if (gh.speechT <= 0) gh.speech = null;
    } else if (state == GameState.playing) {
      gh.idle += dt;
      if (gh.idle > 11) {
        final frases = [..._cheer, ...escenario.consejos];
        say(frases[_rnd.nextInt(frases.length)]);
      }
    }
  }

  // -------------------------------------------------------------------------
  // Colisiones con tiles
  // -------------------------------------------------------------------------

  /// ¿Hay algo sólido en el punto (x, y) del mundo? Cuenta la tierra, la
  /// roca y lo que queda por debajo de una cuesta; las ramas no.
  bool esSolido(double x, double y) {
    final tx = (x / T).floor(), ty = (y / T).floor();
    final t = _tile(tx, ty);
    if (Tile.isSlope(t)) return y - ty * T >= Tile.slopeSurface(t, x - tx * T);
    return Tile.isSolid(t);
  }

  int _tile(int tx, int ty) {
    if (tx < 0 || ty < 0 || tx >= level.width || ty >= kRows) {
      return Tile.empty;
    }
    return grid[ty][tx];
  }

  /// Casillas que cortan el paso por los lados y por arriba.
  bool _solid(int tx, int ty) {
    if (ty < 0 || ty >= kRows) return false;
    if (tx < 0 || tx >= level.width) return true;
    return Tile.isSolid(grid[ty][tx]);
  }

  /// Lo que puede subir o bajar un personaje de golpe al caminar, sin
  /// saltar (sirve para seguir las cuestas).
  static const _escalon = 8.0;

  /// Mueve la caja [b] según su velocidad y la para al chocar.
  Choque mover(Box b, double dt) {
    final hit = Choque();
    final enSuelo = b.onGround;

    // 1. De lado. En el suelo se ignoran los pies (_escalon) para poder
    //    subir cuestas.
    b.x += b.vx * dt;
    final top = (b.y / T).floor();
    final bot = ((b.bottom - (enSuelo ? _escalon : 0.01)) / T).floor();
    if (b.vx > 0) {
      final tx = ((b.right - 0.01) / T).floor();
      for (var ty = top; ty <= bot; ty++) {
        if (_solid(tx, ty)) {
          b.x = tx * T - b.w;
          b.vx = 0;
          hit.pared = true;
          break;
        }
      }
    } else if (b.vx < 0) {
      final tx = (b.x / T).floor();
      for (var ty = top; ty <= bot; ty++) {
        if (_solid(tx, ty)) {
          b.x = (tx + 1) * T;
          b.vx = 0;
          hit.pared = true;
          break;
        }
      }
    }

    // 2. Arriba o abajo.
    b.y += b.vy * dt;
    b.onGround = false;
    if (b.vy >= 0) {
      final antes = b.bottom - b.vy * dt;
      final suelo = _suelo(
        b,
        desde: antes - (enSuelo ? _escalon : 0),
        hasta: b.bottom + (enSuelo ? _escalon : 0.05),
        antes: antes,
      );
      if (suelo != null) {
        b.y = suelo - b.h;
        b.vy = 0;
        b.onGround = true;
      }
    } else {
      final ty = (b.y / T).floor();
      final l = (b.x / T).floor(), r = ((b.right - 0.01) / T).floor();
      for (var tx = l; tx <= r; tx++) {
        if (_solid(tx, ty)) {
          b.y = (ty + 1) * T;
          b.vy = 0;
          hit.techo = true;
          break;
        }
      }
    }
    return hit;
  }

  /// La superficie más alta que pisaría [b] entre las alturas [desde] y
  /// [hasta], o null si no hay ninguna. [antes] es dónde tenía los pies
  /// antes de moverse (para las ramas: solo se pisan viniendo de arriba).
  double? _suelo(
    Box b, {
    required double desde,
    required double hasta,
    required double antes,
  }) {
    // Si el centro está sobre una cuesta, manda la cuesta. Se acepta
    // aunque quede hasta una casilla por encima: así, si llega por un lado,
    // sube a la superficie en vez de colarse dentro.
    final tc = (b.cx / T).floor();
    for (var ty = ((desde - T) / T).floor(); ty <= (hasta / T).floor(); ty++) {
      final t = _tile(tc, ty);
      if (!Tile.isSlope(t)) continue;
      final s = ty * T + Tile.slopeSurface(t, b.cx - tc * T);
      if (s >= desde - T && s <= hasta) return s;
    }

    double? mejor;
    final l = (b.x / T).floor(), r = ((b.right - 0.01) / T).floor();
    for (var ty = (desde / T).ceil(); ty <= (hasta / T).floor(); ty++) {
      final s = ty * T;
      for (var tx = l; tx <= r; tx++) {
        final t = _tile(tx, ty);
        final encima = _tile(tx, ty - 1);
        final pisable =
            (Tile.isSolid(t) &&
                !Tile.isSolid(encima) &&
                !Tile.isSlope(encima)) ||
            (t == Tile.platform && s >= antes - 0.5);
        if (pisable && (mejor == null || s < mejor)) mejor = s;
      }
    }
    return mejor;
  }
}
