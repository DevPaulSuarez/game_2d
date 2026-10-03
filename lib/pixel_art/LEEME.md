# Pixel art hecho con código: guía rápida

Los personajes principales son imágenes PNG (`lib/personajes/`). Todo lo
demás se dibuja aquí con código cuando se abre el juego.

| Archivo             | Qué dibujos tiene                                   |
|---------------------|-----------------------------------------------------|
| `pixel_art.dart`    | El "inventario": junta todos los dibujos            |
| `herramientas.dart` | Cómo se dibuja: mapas de letras y rectángulos       |
| `enemigos.dart`     | Duende, rata, mago, arquero sombrío y lo que lanzan |
| `objetos.dart`      | Cristales, cofres, corazones, alma y hadas          |
| `terreno.dart`      | Tierra, cuestas, ramas y rocas de cada tema         |
| `decorado.dart`     | Portal de la meta, plantas y princesa de las hadas  |
| `intro.dart`        | Casa, jardín, farol, pinos, poción y corazón        |

En el resto del juego se usan así: `p.pixel.enemigos.duende`,
`p.pixel.objetos.cofre`, `p.pixel.terrenoBosque.roca`...

## Dibujar con un mapa de letras

Cada letra es un color de la paleta y `.` es transparente. Por ejemplo,
la rata (`enemigos.dart`):

```dart
const _rat = [
  '................',
  '...DD...........',
  '..DMMD..........',
  '.DMMMMMMMMD.....',
  'DKMMMMMMMMMD....',   ← K = el ojo
  'PMMMMMMMMMMMD...',
  '.DMMMMMMMMMMMDTT',
  '..DMMMMMMMMMD..T',
  '...PP..PP.PP....',   ← P = las patas
];

const _ratPal = {
  'M': Color(0xFF8A8A9A),   // cuerpo
  'D': Color(0xFF4A4A5A),   // sombra
  'K': Color(0xFF000000),   // ojo
  'P': Color(0xFFF0A0B0),   // patas
  'T': Color(0xFFE08898),   // cola
};
```

Los colores se escriben `Color(0xFFRRGGBB)`: `FF` = opaco y luego el
color en hexadecimal (como en un editor de imágenes).

Para cambiar el dibujo, edita las letras. Para una pose nueva que solo
cambia unas filas, usa `parche`:

```dart
// La rata caminando: igual que _rat pero con otra fila 8 (las patas).
final _ratWalk = parche(_rat, 8, const ['..PP..PP..PP....']);
```

`desdeMapa` añade solo volumen y un contorno oscuro (con
`retoque: false` no lo hace).

## Dibujar con rectángulos

```dart
ui.Image _buildLamp() => dibujarImagen(12, 44, (c, p) {
  rect(c, p, Pal.black, 5, 10, 2, 34);   // color, x, y, ancho, alto
  ...
});
```

## Añadir un dibujo nuevo

1. Escribe su mapa (o sus rectángulos) en el archivo que toque.
2. Añade un campo en la clase de ese archivo, por ejemplo en
   `DibujosObjetos`: `final llave = desdeMapa(_llave, _llavePal);`
3. Úsalo al dibujar: `p.img(p.pixel.objetos.llave, x, y);`
