// EL GUION DE LA INTRO: la historia, paso a paso y en orden.
//
// Aquí se cambian los diálogos y lo que pasa en la intro. Los pasos son:
//
//   Dice('ARQUERO', 'HOLA.')    alguien habla (null = el narrador); espera
//                               a que el jugador pulse
//   Camina('archer', 260, 45)   un actor camina hasta x = 260, a 45 px/s
//   Espera(0.8)                 no pasa nada durante 0,8 segundos
//   Haz((c) {...})              hace algo al instante
//   Anima(1.5, (c, p, dt) {...}) anima durante 1,5 s; p va de 0 a 1
//
// Los actores son: 'princess', 'man' (el villano), 'archer', 'ghost'
// (fantasma de la princesa), 'potion', 'heart' y 'orb' (bola de magia).
// Quién puede hablar (con retrato): 'PRINCESA', 'HOMBRE', 'DEMONIO' y
// 'ARQUERO'.
//
// Los textos van en MAYÚSCULAS y sin ; ni comillas ni apóstrofos (la
// fuente pixel no los tiene). Mira las letras en lib/dibujo/letras.dart.

import 'dart:math' as math;

import 'escena.dart';

List<Paso> guionIntro() {
  const g = kSceneGround;
  return [
    // ---------------------------------------------------------------
    // 1. EL REINO EN PAZ
    // ---------------------------------------------------------------
    Espera(0.8),
    Dice(
      null,
      'HACE MUCHO TIEMPO, EN UN REINO ENTRE LAS NUBES, VIVÍA UNA PRINCESA CELESTIAL.',
    ),
    Haz(
      (c) => c.a('princess')
        ..visible = true
        ..alpha = 0,
    ),
    Anima(1.5, (c, p, dt) {
      c.a('princess').alpha = p;
      c.glory = p * 0.35;
    }),
    Camina('princess', 175, 38),
    Dice(
      null,
      'DONDE ELLA PASABA, LAS FLORES SE ABRÍAN Y LA GENTE VOLVÍA A SONREÍR. SU LUZ LLENABA EL REINO DE PAZ Y ALEGRÍA.',
    ),
    Anima(1.0, (c, p, dt) => c.glory = 0.35 * (1 - p)),

    // ---------------------------------------------------------------
    // 2. VUELVE SU PAREJA... Y LA TRAICIONA
    // ---------------------------------------------------------------
    Haz((c) => c.a('man').flip = true),
    Camina('man', 250, 55),
    Dice('HOMBRE', '¡PRINCESA! ¡MI AMOR, POR FIN ESTOY DE VUELTA!'),
    Dice(
      'PRINCESA',
      '¡AMOR MÍO, HAS VUELTO! TE EXTRAÑÉ TANTO... ¿DÓNDE ESTUVISTE TODO ESTE TIEMPO?',
    ),
    Dice(
      'HOMBRE',
      'VIAJÉ MUY LEJOS, PERO NUNCA DEJÉ DE PENSAR EN TI. Y HOY VENGO A HACERTE UNA PROMESA...',
    ),
    Dice(
      'HOMBRE',
      'TE DARÉ UN REINO SIN FIN, JOYAS QUE BRILLAN COMO ESTRELLAS... ¡TODO LO QUE DESEES!',
    ),
    Dice(
      'PRINCESA',
      'NO NECESITO NADA DE ESO. ME BASTA CON VER FELIZ AL REINO... Y CON TENERTE A MI LADO.',
    ),
    Anima(1.2, (c, p, dt) => c.darkness = p * 0.2),
    Dice('HOMBRE', 'TAN BUENA... Y TAN INGENUA.'),
    Dice('PRINCESA', '¿QUÉ...? ¿POR QUÉ ME MIRAS ASÍ?'),
    Dice(
      'HOMBRE',
      'TU LUZ SIEMPRE FUE LO ÚNICO QUE YO QUERÍA. Y AHORA... ¡SERÁ MÍA!',
    ),
    // El poder oscuro lo envuelve: humo, rayos y oscuridad
    Anima(2.0, (c, p, dt) {
      final m = c.a('man');
      m.sprite = 'poder';
      c.shake = p < 1 ? 1 + p * 1.5 : 0;
      c.darkness = 0.2 + p * 0.3;
      for (var i = 0; i < 2; i++) {
        final ang = c.azar(0, math.pi * 2);
        final r = c.azar(6, 20);
        c.emitir(
          FxKind.smoke,
          m.x + math.cos(ang) * r,
          g - c.azar(0, 34),
          math.cos(ang) * 10,
          c.azar(-45, -20),
          c.azar(0.7, 1.3),
        );
      }
      if (c.bolt <= 0 && c.rnd.nextDouble() < dt * 2) {
        c.bolt = 0.18;
        c.boltX = m.x + c.azar(-10, 10);
        c.flash = 0.6;
      }
    }),
    // LANZAR MAGIA: carga la bola y se la lanza a la princesa
    Anima(0.8, (c, p, dt) {
      c.a('man').sprite = 'lanzar_magia_${(p * 3).floor().clamp(0, 2) + 1}';
    }),
    Haz((c) {
      final m = c.a('man');
      m.sprite = 'lanzar_magia_4';
      c.a('orb')
        ..visible = true
        ..x = m.x - 19
        ..y = g - 25;
    }),
    Anima(0.5, (c, p, dt) {
      final m = c.a('man');
      if (p > 0.5) m.sprite = 'lanzar_magia_5';
      c.a('orb')
        ..x = m.x - 19 + (175 - (m.x - 19)) * p
        ..y = g - 25 + 7 * p;
    }),
    Haz((c) {
      c.a('orb').visible = false;
      c.flash = 1;
      c.shake = 3;
    }),
    // La princesa cae (cuadros de MUERTE de su hoja)
    Anima(0.9, (c, p, dt) {
      c.a('princess').sprite = 'muerte_${(p * 4).floor().clamp(0, 3) + 1}';
      if (p >= 1) c.shake = 0;
    }),
    // ATAQUE (ROBA EL CORAZÓN): el rayo rojo le saca el corazón
    Anima(
      0.6,
      (c, p, dt) => c.a('man').sprite = p < 0.5 ? 'ataque_1' : 'ataque_2',
    ),
    Anima(0.6, (c, p, dt) {
      c.a('man').sprite = p < 0.35
          ? 'ataque_3'
          : p < 0.7
          ? 'ataque_4'
          : 'ataque_5';
      c.beam = p;
      c.beamAlpha = 1;
    }),
    Haz((c) {
      c.flash = 0.6;
      c.a('heart')
        ..visible = true
        ..x = 175
        ..y = g - 6;
    }),
    // El corazón viaja por el rayo hasta su mano
    Anima(1.4, (c, p, dt) {
      final h = c.a('heart');
      final m = c.a('man');
      final hx = m.x - 18, hy = g - 17;
      h.x = 175 + (hx - 175) * p;
      h.y = g - 6 + (hy - (g - 6)) * p + math.sin(p * math.pi * 6) * 1.5;
    }),
    Anima(0.3, (c, p, dt) {
      c.beamAlpha = 1 - p;
      if (p >= 1) c.beam = 0;
    }),
    Haz((c) {
      c.a('heart').visible = false;
      c.a('man').sprite = 'con_corazon';
    }),
    Dice(
      'HOMBRE',
      '¿AMOR? NUNCA TE AMÉ, PRINCESA. Y ESTE CORAZÓN... ¡YA NO TE SIRVE DE NADA!',
    ),
    // Lo aprieta en su mano y el corazón estalla en pedazos
    Haz((c) {
      final m = c.a('man');
      m.sprite = 'man';
      for (var i = 0; i < 16; i++) {
        final ang = -math.pi * c.azar(0.05, 0.95);
        final sp = c.azar(60, 150);
        c.emitir(
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
    Anima(0.4, (c, p, dt) {
      if (p >= 1) c.shake = 0;
    }),
    Espera(0.6),
    // SALTO para retirarse; en el aire se transforma en demonio alado
    Haz((c) => c.a('man').sprite = 'saltar_1'),
    Espera(0.35),
    Anima(0.9, (c, p, dt) {
      final m = c.a('man');
      m.sprite = p < 0.45 ? 'saltar_2' : 'saltar_3';
      m.x = 250 + p * 30;
      m.y = g - math.sin(p * math.pi / 2) * 80;
    }),
    Anima(1.2, (c, p, dt) {
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
        final ang = c.azar(0, math.pi * 2);
        c.emitir(
          FxKind.smoke,
          m.x + math.cos(ang) * 18,
          m.y - c.azar(0, 40),
          math.cos(ang) * 20,
          c.azar(-30, 10),
          c.azar(0.6, 1.1),
        );
      }
    }),
    Dice('DEMONIO', '¡JA, JA, JA! ¡CON TU LUZ SERÉ UN DEMONIO INVENCIBLE!'),
    // Desaparece en una nube de humo
    Haz((c) {
      final d = c.a('man');
      c.flash = 0.7;
      c.shake = 2;
      for (var i = 0; i < 90; i++) {
        c.bocanadaHumo(d, 60, 90);
      }
    }),
    Anima(1.2, (c, p, dt) {
      final d = c.a('man');
      d.alpha = 1 - p;
      if (p < 0.7) {
        for (var i = 0; i < 8; i++) {
          c.bocanadaHumo(d, 30, 50);
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
    Espera(0.6),
    Anima(2.0, (c, p, dt) {
      c.limbo = p;
      c.darkness = 0.6 * (1 - p);
    }),
    Dice('PRINCESA', '¿DÓNDE ESTOY...? TODO ES TAN FRÍO Y SILENCIOSO...'),
    Dice(
      'PRINCESA',
      'ERA MI AMOR... LE DI MI CORAZÓN ENTERO. ¿POR QUÉ NO VI LO QUE ESCONDÍA?',
    ),
    Dice('PRINCESA', '¿FUE MI CULPA? ¿ACASO MI LUZ NUNCA FUE SUFICIENTE...?'),
    Dice('PRINCESA', 'MI CORAZÓN ESTÁ HECHO MIL PEDAZOS... ¿QUEDA ALGO DE MÍ?'),

    // ---------------------------------------------------------------
    // 4. EL ARQUERO: pasa, se detiene y la reconoce
    // ---------------------------------------------------------------
    Anima(1.5, (c, p, dt) => c.limbo = 1 - p * 0.6),
    Camina('archer', 260, 45),
    Espera(0.8),
    Dice('ARQUERO', '...'),
    Haz((c) => c.a('archer').flip = true),
    Espera(0.5),
    Dice('ARQUERO', 'ESPERA... ESE CABELLO... ESA ESPADA...'),
    Dice(
      'ARQUERO',
      '¡NO PUEDE SER! ES ELLA... LA PRINCESA. MI AMIGA, LA QUE SIEMPRE TENÍA UNA SONRISA PARA TODOS.',
    ),
    Camina('archer', 212, 60),
    Dice(
      'ARQUERO',
      'AGUANTA, PRINCESA. ESTA POCIÓN ES TODO LO QUE TENGO... ¡POR FAVOR, QUE FUNCIONE!',
    ),
    // Le lanza la poción: vuela en arco hasta ella
    Haz((c) {
      c.a('potion')
        ..sprite = 'potionGood'
        ..visible = true
        ..x = 206
        ..y = g - 18;
    }),
    Anima(0.7, (c, p, dt) {
      c.a('potion')
        ..x = 206 - 31 * p
        ..y = g - 18 + 12 * p - math.sin(p * math.pi) * 22;
    }),
    Haz((c) {
      c.a('potion').visible = false;
      c.flash = 0.5;
      c.healFlash = 1;
      for (var i = 0; i < 30; i++) {
        final ang = c.azar(0, math.pi * 2);
        final sp = c.azar(20, 70);
        c.emitir(
          FxKind.sparkle,
          175,
          g - 6,
          math.cos(ang) * sp,
          math.sin(ang) * sp - 20,
          c.azar(0.8, 1.6),
        );
      }
    }),
    // Sale el fantasma de la princesa y el limbo se disipa
    Haz((c) {
      c.princessIsGhost = true;
      c.a('ghost')
        ..visible = true
        ..alpha = 0
        ..x = 175;
    }),
    Anima(2.0, (c, p, dt) {
      c.limbo = 0.4 * (1 - p);
      c.a('ghost')
        ..alpha = 0.78 * p
        ..y = g - p * 18;
    }),
    Dice(
      'PRINCESA',
      '¿ARQUERO...? ¿ERES TÚ? TU VOZ ME SACÓ DE LA OSCURIDAD...',
    ),
    Dice(
      'PRINCESA',
      'PERO MI CUERPO NO DESPIERTA. ÉL ME TRAICIONÓ... Y MI CORAZÓN QUEDÓ HECHO MIL PEDAZOS.',
    ),
    Dice('ARQUERO', 'ENTONCES YO ME ENCARGARÉ DE SANARTE.'),
    Anima(1.5, (c, p, dt) => c.glory = p),
    Dice(
      'ARQUERO',
      'BUSCARÉ CADA PEDAZO DE TU CORAZÓN, UNO POR UNO, HASTA SANARLO... Y TE DEVOLVERÉ LA ESPERANZA. TE LO PROMETO.',
    ),
    Dice(
      'PRINCESA',
      'ENTONCES NO ESTOY SOLA... GRACIAS, AMIGO. NO PUEDO LUCHAR, PERO SIEMPRE ESTARÉ A TU LADO.',
    ),
    Dice(
      null,
      'ASÍ COMENZÓ EL VIAJE DE UN ARQUERO Y UNA PRINCESA PARA DEVOLVERLE LA LUZ AL REINO.',
    ),
    Anima(3.2, (c, p, dt) {
      c.card = 'STAGE 1';
      c.cardSub = 'EL BOSQUE DE LOS DUENDES';
    }),
  ];
}
