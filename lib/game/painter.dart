import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../personajes/arquero/ajustes.dart';
import '../personajes/arquero/animacion.dart';
import '../personajes/arquero/arquero.dart';
import 'art.dart';
import 'cutscene.dart';
import 'game.dart';
import 'level.dart';
import 'pixel_font.dart';
import 'sprites.dart';

class GamePainter extends CustomPainter {
  final Game game;
  final Sprites sp;
  final Art art;
  final _paint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  final bool touch;

  GamePainter(
    this.game,
    this.sp,
    this.art,
    Listenable repaint, {
    this.touch = false,
  }) : super(repaint: repaint);

  static const double worldH = kRows * T;
  static const _gold = Color(0xFFFCB850);
  static const _sky = Color(0xFFB8D8F8);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / worldH;
    final viewW = size.width / scale;

    canvas.save();
    canvas.clipRect(Offset.zero & size);
    canvas.scale(scale);

    if (game.state == GameState.intro && game.intro != null) {
      _drawIntro(canvas, game.intro!, viewW);
      canvas.restore();
      return;
    }

    final cam = (game.camX * scale).roundToDouble() / scale;
    if (_hadas) {
      _drawSkyHadas(canvas, cam, viewW);
    } else {
      _drawSkyBosque(canvas, cam, viewW);
    }

    canvas.save();
    canvas.translate(-cam, 0);
    _drawBackground(canvas, cam, viewW);
    _drawMeta(canvas);
    _drawTiles(canvas, cam, viewW);
    _drawCofres(canvas);
    _drawCristales(canvas);
    _drawHadas(canvas);
    _drawEnemies(canvas);
    _drawProyectiles(canvas);
    _drawArrows(canvas);
    _drawPlayer(canvas);
    _drawEffects(canvas);
    if (game.state != GameState.title) _drawGhost(canvas, cam, viewW);
    if (game.state == GameState.reward) _drawRewardFlight(canvas);
    canvas.restore();

