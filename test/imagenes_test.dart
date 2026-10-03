import 'package:flutter_test/flutter_test.dart';
import 'package:game_2d/personajes/imagenes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('las imágenes de cada personaje se cargan desde su carpeta', () async {
    final art = await Art.load();
    expect(art.arquero.count('caminar'), 8);
    expect(art.arquero.count('correr'), 8);
    expect(art.arquero.count('saltar'), 4);
    expect(art.arquero.count('atacar'), 5);
    expect(art.villano.count('caminar'), 6);
    expect(art.princesa.count('caminar'), 5);
    expect(art.princesa.count('fantasma_azul_frente'), 1);
  });
}
