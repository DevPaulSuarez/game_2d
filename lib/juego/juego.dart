// EL JUEGO: guarda todo lo que pasa en la partida y decide qué toca en
// cada instante (título, intro, jugando, muriendo, meta...).
//
// main.dart llama a update() unas 120 veces por segundo. Las piezas:
//
//   juego.dart      ESTE archivo: el estado y el orden de las cosas
//   ajustes.dart    los números (gravedad, puntos, fichas de enemigos...)
//   entidades.dart  los datos de cada cosa (caja, enemigo, cofre, hada...)
//   fisica.dart     moverse y chocar con el mapa
//   enemigos.dart   lo que hacen los enemigos y sus proyectiles
//   objetos.dart    hadas, cofres, cristales y efectos
//   fantasma.dart   el fantasma de la princesa y sus frases
//   nivel.dart      el mapa ya construido (casillas, tamaño de casilla)
//
// Quien importa este archivo tiene también todas esas piezas.

import 'dart:math' as math;

import '../escenarios/escenario.dart';
import '../escenarios/escenarios.dart';
import '../intro/escena.dart';
import '../personajes/arquero/ajustes.dart';
import '../personajes/arquero/arquero.dart';
import '../personajes/arquero/disparar.dart';
import '../personajes/arquero/recibir_dano.dart';
import '../sonido/efecto.dart';
import 'ajustes.dart';
import 'enemigos.dart';
import 'entidades.dart';
import 'fantasma.dart';
import 'fisica.dart';
import 'nivel.dart';
import 'objetos.dart';

export 'ajustes.dart';
export 'enemigos.dart';
export 'entidades.dart';
export 'fantasma.dart';
export 'fisica.dart';
export 'nivel.dart';
export 'objetos.dart';

/// En qué pantalla está el juego.
enum GameState {
  /// Pantalla de título.
  title,

  /// La historia del principio (lib/intro/).
  intro,
  playing,

  /// El arquero cae; luego se pierde una vida.
  dying,

  /// Llegó a la meta: el fragmento vuela hacia él.
  reward,

  /// "STAGE COMPLETADO" y cuenta de puntos.
  clear,
  gameOver,
}

class Game {
  final rnd = math.Random();

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

  /// Dónde empieza lo que se ve de pantalla (en x) y lo que mide de ancho.
  double camX = 0;
  double viewW = 400;
  int score = 0;
  int numCristales = 0;
  int lives = AjustesJuego.vidasIniciales;

  /// El reloj de arriba (TIEMPO).
  double time = 300;

  /// Segundos desde que se abrió el juego (para animaciones).
  double clock = 0;
  GameState state = GameState.title;

  /// Segundos que lleva en la pantalla actual.
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

  /// Atajos a la física (fisica.dart).
  Choque mover(Box b, double dt) => level.mover(b, dt);
  bool esSolido(double x, double y) => level.esSolido(x, y);

  void _loadLevel() {
    level = escenario.construir();
    grid = level.grid;
    final suelo = (level.filaSuelo(3) ?? 13) * T;
    arquero = Arquero(3 * T, suelo - AjustesArquero.alto)..onGround = true;
    ghost = Ghost(arquero.x - 20, arquero.y - 10);
    enemies
      ..clear()
      ..addAll(level.enemies.map((s) => crearEnemigo(s, rnd)));
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

  /// Llamado desde un toque en pantalla.
  void requestStart() => _startRequested = true;

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
        actualizarFantasma(dt);
        break;
      case GameState.reward:
        stateTimer += dt;
        _updateCommon(dt);
        if (stateTimer > AjustesJuego.duracionRecompensa) {
          state = GameState.clear;
          stateTimer = 0;
        }
        break;
      case GameState.clear:
        stateTimer += dt;
        _updateCommon(dt);
        if (time > 0) {
          // El tiempo que sobra se convierte en puntos.
          final step = math.min(time, 1.0);
          time -= step;
          score += (step * AjustesJuego.puntosPorSegundo).round();
        } else if (startPressed && stateTimer > 2) {
          if (hayOtroEscenario) {
            // Al siguiente escenario, conservando puntos, cristales y vidas.
            stage++;
            _loadLevel();
            _beginStage();
          } else {
            _reiniciarPartida();
            stage = empezarEnEscenario;
            _loadLevel();
            state = GameState.title;
          }
        }
        break;
      case GameState.gameOver:
        stateTimer += dt;
        if (startPressed && stateTimer > 1) {
          _reiniciarPartida();
          _loadLevel();
          _beginStage();
        }
        break;
    }
  }

  void _reiniciarPartida() {
    score = 0;
    numCristales = 0;
    lives = AjustesJuego.vidasIniciales;
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
    tarjeta = conTarjeta ? AjustesJuego.duracionTarjeta : 0;
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
    time -= dt * AjustesJuego.velocidadReloj;
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

    // Se cayó por un precipicio.
    if (p.y > kRows * T + 16) {
      _die();
      return;
    }

    actualizarFlechas(this, dt);
    actualizarEnemigos(dt);
    if (state != GameState.playing) return;
    actualizarProyectiles(dt);
    if (state != GameState.playing) return;
    actualizarHadas(dt);
    actualizarCofres();
    recogerCristales();

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

  /// La cámara sigue al arquero dejándolo un poco a la izquierda.
  void _updateCamera() {
    final target = arquero.cx - viewW * 0.4;
    camX = math.max(camX, target);
    camX = camX.clamp(0, math.max(0, level.width * T - viewW)).toDouble();
  }

  void sumarPuntos(int pts, double x, double y) {
    score += pts;
    scorePops.add(ScorePop('$pts', x, y));
  }

  /// Algo le hizo daño al arquero; [fromX] es de dónde vino el golpe.
  void herir(double fromX) {
    if (recibirGolpe(arquero, fromX)) {
      _die();
      return;
    }
    sonar(Efecto.dano);
    say(frasesPreocupada[rnd.nextInt(frasesPreocupada.length)], force: true);
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
      p.vy = math.min(
        p.vy + AjustesJuego.gravedad * dt,
        AjustesJuego.caidaMaxima,
      );
      mover(p, dt);
    }
    if (stateTimer > AjustesJuego.duracionMuerte) {
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

  /// Progreso (0..1) del fragmento que sale del portal hacia el arquero.
  double get rewardProgress => state == GameState.reward
      ? math.min(1, stateTimer / AjustesJuego.vueloRecompensa)
      : 1;

  /// Lo que se mueve aunque el arquero no juegue (fantasma y efectos).
  void _updateCommon(double dt) {
    actualizarFantasma(dt);
    actualizarEfectos(dt);
  }
}
