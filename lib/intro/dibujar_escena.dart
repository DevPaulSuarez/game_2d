// DIBUJA LA INTRO ENTERA: el cielo de noche, la casa y el jardín de la
// princesa, los efectos (humo, chispas, rayos), los actores, el limbo, el
// diálogo y la tarjeta final.
//
// Los actores están en dibujar_actores.dart y el diálogo en
// dibujar_dialogo.dart. Los dibujos de la casa, el farol, etc. en
// lib/pixel_art/intro.dart.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../dibujo/pantallas.dart';
import '../dibujo/pincel.dart';
import 'dibujar_actores.dart';
import 'dibujar_dialogo.dart';
import 'escena.dart';

void dibujarIntro(Pincel p, Cutscene s, double viewW) {
  final c = p.c;
  final shakeX = s.shake > 0 ? (math.sin(s.t * 60) * s.shake) : 0.0;
  // La escena mide kSceneW de ancho y se centra en la pantalla.
  final ox = ((viewW - kSceneW) / 2).roundToDouble();
  _cielo(p, s, viewW, ox);

  c.save();
  c.translate(ox + shakeX, 0);
  _jardin(p, s, viewW, ox);
  _brillos(p, s);
  _efectos(p, s);
  dibujarActores(p, s);
  _rayoDelCorazon(p, s);
  c.restore();

  // Rayo
  if (s.bolt > 0) _rayo(p, s, ox);

  // Oscuridad rojiza + viñeta
  if (s.darkness > 0) {
    p.paint.color = Color.fromRGBO(40, 0, 20, s.darkness * 0.55);
    c.drawRect(Rect.fromLTWH(0, 0, viewW, worldH), p.paint);
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

  if (s.limbo > 0) _limbo(p, s, viewW, ox + shakeX);

  // Destello verde de la poción curativa
  if (s.healFlash > 0) {
    p.paint.color = Color.fromRGBO(120, 255, 190, s.healFlash * 0.35);
    c.drawRect(Rect.fromLTWH(0, 0, viewW, worldH), p.paint);
  }

  // Destello rojo
  if (s.flash > 0) {
    p.paint.color = Color.fromRGBO(255, 80, 80, s.flash.clamp(0.0, 1.0) * 0.55);
    c.drawRect(Rect.fromLTWH(0, 0, viewW, worldH), p.paint);
  }

  dibujarDialogo(p, s, viewW);

  // Tarjeta del stage
  if (s.card != null) {
    dibujarTarjetaStage(p, viewW, s.card!, s.cardSub ?? '');
  }
}

/// Cielo de noche con estrellas, luna, montañas y pinos.
void _cielo(Pincel p, Cutscene s, double viewW, double ox) {
  final c = p.c;
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
    p.paint.color = Colors.white.withValues(alpha: tw > 0.5 ? 0.45 : 1.0);
    c.drawRect(
      Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), 1, 1),
      p.paint,
    );
    if (big && tw < 0.2) {
      c.drawRect(
        Rect.fromLTWH(x.roundToDouble() - 1, y.roundToDouble(), 3, 1),
        p.paint,
      );
      c.drawRect(
        Rect.fromLTWH(x.roundToDouble(), y.roundToDouble() - 1, 1, 3),
        p.paint,
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
  p.glow(mx, my, 44, moon.withValues(alpha: 0.35));
  p.paint.color = moon;
  c.drawCircle(Offset(mx, my), 16, p.paint);
  p.paint.color = Color.lerp(
    const Color(0xFFE0D8B0),
    const Color(0xFFB03838),
    s.darkness,
  )!;
  c.drawCircle(Offset(mx - 5, my - 4), 4, p.paint);
  c.drawCircle(Offset(mx + 6, my + 5), 3, p.paint);
  c.drawCircle(Offset(mx + 2, my - 8), 2, p.paint);

  // Montañas lejanas escalonadas
  p.paint.color = const Color(0xFF2A1E4E);
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
      p.paint,
    );
  }
  // Pinos en silueta
  final pino = p.pixel.intro.pino;
  for (var i = -2; i < 14; i++) {
    final x = ox + i * 36.0 + (i.isEven ? 0 : 12);
    if (x > 30 + ox && x < 130 + ox) continue; // hueco para la casa
    p.img(pino, x, kSceneGround - pino.height + (i % 3) * 4);
  }
}

