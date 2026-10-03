import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'game/art.dart';
import 'game/game.dart';
import 'game/level.dart';
import 'game/painter.dart';
import 'game/sprites.dart';
import 'sonido/sonido.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final art = await Art.load();
  final sonido = Sonido();
  try {
    await sonido.cargar();
  } catch (e) {
    // Sin sonido el juego sigue funcionando.
    debugPrint('No se pudo cargar el sonido: $e');
  }
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(PixelApp(art: art, sonido: sonido));
}

class PixelApp extends StatelessWidget {
  final Art art;
  final Sonido sonido;
  const PixelApp({super.key, required this.art, required this.sonido});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'El Arquero y la Princesa Celestial',
      debugShowCheckedModeBanner: false,
      home: GameScreen(art: art, sonido: sonido),
    );
  }
}

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
  final sprites = Sprites();
  final repaint = _Repaint();
  final touch = Input();
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
                          sprites,
                          widget.art,
                          repaint,
                          touch: _isMobile,
                        ),
                      ),
                    ),
                  ),
                  if (_isMobile) ..._touchControls(),
                  _skipButton(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _touchControls() {
    return [
      Positioned(
        left: 24,
        bottom: 20,
        child: Row(
          children: [
            _button(Icons.arrow_back, (v) => touch.left = v),
            const SizedBox(width: 16),
            _button(Icons.arrow_forward, (v) => touch.right = v),
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
              child: _button(Icons.north_east, (v) => touch.shoot = v),
            ),
            const SizedBox(width: 12),
            _button(Icons.arrow_upward, (v) => touch.jump = v, size: 72),
          ],
        ),
      ),
    ];
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

  Widget _button(IconData icon, void Function(bool) set, {double size = 60}) {
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
}

class _Repaint extends ChangeNotifier {
  void tick() => notifyListeners();
}
