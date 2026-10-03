// LOS ACTORES DE LA INTRO: princesa, villano, arquero, fantasma, bola de
// magia, poción y corazón. Qué imagen lleva cada uno lo decide su
// `sprite` (lo cambia el guion, guion.dart).

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../dibujo/pincel.dart';
import '../personajes/arquero/ajustes.dart';
import '../personajes/imagenes.dart';
import 'escena.dart';

/// Dibuja todos los actores visibles, en este orden (el último, encima).
void dibujarActores(Pincel p, Cutscene s) {
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
    switch (name) {
      case 'archer':
        _arquero(p, a);
      case 'man':
        _villano(p, s, a);
      case 'princess':
        dibujarPrincesa(p, a);
      case 'ghost':
        dibujarFantasmaActor(p, s, a);
      case 'orb':
        _bolaMagia(p, a);
      default:
        // Poción o corazón: dibujos de lib/pixel_art/intro.dart.
        final d = p.pixel.intro;
        final ui.Image img = a.sprite == 'potionGood'
            ? d.pocion
            : d.corazonGrande;
        p.imgCentered(
          img,
          a.x,
          a.y - img.height / 2,
          alpha: a.alpha,
          flipX: a.flip,
        );
    }
  }
}

void _arquero(Pincel p, Actor a) {
  final f = a.walking
      ? p.art.arquero.frame(
          'caminar',
          (a.pasos / AjustesArquero.pixelesPorCuadroCaminar).floor(),
        )
      : p.art.arquero.frame('quieto_derecha');
  p.frame(f, a.x, a.y, flipX: a.flip, alpha: a.alpha);
}

/// La princesa. [Actor.sprite] = 'princess' (camina o está quieta) o
/// 'muerte_N' (cae al recibir la bola de magia).
void dibujarPrincesa(Pincel p, Actor a) {
  final pr = p.art.princesa;
  final Sprite f;
  if (a.sprite.startsWith('muerte')) {
    f = pr.frame('muerte', int.parse(a.sprite.substring(7)) - 1);
  } else if (a.walking) {
    // Un cuadro cada 3,5 px: 5 cuadros por paso.
    f = pr.frame('caminar', (a.pasos / 3.5).floor());
  } else {
    f = pr.frame(a.flip ? 'quieto_izquierda' : 'quieto_derecha');
  }
  p.frame(f, a.x, a.y, flipX: a.walking && a.flip, alpha: a.alpha);
}

/// La bola de magia del villano; (x, y) es su centro. En la hoja va
/// hacia la derecha: se voltea porque la lanza hacia la izquierda.
void _bolaMagia(Pincel p, Actor a) {
  const scale = 0.7;
  final f = p.art.villano.frame('bola_magia');
  p.glow(a.x, a.y, 14, const Color(0xAAFF3040));
  p.frame(f, a.x, a.y + f.ay / f.ppu * scale / 2, flipX: true, scale: scale);
}

/// El fantasma de la princesa en la intro, flotando.
void dibujarFantasmaActor(Pincel p, Cutscene s, Actor a) {
  final feet = a.y + math.sin(s.t * 2.5) * 2;
  p.glow(
    a.x,
    feet - Art.alturaPrincesa / 2,
    28,
    Color.fromRGBO(120, 200, 255, 0.4 * a.alpha),
  );
  p.frame(
    p.art.princesa.frame('fantasma_azul_frente'),
    a.x,
    feet,
    alpha: a.alpha,
  );
}

/// El villano. [Actor.sprite] es el nombre de su PNG (p. ej. 'ataque_2',
/// 'con_corazon'); 'man' = caminar/quieto y 'demonio' = último cuadro de
/// la transformación, flotando.
void _villano(Pincel p, Cutscene s, Actor a) {
  final v = p.art.villano;
  if (a.sprite == 'man') {
    // Parado mira hacia donde iba (flip = hacia la izquierda).
    // Un cuadro cada 2,7 px: su paso mide ~16 px en 6 cuadros.
    final f = a.walking
        ? v.frame('caminar', (a.pasos / 2.7).floor())
        : v.frame(a.flip ? 'quieto_izquierda' : 'quieto_derecha');
    p.frame(f, a.x, a.y, flipX: a.walking && a.flip, alpha: a.alpha);
    return;
  }
  if (a.sprite == 'demonio') {
    final bob = math.sin(s.t * 4) * 2;
    final f = v.frame('demonio', v.count('demonio') - 1);
    p.frame(f, a.x, a.y + bob, alpha: a.alpha);
    return;
  }
  final f = v.frameByName(a.sprite);
  // Los cuadros de la hoja miran a la derecha; el demonio es simétrico.
  final flip = a.flip && !a.sprite.startsWith('demonio');
  p.frame(f, a.x, a.y, flipX: flip, alpha: a.alpha);
}
