// QUÉ ES UN ESCENARIO (un "stage" del juego).
//
// Cada escenario se dibuja con letras, como un mapa. El nivel se arma
// pegando TRAMOS de izquierda a derecha, como piezas de un rompecabezas.
// Cada tramo tiene 15 filas del mismo largo (la fila de arriba es el
// cielo; la de abajo, el fondo de la pantalla).
//
// Las filas se escriben como r'....' (con la r delante) para poder usar
// la barra \ de las cuestas.
//
// LEYENDA
//   .  aire (nada)
//   #  tierra (la hierba y los bordes se dibujan solos)
//   /  cuesta que sube      (debajo: #   a su derecha: #)
//   \  cuesta que baja      (debajo: #   a su izquierda: #)
//   =  rama: se pisa desde arriba y se atraviesa desde abajo
//   X  roca
//   *  cristal
//   c  cofre con cristales
//   p  cofre con poción (cura un corazón)
//   g  duende           (lanza piedras)
//   r  rata             (solo camina)
//   m  mago oscuro      (lanza bolas mágicas)
//   a  arquero sombrío  (dispara flechas)
//   h  hada             (al tocarla te cura)
//   C  meta: aquí empieza el portal (encima del suelo)
//
// Enemigos, cofres, cristales y hadas se ponen en la casilla donde están,
// justo encima de lo que pisan.

import 'dart:math';

import '../game/level.dart';

class Escenario {
  /// Número que se ve en pantalla ("STAGE 2").
  final int numero;
  final String nombre;

  /// Colores y decorado (ver [Tema]).
  final Tema tema;

  /// Segundos del reloj al empezar.
  final int tiempo;

  /// Música de fondo: nombre de un archivo de lib/sonido/musica/ (sin .m4a).
  final String musica;

  /// Lo que dice la princesa fantasma en momentos clave.
  final String fraseInicio;
  final String fraseMetaCerca;
  final String fraseRecompensa;

  /// Consejos que la princesa dice de vez en cuando en este escenario.
  final List<String> consejos;

  /// El mapa, en trozos que se pegan de izquierda a derecha.
  final List<List<String>> tramos;

  const Escenario({
    required this.numero,
    required this.nombre,
    required this.tema,
    required this.tiempo,
    required this.musica,
    required this.fraseInicio,
    required this.fraseMetaCerca,
    required this.fraseRecompensa,
    required this.consejos,
    required this.tramos,
  });

  /// Convierte los tramos de letras en un nivel jugable.
  LevelData construir() {
    // 1. Pegar los tramos en 15 filas largas.
    final filas = List.filled(kRows, '');
    for (var n = 0; n < tramos.length; n++) {
      final tramo = tramos[n];
      if (tramo.length != kRows) {
        throw FormatException(
          '$nombre, tramo ${n + 1}: tiene ${tramo.length} filas y deben '
          'ser $kRows.',
        );
      }
      for (var y = 0; y < kRows; y++) {
        if (tramo[y].length != tramo[0].length) {
          throw FormatException(
            '$nombre, tramo ${n + 1}, fila ${y + 1}: mide '
            '${tramo[y].length} y la primera fila mide ${tramo[0].length}. '
            'Todas las filas de un tramo deben medir lo mismo.',
          );
        }
        filas[y] += tramo[y];
      }
    }

    // 2. Leer cada letra.
    final ancho = filas[0].length;
    final grid = List.generate(kRows, (_) => List<int>.filled(ancho, 0));
    final enemigos = <EnemySpawn>[];
    final cristales = <Point<int>>[];
    final hadas = <Point<int>>[];
    final cofres = <CofreSpawn>[];
    int? meta;

    String letra(int x, int y) =>
        (x < 0 || x >= ancho || y < 0 || y >= kRows) ? '.' : filas[y][x];

    for (var y = 0; y < kRows; y++) {
      for (var x = 0; x < ancho; x++) {
        switch (letra(x, y)) {
          case '.':
            break;
          case '#':
            grid[y][x] = Tile.ground;
          case 'X':
            grid[y][x] = Tile.rock;
          case '=':
            grid[y][x] = Tile.platform;
          case '/':
            grid[y][x] = Tile.slopeUp;
            _comprobarCuesta(letra, x, y, '/', x + 1, 'derecha');
          case r'\':
            grid[y][x] = Tile.slopeDown;
            _comprobarCuesta(letra, x, y, r'\', x - 1, 'izquierda');
          case '*':
            cristales.add(Point(x, y));
          case 'c':
            cofres.add(CofreSpawn(x, y, pocion: false));
          case 'p':
            cofres.add(CofreSpawn(x, y, pocion: true));
          case 'h':
            hadas.add(Point(x, y));
          case 'C':
            meta = x;
          default:
            final l = letra(x, y);
            final tipo = _enemigos[l];
            if (tipo == null) {
              throw FormatException(
                '$nombre: letra "$l" desconocida en la columna $x, '
                'fila ${y + 1}. Mira la leyenda en escenario.dart.',
              );
            }
            enemigos.add(EnemySpawn(x, y, tipo));
        }
      }
    }
    if (meta == null) {
      throw FormatException('$nombre: falta la meta "C" en el mapa.');
    }

    return LevelData(
      width: ancho,
      grid: grid,
      enemies: enemigos,
      cristales: cristales,
      hadas: hadas,
      cofres: cofres,
      metaX: meta,
      tema: tema,
    );
  }

  /// Una cuesta necesita tierra debajo y tierra en su lado alto; si no,
  /// el terreno quedaría con un agujero.
  void _comprobarCuesta(
    String Function(int x, int y) letra,
    int x,
    int y,
    String cuesta,
    int xAlto,
    String lado,
  ) {
    if (letra(x, y + 1) != '#' || letra(xAlto, y) != '#') {
      throw FormatException(
        '$nombre: la cuesta "$cuesta" de la columna $x, fila ${y + 1} '
        'necesita "#" debajo y "#" a su $lado.',
      );
    }
  }

  static const _enemigos = {
    'g': EnemyKind.goblin,
    'r': EnemyKind.rat,
    'm': EnemyKind.mage,
    'a': EnemyKind.darkArcher,
  };
}
