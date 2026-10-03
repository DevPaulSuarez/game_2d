# game_2d: contexto para Claude

Lee esto antes de trabajar en el proyecto. Resume quién lo hace, cómo
está montado y qué se decidió en conversaciones anteriores.

## Quién lo hace

- Habla español (informal, con faltas de escritura): **responde siempre en
  español**, con explicaciones sencillas.
- Viene del backend con C#/.NET y es **principiante en videojuegos** y en
  pixel art.
- Quiere el código **modular**, como piezas de un rompecabezas: cada archivo
  hace una sola cosa, los números en un único sitio (`ajustes.dart`) y una
  guía `LEEME.md` en cada carpeta importante.
- **Usa Flutter puro.** Probó Godot y no le gustó: no vuelvas a proponerlo.
  Tampoco usa Flame; si lo pregunta, la conclusión fue que migrar no
  compensa (habría que reescribir casi todo).
- Quiere hacer el arte él mismo: no le propongas packs de assets.
- Plataformas objetivo: Android e iOS. Trabaja en un Mac con Xcode 27.

## El juego

Plataformas 2D en pixel art: **el arquero y la princesa celestial**.

### Historia (intro en `lib/intro/guion.dart`)

1. Una princesa celestial llena el reino de paz y alegría.
2. Vuelve su **pareja** (el villano), le promete un reino sin fin y joyas;
   ella dice que solo quiere ver feliz al reino y tenerlo a su lado.
3. Él la **traiciona**: poder oscuro, *lanzar magia* (bola de magia), ella
   cae, el rayo de *ataque* le saca el corazón, él dice que nunca la amó y
   **lo rompe en pedazos** en su mano.
4. Salta, se transforma en **demonio** y desaparece en una nube de humo.
5. La princesa entra en el **limbo** (todo gris) y se pregunta por qué no
   vio la traición, si fue su culpa, si queda algo de ella.
6. El **arquero** pasa de largo, se detiene y la reconoce: es su **amiga**
   (no se conocen desde la infancia). Le lanza una poción curativa.
7. Sale el **fantasma de la princesa** (su cuerpo sigue en el suelo).
8. El arquero **promete sanar su corazón** buscando cada pedazo, uno por
   uno, y devolverle la esperanza. Ella lo acompañará como fantasma.
9. Tarjeta "STAGE 1".

En los niveles se recogen fragmentos de corazón y el fantasma acompaña al
arquero dándole ánimos.

### Mecánicas

- Caminar, correr (estela de siluetas), saltar (con salto "coyote"),
  disparar flechas y golpe cuerpo a cuerpo con el mismo botón.
- **Sin escudo**: se quitó a propósito, el juego es de **esquivar**.
- Pisar enemigos, cofres con cristales o pociones, hadas que curan, portal
  de meta.
- Enemigos: duende (piedras), rata, mago oscuro (bolas mágicas), arquero
  sombrío (flechas).

## Cómo está montado

Flutter puro, sin motor de juegos. Mapa completo en `lib/LEEME.md` y un
`LEEME.md` en cada carpeta. Las **reglas** (`juego/`) y el **dibujo**
(`dibujo/`) están separados.

- `lib/main.dart`: arranque (carga imágenes y sonido).
- `lib/pantalla/`: `pantalla_juego.dart` (un `Ticker` llama a
  `game.update()` en pasos de 1/120 s y lee el teclado) y
  `controles_tactiles.dart`.
- `lib/juego/`: `juego.dart` (clase `Game`: estado y orden de las cosas),
  `ajustes.dart` (números del juego y tabla `fichasEnemigos`),
  `entidades.dart` (`Input`, `Box`, `Enemy`...), `fisica.dart`,
  `enemigos.dart`, `objetos.dart`, `fantasma.dart` (frases) y `nivel.dart`
  (`Tile`, `T`, `LevelData`). Las piezas son `extension ... on Game`;
  `juego.dart` las reexporta todas.
- `lib/dibujo/`: `pintor.dart` (`GamePainter`, solo el orden) llama a una
  función por pieza (`fondo_bosque`, `fondo_hadas`, `terreno`, `meta`,
  `objetos`, `enemigos`, `arquero`, `fantasma`, `hud`, `pantallas`). Todas
  reciben un `Pincel` (`pincel.dart`) con el lienzo, el juego y las
  imágenes. `letras.dart`: fuente pixel 3x5.
- `lib/intro/`: `guion.dart` (la historia como lista de pasos: `Dice`
  diálogo, `Camina`, `Anima` durante N segundos, `Haz`, `Espera`),
  `escena.dart` (motor: `Cutscene`, actores, efectos) y
  `dibujar_escena/actores/dialogo.dart`.
