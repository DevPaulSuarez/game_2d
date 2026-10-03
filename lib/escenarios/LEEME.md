# Escenarios: guía rápida

Cada escenario (stage) es un archivo en esta carpeta:

| Archivo              | Qué es                                            |
|----------------------|---------------------------------------------------|
| `escenarios.dart`    | La lista de escenarios, en orden de juego         |
| `escenario.dart`     | La **leyenda** de letras y cómo se lee un mapa    |
| `bosque_duendes.dart`| STAGE 1: El Bosque de los Duendes                 |
| `reino_hadas.dart`   | STAGE 2: El Reino de las Hadas                    |

## El mapa se dibuja con letras

Cada escenario es una lista de **tramos**. Cada tramo tiene 15 filas del
mismo largo y se pega a la derecha del anterior, como piezas de un
rompecabezas. Ejemplo (una colina con una rama encima y un cofre):

```
r'.........===.......',   ← rama (se atraviesa desde abajo)
r'...................',
r'......../###\......',   ← cima de la colina
r'...c.../#####\..g..',   ← cofre, cuestas y un duende
r'###################',   ← tierra
r'###################',
```

Cada fila se escribe como `r'....'` (con la `r` delante) para poder usar
la barra `\` de las cuestas.

Letras: `#` tierra, `/` cuesta que sube, `\` cuesta que baja, `=` rama,
`X` roca, `*` cristal, `c` cofre con cristales, `p` cofre con poción,
`g` duende, `r` rata, `m` mago oscuro, `a` arquero sombrío, `h` hada,
`C` portal de la meta. La lista completa está arriba de `escenario.dart`.

La tierra se dibuja sola: sale hierba donde tiene cielo encima, un borde
donde hay un precipicio al lado y esquinas redondeadas.

Si te equivocas (una fila más corta, una letra que no existe, una cuesta
sin tierra debajo...), el juego te dice en qué tramo y fila está el error.

## Reglas para que se pueda jugar

- El arquero salta como mucho **4 casillas** de alto.
- Un precipicio de **3** casillas se salta caminando; de **5** o **6**,
  solo corriendo.
- Las cuestas (`/` y `\`) se suben caminando. Un escalón recto de una
  casilla (sin cuesta) hay que saltarlo.
- Una cuesta necesita `#` debajo y `#` en su lado alto:
  `/` lleva `#` a su derecha y `\` lleva `#` a su izquierda.
- Los enemigos caminan y se caen por los bordes: ponlos donde haya sitio.
- El portal `C` va encima del suelo y mide 5 casillas de ancho: deja
  suelo llano debajo y a su derecha.

## Probar un escenario directamente

En `escenarios.dart` cambia `empezarEnEscenario = 0` por `1` y el juego
empezará en el Reino de las Hadas. Vuelve a ponerlo en `0` al terminar.

## Crear un escenario nuevo (STAGE 3)

1. Copia `reino_hadas.dart` con otro nombre, por ejemplo
   `cueva_cristal.dart`.
2. Dentro, cambia el nombre de la constante (`reinoHadas` →
   `cuevaCristal`), el `numero: 3`, el `nombre`, las frases y el mapa.
3. En `escenarios.dart`, impórtalo y añádelo al final de la lista.
4. `tema:` decide el aspecto: `Tema.bosque` (día, hierba verde, ramas,
   rocas con musgo) o `Tema.hadas` (noche, hierba turquesa, raíces que
   brillan, piedras con runas). Un aspecto nuevo necesita su terreno en
   `lib/pixel_art/terreno.dart` y su cielo en `lib/dibujo/` (copia
   `fondo_hadas.dart` como ejemplo y elígelo en `lib/dibujo/pintor.dart`).

Después de cambiar un mapa, ejecuta `flutter test`. Comprueba que todos
los escenarios se construyen sin errores y que un "jugador robot" puede
llegar corriendo y saltando hasta el portal de cada uno.
