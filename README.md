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

| Carpeta              | Qué hay                                                    |
|----------------------|------------------------------------------------------------|
| `lib/game/`          | Bucle del juego, física, dibujo, intro y fuente pixel      |
| `lib/personajes/`    | Un módulo por personaje: `hoja.png`, `imagenes/` y código  |
| `lib/escenarios/`    | Los niveles, dibujados con letras (ver su `LEEME.md`)      |
| `lib/sonido/`        | Efectos y música                                           |
| `tools/`             | Scripts para recortar sprites y crear sonidos              |
| `test/`              | Pruebas automáticas                                        |

## Herramientas (opcional)

Para volver a recortar sprites o crear sonidos hace falta Python:

```
python3 -m venv .venv && .venv/bin/pip install pillow numpy scipy
.venv/bin/python tools/build_sprites.py
.venv/bin/python tools/crear_sonidos.py
```
