# El juego: guía rápida

Aquí están las **reglas** del juego: qué pasa en cada instante. No se
dibuja nada (eso está en `lib/dibujo/`).

| Archivo          | Qué hace                                                  |
|------------------|-----------------------------------------------------------|
| `juego.dart`     | La clase `Game`: el estado de la partida y el orden de las cosas |
| `ajustes.dart`   | **Los números**: gravedad, puntos, vidas, fichas de enemigos |
| `entidades.dart` | Los datos de cada cosa: caja, enemigo, cofre, hada...     |
| `fisica.dart`    | Moverse y chocar con el suelo, cuestas, ramas y paredes   |
| `enemigos.dart`  | Lo que hacen los enemigos y sus proyectiles               |
| `objetos.dart`   | Hadas, cofres, cristales, chispas y puntos que suben      |
| `fantasma.dart`  | El fantasma de la princesa: cómo flota y sus frases       |
| `nivel.dart`     | El mapa ya construido: casillas (`Tile`) y su tamaño (`T`) |

Lo del arquero (caminar, saltar, disparar...) está en
`lib/personajes/arquero/`.

## Las pantallas del juego

`Game.state` dice en qué pantalla está:

```
title  →  intro  →  playing  →  reward  →  clear  →  (siguiente stage)
 (título)  (historia) (jugando)  (meta)    (completado)
                       │
                       └→ dying (muere) → playing (si quedan vidas)
                                        → gameOver (si no)
```

Todo eso se decide en `update()` de `juego.dart`.

## Qué pasa en cada instante (jugando)

`_updatePlaying()` en `juego.dart`, en este orden:

```
reloj            → baja el tiempo; si llega a 0, muere
arquero          → camina, salta, dispara (personajes/arquero/)
flechas          → avanzan y dan a los enemigos
enemigos         → caminan, atacan, se pisan (enemigos.dart)
proyectiles      → piedras, bolas y flechas enemigas (enemigos.dart)
hadas, cofres,   → se recogen al tocarlos (objetos.dart)
cristales
meta             → si llega al portal, ¡stage completado!
cámara           → sigue al arquero
```

## Las "extension"

`enemigos.dart`, `objetos.dart`, `fantasma.dart` y `fisica.dart` empiezan
con algo como:

```dart
extension Enemigos on Game {
  void actualizarEnemigos(double dt) { ... }
}
```

Eso significa: "añade estas funciones a `Game`, pero escritas en otro
archivo". Así `juego.dart` puede llamar a `actualizarEnemigos(dt)` como
si fuera suya, y cada archivo se ocupa de una sola cosa. Es parecido a
los *extension methods* de C#.

## Ejemplo: un enemigo nuevo (murciélago)

1. En `nivel.dart`, añade `bat` a `enum EnemyKind`.
2. En `ajustes.dart`, añade su ficha a `fichasEnemigos` (tamaño, vida,
   velocidad, puntos y, si ataca de lejos, `alcance`).
3. En `lib/escenarios/escenario.dart`, dale una letra en `_enemigos`
   (por ejemplo `'b': EnemyKind.bat`) y apúntala en la leyenda.
4. Si lanza algo, añádelo en `_lanzar()` de `enemigos.dart`.
5. Dibújalo en `lib/pixel_art/enemigos.dart` y elige su imagen en
   `lib/dibujo/enemigos.dart`.
6. `flutter analyze` te dirá si falta algún `switch` por completar.
