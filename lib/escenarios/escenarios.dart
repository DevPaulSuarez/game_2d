// LA LISTA DE ESCENARIOS, en el orden en que se juegan.
//
// Para añadir un escenario: crea su archivo (copia reino_hadas.dart como
// ejemplo), impórtalo aquí y ponlo en la lista.

import 'bosque_duendes.dart';
import 'escenario.dart';
import 'reino_hadas.dart';

const escenarios = <Escenario>[
  bosqueDuendes, // STAGE 1
  reinoHadas, // STAGE 2
];

/// Con qué escenario empieza el juego (0 = el primero de la lista).
/// Pon 1 para probar directamente el Reino de las Hadas.
const empezarEnEscenario = 0;