/// Suelo, casa, cerca, farol, rosas y helechos.
void _jardin(Pincel p, Cutscene s, double viewW, double ox) {
  final d = p.pixel.intro;
  // Suelo de pasto
  for (var x = -ox - 16; x < viewW - ox + 16; x += 16) {
    final tx = (x / 16).floor() * 16.0;
    p.img(d.pasto, tx, kSceneGround);
    p.img(d.tierra, tx, kSceneGround + 16);
  }

  // Casa, jardín, cerca y farol
  p.img(d.casa, 21, kSceneGround - d.casa.height);
  for (var i = 0; i < 4; i++) {
    p.img(d.cerca, -40.0 + i * 16, kSceneGround - d.cerca.height);
  }
  for (var i = 0; i < 3; i++) {
    p.img(d.cerca, 112.0 + i * 16, kSceneGround - d.cerca.height);
  }
  final lampX = 100.0;
  p.glow(
    lampX + 6,
    kSceneGround - 38,
    28,
    const Color(0x66FCE890).withValues(alpha: 0.4 * (1 - s.darkness)),
  );
  p.img(d.farol, lampX, kSceneGround - d.farol.height);
  for (var i = 0; i < 9; i++) {
    final x = 12.0 + i * 11 + (i.isOdd ? 3 : 0);
    if (x > 50 && x < 78) continue; // camino a la puerta
    p.img(
      i % 3 == 1 ? d.rosaBlanca : d.rosa,
      x,
      kSceneGround - d.rosa.height + 1,
    );
  }
  for (var i = 0; i < 5; i++) {
    p.img(
      i.isEven ? d.rosa : d.rosaBlanca,
      300.0 + i * 9,
      kSceneGround - d.rosa.height + 1,
    );
  }
  final helecho = p.pixel.decorado.helecho;
  p.img(helecho, 330, kSceneGround - helecho.height);
  p.img(helecho, 344, kSceneGround - helecho.height);
}

/// Luz dorada de la promesa y auras de la princesa, el demonio y el
/// corazón.
void _brillos(Pincel p, Cutscene s) {
  final c = p.c;
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
    p.glow(cx, cy, 70, Color.fromRGBO(255, 230, 150, 0.45 * s.glory));
  }

  // Aura de la princesa viva
  final pr = s.a('princess');
  if (pr.visible && pr.alpha > 0 && !s.princessFallen) {
    p.glow(pr.x, pr.y - 16, 30, Color.fromRGBO(255, 240, 180, 0.35 * pr.alpha));
  }
  // Aura oscura del demonio
  final man = s.a('man');
  if (man.sprite.startsWith('demon') && man.visible) {
    p.glow(
      man.x,
      man.y - 20,
      36,
      Color.fromRGBO(176, 32, 192, 0.53 * man.alpha),
    );
  }
  // Brillo del corazón robado
  final heart = s.a('heart');
  if (heart.visible) {
    final pulse = 0.5 + 0.5 * math.sin(s.t * 10);
    p.glow(
      heart.x,
      heart.y - 5,
      14 + pulse * 4,
      Color.fromRGBO(255, 48, 80, 0.67 * heart.alpha),
    );
  }
}

