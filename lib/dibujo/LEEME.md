# El dibujo: guía rápida

Aquí se dibuja todo lo que se ve **durante el juego**. Cada archivo
dibuja una cosa. No cambia nada del juego: solo mira cómo está y lo pinta.

| Archivo             | Qué dibuja                                        |
|---------------------|---------------------------------------------------|
| `pintor.dart`       | **El orden**: llama a todas las piezas            |
| `pincel.dart`       | Herramientas comunes (imagen, brillo, retrato...) |
| `fondo_bosque.dart` | Cielo, montañas y plantas del Bosque de los Duendes |
| `fondo_hadas.dart`  | Cielo, castillos y lucecitas del Reino de las Hadas |
| `terreno.dart`      | Las casillas del mapa (tierra, cuestas, ramas...) |
| `meta.dart`         | El portal, la princesa hada y la recompensa       |
| `objetos.dart`      | Cristales, cofres, hadas, chispas y puntos        |
| `enemigos.dart`     | Enemigos y lo que lanzan                          |
| `arquero.dart`      | El arquero, su estela y sus flechas               |
| `fantasma.dart`     | El fantasma de la princesa y su globo de texto    |
| `hud.dart`          | La barra de arriba                                |
| `pantallas.dart`    | Título, fin del juego, stage completado, tarjeta  |
| `letras.dart`       | La fuente pixel (3x5) y `drawPixelText`           |

La intro se dibuja aparte, en `lib/intro/`. Los dibujos en sí (las
imágenes) vienen de `lib/personajes/` (PNG) y `lib/pixel_art/` (código).

## El orden importa

`pintor.dart` dibuja de atrás hacia delante: lo que se dibuja después
queda **encima**. Por eso el cielo va primero y el HUD al final.

## Coordenadas

- El mundo mide **240 píxeles de alto** (15 casillas de 16). Se escala
  para llenar la pantalla del móvil.
- Una casilla mide `T` = 16 píxeles.
- `x` crece hacia la derecha e `y` crece **hacia abajo** (y = 0 es arriba).
- El cielo y el HUD se dibujan "en pantalla" (no se mueven). El mundo se
  dibuja movido por la cámara (`cam`).

## Cada pieza recibe un Pincel

```dart
void dibujarCofres(Pincel p) {
  for (final k in p.game.cofres) {               // el estado del juego
    final img = p.pixel.objetos.cofre;            // un dibujo de pixel_art
    p.sprite(img, k);                             // dibujarlo sobre su caja
  }
}
```

- `p.c` es el lienzo de Flutter (`Canvas`), por si necesitas dibujar
  rectángulos o caminos a mano.
- `p.game` es el juego, `p.art` las imágenes de los personajes y
  `p.pixel` el pixel art hecho con código.

## Ejemplo: añadir algo nuevo al dibujo

1. Crea `mi_cosa.dart` con una función `void dibujarMiCosa(Pincel p)`.
2. En `pintor.dart`, impórtalo y llama a `dibujarMiCosa(p);` en el sitio
   que toque (antes o después de otras cosas, según deba quedar detrás o
   delante).
