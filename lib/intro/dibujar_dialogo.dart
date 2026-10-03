// EL CUADRO DE DIÁLOGO DE LA INTRO: el retrato de quien habla, su nombre
// en su color y el texto apareciendo letra a letra.
//
// Para que un personaje nuevo hable con retrato, añádelo en _retrato,
// _fondoRetrato y _colorNombre.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../dibujo/letras.dart';
import '../dibujo/pincel.dart';
import '../personajes/imagenes.dart';
import 'escena.dart';

/// Retrato de cada personaje que puede hablar.
Sprite? _retrato(Pincel p, String? who) => switch (who) {
  'PRINCESA' => p.art.princesa.frame('retrato'),
  'HOMBRE' => p.art.villano.frame('retrato'),
  'DEMONIO' => p.art.villano.frame('retrato_demonio'),
  'ARQUERO' => p.art.arquero.frame('retrato'),
  _ => null,
};

/// Color de fondo detrás del retrato.
Color _fondoRetrato(String? who) => switch (who) {
  'DEMONIO' => const Color(0xFF3A0A18),
  'HOMBRE' => const Color(0xFF2A2A3A),
  'ARQUERO' => const Color(0xFF1E3A1A),
  _ => const Color(0xFF1A2A5A),
};

/// Color del nombre de quien habla.
Color _colorNombre(String? who) => switch (who) {
  'PRINCESA' => const Color(0xFF9CD4FF),
  'ARQUERO' => const Color(0xFFA8D458),
  'DEMONIO' => const Color(0xFFFF5050),
  'HOMBRE' => const Color(0xFFD8C8A0),
  _ => const Color(0xFFB0B0C0),
};

void dibujarDialogo(Pincel p, Cutscene s, double viewW) {
  if (s.text.isEmpty) return;
  final c = p.c;
  const px = 2.0;
  final retrato = _retrato(p, s.speaker);
  final boxW = math.min(viewW - 20, 460.0);
  final bx = (viewW - boxW) / 2;
  final textX = bx + (retrato != null ? 62 : 10);
  final maxChars = ((bx + boxW - 10 - textX) / (4 * px)).floor();
  final shown = s.text.substring(0, s.visibleChars);
  final lines = wrapText(shown, maxChars);
  final allLines = wrapText(s.text, maxChars).length;
  final h = math.max(retrato != null ? 60.0 : 0.0, 24.0 + allLines * 14);
  p.box(Rect.fromLTWH(bx, 8, boxW, h));

  if (retrato != null) {
    final pr = Rect.fromLTWH(bx + 6, 14, 48, 48);
    // Marco dorado y fondo de color.
    p.paint.color = const Color(0xFFE0B040);
    c.drawRect(pr.inflate(1), p.paint);
    p.paint.color = _fondoRetrato(s.speaker);
    c.drawRect(pr, p.paint);
    c.save();
    c.clipRect(pr);
    // Mientras habla, el retrato salta un píxel (como si moviera la boca).
    final talking = !s.textFull && (s.t * 10).floor().isEven;
    p.frameFit(
      retrato,
      pr.shift(Offset(0, talking ? 1 : 0)),
      tinte: s.speaker == 'PRINCESA' ? _tintePrincesa(s) : null,
    );
    c.restore();
  }

  final who = s.speaker;
  drawPixelText(
    c,
    who ?? 'NARRADOR',
    textX,
    14,
    px: 1.5,
    color: _colorNombre(who),
  );
  for (var i = 0; i < lines.length; i++) {
    drawPixelText(c, lines[i], textX, 27 + i * 14.0, px: px);
  }
  // Triangulito que parpadea: "pulsa para seguir".
  if (s.textFull && (s.t * 3).floor().isEven) {
    p.paint.color = Colors.white;
    c.drawPath(
      Path()
        ..moveTo(bx + boxW - 14, 8 + h - 9)
        ..lineTo(bx + boxW - 6, 8 + h - 9)
        ..lineTo(bx + boxW - 10, 8 + h - 4)
        ..close(),
      p.paint,
    );
  }
}

/// El retrato de la princesa es azul de fantasma, o gris en el limbo.
Color? _tintePrincesa(Cutscene s) {
  if (s.princessIsGhost) return const Color(0xFF8CD0FF);
  if (s.limbo > 0.3) return const Color(0xFF8C8CA8);
  return null;
}
