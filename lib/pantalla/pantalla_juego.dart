// LA PANTALLA DEL JUEGO: el bucle que mueve el juego (unas 120 veces por
// segundo), el teclado y el botón OMITIR de la intro.
//
// Teclas: flechas o A/D mover, espacio/arriba/W/Z saltar, X/J disparar,
// Shift correr, Escape/Enter omitir la intro.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../dibujo/pintor.dart';
import '../juego/juego.dart';
import '../personajes/imagenes.dart';
import '../pixel_art/pixel_art.dart';
import '../sonido/sonido.dart';
import 'controles_tactiles.dart';

class GameScreen extends StatefulWidget {
  final Art art;
  final Sonido sonido;
  const GameScreen({super.key, required this.art, required this.sonido});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  final game = Game();
  final pixel = PixelArt();
  final repaint = _Repaint();

  /// Botones táctiles que se están pulsando.
  final touch = Input();

  /// Lo que se le pasa al juego: teclado + botones táctiles.
  final input = Input();
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  bool get _isMobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    repaint.dispose();
    super.dispose();
  }

  /// Se llama en cada cuadro de la pantalla.
  void _onTick(Duration elapsed) {
    var dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt > 1 / 20) dt = 1 / 20;

    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    bool k(List<LogicalKeyboardKey> ks) => ks.any(keys.contains);
    input
      ..left =
          touch.left ||
          k([LogicalKeyboardKey.arrowLeft, LogicalKeyboardKey.keyA])
      ..right =
          touch.right ||
          k([LogicalKeyboardKey.arrowRight, LogicalKeyboardKey.keyD])
      ..jump =
          touch.jump ||
          k([
            LogicalKeyboardKey.space,
            LogicalKeyboardKey.arrowUp,
            LogicalKeyboardKey.keyW,
            LogicalKeyboardKey.keyZ,
          ])
      ..run =
          touch.run ||
          k([LogicalKeyboardKey.shiftLeft, LogicalKeyboardKey.shiftRight])
      ..shoot =
          touch.shoot || k([LogicalKeyboardKey.keyX, LogicalKeyboardKey.keyJ])
      ..skip =
          touch.skip || k([LogicalKeyboardKey.escape, LogicalKeyboardKey.enter])
      ..start = k([LogicalKeyboardKey.enter]);
    touch.skip = false;

    // Subpasos pequeños para una física estable.
    while (dt > 0) {
      final step = dt > 1 / 120 ? 1 / 120 : dt;
      game.update(step, input);
      dt -= step;
    }
    // Sonidos que pidió el juego en este cuadro, y la música que toca.
    widget.sonido.reproducir(game.sonidos);
    game.sonidos.clear();
    widget.sonido.musica(game.musica);
    repaint.tick();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        autofocus: true,
        // Consumimos las teclas para evitar el "beep" del sistema en macOS.
        onKeyEvent: (_, _) => KeyEventResult.handled,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final scale = c.maxHeight / (kRows * T);
              game.viewW = c.maxWidth / scale;
              return Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: game.requestStart,
                      child: CustomPaint(
                        painter: GamePainter(
                          game,
                          pixel,
                          widget.art,
                          repaint,
                          touch: _isMobile,
                        ),
                      ),
                    ),
                  ),
                  if (_isMobile) ...controlesTactiles(touch),
                  _skipButton(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Botón para saltar la intro.
  Widget _skipButton() {
    return Positioned(
      right: 12,
      bottom: _isMobile ? null : 12,
      top: _isMobile ? 40 : null,
      child: ListenableBuilder(
        listenable: repaint,
        builder: (context, _) {
          if (game.state != GameState.intro) return const SizedBox.shrink();
          return TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.black54,
              foregroundColor: Colors.white,
            ),
            onPressed: () => touch.skip = true,
            child: const Text('OMITIR ▶▶'),
          );
        },
      ),
    );
  }
}

/// Avisa al pintor de que toca volver a dibujar.
class _Repaint extends ChangeNotifier {
  void tick() => notifyListeners();
}
