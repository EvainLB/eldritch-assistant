import 'package:eldritch_companion/catalogo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el catálogo tiene los mazos del juego base', () {
    expect(mazos.map((m) => m.id), contains('expedicion'));
    expect(expansiones.first.primigenios.length, 4);
  });
}
