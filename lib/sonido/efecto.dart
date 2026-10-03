// LOS EFECTOS DE SONIDO del juego.
//
// Cada efecto es un archivo de lib/sonido/efectos/ con el mismo nombre
// (Efecto.salto -> salto.wav). Para cambiar un sonido, reemplaza su .wav;
// para crearlos de nuevo: .venv/bin/python tools/crear_sonidos.py
//
// El juego no reproduce los sonidos directamente: los apunta con
// mundo.sonar(Efecto.salto) y sonido.dart los reproduce después. Así las
// pruebas automáticas funcionan sin altavoces.

enum Efecto {
  salto('salto', 0.5),
  flecha('flecha', 0.6),
  espada('espada', 0.8),
  golpe('golpe', 0.7),
  enemigoMuere('enemigo_muere', 0.6),
  pisoton('pisoton', 0.7),
  cristal('cristal', 0.45),
  cofre('cofre', 0.7),
  curar('curar', 0.7),
  hada('hada', 0.7),
  dano('dano', 0.8),
  magia('magia', 0.35),
  muerte('muerte', 0.8),
  victoria('victoria', 0.8),
  inicio('inicio', 0.6);

  /// Nombre del archivo (sin .wav).
  final String archivo;

  /// Volumen, de 0 (mudo) a 1 (máximo).
  final double volumen;

  const Efecto(this.archivo, this.volumen);
}
