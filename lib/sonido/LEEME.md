# Sonido: guía rápida

| Archivo / carpeta | Qué hay                                                   |
|-------------------|-----------------------------------------------------------|
| `efecto.dart`     | La lista de efectos de sonido y el volumen de cada uno    |
| `sonido.dart`     | Reproduce los efectos y la música (y el volumen de la música) |
| `efectos/*.wav`   | Un archivo por efecto (`salto.wav`, `flecha.wav`...)      |
| `musica/*.m4a`    | La música: `titulo`, `bosque` (Stage 1) y `hadas` (Stage 2) |

## Cambiar un sonido

Reemplaza su archivo por otro con el mismo nombre. Por ejemplo, para
otro salto, cambia `efectos/salto.wav`.

Para volver a crear todos los sonidos y la música originales:

```
.venv/bin/python tools/crear_sonidos.py
```

## Añadir un efecto nuevo

1. Pon el archivo en `efectos/`, por ejemplo `llave.wav`.
2. En `efecto.dart`, añade `llave('llave', 0.7),` a la lista (el número
   es el volumen, de 0 a 1).
3. Donde quieras que suene: `mundo.sonar(Efecto.llave);`

## Música de un escenario

Cada escenario dice su música en su archivo de `lib/escenarios/`
(`musica: 'bosque'`). Pon el `.m4a` en `musica/` con ese nombre.
