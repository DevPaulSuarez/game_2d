// EL PIXEL ART HECHO CON CÓDIGO: todo lo que no viene de un PNG.
//
// Los personajes principales (arquero, princesa, villano) son imágenes de
// lib/personajes/. El resto se dibuja aquí, con código, al abrir el juego:
//
//   herramientas.dart  cómo se dibuja (mapas de letras y rectángulos)
//   enemigos.dart      duende, rata, mago, arquero sombrío y lo que lanzan
//   objetos.dart       cristales, cofres, corazones, alma y hadas
//   terreno.dart       tierra, cuestas, ramas y rocas de cada tema
//   decorado.dart      portal de la meta, plantas y princesa de las hadas
//   intro.dart         casa, jardín, farol, pinos, poción y corazón
//
// Se usa así: pixelArt.enemigos.duende, pixelArt.objetos.cofre...

import 'decorado.dart';
import 'enemigos.dart';
import 'intro.dart';
import 'objetos.dart';
import 'terreno.dart';

export 'decorado.dart';
export 'enemigos.dart';
export 'herramientas.dart' show Pal;
export 'intro.dart';
export 'objetos.dart';
export 'terreno.dart';

class PixelArt {
  final terrenoBosque = crearTerrenoBosque();
  final terrenoHadas = crearTerrenoHadas();
  final enemigos = DibujosEnemigos();
  final objetos = DibujosObjetos();
  final decorado = DibujosDecorado();
  final intro = DibujosIntro();
}