    _drawHud(canvas, viewW);
    _drawOverlay(canvas, viewW);
    if (game.tarjeta > 0) _drawStageCard(canvas, viewW);
    canvas.restore();
  }

  /// ¿Estamos en un escenario con el aspecto del Reino de las Hadas?
  bool get _hadas => game.level.tema == Tema.hadas;

  // -------------------------------------------------------------------------
  // Utilidades
  // -------------------------------------------------------------------------

  void _img(
    Canvas c,
    ui.Image img,
    double x,
    double y, {
    bool flipX = false,
    bool flipY = false,
    double alpha = 1,
  }) {
    _paint.color = Color.fromRGBO(0, 0, 0, alpha);
    if (!flipX && !flipY) {
      c.drawImage(img, Offset(x, y), _paint);
      return;
    }
    c.save();
    c.translate(x + (flipX ? img.width : 0), y + (flipY ? img.height : 0));
    c.scale(flipX ? -1 : 1, flipY ? -1 : 1);
    c.drawImage(img, Offset.zero, _paint);
    c.restore();
  }

  final _hq = Paint()..filterQuality = FilterQuality.medium;

  /// Dibuja la imagen de un personaje con sus pies en (footX, footY).
  void _frame(
    Canvas c,
    Sprite f,
    double footX,
    double footY, {
    bool flipX = false,
    double alpha = 1,
    double scale = 1,
    Color? silueta,
  }) {
    final k = scale / f.ppu;
    c.save();
    c.translate(footX, footY);
    c.scale(flipX ? -k : k, k);
    _hq.color = Color.fromRGBO(0, 0, 0, alpha);
    // Silueta: la forma del dibujo pintada de un solo color.
    _hq.colorFilter = silueta == null
        ? null
        : ColorFilter.mode(silueta, BlendMode.srcIn);
    c.drawImageRect(
      f.image,
      f.src,
      Rect.fromLTWH(-f.ax, -f.ay, f.src.width, f.src.height),
      _hq,
    );
    _hq.colorFilter = null;
    c.restore();
  }

  /// Dibuja una imagen ajustada a un rectángulo (retratos).
  /// [tinte] la tiñe de un color (p. ej. azul para el fantasma).
  void _frameFit(Canvas c, Sprite f, Rect dst, {Color? tinte}) {
    _hq.color = Colors.black;
    _hq.colorFilter = tinte == null
        ? null
        : ColorFilter.mode(tinte, BlendMode.modulate);
    c.drawImageRect(f.image, f.src, dst, _hq);
    _hq.colorFilter = null;
  }

  /// Dibuja un sprite alineado abajo y centrado respecto a su caja.
  void _sprite(
    Canvas c,
    ui.Image img,
    Box b, {
    bool flipX = false,
    bool flipY = false,
    double alpha = 1,
  }) {
    _img(
      c,
      img,
      (b.cx - img.width / 2).roundToDouble(),
      (b.bottom - img.height).roundToDouble(),
      flipX: flipX,
      flipY: flipY,
      alpha: alpha,
    );
  }

  /// Dibuja una imagen centrada en (cx, cy) con escala y rotación.
  void _imgCentered(
    Canvas c,
    ui.Image img,
    double cx,
    double cy, {
    double scale = 1,
    double rot = 0,
    double alpha = 1,
    bool flipX = false,
  }) {
    c.save();
    c.translate(cx, cy);
    if (rot != 0) c.rotate(rot);
    c.scale(flipX ? -scale : scale, scale);
    _paint.color = Color.fromRGBO(0, 0, 0, alpha);
    c.drawImage(img, Offset(-img.width / 2, -img.height / 2), _paint);
    c.restore();
  }

  void _glow(Canvas c, double cx, double cy, double r, Color color) {
    final p = Paint()
      ..shader = ui.Gradient.radial(Offset(cx, cy), r, [
        color,
        color.withValues(alpha: 0),
      ]);
    c.drawCircle(Offset(cx, cy), r, p);
  }

  void _box(Canvas c, Rect r, {Color fill = const Color(0xE0101028)}) {
    _paint.color = Colors.white;
    c.drawRect(r.inflate(1), _paint);
    _paint.color = fill;
    c.drawRect(r, _paint);
  }

  /// Altura del suelo llano en la x del mundo, o null si ahí hay un hueco,
  /// una cuesta o una roca (para no poner decorado donde no toca).
  double? _sueloLlano(double x) {
    final tx = (x / T).floor();
    final fila = game.level.filaSuelo(tx);
    if (fila == null || game.grid[fila][tx] != Tile.ground) return null;
    return fila * T;
  }

  // -------------------------------------------------------------------------
  // Mundo
  // -------------------------------------------------------------------------

  void _drawBackground(Canvas c, double cam, double viewW) {
    if (_hadas) {
      _drawBackgroundHadas(c, cam, viewW);
    } else {
      _drawBackgroundBosque(c, cam, viewW);
    }
  }

  Terreno get _terreno => _hadas ? sp.terrenoHadas : sp.terrenoBosque;

  int _tile(int tx, int ty) {
    if (tx < 0 || tx >= game.level.width) return Tile.ground;
    if (ty < 0 || ty >= kRows) return Tile.empty;
    return game.grid[ty][tx];
  }

  /// Cada casilla elige su dibujo mirando a sus vecinas: la tierra lleva
  /// hierba si tiene cielo encima y borde si tiene un hueco al lado.
  void _drawTiles(Canvas c, double cam, double viewW) {
    final t = _terreno;
    final x0 = math.max(0, (cam / T).floor());
    final x1 = math.min(game.level.width - 1, ((cam + viewW) / T).ceil());
    bool hueco(int tile) => tile == Tile.empty || tile == Tile.platform;
    for (var ty = 0; ty < kRows; ty++) {
      for (var tx = x0; tx <= x1; tx++) {
        final tile = game.grid[ty][tx];
        final ui.Image? img = switch (tile) {
          Tile.ground =>
            t.tierra[(hueco(_tile(tx, ty - 1)) ? 1 : 0) +
                (hueco(_tile(tx - 1, ty)) ? 2 : 0) +
                (hueco(_tile(tx + 1, ty)) ? 4 : 0)],
          Tile.slopeUp => t.cuestaSube,
          Tile.slopeDown => t.cuestaBaja,
          Tile.rock => _tile(tx, ty - 1) == Tile.rock ? t.roca : t.rocaArriba,
          Tile.platform =>
            t.rama[(_tile(tx - 1, ty) != Tile.platform ? 1 : 0) +
                (_tile(tx + 1, ty) != Tile.platform ? 2 : 0)],
          _ => null,
        };
        if (img != null) _img(c, img, tx * T, ty * T);
      }
    }
  }

  void _drawCristales(Canvas c) {
    final frames = sp.cristal;
    for (final k in game.cristales) {
      // Cada cristal destella a su ritmo y flota un poco.
      final f = ((game.clock * 6 + k.x / 23).floor()) % frames.length;
      final dy = math.sin(game.clock * 3 + k.x / 40) * 1.5;
      _glow(c, k.cx, k.cy + dy, 9, const Color(0x445CD8F8));
      _img(c, frames[f], k.x - 1, k.y + dy);
    }
    for (final pop in game.cristalPops) {
      _img(c, frames[0], pop.x, pop.y);
    }
  }

  void _drawCofres(Canvas c) {
    for (final k in game.cofres) {
      if (k.abierto && k.t < 1) {
        _glow(c, k.cx, k.y, 18 * (1 - k.t), const Color(0xAAFCE878));
      }
      _sprite(c, k.abierto ? sp.cofreAbierto : sp.cofre, k);
    }
  }

  /// Suelo bajo el portal de la meta.
  double get _sueloMeta => (game.level.filaSuelo(game.level.metaX) ?? 13) * T;

  /// Portal de la meta: la magia gira dentro del arco de piedra.
  void _drawMeta(Canvas c) {
    final x = game.level.metaX * T, suelo = _sueloMeta;
    final img = _hadas ? sp.portalHadas : sp.portalBosque;
    final y = suelo - img.height;
    final color = _hadas ? const Color(0xFFFF9AD0) : const Color(0xFF9AF0A0);
    final cx = x + 40, cy = y + 58;
    _glow(c, cx, cy, 46, color.withValues(alpha: 0.35));
    c.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: 38, height: 64),
      Paint()
        ..shader = ui.Gradient.radial(
          Offset(cx, cy),
          32,
          [
            Colors.white.withValues(alpha: 0.9),
            color.withValues(alpha: 0.7),
            color.withValues(alpha: 0.1),
          ],
          [0, 0.4, 1],
        ),
    );
    // Chispas girando en espiral
    for (var i = 0; i < 10; i++) {
      final a = game.clock * 2 + i * math.pi / 5;
      final r = 6 + (i % 5) * 3.0;
      _paint.color = Colors.white.withValues(alpha: 0.8);
      c.drawRect(
        Rect.fromLTWH(cx + math.cos(a) * r, cy + math.sin(a) * r * 1.6, 1, 1),
        _paint,
      );
    }
    _img(c, img, x, y);
    if (_hadas) _drawPrincesaHada(c, x + 92, suelo);
  }

  /// La princesa de las hadas espera junto al portal, con sus alas.
  void _drawPrincesaHada(Canvas c, double px, double feet) {
    final bob = math.sin(game.clock * 2) * 1.5;
    final wing = 0.75 + math.sin(game.clock * 9) * 0.25;
    _paint.color = const Color(0x88D8F4FF);
    for (final side in [-1, 1]) {
      c.drawOval(
        Rect.fromCenter(
          center: Offset(px + side * 11, feet - 22 + bob),
          width: 14 * wing,
          height: 20,
        ),
        _paint,
      );
    }
    _glow(c, px, feet - 16, 26, const Color(0x55FCE878));
    _img(
      c,
      sp.fairyPrincess,
      px - sp.fairyPrincess.width / 2,
      feet - sp.fairyPrincess.height + bob,
    );
  }

  void _drawHadas(Canvas c) {
    final frame = sp.fairy[(game.clock * 8).floor() % 2];
    for (final h in game.hadas) {
      _glow(c, h.cx, h.cy, 16, const Color(0x7778F0C8));
      _imgCentered(c, frame, h.cx, h.cy);
      // Chispitas que caen
      for (var i = 0; i < 3; i++) {
        final t = (game.clock * 1.5 + i / 3) % 1;
        _paint.color = Color.fromRGBO(252, 232, 120, 1 - t);
        c.drawRect(
          Rect.fromLTWH(h.cx - 4 + i * 4, h.bottom + t * 12, 1, 1),
          _paint,
        );
      }
    }
  }

  void _drawEnemies(Canvas c) {
    for (final e in game.enemies) {
      if (!e.active) continue;
      final paso = (e.anim * 5).floor().isOdd;
      final ui.Image img = switch (e.kind) {
        EnemyKind.goblin =>
          e.throwPose > 0 ? sp.goblinThrow : (paso ? sp.goblinWalk : sp.goblin),
        EnemyKind.rat => (e.anim * 10).floor().isOdd ? sp.ratWalk : sp.rat,
        EnemyKind.mage =>
          e.throwPose > 0 ? sp.mageCast : (paso ? sp.mageWalk : sp.mage),
        EnemyKind.darkArcher =>
          e.throwPose > 0
              ? sp.darkArcherShoot
              : (paso ? sp.darkArcherWalk : sp.darkArcher),
      };
      if (e.kind == EnemyKind.mage && !e.dead) {
        // Brillo del orbe del bastón.
        final ox = e.dir > 0 ? e.right - 2 : e.x + 2;
        final r = e.throwPose > 0 ? 14.0 : 7.0;
        _glow(c, ox, e.y - 1, r, const Color(0x88FF5CE0));
      }
      final alpha = e.hitFlash > 0 ? 0.4 : 1.0;
      _sprite(c, img, e, flipX: e.dir > 0, flipY: e.dead, alpha: alpha);
    }
  }

  void _drawProyectiles(Canvas c) {
    for (final r in game.proyectiles) {
      switch (r.tipo) {
        case TipoProyectil.piedra:
          _img(c, sp.rock, r.x, r.y);
        case TipoProyectil.magia:
          _glow(c, r.cx, r.cy, 12, const Color(0x99FF5CE0));
          _imgCentered(c, sp.orb, r.cx, r.cy, rot: r.t * 6);
        case TipoProyectil.flecha:
          _img(c, sp.enemyArrow, r.x, r.y, flipX: r.vx > 0);
      }
    }
  }

  void _drawArrows(Canvas c) {
    for (final a in game.flechas) {
      _frame(c, art.arquero.frame('flecha'), a.cx, a.y + 4, flipX: a.vx < 0);
    }
  }

  void _drawPlayer(Canvas c) {
    final p = game.arquero;
    if (!p.visible) return;
    // Parpadea mientras es invencible tras un golpe.
    if (p.invencible > 0 &&
        p.tiempoDano <= 0 &&
        (game.clock * 20).floor().isEven) {
      return;
    }
    if (game.state == GameState.playing) {
      _drawEstela(c, p);
    }
    final f = imagenDelArquero(
      p,
      art.arquero,
      muriendo: game.state == GameState.dying,
      tiempoMuerte: game.stateTimer,
    );
    _frame(c, f.img, p.cx, p.bottom, flipX: f.flip);
  }

  /// Siluetas difuminadas que deja al correr (las viejas, más tenues).
  void _drawEstela(Canvas c, Arquero p) {
    const color = Color(AjustesArquero.colorEstela);
    for (final h in p.estela) {
      final f = imagenDelArquero(h.pose, art.arquero);
      _frame(
        c,
        f.img,
        h.pose.cx,
        h.pose.bottom,
        flipX: f.flip,
        alpha: h.fuerza * AjustesArquero.opacidadEstela,
        silueta: color,
      );
    }
  }

  void _drawEffects(Canvas c) {
    _paint.color = Colors.white;
    for (final s in game.sparks) {
      final r = 2 + s.t * 16;
      for (var i = 0; i < 4; i++) {
        final a = i * math.pi / 2 + math.pi / 4;
        c.drawRect(
          Rect.fromLTWH(
            s.x + math.cos(a) * r - 1,
            s.y + math.sin(a) * r - 1,
            2,
            2,
          ),
          _paint,
        );
      }
    }
    for (final s in game.scorePops) {
      drawPixelText(c, s.text, s.x, s.y, center: true);
    }
  }

  void _drawGhost(Canvas c, double cam, double viewW) {
    final g = game.ghost;
    final bob = math.sin(game.clock * 3) * 1.5;
    final cx = g.x, cy = g.y + bob;
    _glow(c, cx, cy, 22, const Color(0x5578C8FF));
    // Pies a media altura por debajo del centro: (cx, cy) es su centro.
    _frame(
      c,
      art.princesa.frame('fantasma_azul_derecha'),
      cx,
      cy + Art.alturaPrincesa / 2,
      alpha: 0.8,
      flipX: game.arquero.mira < 0,
    );

    final text = g.speech;
    if (text == null) return;
    const px = 1.5;
    final lines = wrapText(text, 22);
    var maxLen = 0;
    for (final l in lines) {
      maxLen = math.max(maxLen, l.length);
    }
    final w = pixelTextWidth('X' * maxLen, px) + 10;
    final h = lines.length * 10.0 + 6;
    var bx = cx - w / 2;
    bx = bx.clamp(cam + 4, cam + viewW - w - 4).toDouble();
    final by = math.max(24.0, cy - 18 - h);
    // Cola del globo
    _paint.color = Colors.white;
    c.drawPath(
      Path()
        ..moveTo(cx - 4, by + h - 1)
        ..lineTo(cx + 4, by + h - 1)
        ..lineTo(cx, by + h + 6)
        ..close(),
      _paint,
    );
    _paint.color = Colors.black;
    c.drawRect(Rect.fromLTWH(bx - 1, by - 1, w + 2, h + 2), _paint);
    _paint.color = Colors.white;
    c.drawRect(Rect.fromLTWH(bx, by, w, h), _paint);
    for (var i = 0; i < lines.length; i++) {
      drawPixelText(
        c,
        lines[i],
        bx + w / 2,
        by + 4 + i * 10,
        px: px,
        center: true,
        color: const Color(0xFF2A4A9A),
        shadow: null,
      );
    }
  }

  /// Fragmento de corazón y alma saliendo del portal hacia el arquero.
  void _drawRewardFlight(Canvas c) {
    final t = game.rewardProgress;
    final p = game.arquero;
    final sx = game.puertaMetaX, sy = _sueloMeta - 40;
    final tx = p.cx, ty = p.y - 26;
    final e = 1 - math.pow(1 - t, 3).toDouble();
    final x = sx + (tx - sx) * e;
    final y = sy + (ty - sy) * e - math.sin(t * math.pi) * 40;
    final pulse = 1 + math.sin(game.clock * 6) * 0.08;
    _glow(c, x - 10, y, 20, const Color(0x88FF7EB6));
    _glow(c, x + 12, y, 20, const Color(0x885CD8F8));
    _imgCentered(c, sp.heartFragment, x - 10, y, scale: pulse);
    _imgCentered(c, sp.soul, x + 12, y, scale: pulse);
  }

  // -------------------------------------------------------------------------
  // Bosque de los Duendes: cielo y decorado
  // -------------------------------------------------------------------------

  /// Cielo de día con capas de montañas y bosque. Las capas lejanas se
  /// mueven más despacio que el arquero (efecto de profundidad).
  void _drawSkyBosque(Canvas c, double cam, double viewW) {
    c.drawRect(
      Rect.fromLTWH(0, 0, viewW, worldH),
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(0, worldH),
          const [Color(0xFF6EB4E8), Color(0xFFBFE3F4), Color(0xFFF6EFD8)],
          const [0, 0.6, 1],
        ),
    );
    // Sol suave
    _glow(c, viewW * 0.18, 40, 70, const Color(0x66FFF4C0));

    // Nubes suaves que se desplazan despacio
    _paint.color = const Color(0xB0FFFFFF);
    for (var i = 0; i < 5; i++) {
      final w = 60.0 + (i * 37) % 50;
      var x = (i * 173.0 - cam * 0.08 + game.clock * 4) % (viewW + 160);
      x -= 80;
      final y = 30.0 + (i * 23) % 50;
      c.drawOval(Rect.fromLTWH(x, y, w, 14), _paint);
      c.drawOval(Rect.fromLTWH(x + w * 0.2, y - 6, w * 0.5, 14), _paint);
    }

    // Montañas lejanas (al 12 %)
    _cordillera(c, cam * 0.12, viewW, 150, 70, 220, const Color(0xFF9CC0DA));
    // Colinas con pinos (al 30 %)
    _cordillera(c, cam * 0.30, viewW, 175, 30, 160, const Color(0xFF6FA88A));
    _pinos(c, cam * 0.30, viewW, 178, const Color(0xFF5A9478), 1.0);
    // Bosque cercano (al 55 %)
    _pinos(c, cam * 0.55, viewW, 205, const Color(0xFF3F7A5E), 1.6);
    // Rayos de luz entre los árboles
    for (var i = 0; i < 3; i++) {
      final x = (i * 260.0 - cam * 0.2) % (viewW + 200) - 60;
      c.drawPath(
        Path()
          ..moveTo(x, 0)
          ..lineTo(x + 40, 0)
          ..lineTo(x + 140, worldH)
          ..lineTo(x + 80, worldH)
          ..close(),
        Paint()..color = const Color(0x14FFF8D0),
      );
    }
  }

  /// Sierra de montañas o colinas: picos suaves que se repiten.
  void _cordillera(
    Canvas c,
    double off,
    double viewW,
    double base,
    double alto,
    double periodo,
    Color col,
  ) {
    final path = Path()..moveTo(0, worldH);
    for (var x = 0.0; x <= viewW + 8; x += 8) {
      final u = (x + off) / periodo * 2 * math.pi;
      final y =
          base -
          alto * (0.55 + 0.3 * math.sin(u) + 0.15 * math.sin(u * 2.7 + 1));
      path.lineTo(x, y);
    }
    path
      ..lineTo(viewW, worldH)
      ..close();
    c.drawPath(path, Paint()..color = col);
  }

  /// Fila de pinos en silueta.
  void _pinos(
    Canvas c,
    double off,
    double viewW,
    double base,
    Color col,
    double escala,
  ) {
    _paint.color = col;
    final paso = 26 * escala;
    final first = (off / paso).floor() - 1;
    final last = ((off + viewW) / paso).ceil() + 1;
    c.drawRect(Rect.fromLTWH(0, base, viewW, worldH - base), _paint);
    for (var k = first; k <= last; k++) {
      final h = (28 + (k * 7919 % 5) * 7) * escala;
      final x = k * paso - off + (k * 31 % 9);
      c.drawPath(
        Path()
          ..moveTo(x - 9 * escala, base)
          ..lineTo(x, base - h)
          ..lineTo(x + 9 * escala, base)
          ..close(),
        _paint,
      );
    }
  }

  /// Helechos, flores, hierbas y motas de polen sobre el suelo.
  void _drawBackgroundBosque(Canvas c, double cam, double viewW) {
    const period = 36 * T;
    final first = (cam / period).floor() - 1;
    final last = ((cam + viewW) / period).ceil();
    for (var k = first; k <= last; k++) {
      final base = k * period;
      for (final (tx, img) in [
        (2.0, sp.helecho),
        (6.5, sp.matoHierba),
        (11.0, sp.florBosque),
        (15.0, sp.helecho),
        (19.5, sp.matoHierba),
        (24.0, sp.florBosque),
        (28.0, sp.matoHierba),
        (32.5, sp.helecho),
      ]) {
        final x = base + tx * T;
        final suelo = _sueloLlano(x);
        if (suelo == null || _sueloLlano(x + img.width) != suelo) continue;
        _img(c, img, x, suelo - img.height + 1);
      }
    }
    // Polen que flota con la luz
    for (var i = 0; i < 12; i++) {
      final bx = (cam / 300).floor() * 300 + (i * 149) % 600 - 150;
      final x = bx + math.sin(game.clock * 0.5 + i) * 20;
      final y = 50 + (i * 53) % 130 + math.cos(game.clock * 0.7 + i * 2) * 8;
      _paint.color = Color.fromRGBO(
        255,
        250,
        200,
        0.5 + 0.3 * math.sin(i + game.clock),
      );
      c.drawRect(Rect.fromLTWH(x, y, 1, 1), _paint);
    }
  }

  // -------------------------------------------------------------------------
  // Reino de las Hadas: cielo y decorado
  // -------------------------------------------------------------------------

  /// Cielo al anochecer con estrellas, luna y castillos lejanos. Se dibuja
  /// en coordenadas de pantalla; las capas lejanas se mueven más despacio
  /// que el arquero (efecto de profundidad).
  void _drawSkyHadas(Canvas c, double cam, double viewW) {
    final sky = Rect.fromLTWH(0, 0, viewW, worldH);
    c.drawRect(
      sky,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          const Offset(0, worldH),
          const [Color(0xFF1E1240), Color(0xFF5A2E80), Color(0xFFC77DBA)],
          const [0, 0.55, 1],
        ),
    );

    // Estrellas que titilan (posiciones fijas "al azar").
    for (var i = 0; i < 60; i++) {
      final x = ((i * 97.13 + 13) % 1) * viewW + (i * 53) % viewW;
      final y = 26 + (i * 37 % 110).toDouble();
      final tw = 0.4 + 0.6 * (0.5 + 0.5 * math.sin(game.clock * 2 + i * 1.7));
      _paint.color = Color.fromRGBO(255, 250, 230, tw);
      c.drawRect(Rect.fromLTWH(x % viewW, y, i % 7 == 0 ? 2 : 1, 1), _paint);
    }

    // Luna
    final mx = viewW * 0.78 - cam * 0.02;
    _glow(c, mx, 52, 40, const Color(0x44FFF4D0));
    _paint.color = const Color(0xFFFFF4D8);
    c.drawCircle(Offset(mx, 52), 14, _paint);
    _paint.color = const Color(0xFFE8D8B8);
    c.drawCircle(Offset(mx - 4, 48), 3, _paint);
    c.drawCircle(Offset(mx + 5, 56), 2, _paint);

    // Castillos y montañas lejanas (se mueven al 20 %).
    _silhouettes(c, cam * 0.2, viewW, 150, const Color(0xFF3A2468), 260);
    // Bosque de setas (se mueve al 45 %).
    _mushroomHills(c, cam * 0.45, viewW, const Color(0xFF2A1A50));
  }

  void _silhouettes(
    Canvas c,
    double off,
    double viewW,
    double base,
    Color col,
    double period,
  ) {
    _paint.color = col;
    final first = (off / period).floor() - 1;
    final last = ((off + viewW) / period).ceil();
    for (var k = first; k <= last; k++) {
      final x0 = k * period - off;
      // Colinas
      c.drawOval(Rect.fromLTWH(x0 - 40, base + 10, 200, 90), _paint);
      c.drawOval(Rect.fromLTWH(x0 + 120, base + 20, 180, 80), _paint);
      // Castillo: torres con tejado en punta
      for (final (dx, w, h) in [
        (60.0, 14.0, 60.0),
        (78.0, 20.0, 80.0),
        (102.0, 14.0, 50.0),
      ]) {
        final tx = x0 + dx;
        c.drawRect(Rect.fromLTWH(tx, base + 30 - h, w, h + 20), _paint);
        c.drawPath(
          Path()
            ..moveTo(tx - 3, base + 30 - h)
            ..lineTo(tx + w / 2, base + 30 - h - w * 1.3)
            ..lineTo(tx + w + 3, base + 30 - h)
            ..close(),
          _paint,
        );
      }
      // Ventanas encendidas
      _paint.color = const Color(0xAAFCE890);
      c.drawRect(Rect.fromLTWH(x0 + 86, base - 30, 3, 5), _paint);
      c.drawRect(Rect.fromLTWH(x0 + 64, base - 10, 2, 4), _paint);
      _paint.color = col;
    }
  }

  void _mushroomHills(Canvas c, double off, double viewW, Color col) {
    const period = 180.0;
    _paint.color = col;
    final first = (off / period).floor() - 1;
    final last = ((off + viewW) / period).ceil();
    for (var k = first; k <= last; k++) {
      final x0 = k * period - off;
      c.drawRect(Rect.fromLTWH(x0 - 10, 190, period + 20, 50), _paint);
      for (final (dx, h, r) in [
        (20.0, 40.0, 22.0),
        (95.0, 58.0, 30.0),
        (150.0, 30.0, 16.0),
      ]) {
        c.drawRect(Rect.fromLTWH(x0 + dx - 4, 200 - h, 8, h), _paint);
        c.drawOval(
          Rect.fromLTWH(x0 + dx - r, 200 - h - r * 0.6, r * 2, r * 1.2),
          _paint,
        );
      }
    }
  }

  /// Flores que brillan, setitas y lucecitas de hada sobre el suelo.
  void _drawBackgroundHadas(Canvas c, double cam, double viewW) {
    const period = 40 * T;
    final first = (cam / period).floor() - 1;
    final last = ((cam + viewW) / period).ceil();
    for (var k = first; k <= last; k++) {
      final base = k * period;
      for (final tx in [3.0, 9.5, 17.0, 24.0, 31.5, 36.0]) {
        final x = base + tx * T;
        final suelo = _sueloLlano(x);
        if (suelo == null || _sueloLlano(x + 10) != suelo) continue;
        final flower = tx.floor().isOdd;
        final img = flower ? sp.glowFlower : sp.tinyMushroom;
        if (flower) {
          final pulse = 0.5 + 0.5 * math.sin(game.clock * 2 + tx);
          _glow(c, x + 4, suelo - 10, 8 + pulse * 3, const Color(0x557CE0F8));
        }
        _img(c, img, x, suelo - img.height + 1);
      }
    }
    // Lucecitas que flotan
    for (var i = 0; i < 14; i++) {
      final bx = (cam / 300).floor() * 300 + (i * 131) % 600 - 150;
      final x = bx + math.sin(game.clock * 0.7 + i) * 18;
      final y = 60 + (i * 47) % 120 + math.cos(game.clock * 0.9 + i * 2) * 10;
      final a = 0.5 + 0.5 * math.sin(game.clock * 3 + i);
      _glow(c, x, y, 5, Color.fromRGBO(200, 255, 170, 0.35 * a));
      _paint.color = Color.fromRGBO(230, 255, 200, a);
      c.drawRect(Rect.fromLTWH(x, y, 1, 1), _paint);
    }
  }

  /// Tarjeta "STAGE N" en negro antes de empezar a jugar.
  void _drawStageCard(Canvas c, double viewW) {
    _paint.color = Colors.black;
    c.drawRect(Rect.fromLTWH(0, 0, viewW, worldH), _paint);
    final cx = viewW / 2;
    _frame(c, art.arquero.frame('quieto_frente'), cx - 60, 200, scale: 2);
    _glow(c, cx + 60, 168, 30, const Color(0x6678C8FF));
    _frame(
      c,
      art.princesa.frame('fantasma_azul_frente'),
      cx + 60,
      200,
      scale: 2,
      alpha: 0.8,
    );
    drawPixelText(
      c,
      'STAGE ${game.escenario.numero}',
      cx,
      70,
      px: 4,
      color: _gold,
      center: true,
    );
    drawPixelText(c, game.escenario.nombre, cx, 104, px: 2, center: true);
  }

  // -------------------------------------------------------------------------
  // HUD y pantallas
  // -------------------------------------------------------------------------

  void _drawHud(Canvas c, double viewW) {
    const px = 1.5;
    final cols = [
      ('PUNTOS', game.score.toString().padLeft(6, '0')),
      ('CRISTALES', 'X${game.numCristales.toString().padLeft(2, '0')}'),
      ('STAGE', '${game.escenario.numero}'),
      ('VIDAS', 'X${game.lives}'),
      (
        'TIEMPO',
        game.state == GameState.title
            ? ''
            : game.time.ceil().toString().padLeft(3, '0'),
      ),
    ];
    // Vida (corazones)
    drawPixelText(c, 'VIDA', 8, 5, px: px);
    for (var i = 0; i < AjustesArquero.vidaMaxima; i++) {
      final img = i < game.arquero.vida ? sp.heartFull : sp.heartEmpty;
      _imgCentered(c, img, 12 + i * 11, 18, scale: 1.3);
    }
    final start = 50.0;
    final span = viewW - start - 8;
    for (var i = 0; i < cols.length; i++) {
      final x = start + span * i / cols.length;
      drawPixelText(c, cols[i].$1, x, 5, px: px);
      drawPixelText(c, cols[i].$2, x, 14, px: px);
    }
  }

  void _panel(Canvas c, double viewW, double y, double h) {
    _paint.color = const Color(0xEE0A0A24);
    c.drawRect(Rect.fromLTWH(0, y, viewW, h), _paint);
  }

  void _drawOverlay(Canvas c, double viewW) {
    final cx = viewW / 2;
    final blink = (game.clock * 2).floor().isEven;
    switch (game.state) {
      case GameState.title:
        _panel(c, viewW, 40, 130);
        drawPixelText(
          c,
          'EL ARQUERO',
          cx,
          52,
          px: 4,
          color: _gold,
          center: true,
        );
        drawPixelText(
          c,
          'Y LA PRINCESA CELESTIAL',
          cx,
          80,
          px: 2,
          color: _sky,
          center: true,
        );
        drawPixelText(
          c,
          touch
              ? 'FLECHAS: MOVER   DIAGONAL: DISPARAR   ARRIBA: SALTAR'
              : 'FLECHAS: MOVER  ESPACIO: SALTAR  X: FLECHA  SHIFT: CORRER',
          cx,
          106,
          center: true,
        );
        _imgCentered(c, sp.heartFragment, cx - 20, 126, scale: 1.2);
        _imgCentered(c, sp.soul, cx + 20, 126);
        if (blink) {
          drawPixelText(
            c,
            touch
                ? 'TOCA LA PANTALLA PARA COMENZAR'
                : 'PULSA ESPACIO PARA COMENZAR',
            cx,
            146,
            px: 1.5,
            center: true,
          );
        }
        break;
      case GameState.gameOver:
        _panel(c, viewW, 80, 70);
        drawPixelText(c, 'FIN DEL JUEGO', cx, 94, px: 3, center: true);
        if (blink && game.stateTimer > 1) {
          drawPixelText(
            c,
            'PULSA PARA INTENTARLO DE NUEVO',
            cx,
            126,
            px: 1.5,
            center: true,
          );
        }
        break;
      case GameState.clear:
        _drawClear(c, viewW);
        break;
      default:
        break;
    }
  }

  void _drawClear(Canvas c, double viewW) {
    final cx = viewW / 2;
    _panel(c, viewW, 34, 172);
    final n = game.escenario.numero;
    drawPixelText(
      c,
      '¡STAGE $n COMPLETADO!',
      cx,
      44,
      px: 3,
      color: _gold,
      center: true,
    );

    final pulse = 1 + math.sin(game.clock * 4) * 0.06;
    final iy = 100.0;
    _glow(c, cx - 70, iy, 36, const Color(0x66FF7EB6));
    _imgCentered(c, sp.heartFragment, cx - 70, iy, scale: 3 * pulse);
    drawPixelText(c, 'FRAGMENTO DE', cx - 70, iy + 28, center: true);
    drawPixelText(
      c,
      'CORAZÓN $n',
      cx - 70,
      iy + 36,
      center: true,
      color: Pal.pink,
    );

    _glow(c, cx + 70, iy, 36, const Color(0x665CD8F8));
    _imgCentered(c, sp.soul, cx + 70, iy, scale: 2.5 * pulse);
    drawPixelText(c, 'FRAGMENTO DE', cx + 70, iy + 28, center: true);
    drawPixelText(
      c,
      'ALMA $n',
      cx + 70,
      iy + 36,
      center: true,
      color: Pal.soul,
    );

    drawPixelText(c, 'PUNTOS: ${game.score}', cx, 152, px: 2, center: true);
    if (game.bonusDone && game.stateTimer > 2) {
      final blink = (game.clock * 2).floor().isEven;
      if (game.hayOtroEscenario) {
        if (blink) {
          drawPixelText(c, 'PULSA PARA CONTINUAR', cx, 180, center: true);
        }
      } else {
        drawPixelText(
          c,
          'CONTINUARÁ...',
          cx,
          172,
          px: 1.5,
          color: _sky,
          center: true,
        );
        if (blink) {
          drawPixelText(
            c,
            'PULSA PARA VOLVER AL INICIO',
            cx,
            188,
            center: true,
          );
        }
      }
    }
  }

  // -------------------------------------------------------------------------
  // Intro
  // -------------------------------------------------------------------------

  ui.Image _actorImage(Cutscene s, Actor a) {
    return switch (a.sprite) {
      'potionEvil' => sp.potionEvil,
      'potionGood' => sp.potionGood,
      _ => sp.heartBig,
    };
  }

  /// La princesa de la hoja de princesa. [Actor.sprite] = 'princess'
  /// (camina o está quieta) o 'muerte_N' (cae al recibir el rayo).
  void _drawPrincess(Canvas c, Actor a) {
    final p = art.princesa;
    final Sprite f;
    if (a.sprite.startsWith('muerte')) {
      f = p.frame('muerte', int.parse(a.sprite.substring(7)) - 1);
    } else if (a.walking) {
      // Un cuadro cada 3,5 px: 5 cuadros por paso.
      f = p.frame('caminar', (a.pasos / 3.5).floor());
    } else {
      f = p.frame(a.flip ? 'quieto_izquierda' : 'quieto_derecha');
    }
    _frame(c, f, a.x, a.y, flipX: a.walking && a.flip, alpha: a.alpha);
  }

  /// La bola de magia del villano; (x, y) es su centro. En la hoja va
  /// hacia la derecha: se voltea porque la lanza hacia la izquierda.
  void _drawOrb(Canvas c, Actor a) {
    const scale = 0.7;
    final f = art.villano.frame('bola_magia');
    _glow(c, a.x, a.y, 14, const Color(0xAAFF3040));
    _frame(
      c,
      f,
      a.x,
      a.y + f.ay / f.ppu * scale / 2,
      flipX: true,
      scale: scale,
    );
  }

  /// El fantasma de la princesa en la intro, flotando.
  void _drawGhostActor(Canvas c, Cutscene s, Actor a) {
    final feet = a.y + math.sin(s.t * 2.5) * 2;
    _glow(
      c,
      a.x,
      feet - Art.alturaPrincesa / 2,
      28,
      Color.fromRGBO(120, 200, 255, 0.4 * a.alpha),
    );
    _frame(
      c,
      art.princesa.frame('fantasma_azul_frente'),
      a.x,
      feet,
      alpha: a.alpha,
    );
  }

  static final _numbered = RegExp(r'^(.+)_(\d+)$');

  /// El villano de malo.png. [Actor.sprite] es el nombre de su PNG
  /// (p. ej. 'ataque_2', 'con_corazon'); 'man' = caminar/quieto y
  /// 'demonio' = último cuadro de la transformación, flotando.
  void _drawVillain(Canvas c, Cutscene s, Actor a) {
    final v = art.villano;
    if (a.sprite == 'man') {
      // Parado mira hacia donde iba (flip = hacia la izquierda).
      // Un cuadro cada 2,7 px: su paso mide ~16 px en 6 cuadros.
      final f = a.walking
          ? v.frame('caminar', (a.pasos / 2.7).floor())
          : v.frame(a.flip ? 'quieto_izquierda' : 'quieto_derecha');
      _frame(c, f, a.x, a.y, flipX: a.walking && a.flip, alpha: a.alpha);
      return;
    }
    if (a.sprite == 'demonio') {
      final bob = math.sin(s.t * 4) * 2;
      final f = v.frame('demonio', v.count('demonio') - 1);
      _frame(c, f, a.x, a.y + bob, alpha: a.alpha);
      return;
    }
    final m = _numbered.firstMatch(a.sprite);
    final f = m == null
        ? v.frame(a.sprite)
        : v.frame(m.group(1)!, int.parse(m.group(2)!) - 1);
    // Los cuadros de la hoja miran a la derecha; el demonio es simétrico.
    final flip = a.flip && !a.sprite.startsWith('demonio');
    _frame(c, f, a.x, a.y, flipX: flip, alpha: a.alpha);
  }

  /// Retrato del personaje que habla. Devuelve false si no tiene.
  bool _drawPortrait(Canvas c, Cutscene s, String? who, Rect pr, double dy) {
    final r = pr.shift(Offset(0, dy));
    switch (who) {
      case 'PRINCESA':
        _frameFit(
          c,
          art.princesa.frame('retrato'),
          r,
          // Azul de fantasma; gris mientras está en el limbo.
          tinte: s.princessIsGhost
              ? const Color(0xFF8CD0FF)
              : s.limbo > 0.3
              ? const Color(0xFF8C8CA8)
              : null,
        );
      case 'HOMBRE':
        _frameFit(c, art.villano.frame('retrato'), r);
      case 'DEMONIO':
        _frameFit(c, art.villano.frame('retrato_demonio'), r);
      case 'ARQUERO':
        _frameFit(c, art.arquero.frame('retrato'), r);
      default:
        return false;
    }
    return true;
  }

  bool _hasPortrait(String? who) =>
      who == 'PRINCESA' ||
      who == 'HOMBRE' ||
      who == 'DEMONIO' ||
      who == 'ARQUERO';

  void _drawIntroSky(Canvas c, Cutscene s, double viewW, double ox) {
    // Cielo nocturno degradado
    c.drawRect(
      Rect.fromLTWH(0, 0, viewW, worldH),
      Paint()
        ..shader = ui.Gradient.linear(
          const Offset(0, 0),
          const Offset(0, kSceneGround),
          [
            const Color(0xFF0C0A2A),
            const Color(0xFF2A1A5A),
            const Color(0xFF7A3A7A),
          ],
          [0, 0.6, 1],
        ),
    );
    // Estrellas titilantes
    final rnd = math.Random(3);
    for (var i = 0; i < 90; i++) {
      final x = rnd.nextDouble() * viewW, y = rnd.nextDouble() * 150;
      final big = rnd.nextDouble() < 0.12;
      final tw = math.sin(s.t * (2 + rnd.nextDouble() * 3) + i);
      _paint.color = Colors.white.withValues(alpha: tw > 0.5 ? 0.45 : 1.0);
      c.drawRect(
        Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), 1, 1),
        _paint,
      );
      if (big && tw < 0.2) {
        c.drawRect(
          Rect.fromLTWH(x.roundToDouble() - 1, y.roundToDouble(), 3, 1),
          _paint,
        );
        c.drawRect(
          Rect.fromLTWH(x.roundToDouble(), y.roundToDouble() - 1, 1, 3),
          _paint,
        );
      }
    }
    // Luna llena con halo (se tiñe de rojo con la oscuridad)
    final mx = ox + 348, my = 108.0;
    final moon = Color.lerp(
      const Color(0xFFFCF4D0),
      const Color(0xFFE85050),
      s.darkness,
    )!;
    _glow(c, mx, my, 44, moon.withValues(alpha: 0.35));
    _paint.color = moon;
    c.drawCircle(Offset(mx, my), 16, _paint);
    _paint.color = Color.lerp(
      const Color(0xFFE0D8B0),
      const Color(0xFFB03838),
      s.darkness,
    )!;
    c.drawCircle(Offset(mx - 5, my - 4), 4, _paint);
    c.drawCircle(Offset(mx + 6, my + 5), 3, _paint);
    c.drawCircle(Offset(mx + 2, my - 8), 2, _paint);

    // Montañas lejanas escalonadas
    _paint.color = const Color(0xFF2A1E4E);
    for (var x = -ox - 8; x < viewW - ox + 8; x += 4) {
      final wx = x + ox;
      final h =
          34 +
          math.sin(x * 0.021) * 16 +
          math.sin(x * 0.057 + 1) * 8 +
          math.sin(x * 0.13) * 3;
      c.drawRect(
        Rect.fromLTWH(
          wx.floorToDouble(),
          (kSceneGround - 40 - h).floorToDouble(),
          4,
          h + 40,
        ),
        _paint,
      );
    }
    // Pinos en silueta
    for (var i = -2; i < 14; i++) {
      final x = ox + i * 36.0 + (i.isEven ? 0 : 12);
      if (x > 30 + ox && x < 130 + ox) continue; // hueco para la casa
      _img(c, sp.pine, x, kSceneGround - sp.pine.height + (i % 3) * 4);
    }
  }

  void _drawIntro(Canvas c, Cutscene s, double viewW) {
    final shakeX = s.shake > 0 ? (math.sin(s.t * 60) * s.shake) : 0.0;
    final ox = ((viewW - kSceneW) / 2).roundToDouble();
    _drawIntroSky(c, s, viewW, ox);

    c.save();
    c.translate(ox + shakeX, 0);

    // Suelo de pasto
    for (var x = -ox - 16; x < viewW - ox + 16; x += 16) {
      final tx = (x / 16).floor() * 16.0;
      _img(c, sp.grass, tx, kSceneGround);
      _img(c, sp.dirt, tx, kSceneGround + 16);
    }

    // Casa, jardín, cerca y farol
    _img(c, sp.house, 21, kSceneGround - sp.house.height);
    for (var i = 0; i < 4; i++) {
      _img(c, sp.fence, -40.0 + i * 16, kSceneGround - sp.fence.height);
    }
    for (var i = 0; i < 3; i++) {
      _img(c, sp.fence, 112.0 + i * 16, kSceneGround - sp.fence.height);
    }
    final lampX = 100.0;
    _glow(
      c,
      lampX + 6,
      kSceneGround - 38,
      28,
      const Color(0x66FCE890).withValues(alpha: 0.4 * (1 - s.darkness)),
    );
    _img(c, sp.lamp, lampX, kSceneGround - sp.lamp.height);
    for (var i = 0; i < 9; i++) {
      final x = 12.0 + i * 11 + (i.isOdd ? 3 : 0);
      if (x > 50 && x < 78) continue; // camino a la puerta
      _img(
        c,
        i % 3 == 1 ? sp.whiteRose : sp.rose,
        x,
        kSceneGround - sp.rose.height + 1,
      );
    }
    for (var i = 0; i < 5; i++) {
      _img(
        c,
        i.isEven ? sp.rose : sp.whiteRose,
        300.0 + i * 9,
        kSceneGround - sp.rose.height + 1,
      );
    }
    _img(c, sp.helecho, 330, kSceneGround - sp.helecho.height);
    _img(c, sp.helecho, 344, kSceneGround - sp.helecho.height);

    // Luz dorada de la promesa
    if (s.glory > 0) {
      final cx = 190.0, cy = kSceneGround - 30;
      for (var i = 0; i < 12; i++) {
        final ang = s.t * 0.3 + i * math.pi / 6;
        final path = Path()
          ..moveTo(cx, cy)
          ..lineTo(
            cx + math.cos(ang - 0.08) * 220,
            cy + math.sin(ang - 0.08) * 220,
          )
          ..lineTo(
            cx + math.cos(ang + 0.08) * 220,
            cy + math.sin(ang + 0.08) * 220,
          )
          ..close();
        c.drawPath(
          path,
          Paint()..color = Color.fromRGBO(255, 220, 120, 0.10 * s.glory),
        );
      }
      _glow(c, cx, cy, 70, Color.fromRGBO(255, 230, 150, 0.45 * s.glory));
    }

    // Aura de la princesa viva
    final pr = s.a('princess');
    if (pr.visible && pr.alpha > 0 && !s.princessFallen) {
      _glow(
        c,
        pr.x,
        pr.y - 16,
        30,
        Color.fromRGBO(255, 240, 180, 0.35 * pr.alpha),
      );
    }
    // Aura oscura del demonio
    final man = s.a('man');
    if (man.sprite.startsWith('demon') && man.visible) {
      _glow(
        c,
        man.x,
        man.y - 20,
        36,
        Color.fromRGBO(176, 32, 192, 0.53 * man.alpha),
      );
    }
    final heart = s.a('heart');
    if (heart.visible) {
      final pulse = 0.5 + 0.5 * math.sin(s.t * 10);
      _glow(
        c,
        heart.x,
        heart.y - 5,
        14 + pulse * 4,
        Color.fromRGBO(255, 48, 80, 0.67 * heart.alpha),
      );
    }

    // Humo y fragmentos del alma
    for (final f in s.fx) {
      switch (f.kind) {
        case FxKind.smoke:
          final r = 2 + f.k * 6;
          _paint.color = Color.fromRGBO(120, 40, 150, 0.7 * (1 - f.k));
          c.drawRect(Rect.fromLTWH(f.x - r, f.y - r, r * 2, r * 2), _paint);
          _paint.color = Color.fromRGBO(40, 10, 60, 0.6 * (1 - f.k));
          c.drawRect(Rect.fromLTWH(f.x - r / 2, f.y - r / 2, r, r), _paint);
        case FxKind.shard:
          // Pedazos del corazón roto
          _glow(c, f.x, f.y, 8, const Color(0x88FF3050));
          _imgCentered(
            c,
            sp.heartFragment,
            f.x,
            f.y,
            scale: 0.6,
            rot: s.t * 5 + f.x,
          );
        case FxKind.sparkle:
        case FxKind.ember:
          final a = 1 - f.k;
          _paint.color = f.kind == FxKind.ember
              ? Color.fromRGBO(255, 214, 110, a)
              : Color.fromRGBO(255, 250, 210, a);
          final x = f.x.roundToDouble(), y = f.y.roundToDouble();
          c.drawRect(Rect.fromLTWH(x, y, 1, 1), _paint);
          if (f.k < 0.5) {
            c.drawRect(Rect.fromLTWH(x - 1, y, 3, 1), _paint);
            c.drawRect(Rect.fromLTWH(x, y - 1, 1, 3), _paint);
          }
      }
    }

    // Actores
    for (final name in [
      'princess',
      'man',
      'orb',
      'potion',
      'archer',
      'heart',
      'ghost',
    ]) {
      final a = s.a(name);
      if (!a.visible || a.alpha <= 0) continue;
      if (name == 'archer') {
        final f = a.walking
            ? art.arquero.frame(
                'caminar',
                (a.pasos / AjustesArquero.pixelesPorCuadroCaminar).floor(),
              )
            : art.arquero.frame('quieto_derecha');
        _frame(c, f, a.x, a.y, flipX: a.flip, alpha: a.alpha);
        continue;
      }
      if (name == 'man') {
        _drawVillain(c, s, a);
        continue;
      }
      if (name == 'princess') {
        _drawPrincess(c, a);
        continue;
      }
      if (name == 'ghost') {
        _drawGhostActor(c, s, a);
        continue;
      }
      if (name == 'orb') {
        _drawOrb(c, a);
        continue;
      }
      final img = _actorImage(s, a);
      _imgCentered(
        c,
        img,
        a.x,
        a.y - img.height / 2,
        alpha: a.alpha,
        flipX: a.flip,
      );
    }

    // Rayo rojo del ataque (roba el corazón)
    if (s.beam > 0 && s.beamAlpha > 0) {
      final m = s.a('man');
      // Sale de la mano extendida de los cuadros ataque_3..5.
      final from = Offset(m.x - 18, m.y - 17);
      // Termina en el pecho de la princesa, ya en el suelo.
      const to = Offset(175, kSceneGround - 6);
      final end = Offset.lerp(from, to, s.beam)!;
      final wob = math.sin(s.t * 40) * 1.5;
      final path = Path()
        ..moveTo(from.dx, from.dy)
        ..quadraticBezierTo(
          (from.dx + end.dx) / 2,
          (from.dy + end.dy) / 2 + wob,
          end.dx,
          end.dy,
        );
      final a = s.beamAlpha;
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..color = Color.fromRGBO(255, 30, 60, 0.35 * a),
      );
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Color.fromRGBO(255, 90, 110, a),
      );
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = Color.fromRGBO(255, 240, 240, a),
      );
      _glow(c, from.dx, from.dy, 10, Color.fromRGBO(255, 40, 70, 0.8 * a));
      _glow(c, end.dx, end.dy, 14, Color.fromRGBO(255, 40, 70, 0.9 * a));
    }

    c.restore();

    // Rayo
    if (s.bolt > 0) {
      final bx = ox + s.boltX;
      var x = bx + 30, y = 0.0;
      final rnd = math.Random((s.t * 20).floor());
      final path = Path()..moveTo(x, y);
      while (y < kSceneGround - 30) {
        x += rnd.nextDouble() * 16 - 8 + (bx - x) * 0.15;
        y += 10 + rnd.nextDouble() * 10;
        path.lineTo(x, y);
      }
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = const Color(0x88B060FF),
      );
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white,
      );
    }

    // Oscuridad rojiza + viñeta
    if (s.darkness > 0) {
      _paint.color = Color.fromRGBO(40, 0, 20, s.darkness * 0.55);
      c.drawRect(Rect.fromLTWH(0, 0, viewW, worldH), _paint);
      c.drawRect(
        Rect.fromLTWH(0, 0, viewW, worldH),
        Paint()
          ..shader = ui.Gradient.radial(
            Offset(viewW / 2, worldH / 2),
            viewW * 0.6,
            [Colors.transparent, Color.fromRGBO(0, 0, 0, s.darkness * 0.8)],
          ),
      );
    }

    if (s.limbo > 0) _drawLimbo(c, s, viewW, ox + shakeX);

    // Destello verde de la poción curativa
    if (s.healFlash > 0) {
      _paint.color = Color.fromRGBO(120, 255, 190, s.healFlash * 0.35);
      c.drawRect(Rect.fromLTWH(0, 0, viewW, worldH), _paint);
    }

    // Destello
    if (s.flash > 0) {
      _paint.color = Color.fromRGBO(
        255,
        80,
        80,
        s.flash.clamp(0.0, 1.0) * 0.55,
      );
      c.drawRect(Rect.fromLTWH(0, 0, viewW, worldH), _paint);
    }

    _drawDialog(c, s, viewW);

    // Tarjeta del stage
    if (s.card != null) {
      _paint.color = Colors.black;
      c.drawRect(Rect.fromLTWH(0, 0, viewW, worldH), _paint);
      final cx = viewW / 2;
      _frame(c, art.arquero.frame('quieto_frente'), cx - 60, 200, scale: 2);
      _glow(c, cx + 60, 168, 30, const Color(0x6678C8FF));
      _frame(
        c,
        art.princesa.frame('fantasma_azul_frente'),
        cx + 60,
        200,
        scale: 2,
        alpha: 0.8,
      );
      drawPixelText(c, s.card!, cx, 70, px: 4, color: _gold, center: true);
      drawPixelText(c, s.cardSub ?? '', cx, 104, px: 2, center: true);
    }
  }

  /// El limbo: un velo gris azulado que apaga el mundo; solo se ve a la
  /// princesa, con una luz pálida, y motas que suben despacio.
  /// [dx] = desplazamiento de la escena (los actores se dibujan movidos).
  void _drawLimbo(Canvas c, Cutscene s, double viewW, double dx) {
    final k = s.limbo;
    _paint.color = Color.fromRGBO(18, 20, 36, 0.88 * k);
    c.drawRect(Rect.fromLTWH(0, 0, viewW, worldH), _paint);
    for (var i = 0; i < 40; i++) {
      final x = (i * 97.3) % viewW + math.sin(s.t * 0.7 + i) * 6;
      final y = worldH - ((s.t * (6 + i % 5 * 2) + i * 53) % worldH);
      final a = (0.25 + 0.25 * math.sin(s.t * 2 + i)) * k;
      _paint.color = Color.fromRGBO(190, 200, 230, a);
      c.drawRect(Rect.fromLTWH(x, y, 1, 1), _paint);
    }
    final pr = s.a('princess');
    if (!pr.visible) return;
    c.save();
    c.translate(dx, 0);
    _glow(c, pr.x, pr.y - 8, 34, Color.fromRGBO(200, 210, 255, 0.25 * k));
    _drawPrincess(c, pr);
    final gh = s.a('ghost');
    if (gh.visible && gh.alpha > 0) _drawGhostActor(c, s, gh);
    c.restore();
  }

  void _drawDialog(Canvas c, Cutscene s, double viewW) {
    if (s.text.isEmpty) return;
    const px = 2.0;
    final portrait = _hasPortrait(s.speaker) ? true : null;
    final boxW = math.min(viewW - 20, 460.0);
    final bx = (viewW - boxW) / 2;
    final textX = bx + (portrait != null ? 62 : 10);
    final maxChars = ((bx + boxW - 10 - textX) / (4 * px)).floor();
    final shown = s.text.substring(0, s.visibleChars);
    final lines = wrapText(shown, maxChars);
    final allLines = wrapText(s.text, maxChars).length;
    final h = math.max(portrait != null ? 60.0 : 0.0, 24.0 + allLines * 14);
    _box(c, Rect.fromLTWH(bx, 8, boxW, h));

    if (portrait != null) {
      final pr = Rect.fromLTWH(bx + 6, 14, 48, 48);
      final bg = switch (s.speaker) {
        'DEMONIO' => const Color(0xFF3A0A18),
        'HOMBRE' => const Color(0xFF2A2A3A),
        'ARQUERO' => const Color(0xFF1E3A1A),
        _ => const Color(0xFF1A2A5A),
      };
      _paint.color = const Color(0xFFE0B040);
      c.drawRect(pr.inflate(1), _paint);
      _paint.color = bg;
      c.drawRect(pr, _paint);
      c.save();
      c.clipRect(pr);
      final talking = !s.textFull && (s.t * 10).floor().isEven;
      _drawPortrait(c, s, s.speaker, pr, talking ? 1 : 0);
      c.restore();
    }

    final who = s.speaker;
    final col = switch (who) {
      'PRINCESA' => const Color(0xFF9CD4FF),
      'ARQUERO' => const Color(0xFFA8D458),
      'DEMONIO' => const Color(0xFFFF5050),
      'HOMBRE' => const Color(0xFFD8C8A0),
      _ => const Color(0xFFB0B0C0),
    };
    drawPixelText(c, who ?? 'NARRADOR', textX, 14, px: 1.5, color: col);
    for (var i = 0; i < lines.length; i++) {
      drawPixelText(c, lines[i], textX, 27 + i * 14.0, px: px);
    }
    if (s.textFull && (s.t * 3).floor().isEven) {
      _paint.color = Colors.white;
      c.drawPath(
        Path()
          ..moveTo(bx + boxW - 14, 8 + h - 9)
          ..lineTo(bx + boxW - 6, 8 + h - 9)
          ..lineTo(bx + boxW - 10, 8 + h - 4)
          ..close(),
        _paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) => false;
}
