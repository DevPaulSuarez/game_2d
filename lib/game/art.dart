import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../personajes/arquero/ajustes.dart';

/// Una imagen de un personaje con su punto de apoyo (los pies).
class Sprite {
  final ui.Image image;

  /// Pies dentro de la imagen, en píxeles de la imagen.
  final double ax, ay;

  /// Píxeles de la imagen por píxel del mundo (lo fija el personaje).
  double ppu = 1;

  Sprite(this.image, this.ax, this.ay);

  Rect get src =>
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
}

/// Todas las imágenes de un personaje, agrupadas por animación.
///
/// Se cargan solas desde `lib/personajes/CARPETA/imagenes/`:
///   quieto_frente.png       → animación "quieto_frente" con 1 cuadro
///   caminar_1.png … _5.png  → animación "caminar" con 5 cuadros
/// Para añadir un cuadro basta con crear `caminar_6.png`.
class Character {
  final Map<String, List<Sprite>> anims;
  Character(this.anims);

  int count(String anim) => anims[anim]?.length ?? 0;

  /// Cuadro número [i] (empieza en 0); se repite en bucle.
  Sprite frame(String anim, [int i = 0]) {
    final list = anims[anim];
    if (list == null) {
      throw StateError('Falta la animación "$anim" (¿existe su PNG?)');
    }
    return list[i % list.length];
  }

  /// Cuadro para un progreso de 0 a 1 (animaciones que no se repiten).
  Sprite progress(String anim, double p) {
    final n = count(anim);
    return frame(anim, (p * n).floor().clamp(0, n - 1));
  }

  static final _numbered = RegExp(r'^(.+)_(\d+)$');

  /// [height] = altura en el juego (píxeles del mundo) de
  /// `quieto_frente.png`;
  /// el resto de imágenes se escalan en la misma proporción.
  static Future<Character> load(
    AssetManifest manifest,
    String folder, {
    required double height,
  }) async {
    final prefix = 'lib/personajes/$folder/imagenes/';
    final files = manifest.listAssets().where(
      (a) => a.startsWith(prefix) && a.endsWith('.png'),
    );
    final numbered = <String, Map<int, Sprite>>{};
    for (final path in files) {
      final name = path.substring(prefix.length, path.length - 4);
      final m = _numbered.firstMatch(name);
      final anim = m?.group(1) ?? name;
      final index = m != null ? int.parse(m.group(2)!) : 1;
      (numbered[anim] ??= {})[index] = await _loadSprite(path);
    }
    final anims = <String, List<Sprite>>{
      for (final e in numbered.entries)
        e.key: [for (final k in (e.value.keys.toList()..sort())) e.value[k]!],
    };
    final c = Character(anims);
    final ppu = c.frame('quieto_frente').ay / height;
    for (final list in anims.values) {
      for (final s in list) {
        s.ppu = ppu;
      }
    }
    return c;
  }

  /// Carga un PNG y calcula dónde están los pies: la fila más baja con
  /// color y el centro horizontal de la mitad inferior del dibujo.
  static Future<Sprite> _loadSprite(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final image = (await codec.getNextFrame()).image;
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final w = image.width, h = image.height;
    bool opaque(int x, int y) => bytes.getUint8((y * w + x) * 4 + 3) > 0;

    var top = h, bottom = -1;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        if (opaque(x, y)) {
          if (y < top) top = y;
          bottom = y;
          break;
        }
      }
    }
    if (bottom < 0) return Sprite(image, w / 2, h.toDouble());
    final mid = (top + bottom) ~/ 2;
    var sum = 0.0, n = 0;
    for (var y = mid; y <= bottom; y++) {
      for (var x = 0; x < w; x++) {
        if (opaque(x, y)) {
          sum += x;
          n++;
        }
      }
    }
    return Sprite(image, n > 0 ? sum / n : w / 2, bottom + 1.0);
  }
}

/// Personajes dibujados a partir de imágenes (la hoja.png de cada uno).
class Art {
  final Character arquero;
  final Character villano;
  final Character princesa;
  Art(this.arquero, this.villano, this.princesa);

  /// Altura de cada personaje de pie, en píxeles del mundo.
  static const double alturaArquero = AjustesArquero.alturaDibujo;
  static const double alturaVillano = 36;
  static const double alturaPrincesa = 30;

  static Future<Art> load() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return Art(
      await Character.load(manifest, 'arquero', height: alturaArquero),
      await Character.load(manifest, 'villano', height: alturaVillano),
      await Character.load(manifest, 'princesa', height: alturaPrincesa),
    );
  }
}
