# game_2d

Juego de plataformas 2D hecho con Flutter (sin motores externos):
**el arquero y la princesa celestial**.

## Empezar

```
git clone https://github.com/DevPaulSuarez/game_2d.git
cd game_2d
flutter pub get
flutter run
flutter test
```

## Carpetas

El mapa completo ("quiero cambiar X → abre Y") está en
[`lib/LEEME.md`](lib/LEEME.md). Cada carpeta tiene su propio `LEEME.md`.

| Carpeta            | Qué hay                                                    |
|--------------------|------------------------------------------------------------|
| `lib/pantalla/`    | La pantalla de Flutter: bucle, teclado y botones táctiles  |
| `lib/juego/`       | Las reglas: estado, física, enemigos, objetos, fantasma    |
| `lib/dibujo/`      | Dibuja cada cosa en pantalla (una pieza por archivo)       |
| `lib/intro/`       | La historia del principio: guion, motor y dibujo           |
| `lib/personajes/`  | Arquero, princesa y villano: `hoja.png`, `imagenes/` y código |
| `lib/pixel_art/`   | Dibujos hechos con código (enemigos, objetos, terreno...)  |
| `lib/escenarios/`  | Los niveles, dibujados con letras                          |
| `lib/sonido/`      | Efectos y música                                           |
| `tools/`           | Scripts para recortar sprites y crear sonidos              |
| `test/`            | Pruebas automáticas                                        |

## Herramientas (opcional)

Para volver a recortar sprites o crear sonidos hace falta Python:

```
python3 -m venv .venv && .venv/bin/pip install pillow numpy scipy
.venv/bin/python tools/build_sprites.py
.venv/bin/python tools/crear_sonidos.py
```
