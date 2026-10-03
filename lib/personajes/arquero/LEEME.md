# El arquero: guía rápida

Todo lo del arquero está en esta carpeta. Cada archivo es una **pieza**
que hace una sola cosa:

| Quiero cambiar...                                  | Abre               |
|----------------------------------------------------|--------------------|
| Un número (velocidad, altura del salto, alcance...) | `ajustes.dart`     |
| Cómo camina o corre                                 | `caminar.dart`     |
| Cómo salta, cae o aterriza                          | `saltar.dart`      |
| Las flechas                                         | `disparar.dart`    |
| El golpe cuerpo a cuerpo                            | `atacar.dart`      |
| Perder vida, curarse, morir                         | `recibir_dano.dart`|
| Las siluetas que deja al correr                     | `estela.dart`      |
| Qué imagen se ve en cada momento                    | `animacion.dart`   |
| Un dibujo                                           | `imagenes/*.png`   |
| La hoja grande de la que se recortan los dibujos    | `hoja.png`         |
| El orden en que se juntan las piezas                | `arquero.dart`     |

## Cómo encajan las piezas

Unas 120 veces por segundo el juego llama a `actualizar()` en
`arquero.dart`, que hace esto en orden:

```
caminar      → cambia la velocidad según las flechas
saltar       → si pulsó saltar, lo impulsa hacia arriba
atacar / disparar → si pulsó disparar
caer         → gravedad, choques con el suelo, cuestas y ramas
estela       → si corre, deja una silueta detrás
```

Después, el juego lo dibuja con la imagen que elige `animacion.dart`.

## Las imágenes

- `caminar_1.png`, `caminar_2.png`, ... son los cuadros de una animación.
  En el código se piden por el nombre sin número: `'caminar'`.
- ¿Quieres un cuadro más? Crea `caminar_6.png` y ya está. No hay que
  tocar código.
- Dibuja siempre mirando a la **derecha**: al ir a la izquierda se voltea
  sola. (Las de `quieto_...` son la excepción: hay una por lado.)
- Los pies deben quedar abajo del todo en la imagen: el juego apoya ahí
  al personaje.
- Si editas un PNG a mano, no vuelvas a ejecutar
  `tools/build_sprites.py`: ese script vuelve a recortar las hojas
  grandes y sobrescribe todos los PNG de esta carpeta.

## Ejemplo: añadir una pieza nueva (agacharse)

1. **Imagen**: pon `agachado.png` en `imagenes/` (sirve de prueba copiar
   `saltar_1.png`, que ya está agachado).
2. **Botón**: añade `final bool agacharse;` a la clase `Botones` en
   `arquero.dart`. Después:
   - en `lib/juego/entidades.dart`, añade `bool down = false;` a `Input`;
   - en `lib/pantalla/pantalla_juego.dart`, di qué tecla lo activa
     (`..down = k([LogicalKeyboardKey.arrowDown])`);
   - en `lib/juego/juego.dart`, donde se crea `Botones(...)`, añade
     `agacharse: input.down`.
3. **Dato**: añade `bool agachado = false;` a la clase `Arquero`.
4. **Pieza**: crea `agacharse.dart`:
   ```dart
   import 'arquero.dart';

   void agacharse(Arquero a, Botones b) {
     a.agachado = b.agacharse && a.onGround;
     if (a.agachado) a.vx = 0;
   }
   ```
   Y en `caminar.dart`, para que agachado no camine, añade al principio
   `if (a.agachado) return;`
5. **Encájala** en `actualizar()` de `arquero.dart`, antes de `caminar`:
   `agacharse(this, b);`
6. **Imagen en pantalla**: en `animacion.dart`, antes del paso de
   "En el aire":
   ```dart
   if (a.agachado) return (img: imagenes.frame('agachado'), flip: izq);
   ```

## Probar

- `flutter run` para jugar.
- `flutter test` comprueba solo que caminar, saltar, disparar y
  golpear siguen funcionando. Pásalo después de cada cambio.
