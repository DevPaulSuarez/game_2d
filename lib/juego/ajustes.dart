import 'nivel.dart';

/// Los números del juego (todo lo que no es del arquero) en un solo sitio.
///
/// Cambia un número, guarda y prueba el juego. Los números del arquero
/// están en lib/personajes/arquero/ajustes.dart. Las distancias están en
/// "píxeles del mundo" (un bloque del suelo mide 16) y los tiempos en
/// segundos.
class AjustesJuego {
  // ---- Partida ------------------------------------------------------------

  /// Vidas al empezar (las "X3" de arriba; los corazones son otra cosa).
  static const vidasIniciales = 3;

  /// Cada cuántos cristales se gana una vida extra.
  static const cristalesPorVida = 100;

  /// Lo rápido que baja el reloj: 2,5 = baja 2,5 por cada segundo real.
  static const velocidadReloj = 2.5;

  /// Puntos por cada segundo que sobra en el reloj al llegar a la meta.
  static const puntosPorSegundo = 50;

  /// Segundos que dura la tarjeta "STAGE N" antes de jugar.
  static const duracionTarjeta = 2.5;

  /// Segundos que dura la animación de muerte antes de volver a empezar.
  static const duracionMuerte = 3.0;

  /// Segundos celebrando en la meta (el fragmento vuela del portal al
  /// arquero) antes de la pantalla de "STAGE COMPLETADO".
  static const duracionRecompensa = 4.5;

  /// Segundos que tarda el fragmento en llegar del portal al arquero.
  static const vueloRecompensa = 2.5;

  // ---- Gravedad (para todos) ----------------------------------------------

  static const gravedad = 1600.0;

  /// Velocidad máxima al caer.
  static const caidaMaxima = 450.0;

  /// Lo que puede subir o bajar un personaje de golpe al caminar, sin
  /// saltar (sirve para seguir las cuestas).
  static const escalon = 8.0;

  // ---- Puntos -------------------------------------------------------------

  static const puntosCristal = 100;

  /// Si tienes la vida llena, el hada o la poción dan puntos.
  static const puntosHada = 500;
  static const puntosPocion = 1000;

  /// Cristales que salen de un cofre.
  static const cristalesPorCofre = 5;

  // ---- Fantasma de la princesa --------------------------------------------

  /// Segundos que se ve cada frase.
  static const duracionFrase = 2.8;

  /// Segundos en silencio antes de decir algo para dar ánimos.
  static const silencioFantasma = 11.0;
}

/// Cómo es cada tipo de enemigo.
class FichaEnemigo {
  /// Tamaño de la caja con la que choca.
  final double ancho, alto;

  /// Golpes que aguanta.
  final int vida;

  /// Velocidad al caminar.
  final double velocidad;

  /// Puntos que da al vencerlo.
  final int puntos;

  /// A qué distancia ve al arquero (x horizontal, y vertical) y cuántos
  /// segundos espera como mínimo entre ataques. null = no ataca de lejos.
  final ({double x, double y, double espera})? alcance;

  const FichaEnemigo({
    required this.ancho,
    required this.alto,
    required this.vida,
    required this.velocidad,
    required this.puntos,
    this.alcance,
  });
}

const fichasEnemigos = {
  // Duende: lanza piedras que caen en curva.
  EnemyKind.goblin: FichaEnemigo(
    ancho: 14,
    alto: 15,
    vida: 2,
    velocidad: 25,
    puntos: 200,
    alcance: (x: 150, y: 48, espera: 1.8),
  ),
  // Rata: solo corre por el suelo.
  EnemyKind.rat: FichaEnemigo(
    ancho: 14,
    alto: 8,
    vida: 1,
    velocidad: 65,
    puntos: 100,
  ),
  // Mago oscuro: lanza bolas mágicas que ondulan.
  EnemyKind.mage: FichaEnemigo(
    ancho: 14,
    alto: 20,
    vida: 2,
    velocidad: 18,
    puntos: 300,
    alcance: (x: 170, y: 56, espera: 2.4),
  ),
  // Arquero sombrío: la flecha va recta, así que solo dispara si está más
  // o menos a la altura del arquero.
  EnemyKind.darkArcher: FichaEnemigo(
    ancho: 12,
    alto: 20,
    vida: 1,
    velocidad: 30,
    puntos: 200,
    alcance: (x: 200, y: 20, espera: 2.0),
  ),
};