- `lib/pixel_art/`: pixel art dibujado con código. `PixelArt` agrupa
  `enemigos`, `objetos`, `decorado`, `intro`, `terrenoBosque` y
  `terrenoHadas`; `herramientas.dart` tiene `desdeMapa`, `dibujarImagen`,
  `rect` y `parche`.
- `lib/personajes/`: `imagenes.dart` (`Art`, `Character`, `Sprite`: carga
  los PNG) y un módulo por personaje `<arquero|villano|princesa>/` con
  - `hoja.png`: la hoja grande original,
  - `imagenes/`: los cuadros recortados (los genera `tools/build_sprites.py`),
  - código propio (el arquero: `arquero.dart`, `caminar.dart`,
    `saltar.dart`, `disparar.dart`, `atacar.dart`, `recibir_dano.dart`,
    `estela.dart`, `animacion.dart`, `ajustes.dart`, `LEEME.md`).
- `lib/escenarios/`: los niveles, dibujados con letras (leyenda en
  `escenario.dart` y `LEEME.md`). Stage 1: Bosque de los Duendes. Stage 2:
  Reino de las Hadas.
- `lib/sonido/`: `efecto.dart`, `sonido.dart`, `efectos/*.wav`,
  `musica/*.m4a` (los genera `tools/crear_sonidos.py`).

### Imágenes de los personajes

- Nombres: `caminar_1.png`, `caminar_2.png`... forman la animación
  `'caminar'`; `quieto_derecha.png` es una animación de 1 cuadro.
- `imagenes.dart` escala cada personaje por la altura de `quieto_frente`
  (arquero 30, princesa 30, villano 36 píxeles del mundo) y apoya los pies
  en la fila más baja con color.
- La princesa tiene: `quieto_*`, `caminar`, `atacar`, `saltar`, `muerte`,
  `fantasma_{verde,azul,blanco}_{frente,derecha,espalda,izquierda}`,
  `retrato`. En el juego se usa el fantasma **azul**. Las que no se usan
  están listadas en `lib/personajes/LEEME.md`.
- El villano tiene, entre otras: `ataque_1..5` (roba el corazón),
  `lanzar_magia_1..5`, `bola_magia`, `con_corazon`, `demonio_1..4`,
  `retrato`, `retrato_demonio`.
- En las hojas la pose "IZQUIERDA" en realidad mira a la derecha: el
  script usa la de la derecha volteada.
- Para la princesa y parte del villano los recortes son rectángulos
  escritos a mano en `tools/build_sprites.py` (los cuadros salen pegados).

### Textos en pantalla

La fuente pixel solo tiene: letras A–Z, números, `- ! ¡ : . / ? ¿ , * ( ) +`
y `Á É Í Ó Ú Ü Ñ`. **No uses** `;`, comillas, apóstrofos ni `…` (escribe
`...`). Los textos van en MAYÚSCULAS.

## Comandos

```
flutter pub get
flutter analyze
flutter test
flutter run

# Herramientas (Python)
python3 -m venv .venv && .venv/bin/pip install pillow numpy scipy
.venv/bin/python tools/build_sprites.py          # recorta las hojas
.venv/bin/python tools/build_sprites.py --debug  # + tools/out/*_boxes.png
.venv/bin/python tools/crear_sonidos.py          # crea efectos y música
```

Comprueba siempre con `flutter analyze` y `flutter test` antes de dar algo
por terminado.

### Ver la intro sin teléfono

Para revisar cómo se ve un cambio visual: crea un test temporal que cree
`Art.load()`, `PixelArt()`, `Game()` y un `Cutscene()`, avance
`cutscene.update(dt, avanzar)` y pinte `GamePainter.paint()` sobre un
`ui.PictureRecorder` para guardar PNG en una carpeta temporal. Míralos y
**borra el test** al terminar. Para una reorganización sin cambios
visuales, guarda los PNG antes y después y compáralos con `diff -r`.

## Problemas conocidos y pendientes

- **iOS no compila**: Flutter 3.41.9 falla con Xcode 27 (`lipo
  -verify_arch` con 2 arquitecturas). Se arregla con Flutter 3.47.5 o
  posterior (`flutter upgrade`); el usuario aún no lo ha aprobado.
- **No hay carpeta `android/`** aunque Android es objetivo: se crea con
  `flutter create --platforms=android .` (pendiente de que lo pida).
- La princesa de las hadas (Stage 2) sigue dibujada con código.
- Hay mezcla de resoluciones: personajes desde hojas grandes y el resto
  pixel art con código.

## Git

Repositorio público: https://github.com/DevPaulSuarez/game_2d (rama
`main`). Haz commit o push solo cuando el usuario lo pida.
