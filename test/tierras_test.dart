import 'package:eldritch_companion/partida.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprueba el tablero de las Tierras del Sueño, Hypnos y la Aventura «Sueños de otros mundos».
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  late Partida p;
  setUpAll(() async {
    p = Partida();
    await p.iniciar();
  });
  const exps = {'base', 'tierras_sueno'};

  test('sin tablero del Sueño contra un Primigenio base: no hay mazos del Sueño', () {
    p.nuevaPartida(exps, 'azathoth');
    for (final m in Partida.mazosSueno) {
      expect(p.total(m), 0, reason: m);
    }
    expect(p.total('americas'), 12);
    expect(p.total('otros_mundos'), 30);
  });

  test('Hypnos: tablero del Sueño, 3 especiales y sin Aventura', () {
    p.nuevaPartida(exps, 'hypnos');
    expect(p.total('sueno'), 16);
    expect(p.total('bosque'), 5);
    expect(p.total('kadath'), 5);
    expect(p.total('luna'), 5);
    expect(p.total('subterraneo'), 5);
    expect(p.total('esp_corona'), 8);
    expect(p.total('esp_oniro'), 8);
    expect(p.total('esp_sueno_en_sueno'), 8);
    expect(p.total('investigacion'), 24);
    expect(p.total('mitos'), 3 + 6 + 7);
    expect(p.hayAventuraAntartida, isFalse);
  });

  test('Atlach-Nacha: su Mazo de Mitos, 3 Misterios y sin tablero del Sueño', () {
    p.nuevaPartida(exps, 'atlach_nacha');
    expect(p.total('mitos'), 4 + 6 + 6);
    expect(p.total('investigacion'), 24);
    expect(p.misteriosNecesarios, 3);
    expect(p.misterioActivo, isNotNull);
    expect(p.total('sueno'), 0);
    expect(p.hojasPrimigenio['atlach_nacha'], isNotNull);
  });

  test('preludio Sueños de otros mundos contra Azathoth: tablero y Aventura I, II, III', () {
    final pre = p.sortearPreludio(exps, {'tierras_sueno_tablero'});
    expect(pre, Partida.preludioSuenos);
    p.nuevaPartida(exps, 'azathoth', preludio: pre);
    expect(p.total('sueno'), 16);
    expect(p.grupoAventuraPreludio, 'sueno');
    expect(p.aventuras[p.antartidaActiva]!.etapa, 1);
    p.completarEtapaAntartida();
    expect(p.aventuras[p.antartidaActiva]!.etapa, 2);
    expect(p.aventuras[p.antartidaActiva]!.primigenio, 'sueno');
    p.completarEtapaAntartida();
    expect(p.aventuras[p.antartidaActiva]!.etapa, 3);
    p.completarEtapaAntartida();
    expect(p.antartidaTerminada, isTrue);
  });
}
