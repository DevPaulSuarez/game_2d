// REPRODUCE los efectos y la música (con el paquete audioplayers).

import 'package:audioplayers/audioplayers.dart';

import 'efecto.dart';

class Sonido {
  /// Volumen general de la música (los efectos tienen el suyo en efecto.dart).
  static const volumenMusica = 0.35;

  static const _carpeta = 'lib/sonido/';

  final _cache = AudioCache(prefix: _carpeta);
  final _efectos = <Efecto, AudioPool>{};
  final _musica = AudioPlayer();
  String? _pista;

  /// Prepara todos los efectos para que suenen sin retraso.
  Future<void> cargar() async {
    _musica.audioCache = _cache;
    await _musica.setReleaseMode(ReleaseMode.loop);
    for (final e in Efecto.values) {
      _efectos[e] = await AudioPool.createFromAsset(
        path: 'efectos/${e.archivo}.wav',
        maxPlayers: 4,
        audioCache: _cache,
      );
    }
  }

  /// Reproduce los efectos que el juego apuntó en este cuadro.
  void reproducir(List<Efecto> lista) {
    // Si el mismo efecto se pidió varias veces a la vez, suena una sola.
    for (final e in lista.toSet()) {
      _efectos[e]?.start(volume: e.volumen);
    }
  }

  /// Cambia la música ([pista] = nombre del archivo de lib/sonido/musica/
  /// sin .m4a; null = silencio). Si ya está sonando, no hace nada.
  Future<void> musica(String? pista) async {
    if (pista == _pista) return;
    _pista = pista;
    await _musica.stop();
    if (pista != null) {
      await _musica.play(
        AssetSource('musica/$pista.m4a'),
        volume: volumenMusica,
      );
    }
  }
}
