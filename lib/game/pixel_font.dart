import 'package:flutter/material.dart';

/// Fuente pixel de 3x5 dibujada a mano.
const Map<String, List<String>> _glyphs = {
  'A': ['.#.', '#.#', '###', '#.#', '#.#'],
  'B': ['##.', '#.#', '##.', '#.#', '##.'],
  'C': ['.##', '#..', '#..', '#..', '.##'],
  'D': ['##.', '#.#', '#.#', '#.#', '##.'],
  'E': ['###', '#..', '##.', '#..', '###'],
  'F': ['###', '#..', '##.', '#..', '#..'],
  'G': ['.##', '#..', '#.#', '#.#', '.##'],
  'H': ['#.#', '#.#', '###', '#.#', '#.#'],
  'I': ['###', '.#.', '.#.', '.#.', '###'],
  'J': ['..#', '..#', '..#', '#.#', '.#.'],
  'K': ['#.#', '#.#', '##.', '#.#', '#.#'],
  'L': ['#..', '#..', '#..', '#..', '###'],
  'M': ['#.#', '###', '###', '#.#', '#.#'],
  'N': ['##.', '#.#', '#.#', '#.#', '#.#'],
  'O': ['.#.', '#.#', '#.#', '#.#', '.#.'],
  'P': ['##.', '#.#', '##.', '#..', '#..'],
  'Q': ['.#.', '#.#', '#.#', '##.', '.##'],
  'R': ['##.', '#.#', '##.', '#.#', '#.#'],
  'S': ['.##', '#..', '.#.', '..#', '##.'],
  'T': ['###', '.#.', '.#.', '.#.', '.#.'],
  'U': ['#.#', '#.#', '#.#', '#.#', '###'],
  'V': ['#.#', '#.#', '#.#', '#.#', '.#.'],
  'W': ['#.#', '#.#', '###', '###', '#.#'],
  'X': ['#.#', '#.#', '.#.', '#.#', '#.#'],
  'Y': ['#.#', '#.#', '.#.', '.#.', '.#.'],
  'Z': ['###', '..#', '.#.', '#..', '###'],
  '0': ['###', '#.#', '#.#', '#.#', '###'],
  '1': ['.#.', '##.', '.#.', '.#.', '###'],
  '2': ['##.', '..#', '.#.', '#..', '###'],
  '3': ['##.', '..#', '.#.', '..#', '##.'],
  '4': ['#.#', '#.#', '###', '..#', '..#'],
  '5': ['###', '#..', '##.', '..#', '##.'],
  '6': ['.##', '#..', '###', '#.#', '###'],
  '7': ['###', '..#', '.#.', '.#.', '.#.'],
  '8': ['###', '#.#', '###', '#.#', '###'],
  '9': ['###', '#.#', '###', '..#', '##.'],
  '-': ['...', '...', '###', '...', '...'],
  '!': ['.#.', '.#.', '.#.', '...', '.#.'],
  '¡': ['.#.', '...', '.#.', '.#.', '.#.'],
  ':': ['...', '.#.', '...', '.#.', '...'],
  '.': ['...', '...', '...', '...', '.#.'],
  '/': ['..#', '..#', '.#.', '#..', '#..'],
  '?': ['##.', '..#', '.#.', '...', '.#.'],
  '¿': ['.#.', '...', '.#.', '#..', '.##'],
  ',': ['...', '...', '...', '.#.', '#..'],
  "'": ['.#.', '.#.', '...', '...', '...'],
  '*': ['...', '#.#', '.#.', '#.#', '...'],
  '(': ['.#.', '#..', '#..', '#..', '.#.'],
  ')': ['.#.', '..#', '..#', '..#', '.#.'],
  '+': ['...', '.#.', '###', '.#.', '...'],
};

/// Letras acentuadas: se dibuja la letra base más una marca encima.
const Map<String, (String, String)> _accented = {
  'Á': ('A', 'acute'),
  'É': ('E', 'acute'),
  'Í': ('I', 'acute'),
  'Ó': ('O', 'acute'),
  'Ú': ('U', 'acute'),
  'Ü': ('U', 'dots'),
  'Ñ': ('N', 'tilde'),
};

/// Parte un texto en líneas de como máximo [maxChars] caracteres.
List<String> wrapText(String text, int maxChars) {
  final lines = <String>[];
  var line = '';
  for (final word in text.split(' ')) {
    if (line.isEmpty) {
      line = word;
    } else if (line.length + 1 + word.length <= maxChars) {
      line = '$line $word';
    } else {
      lines.add(line);
      line = word;
    }
  }
  if (line.isNotEmpty) lines.add(line);
  return lines;
}

double pixelTextWidth(String text, double px) =>
    text.isEmpty ? 0 : (text.length * 4 - 1) * px;

void drawPixelText(
  Canvas canvas,
  String text,
  double x,
  double y, {
  double px = 1,
  Color color = Colors.white,
  Color? shadow = Colors.black,
  bool center = false,
}) {
  text = text.toUpperCase();
  final startX = center ? x - pixelTextWidth(text, px) / 2 : x;
  final paint = Paint()..isAntiAlias = false;

  void pass(Color c, double off) {
    paint.color = c;
    for (var i = 0; i < text.length; i++) {
      var ch = text[i];
      final acc = _accented[ch];
      if (acc != null) ch = acc.$1;
      final glyph = _glyphs[ch];
      if (glyph == null) continue;
      final gx = startX + i * 4 * px + off;
      if (acc != null) {
        final ay = y - 2 * px + off;
        switch (acc.$2) {
          case 'acute':
            canvas.drawRect(Rect.fromLTWH(gx + 2 * px, ay, px, px), paint);
            canvas.drawRect(Rect.fromLTWH(gx + px, ay + px, px, px), paint);
          case 'dots':
            canvas.drawRect(Rect.fromLTWH(gx, ay, px, px), paint);
            canvas.drawRect(Rect.fromLTWH(gx + 2 * px, ay, px, px), paint);
          default:
            canvas.drawRect(Rect.fromLTWH(gx, ay, px * 3, px), paint);
        }
      }
      for (var row = 0; row < 5; row++) {
        final line = glyph[row];
        for (var col = 0; col < 3; col++) {
          if (line[col] == '#') {
            canvas.drawRect(
              Rect.fromLTWH(gx + col * px, y + row * px + off, px, px),
              paint,
            );
          }
        }
      }
    }
  }

  if (shadow != null) pass(shadow, px);
  pass(color, 0);
}
