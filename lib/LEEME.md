# Mapa del código

Todo el juego está en esta carpeta. Cada carpeta es una parte del juego
y cada archivo hace **una sola cosa**. Cada carpeta tiene su propio
`LEEME.md` con más detalle.

```
lib/
├── main.dart          arranque: carga imágenes y sonidos, abre la pantalla
├── pantalla/          la pantalla de Flutter: bucle, teclado, botones táctiles
├── juego/             las reglas: estado, física, enemigos, objetos, fantasma
├── dibujo/            dibuja cada cosa en pantalla (una pieza por archivo)
├── intro/             la historia del principio: guion, motor y dibujo
├── personajes/        arquero, princesa y villano (imágenes PNG + código)
├── pixel_art/         dibujos hechos con código (enemigos, objetos, terreno)
├── escenarios/        los niveles, dibujados con letras
└── sonido/            efectos y música
```

## ¿Qué quiero cambiar?

| Quiero cambiar...                                   | Abre                                        |
|-----------------------------------------------------|---------------------------------------------|
| Velocidad, salto, flechas del arquero               | `personajes/arquero/ajustes.dart`           |
| Gravedad, puntos, vidas, reloj                      | `juego/ajustes.dart`                        |
| Vida, velocidad o puntos de un enemigo              | `juego/ajustes.dart` (tabla `fichasEnemigos`) |
| Qué hace un enemigo (cuándo ataca, qué lanza)       | `juego/enemigos.dart`                       |
| Hadas, cofres, cristales                            | `juego/objetos.dart`                        |
| Las frases del fantasma de la princesa              | `juego/fantasma.dart` y el archivo del escenario |
| Un nivel (el mapa)                                  | `escenarios/bosque_duendes.dart`, `reino_hadas.dart` |
| Añadir un nivel nuevo                               | `escenarios/LEEME.md`                       |
| Los diálogos o lo que pasa en la intro              | `intro/guion.dart`                          |
| Un dibujo de personaje (PNG)                        | `personajes/<nombre>/imagenes/`             |
| El dibujo de un enemigo, objeto o planta            | `pixel_art/enemigos.dart`, `objetos.dart`, `decorado.dart` |
| El dibujo de la tierra, cuestas, ramas, rocas       | `pixel_art/terreno.dart`                    |
| El cielo y el fondo de un escenario                 | `dibujo/fondo_bosque.dart`, `fondo_hadas.dart` |
| La barra de arriba (vida, puntos, tiempo)           | `dibujo/hud.dart`                           |
| Pantalla de título, fin del juego, stage completado | `dibujo/pantallas.dart`                     |
| Las letras de la fuente pixel                       | `dibujo/letras.dart`                        |
| Teclas del teclado                                  | `pantalla/pantalla_juego.dart`              |
| Botones táctiles del móvil                          | `pantalla/controles_tactiles.dart`          |
| Un sonido o la música                               | `sonido/LEEME.md`                           |

## Cómo funciona, en pocas palabras

1. `pantalla/pantalla_juego.dart` lee el teclado y los botones, y unas
   **120 veces por segundo** llama a `game.update()` (`juego/juego.dart`).
2. `update()` mueve todo un poquito: el arquero, los enemigos, las
   flechas, el fantasma...
3. Después, `dibujo/pintor.dart` dibuja la pantalla entera llamando a
   cada pieza de `dibujo/` en orden (el fondo primero, el HUD al final).

Las **reglas** (juego/) y el **dibujo** (dibujo/) están separados: las
reglas no saben cómo se ve nada, y el dibujo solo mira el estado del
juego para pintarlo.

## Textos en pantalla

La fuente pixel solo tiene letras A–Z, números, `- ! ¡ : . / ? ¿ , * ( ) +`
y `Á É Í Ó Ú Ü Ñ`. Escribe los textos en MAYÚSCULAS y sin `;`, comillas
ni apóstrofos (usa `...` en vez de `…`).

## Antes de dar algo por terminado

```
flutter analyze   # busca errores en el código
flutter test      # comprueba que todo sigue funcionando
```