/// Humo, pedazos del corazón roto y chispas.
void _efectos(Pincel p, Cutscene s) {
  final c = p.c;
  for (final f in s.fx) {
    switch (f.kind) {
      case FxKind.smoke:
        final r = 2 + f.k * 6;
        p.paint.color = Color.fromRGBO(120, 40, 150, 0.7 * (1 - f.k));
        c.drawRect(Rect.fromLTWH(f.x - r, f.y - r, r * 2, r * 2), p.paint);
        p.paint.color = Color.fromRGBO(40, 10, 60, 0.6 * (1 - f.k));
        c.drawRect(Rect.fromLTWH(f.x - r / 2, f.y - r / 2, r, r), p.paint);
      case FxKind.shard:
        // Pedazos del corazón roto
        p.glow(f.x, f.y, 8, const Color(0x88FF3050));
        p.imgCentered(
          p.pixel.objetos.fragmentoCorazon,
          f.x,
          f.y,
          scale: 0.6,
          rot: s.t * 5 + f.x,
        );
      case FxKind.sparkle:
      case FxKind.ember:
        final a = 1 - f.k;
        p.paint.color = f.kind == FxKind.ember
            ? Color.fromRGBO(255, 214, 110, a)
            : Color.fromRGBO(255, 250, 210, a);
        final x = f.x.roundToDouble(), y = f.y.roundToDouble();
        c.drawRect(Rect.fromLTWH(x, y, 1, 1), p.paint);
        if (f.k < 0.5) {
          c.drawRect(Rect.fromLTWH(x - 1, y, 3, 1), p.paint);
          c.drawRect(Rect.fromLTWH(x, y - 1, 1, 3), p.paint);
        }
    }
  }
}

/// Rayo rojo del ataque: sale de la mano del villano y le roba el corazón
/// a la princesa.
void _rayoDelCorazon(Pincel p, Cutscene s) {
  if (s.beam <= 0 || s.beamAlpha <= 0) return;
  final c = p.c;
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
  p.glow(from.dx, from.dy, 10, Color.fromRGBO(255, 40, 70, 0.8 * a));
  p.glow(end.dx, end.dy, 14, Color.fromRGBO(255, 40, 70, 0.9 * a));
}

/// Rayo morado que cae del cielo (el poder oscuro del villano).
void _rayo(Pincel p, Cutscene s, double ox) {
  final bx = ox + s.boltX;
  var x = bx + 30, y = 0.0;
  final rnd = math.Random((s.t * 20).floor());
  final path = Path()..moveTo(x, y);
  while (y < kSceneGround - 30) {
    x += rnd.nextDouble() * 16 - 8 + (bx - x) * 0.15;
    y += 10 + rnd.nextDouble() * 10;
    path.lineTo(x, y);
  }
  p.c.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0x88B060FF),
  );
  p.c.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white,
  );
}

/// El limbo: un velo gris azulado que apaga el mundo; solo se ve a la
/// princesa, con una luz pálida, y motas que suben despacio.
/// [dx] = desplazamiento de la escena (los actores se dibujan movidos).
void _limbo(Pincel p, Cutscene s, double viewW, double dx) {
  final c = p.c;
  final k = s.limbo;
  p.paint.color = Color.fromRGBO(18, 20, 36, 0.88 * k);
  c.drawRect(Rect.fromLTWH(0, 0, viewW, worldH), p.paint);
  for (var i = 0; i < 40; i++) {
    final x = (i * 97.3) % viewW + math.sin(s.t * 0.7 + i) * 6;
    final y = worldH - ((s.t * (6 + i % 5 * 2) + i * 53) % worldH);
    final a = (0.25 + 0.25 * math.sin(s.t * 2 + i)) * k;
    p.paint.color = Color.fromRGBO(190, 200, 230, a);
    c.drawRect(Rect.fromLTWH(x, y, 1, 1), p.paint);
  }
  final pr = s.a('princess');
  if (!pr.visible) return;
  c.save();
  c.translate(dx, 0);
  p.glow(pr.x, pr.y - 8, 34, Color.fromRGBO(200, 210, 255, 0.25 * k));
  dibujarPrincesa(p, pr);
  final gh = s.a('ghost');
  if (gh.visible && gh.alpha > 0) dibujarFantasmaActor(p, s, gh);
  c.restore();
}
