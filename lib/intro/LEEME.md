# La intro: guía rápida

La historia del principio (antes del Stage 1).

| Archivo                 | Qué hace                                              |
|-------------------------|-------------------------------------------------------|
| `guion.dart`            | **La historia**: diálogos y lo que pasa, en orden     |
| `escena.dart`           | El motor: actores, efectos y los tipos de paso        |
| `dibujar_escena.dart`   | Dibuja todo: cielo, casa, efectos, rayos, limbo...    |
| `dibujar_actores.dart`  | Dibuja a cada actor (princesa, villano, arquero...)   |
| `dibujar_dialogo.dart`  | El cuadro de diálogo con el retrato de quien habla    |

## Cambiar un diálogo

Abre `guion.dart`, busca el texto y cámbialo:

```dart
Dice('ARQUERO', 'ENTONCES YO ME ENCARGARÉ DE SANARTE.'),
```

Recuerda: MAYÚSCULAS y sin `;`, comillas ni apóstrofos.

## Los pasos

La historia es una lista de pasos que se hacen uno detrás de otro:

| Paso                              | Qué hace                                        |
|-----------------------------------|-------------------------------------------------|
| `Dice('PRINCESA', 'HOLA.')`       | Alguien habla; espera a que el jugador pulse    |
| `Dice(null, 'HACE MUCHO...')`     | Habla el narrador (sin retrato)                 |
| `Camina('archer', 260, 45)`       | Un actor camina hasta x = 260 a 45 píxeles/s    |
| `Espera(0.8)`                     | No pasa nada durante 0,8 segundos               |
| `Haz((c) { ... })`                | Hace algo al instante                           |
| `Anima(1.5, (c, p, dt) { ... })`  | Anima durante 1,5 s; `p` va de 0 a 1            |

Dentro de `Haz` y `Anima`, `c` es la escena: `c.a('man')` es el villano,
`c.flash = 1` un destello, `c.shake = 2` hace temblar la pantalla,
`c.darkness` oscurece (0 a 1)...

## Actores

`'princess'`, `'man'` (el villano), `'archer'`, `'ghost'` (fantasma de la
princesa), `'potion'`, `'heart'` (el corazón robado) y `'orb'` (la bola
de magia).

La imagen de un actor la decide su `sprite`. Para el villano es el
nombre de su PNG: `c.a('man').sprite = 'ataque_2'` muestra
`lib/personajes/villano/imagenes/ataque_2.png`.

## Ver la intro sin teléfono

Se puede hacer un test que avance la intro y guarde PNG de cada momento
(mira el apartado "Ver la intro sin teléfono" de `CLAUDE.md`).
