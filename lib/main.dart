// EL ARRANQUE: carga las imágenes y los sonidos y abre la pantalla del
// juego. Mapa de todo el proyecto: lib/LEEME.md.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'pantalla/pantalla_juego.dart';
import 'personajes/imagenes.dart';
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
  // Siempre en horizontal y a pantalla completa.
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
