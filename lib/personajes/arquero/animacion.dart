// PIEZA: qué imagen de imagenes/ se dibuja en cada momento.
//
// Las imágenes se llaman por su nombre de archivo sin el número:
// 'caminar' = caminar_1.png, caminar_2.png, ... Para que una animación
// tenga más cuadros basta con añadir caminar_6.png (no hay que tocar
// código).
//
// Se revisa de arriba abajo y gana la PRIMERA situación que se cumpla.

import '../imagenes.dart';
import 'ajustes.dart';
import 'arquero.dart';

/// Devuelve la imagen y si hay que voltearla (dibujada mirando a la
/// derecha; si el arquero mira a la izquierda se voltea).
({Sprite img, bool flip}) imagenDelArquero(
  Arquero a,
  Character imagenes, {
  bool muriendo = false,
  double tiempoMuerte = 0,
}) {
  final izq = a.mira < 0;
  // Las poses de "quieto" ya vienen dibujadas hacia cada lado.
  Sprite quieto() =>
      imagenes.frame(izq ? 'quieto_izquierda' : 'quieto_derecha');

  // 1. Muriendo: muerte_1 ... muerte_4 a lo largo de 0,8 segundos.
  if (muriendo) {
    return (img: imagenes.progress('muerte', tiempoMuerte / 0.8), flip: izq);
  }

  // 2. Recibiendo un golpe.
  if (a.tiempoDano > 0) {
    final t = 1 - a.tiempoDano / AjustesArquero.duracionDano;
    return (img: imagenes.progress('dano', t), flip: izq);
  }

  // 3. Golpe cuerpo a cuerpo.
  if (a.tiempoAtaque > 0) {
    final t = 1 - a.tiempoAtaque / AjustesArquero.duracionAtaque;
    return (img: imagenes.progress('atacar', t), flip: izq);
  }

  // 4. Disparando una flecha.
  if (a.tiempoDisparo > 0) {
    final t = 1 - a.tiempoDisparo / AjustesArquero.duracionDisparo;
    return (img: imagenes.progress('disparar', t), flip: izq);
  }

  // 5. En el aire: saltar_1 impulso, saltar_2 subiendo, saltar_3 arriba
  //    y cayendo.
  if (!a.onGround) {
    final impulso = a.tiempoEnAire < AjustesArquero.duracionImpulso && a.vy < 0;
    final cuadro = impulso ? 0 : (a.vy < -60 ? 1 : 2);
    return (img: imagenes.frame('saltar', cuadro), flip: izq);
  }

  // 6. Acaba de aterrizar: saltar_4.
  if (a.tiempoAterrizaje > 0) {
    return (img: imagenes.frame('saltar', 3), flip: izq);
  }

  // 7. Parado: mira a su lado; si lleva mucho rato, se voltea de frente.
  if (a.vx.abs() < 5) {
    if (a.tiempoQuieto > AjustesArquero.frenteTras) {
      return (img: imagenes.frame('quieto_frente'), flip: false);
    }
    return (img: quieto(), flip: false);
  }

  // 8. Corriendo o caminando: cambia de cuadro según lo que avanza.
  if (a.vx.abs() > AjustesArquero.velocidadAnimCorrer) {
    final n = (a.pasos / AjustesArquero.pixelesPorCuadroCorrer).floor();
    return (img: imagenes.frame('correr', n), flip: izq);
  }
  final n = (a.pasos / AjustesArquero.pixelesPorCuadroCaminar).floor();
  return (img: imagenes.frame('caminar', n), flip: izq);
}
