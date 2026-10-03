/// TODOS los números del arquero en un solo sitio.
///
/// Cambia un número, guarda y prueba el juego. No hace falta tocar
/// nada más. Las distancias están en "píxeles del mundo" (un bloque del
/// suelo mide 16) y los tiempos en segundos.
class AjustesArquero {
  // ---- Cuerpo -------------------------------------------------------------

  /// Corazones al empezar.
  static const vidaMaxima = 3;

  /// Tamaño de la caja con la que choca (más pequeña que el dibujo).
  static const ancho = 12.0;
  static const alto = 22.0;

  /// Altura del dibujo de pie (quieto_frente.png) dentro del juego.
  static const double alturaDibujo = 30;

  // ---- Caminar y correr (caminar.dart) ------------------------------------

  static const velocidadCaminar = 100.0;
  static const velocidadCorrer = 150.0;

  /// Qué tan rápido gana velocidad en el suelo y en el aire.
  static const aceleracionSuelo = 340.0;
  static const aceleracionAire = 240.0;

  /// Frenado al cambiar de sentido de golpe (derrape).
  static const frenadoGiro = 700.0;

  /// Frenado al soltar las flechas, en el suelo y en el aire.
  static const frenadoSuelo = 450.0;
  static const frenadoAire = 120.0;

  // ---- Saltar (saltar.dart) -----------------------------------------------

  /// Fuerza del salto. Más grande = salta más alto.
  static const fuerzaSalto = 320.0;

  /// Salta un poco más alto si va corriendo (esto por cada unidad de
  /// velocidad).
  static const saltoExtraPorVelocidad = 0.25;

  /// Gravedad mientras sube con el botón de salto apretado (más baja que
  /// la normal: mantener el botón = salto más alto).
  static const gravedadManteniendo = 700.0;

  /// Si pulsas saltar un poco antes de tocar el suelo, el salto se guarda
  /// este tiempo y sale en cuanto aterriza.
  static const saltoGuardado = 0.12;

  /// Tiempo que aún puede saltar después de salir de un borde.
  static const tiempoCoyote = 0.08;

  /// Cuánto dura cada pose del salto.
  static const duracionImpulso = 0.08;
  static const duracionAterrizaje = 0.12;

  /// Solo muestra la pose de aterrizaje si estuvo en el aire al menos esto.
  static const aireMinimoParaAterrizar = 0.15;

  /// Rebote hacia arriba al pisar a un enemigo.
  static const reboteAlPisar = 260.0;

  // ---- Disparar flechas (disparar.dart) -----------------------------------

  static const velocidadFlecha = 330.0;

  /// Distancia que recorre una flecha antes de desaparecer.
  static const alcanceFlecha = 280.0;

  /// Flechas en pantalla a la vez, como máximo.
  static const maxFlechas = 3;

  /// Espera mínima entre un disparo y el siguiente.
  static const recargaDisparo = 0.3;
  static const duracionDisparo = 0.25;

  // ---- Atacar cuerpo a cuerpo (atacar.dart) -------------------------------

  /// Si un enemigo está a esta distancia delante, el botón de disparo da
  /// un golpe en vez de lanzar una flecha.
  static const alcanceGolpe = 20.0;
  static const danoGolpe = 1;
  static const recargaGolpe = 0.35;
  static const duracionAtaque = 0.3;

  // ---- Recibir daño (recibir_dano.dart) -----------------------------------

  /// Tiempo parpadeando sin poder recibir otro golpe.
  static const tiempoInvencible = 1.5;
  static const duracionDano = 0.4;

  /// Empujón hacia atrás y hacia arriba al recibir un golpe.
  static const empujeDano = 120.0;
  static const saltitoDano = 200.0;

  // ---- Animación (animacion.dart) -----------------------------------------

  /// Segundos quieto antes de voltearse de frente.
  static const frenteTras = 3.0;

  /// Cada cuántos píxeles de avance cambia el cuadro de caminar / correr.
  /// Va ligado a lo que mide un paso en el dibujo: si el número es muy
  /// grande, el cuerpo avanza más que las piernas y parece que arrastra
  /// los pies; si es muy pequeño, patalea en el sitio.
  /// (Caminar y correr: 4 cuadros por paso; un paso avanza 14 y 20 px.)
  static const pixelesPorCuadroCaminar = 3.5;
  static const pixelesPorCuadroCorrer = 5.0;

  /// A partir de esta velocidad usa las imágenes de correr.
  static const velocidadAnimCorrer = 115.0;

  // ---- Estela al correr (estela.dart) -------------------------------------

  /// Cada cuántos segundos deja una silueta (más pequeño = más siluetas).
  static const separacionEstela = 0.07;

  /// Cuánto tarda cada silueta en borrarse del todo.
  static const duracionEstela = 0.3;

  /// Transparencia de la silueta más nueva (0 = invisible, 1 = opaca).
  static const opacidadEstela = 0.45;

  /// Color de las siluetas (formato 0xAARRGGBB).
  static const colorEstela = 0xFF9CE8FF;
}
