// EL ARQUERO: el personaje que maneja el jugador.
//
// Esta carpeta es como un rompecabezas. Cada archivo es una pieza:
//
//   ajustes.dart       todos los números (velocidad, salto, alcance...)
//   arquero.dart       ESTE archivo: los datos del arquero y el orden en
//                      que se juntan las piezas
//   caminar.dart       caminar y correr
//   saltar.dart        saltar, caer y aterrizar
//   disparar.dart      lanzar flechas
//   atacar.dart        golpe cuerpo a cuerpo
//   recibir_dano.dart  perder vida, curarse y morir
//   estela.dart        las siluetas que deja detrás al correr
//   animacion.dart     qué imagen se dibuja en cada momento
//   imagenes/          los PNG (caminar_1.png, saltar_2.png...)
//
// Lee LEEME.md para ver cómo cambiar o añadir piezas.

import '../../juego/juego.dart';
import 'ajustes.dart';
import 'atacar.dart';
import 'caminar.dart';
import 'disparar.dart';
import 'estela.dart';
import 'saltar.dart';

/// Los botones que el jugador usa en este momento.
class Botones {
  /// -1 = izquierda, 0 = ninguna, 1 = derecha.
  final int direccion;
  final bool correr;

  /// El botón de salto está apretado (mientras lo mantiene).
  final bool saltoApretado;

  /// Se ACABA de pulsar (solo es true en el primer instante).
  final bool saltoPulsado;
  final bool disparoPulsado;

  const Botones({
    this.direccion = 0,
    this.correr = false,
    this.saltoApretado = false,
    this.saltoPulsado = false,
    this.disparoPulsado = false,
  });
}

/// Todo lo que el arquero "recuerda": dónde está, cuánta vida le queda,
/// hacia dónde mira y qué está haciendo.
///
/// Heredado de [Box]: `x`, `y` (esquina de arriba a la izquierda),
/// `vx`, `vy` (velocidad; `vy` negativa = hacia arriba) y `onGround`
/// (está pisando suelo).
class Arquero extends Box {
  int vida = AjustesArquero.vidaMaxima;

  /// 1 = mira a la derecha, -1 = mira a la izquierda.
  int mira = 1;

  bool visible = true;

  /// Píxeles recorridos por el suelo (para elegir el cuadro de caminar).
  double pasos = 0;

  // Tiempos que van bajando hasta 0. Mientras son mayores que 0, la
  // acción está pasando (y su animación se dibuja).
  double tiempoDisparo = 0;
  double tiempoAtaque = 0;
  double tiempoAterrizaje = 0;
  double tiempoDano = 0;
  double invencible = 0;

  /// Espera antes de poder volver a disparar o golpear.
  double recarga = 0;

  /// Salto pulsado que aún no ha podido salir (ver saltar.dart).
  double saltoGuardado = 0;

  // Tiempos que van subiendo.
  double tiempoEnAire = 0;
  double tiempoQuieto = 0;

  /// Siluetas que deja detrás al correr (ver estela.dart).
  final estela = <Huella>[];
  double esperaEstela = 0;

  Arquero(double x, double y)
    : super(x, y, AjustesArquero.ancho, AjustesArquero.alto);

  /// Lo que hace el arquero en cada instante del juego (unas 120 veces
  /// por segundo). Cada línea es una pieza del rompecabezas: para quitar
  /// una habilidad, borra su línea; para añadir una, crea su archivo y
  /// llámala aquí.
  void actualizar(double dt, Botones b, Game mundo) {
    _contarTiempos(dt);
    caminar(this, b, dt); //       caminar.dart
    saltar(this, b, dt, mundo); // saltar.dart
    if (b.disparoPulsado) {
      _atacarODisparar(mundo); //  atacar.dart / disparar.dart
    }
    caer(this, b, dt, mundo); //   saltar.dart
    actualizarEstela(this, dt); // estela.dart
  }

  /// Una copia de su pose actual (para la estela).
  Arquero copia() => Arquero(x, y)
    ..vx = vx
    ..vy = vy
    ..onGround = onGround
    ..mira = mira
    ..pasos = pasos
    ..tiempoDisparo = tiempoDisparo
    ..tiempoAtaque = tiempoAtaque
    ..tiempoAterrizaje = tiempoAterrizaje
    ..tiempoDano = tiempoDano
    ..tiempoEnAire = tiempoEnAire
    ..tiempoQuieto = tiempoQuieto;

  /// El mismo botón sirve para las dos cosas: si hay un enemigo pegado,
  /// golpe; si no, flecha.
  void _atacarODisparar(Game mundo) {
    if (recarga > 0) return;
    final cerca = enemigosAlAlcance(this, mundo);
    if (cerca.isNotEmpty) {
      atacar(this, cerca, mundo);
    } else {
      dispararFlecha(this, mundo);
    }
  }

  void _contarTiempos(double dt) {
    recarga -= dt;
    tiempoDisparo -= dt;
    tiempoAtaque -= dt;
    tiempoAterrizaje -= dt;
    tiempoDano -= dt;
    invencible -= dt;
    if (onGround) pasos += vx.abs() * dt;

    final sinHacerNada =
        onGround &&
        vx.abs() < 5 &&
        tiempoDisparo <= 0 &&
        tiempoAtaque <= 0 &&
        tiempoDano <= 0;
    tiempoQuieto = sinHacerNada ? tiempoQuieto + dt : 0;
  }
}
