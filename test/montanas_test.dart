import 'package:eldritch_companion/partida.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprueba que Las montañas de la locura arma bien los mazos de la Antártida y su Aventura.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late Partida p;
  setUpAll(() async {
    p = Partida();
    await p.iniciar();
  });

  const exps = {'base', 'montanas_locura'};

  test('sin Antártida: no hay mazos de la Antártida ni Aventura', () {
    p.nuevaPartida(exps, 'ithaqua');
    expect(p.total('puesto_avanzado'), 0);
    expect(p.total('montanas'), 0);
    expect(p.total('inv_antartida'), 0);
    expect(p.hayAventuraAntartida, isFalse);
    expect(p.total('investigacion'), 24);
    expect(p.total('esp_hiperborea'), 8);
    expect(p.total('mitos'), 4 + 6 + 6);
    expect(p.misterioActivo, isNotNull);
  });

  test('preludio de la Antártida contra Ithaqua: 3 mazos y Aventura ANTÁRTIDA I', () {
    final pre = p.sortearPreludio(exps, {'antartida'});
    expect(pre, Partida.preludioAntartida);
    p.nuevaPartida(exps, 'ithaqua', preludio: pre);
    expect(p.opciones, contains('antartida'));
    expect(p.total('puesto_avanzado'), 16);
    expect(p.total('montanas'), 16);
    expect(p.total('inv_antartida'), 16);
    expect(p.etapaAntartida, 1);
    expect(p.aventuras[p.antartidaActiva]!.etapa, 1);
    p.completarEtapaAntartida();
    expect(p.aventuras[p.antartidaActiva]!.etapa, 2);
    p.completarEtapaAntartida();
    expect(p.aventuras[p.antartidaActiva]!.etapa, 3);
    p.completarEtapaAntartida();
    expect(p.antartidaTerminada, isTrue);
    p.deshacerEtapaAntartida();
    expect(p.etapaAntartida, 3);
  });

  test('El resurgir de los Antiguos: mazos de la Antártida sin Aventura', () {
    p.nuevaPartida(exps, 'antiguos', preludio: Partida.preludioAntartida);
    expect(p.total('puesto_avanzado'), 16);
    expect(p.hayAventuraAntartida, isFalse);
    expect(p.total('esp_desapariciones'), 8);
    expect(p.total('esp_dios_oscuro'), 8);
    expect(p.misteriosNecesarios, 4);
    expect(p.total('mitos'), 5 + 7 + 8);
  });

  test('expedición: Arkham, Roma y Sídney añaden sus cartas', () {
    p.nuevaPartida(exps, 'ithaqua');
    final lugares = p.lugaresExpedicion();
    expect(lugares.keys, containsAll(['Arkham', 'Roma', 'Sídney']));
  });
}
