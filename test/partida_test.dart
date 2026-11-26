import 'package:eldritch_companion/partida.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Carta _c(String id, String mazo, {String? ao, String? lugar}) => Carta(
    id: id, expansion: 'base', mazo: mazo, primigenio: ao, lugar: lugar, imagen: '', reverso: '');

void main() {
  late Partida p;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    p = Partida();
    for (final c in [
      _c('a1', 'americas'),
      _c('a2', 'americas'),
      _c('i1', 'investigacion', ao: 'cthulhu'),
      _c('i2', 'investigacion', ao: 'azathoth'),
      _c('e1', 'expedicion', lugar: 'Antártida'),
      _c('e2', 'expedicion', lugar: 'Tunguska'),
    ]) {
      p.cartas[c.id] = c;
    }
    p.nuevaPartida({'base'}, 'cthulhu');
  });

  test('investigación solo incluye al Primigenio elegido', () {
    expect(p.pila('investigacion'), ['i1']);
  });

  test('robar y descartar; al agotarse se barajan los descartes', () {
    final x = p.robar('americas')!;
    p.descartar(x);
    final y = p.robar('americas')!;
    p.descartar(y);
    expect(p.pila('americas'), isEmpty);
    expect(p.descarte('americas').length, 2);
    expect(p.robar('americas'), isNotNull);
    expect(p.descarte('americas'), isEmpty);
    expect(p.pila('americas').length, 1);
  });

  test('quitar expedición cambia el lugar activo', () {
    final antes = p.expedicionActual!;
    p.quitarExpedicion(antes);
    expect(p.expedicionActual, isNot(antes));
  });
}
