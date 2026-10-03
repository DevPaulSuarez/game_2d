# Personajes: guía rápida

Los tres personajes principales están dibujados en hojas grandes (PNG) y
recortados en un PNG por cuadro.

| Carpeta / archivo | Qué hay                                                 |
|-------------------|---------------------------------------------------------|
| `imagenes.dart`   | Carga los PNG de cada personaje al abrir el juego       |
| `arquero/`        | El arquero: imágenes **y su código** (ver su `LEEME.md`) |
| `princesa/`       | La princesa celestial y su fantasma: solo imágenes      |
| `villano/`        | El villano (y el demonio): solo imágenes                |

Cada carpeta tiene:

- `hoja.png`: la hoja grande original.
- `imagenes/`: los cuadros recortados, que son los que usa el juego.

## Nombres de las imágenes

- `caminar_1.png`, `caminar_2.png`... forman la animación `'caminar'`.
  En el código se piden por el nombre sin número:
  `art.arquero.frame('caminar', 3)` es el cuarto cuadro (se empieza en 0).
- `quieto_derecha.png` (sin número) es una animación de 1 cuadro.
- ¿Quieres un cuadro más? Crea `caminar_9.png` y ya está: no hay que
  tocar código.

## Tamaño y pies

- Cada personaje se escala según la altura de su `quieto_frente.png`
  (arquero 30, princesa 30 y villano 36 píxeles del juego). Esos números
  están en `imagenes.dart` (el del arquero, en `arquero/ajustes.dart`).
- El juego apoya al personaje en la **fila más baja con color** de cada
  imagen: deja los pies abajo del todo.

## Volver a recortar las hojas

```
.venv/bin/python tools/build_sprites.py           # recorta todas las hojas
.venv/bin/python tools/build_sprites.py --debug   # + tools/out/*_boxes.png
```

Ojo: este script **sobrescribe** todos los PNG de `imagenes/`. Si
retocaste un PNG a mano, guarda una copia antes.

## Imágenes que el juego aún no usa

Están listas por si las necesitas más adelante (cargan, pero no se ven):

- Princesa: `atacar_1..5`, `saltar_1..4`, `quieto_espalda`,
  `fantasma_azul_espalda`, `fantasma_azul_izquierda` y los fantasmas
  `fantasma_blanco_*` y `fantasma_verde_*` (en el juego se usa el azul).
