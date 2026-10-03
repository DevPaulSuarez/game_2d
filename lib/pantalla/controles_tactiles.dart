// LOS BOTONES EN PANTALLA (solo en el móvil): izquierda y derecha abajo a
// la izquierda; disparar y saltar abajo a la derecha.

import 'package:flutter/material.dart';

import '../juego/juego.dart';

/// Los botones; al pulsarlos cambian [touch].
List<Widget> controlesTactiles(Input touch) {
  return [
    Positioned(
      left: 24,
      bottom: 20,
      child: Row(
        children: [
          _boton(Icons.arrow_back, (v) => touch.left = v),
          const SizedBox(width: 16),
          _boton(Icons.arrow_forward, (v) => touch.right = v),
        ],
      ),
    ),
    Positioned(
      right: 24,
      bottom: 20,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: _boton(Icons.north_east, (v) => touch.shoot = v),
          ),
          const SizedBox(width: 12),
          _boton(Icons.arrow_upward, (v) => touch.jump = v, size: 72),
        ],
      ),
    ),
  ];
}

/// Un botón redondo: [set] recibe true al pulsarlo y false al soltarlo.
Widget _boton(IconData icon, void Function(bool) set, {double size = 60}) {
  return Listener(
    onPointerDown: (_) => set(true),
    onPointerUp: (_) => set(false),
    onPointerCancel: (_) => set(false),
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black.withValues(alpha: 0.3),
        border: Border.all(color: Colors.white54, width: 2),
      ),
      child: Icon(icon, color: Colors.white, size: size * 0.45),
    ),
  );
}
