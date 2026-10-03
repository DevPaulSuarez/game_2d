// LAS COSAS QUE HAY EN EL MUNDO: solo sus datos (dónde están, cuánto
// miden, qué les pasa). Lo que hacen en cada instante está en
// enemigos.dart, objetos.dart y fantasma.dart; cómo se dibujan, en
// lib/dibujo/.

import 'ajustes.dart';
import 'nivel.dart';

/// Los botones que se están pulsando (teclado o pantalla táctil).
class Input {
  bool left = false;
  bool right = false;
  bool jump = false;
  bool run = false;
  bool shoot = false;
  bool start = false;
  bool skip = false;
}

/// Una caja que choca: la base de todo lo que se mueve.
///
/// `x`, `y` = esquina de arriba a la izquierda; `w`, `h` = ancho y alto;
/// `vx`, `vy` = velocidad (`vy` negativa = hacia arriba).
class Box {
  double x, y, w, h;
  double vx = 0, vy = 0;
  bool onGround = false;
  Box(this.x, this.y, this.w, this.h);

  double get right => x + w;
  double get bottom => y + h;
  double get cx => x + w / 2;
  double get cy => y + h / 2;

  bool overlaps(Box o) =>
      x < o.x + o.w && x + w > o.x && y < o.y + o.h && y + h > o.y;
}

/// Un enemigo. Sus números (vida, velocidad, puntos...) están en
/// [fichasEnemigos] (ajustes.dart).
class Enemy extends Box {
  final EnemyKind kind;

  /// -1 = va a la izquierda, 1 = a la derecha.
  int dir = -1;
  int hp;

  /// Se activa al entrar en pantalla (antes no se mueve).
  bool active = false;
  bool dead = false;

  /// Tiempo que se ve transparente tras recibir un golpe.
  double hitFlash = 0;

  /// Tiempo que falta para su próximo ataque.
  double throwTimer;

  /// Tiempo que se ve la pose de lanzar.
  double throwPose = 0;

  /// Reloj de su animación de caminar.
  double anim = 0;

  Enemy(
    this.kind,
    double x,
    double y,
    double w,
    double h,
    this.hp,
    this.throwTimer,
  ) : super(x, y, w, h);

  FichaEnemigo get ficha => fichasEnemigos[kind]!;
  double get speed => ficha.velocidad;
}

enum TipoProyectil {
  /// Piedra de duende: cae en curva.
  piedra,

  /// Bola mágica de mago oscuro: vuela recta ondulando.
  magia,

  /// Flecha de arquero sombrío: recta y rápida.
  flecha,
}

/// Algo que lanza un enemigo contra el arquero.
class Proyectil extends Box {
  final TipoProyectil tipo;
  double t = 0;
  Proyectil(this.tipo, double x, double y, double vx, double vy)
    : super(
        x,
        y,
        switch (tipo) {
          TipoProyectil.piedra => 6,
          TipoProyectil.magia => 8,
          TipoProyectil.flecha => 10,
        },
        switch (tipo) {
          TipoProyectil.piedra => 5,
          TipoProyectil.magia => 8,
          TipoProyectil.flecha => 3,
        },
      ) {
    this.vx = vx;
    this.vy = vy;
  }
}

/// Hada que flota en su sitio; al tocarla cura al arquero.
class Hada extends Box {
  final double baseX, baseY;
  double t = 0;
  Hada(this.baseX, this.baseY) : super(baseX, baseY, 12, 12);
}

/// Cofre: se abre al tocarlo y da cristales o una poción.
class Cofre extends Box {
  final bool pocion;
  bool abierto = false;
  double t = 0;
  Cofre(double x, double y, {required this.pocion}) : super(x, y, 14, 11);
}

/// Chispa blanca que dura un instante (al chocar, al abrir un cofre...).
class Spark {
  double x, y, t = 0;
  Spark(this.x, this.y);
}

/// Cristal que salta de un cofre al abrirlo.
class CristalPop {
  double x, y, vx, vy = -300, t = 0;
  CristalPop(this.x, this.y, this.vx);
}

/// Número de puntos que sube flotando ("200").
class ScorePop {
  final String text;
  double x, y, t = 0;
  ScorePop(this.text, this.x, this.y);
}

/// El fantasma de la princesa: sigue al arquero y le da ánimos.
class Ghost {
  double x, y;

  /// Lo que está diciendo (null = nada) y cuánto le queda en pantalla.
  String? speech;
  double speechT = 0;

  /// Segundos que lleva callada.
  double idle = 0;
  Ghost(this.x, this.y);
}
