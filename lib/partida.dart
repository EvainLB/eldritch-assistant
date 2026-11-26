import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

import 'catalogo.dart';

class Carta {
  final String id;
  final String expansion;
  final String mazo;
  final String? primigenio;

  /// Solo en cartas de expedición: el lugar que marca su reverso.
  final String? lugar;
  final String imagen;
  final String reverso;

  /// Solo en cartas de Mitos: verde, amarillo o azul.
  final String? color;

  const Carta({
    required this.id,
    required this.expansion,
    required this.mazo,
    required this.primigenio,
    required this.lugar,
    required this.imagen,
    required this.reverso,
    this.color,
  });

  factory Carta.fromJson(Map<String, dynamic> j) => Carta(
        id: j['id'],
        expansion: j['expansion'],
        // Cada mazo especial es una pila propia: esp_<clave>
        mazo: j['deck'] == 'especial' ? 'esp_${j['special']}' : j['deck'],
        primigenio: j['ancientOne'],
        lugar: j['location'],
        imagen: j['image'],
        reverso: j['back'],
      );
}

/// Hoja de Primigenio (anverso, reverso y retrato recortado de la ilustración).
class HojaPrimigenio {
  final String id;
  final String expansion;
  final String hoja;
  final String reversoHoja;
  final String retrato;
  const HojaPrimigenio(this.id, this.expansion, this.hoja, this.reversoHoja, this.retrato);

  factory HojaPrimigenio.fromJson(Map<String, dynamic> j) =>
      HojaPrimigenio(j['id'], j['expansion'], j['sheet'], j['sheetBack'], j['portrait']);
}

/// Carta de Mitos. Color: verde, amarillo o azul.
class CartaMitos {
  final String id;
  final String expansion;
  final String color;
  final String imagen;
  final String reverso;
  const CartaMitos(this.id, this.expansion, this.color, this.imagen, this.reverso);

  factory CartaMitos.fromJson(Map<String, dynamic> j) =>
      CartaMitos(j['id'], j['expansion'], j['color'], j['image'], j['back']);
}

/// Carta de Misterio de un Primigenio.
class CartaMisterio {
  final String id;
  final String expansion;
  final String primigenio;
  final String imagen;
  final String reverso;
  const CartaMisterio(this.id, this.expansion, this.primigenio, this.imagen, this.reverso);

  factory CartaMisterio.fromJson(Map<String, dynamic> j) =>
      CartaMisterio(j['id'], j['expansion'], j['ancientOne'], j['image'], j['back']);
}

/// Estado de la partida: mazos para robar (posición 0 = arriba) y descartes.
class Partida extends ChangeNotifier {
  static const _clave = 'partida_v1';
  final _rnd = Random();

  final Map<String, Carta> cartas = {};
  final Map<String, HojaPrimigenio> hojasPrimigenio = {};
  final List<CartaMitos> mitos = [];
  final Map<String, CartaMisterio> misterios = {};

  /// Cartas de Preludio (id -> imagen) y expansión de cada una.
  final Map<String, String> preludios = {};
  final Map<String, String> expansionPreludio = {};

  /// Preludio de esta partida (null si se juega sin preludio).
  String? preludio;

  /// Aventuras por etapas (Los Mi-go: «Agujero en el Mundo»): id -> (etapa, imagen, primigenio).
  final Map<String, ({int etapa, String imagen, String primigenio})> aventuras = {};

  /// Etapa en curso (0 = aún no empieza), carta activa y etapas ya completadas.
  int etapaAventura = 0;
  String? aventuraActiva;
  final List<String> aventurasHechas = [];

  /// Aventura de un preludio (ANTÁRTIDA o SUEÑOS DE OTROS MUNDOS): no da la victoria.
  /// [grupoAventuraPreludio] dice cuál es ('antartida' o 'sueno').
  String? grupoAventuraPreludio;
  int etapaAntartida = 0;
  String? antartidaActiva;
  final List<String> antartidaHechas = [];

  /// Misterios de la partida (solo de referencia): mazo, el activo, resueltos y descartados.
  final List<String> mazoMisterios = [];
  String? misterioActivo;
  final List<String> misteriosResueltos = [];
  final List<String> misteriosDescartados = [];
  Set<String> expansionesActivas = {};

  /// Opciones de expansión activas (Antártida, Egipto...). Se usarán al añadir esas cartas.
  Set<String> opciones = {};
  String? primigenio;
  final Map<String, List<String>> robo = {};
  final Map<String, List<String>> descartes = {};

  /// Etapa (1, 2 o 3) de cada carta del Mazo de Mitos de esta partida.
  final Map<String, int> etapaMitos = {};

  /// Cartas que se quedan en el tablero (Mitos activos, rumores...), en orden de llegada.
  final List<String> enJuego = [];

  /// Fichas Eldritch sobre cada carta en juego.
  final Map<String, int> fichas = {};

  /// Carta robada que se está viendo y aún no se resolvió. Si la app se cierra
  /// en ese momento, al volver se devuelve arriba de su mazo para no perderla.
  String? enMano;

  /// Cartas que se regresaron a la caja durante la partida (ya no se usan).
  final Set<String> retiradas = {};
  bool cargada = false;

  bool get hayPartida => primigenio != null;

  Future<void> iniciar() async {
    for (final e in expansiones.where((e) => e.disponible)) {
      final txt = await rootBundle.loadString('assets/data/cartas_${e.id}.json');
      for (final j in (jsonDecode(txt)['cards'] as List)) {
        final c = Carta.fromJson(j);
        cartas[c.id] = c;
      }
      final extra = jsonDecode(await rootBundle.loadString('assets/data/extra_${e.id}.json'));
      for (final j in extra['ancientOnes'] as List) {
        final h = HojaPrimigenio.fromJson(j);
        hojasPrimigenio[h.id] = h;
      }
      for (final j in (extra['preludes'] ?? []) as List) {
        preludios[j['id']] = j['image'];
        expansionPreludio[j['id']] = j['expansion'];
      }
      for (final j in (extra['adventures'] ?? []) as List) {
        aventuras[j['id']] = (etapa: j['stage'] as int, imagen: j['image'] as String, primigenio: j['ancientOne'] as String);
      }
      for (final j in (extra['mysteries'] ?? []) as List) {
        final m = CartaMisterio.fromJson(j);
        misterios[m.id] = m;
      }
      for (final j in extra['mythos'] as List) {
        final m = CartaMitos.fromJson(j);
        mitos.add(m);
        cartas[m.id] = Carta(
          id: m.id,
          expansion: m.expansion,
          mazo: 'mitos',
          primigenio: null,
          lugar: null,
          imagen: m.imagen,
          reverso: m.reverso,
          color: m.color,
        );
      }
    }
    await _restaurar();
    cargada = true;
    notifyListeners();
  }

  /// Id del preludio «Alineamiento cósmico» (activa el mazo de Ruinas místicas).
  static const preludioAlineacion = 'vestigios_extranos_preludio_03';
  static const preludioAntartida = 'montanas_locura_preludio_antartida';

  /// Opción de expansión que equivale a cada preludio (el circulito activa ese preludio).
  static const preludioSuenos = 'tierras_sueno_preludio_suenos';
  static const preludioDeOpcion = {
    'alineacion_cosmica': preludioAlineacion,
    'antartida': preludioAntartida,
    'tierras_sueno_tablero': preludioSuenos,
  };

  /// Sortea un Preludio de las expansiones elegidas. Si la opción Alineación cósmica
  /// está marcada, ese es el preludio.
  String? sortearPreludio(Set<String> exps, Set<String> opciones) {
    for (final e in preludioDeOpcion.entries) {
      if (opciones.contains(e.key) && preludios.containsKey(e.value)) return e.value;
    }
    final lista = preludios.keys.where((id) => exps.contains(expansionPreludio[id])).toList();
    return lista.isEmpty ? null : lista[_rnd.nextInt(lista.length)];
  }

  void nuevaPartida(Set<String> exps, String primigenioId,
      {Set<String> opciones = const {}, String? preludio}) {
    expansionesActivas = exps;
    this.preludio = preludio;
    opciones = {
      ...opciones,
      for (final e in preludioDeOpcion.entries)
        if (preludio == e.value) e.key,
    };
    this.opciones = {...opciones};
    primigenio = primigenioId;
    robo.clear();
    descartes.clear();
    etapaMitos.clear();
    enJuego.clear();
    fichas.clear();
    enMano = null;
    retiradas.clear();
    _prepararMisterios();
    for (final m in mazos) {
      if (m.id == 'mitos') {
        robo['mitos'] = _armarMitos(exps, primigenioId);
        descartes['mitos'] = [];
        continue;
      }
      if ((m.id == 'ruinas' && !usaRuinasMisticas(opciones, primigenioId)) ||
          (mazosAntartida.contains(m.id) && !usaAntartida(opciones, primigenioId)) ||
          (mazosSueno.contains(m.id) && !usaSueno(opciones, primigenioId))) {
        robo['ruinas'] = [];
        descartes['ruinas'] = [];
        continue;
      }
      final ids = cartas.values
          .where((c) =>
              c.mazo == m.id &&
              exps.contains(c.expansion) &&
              (!m.porPrimigenio || c.primigenio == primigenioId))
          .map((c) => c.id)
          .toList()
        ..shuffle(_rnd);
      robo[m.id] = ids;
      descartes[m.id] = [];
    }
    // Mazos especiales del Primigenio elegido
    for (final c in cartas.values) {
      if (c.mazo.startsWith('esp_') && c.primigenio == primigenioId && exps.contains(c.expansion)) {
        robo.putIfAbsent(c.mazo, () => []).add(c.id);
        descartes.putIfAbsent(c.mazo, () => []);
      }
    }
    for (final k in robo.keys.where((k) => k.startsWith('esp_'))) {
      robo[k]!.shuffle(_rnd);
    }
    _cambio();
  }

  /// Mazo de Mitos según la hoja del Primigenio: cada etapa se baraja por separado
  /// y se apilan con la Etapa I arriba y la III al fondo.
  List<String> _armarMitos(Set<String> exps, String primigenioId) {
    final etapas = primigenioPorId(primigenioId)?.mitos ?? const [];
    List<String> monton(String color) => cartas.values
        .where((c) => c.mazo == 'mitos' && c.color == color && exps.contains(c.expansion))
        .map((c) => c.id)
        .toList()
      ..shuffle(_rnd);
    final verdes = monton('verde'), amarillas = monton('amarillo'), azules = monton('azul');
    List<String> sacar(List<String> de, int n) {
      final r = de.take(n).toList();
      de.removeRange(0, r.length);
      return r;
    }

    final mazo = <String>[];
    for (var i = 0; i < etapas.length; i++) {
      final e = etapas[i];
      final etapa = [
        ...sacar(verdes, e.verdes),
        ...sacar(amarillas, e.amarillas),
        ...sacar(azules, e.azules),
      ]..shuffle(_rnd);
      for (final id in etapa) {
        etapaMitos[id] = i + 1;
      }
      mazo.addAll(etapa);
    }
    return mazo;
  }

  /// Etapa de la carta de arriba del Mazo de Mitos (null si se acabó).
  int? get etapaMitosActual {
    final p = pila('mitos');
    return p.isEmpty ? null : etapaMitos[p.first];
  }

  /// Cartas que quedan en la etapa actual del Mazo de Mitos.
  int get quedanEnEtapa {
    final e = etapaMitosActual;
    return pila('mitos').where((id) => etapaMitos[id] == e).length;
  }

  /// Mazos de esta partida en el orden en que se muestran (especiales antes de Mitos).
  List<String> get mazosPartida => [
        for (final m in mazos)
          if (m.id != 'mitos' && m.id != 'desastres') m.id,
        ...(robo.keys.where((k) => k.startsWith('esp_')).toList()..sort()),
        'desastres',
        'mitos',
      ];

  List<String> pila(String mazo) => robo[mazo] ?? const [];
  List<String> descarte(String mazo) => descartes[mazo] ?? const [];
  int total(String mazo) =>
      pila(mazo).length + descarte(mazo).length + enJuego.where((id) => cartas[id]?.mazo == mazo).length;

  /// El mazo de Ruinas místicas se usa con el preludio Alineación cósmica
  /// o cuando la hoja del Primigenio lo pide (Sicigia).
  static const mazosAntartida = {'puesto_avanzado', 'montanas', 'inv_antartida'};

  /// El tablero de la Antártida (y sus 3 mazos) se usa con el preludio «Augurio de perdición
  /// desde la Antártida» o contra El resurgir de los Antiguos.
  static bool usaAntartida(Set<String> opciones, String primigenioId) =>
      opciones.contains('antartida') || primigenioId == 'antiguos';

  static const mazosSueno = {'sueno', 'bosque', 'kadath', 'luna', 'subterraneo'};

  /// El tablero de las Tierras del Sueño se usa con el preludio «Sueños de otros mundos» o contra Hypnos.
  static bool usaSueno(Set<String> opciones, String primigenioId) =>
      opciones.contains('tierras_sueno_tablero') || primigenioId == 'hypnos';

  static bool usaRuinasMisticas(Set<String> opciones, String primigenioId) =>
      opciones.contains('alineacion_cosmica') || primigenioId == 'syzygy';

  /// Lugar activo de un mazo con ficha (Expedición, Ruinas místicas): el reverso de la carta de arriba.
  String? lugarActual(String mazo) {
    final p = pila(mazo);
    if (p.isEmpty) return null;
    return cartas[p.first]?.lugar;
  }

  String? get expedicionActual => lugarActual('expedicion');

  /// Junta mazo y descartes y lo baraja todo (lo piden algunas cartas, p. ej. con las Ruinas místicas).
  void barajarTodo(String mazo) {
    robo[mazo]!
      ..addAll(descartes[mazo]!)
      ..shuffle(_rnd);
    descartes[mazo]!.clear();
    _cambio();
  }

  /// Saca la carta de arriba. Si el mazo está vacío, baraja antes los descartes
  /// (salvo el de Mitos: si se acaba, los investigadores pierden).
  Carta? robar(String mazo) {
    final p = robo[mazo];
    if (p == null) return null;
    if (p.isEmpty && mazo != 'mitos') barajarDescartes(mazo, notificar: false);
    if (p.isEmpty) return null;
    final id = p.removeAt(0);
    enMano = id;
    _cambio();
    return cartas[id];
  }

  void descartar(Carta c) {
    if (enMano == c.id) enMano = null;
    descartes[c.mazo]!.add(c.id);
    _cambio();
  }

  /// Lugares de expedición con cuántas cartas siguen en la partida y cuántas están en la caja.
  Map<String, ({int enPartida, int enCaja})> lugaresExpedicion() {
    final r = <String, ({int enPartida, int enCaja})>{};
    for (final c in cartas.values) {
      if (c.mazo != 'expedicion' || c.lugar == null || !expansionesActivas.contains(c.expansion)) continue;
      final a = r[c.lugar!] ?? (enPartida: 0, enCaja: 0);
      r[c.lugar!] = retiradas.contains(c.id)
          ? (enPartida: a.enPartida, enCaja: a.enCaja + 1)
          : (enPartida: a.enPartida + 1, enCaja: a.enCaja);
    }
    return r;
  }

  /// Regresa a la caja todas las cartas de expedición de un lugar.
  void retirarLugar(String lugar) {
    final ids = cartas.values
        .where((c) => c.mazo == 'expedicion' && c.lugar == lugar)
        .map((c) => c.id)
        .toSet();
    robo['expedicion']?.removeWhere(ids.contains);
    descartes['expedicion']?.removeWhere(ids.contains);
    enJuego.removeWhere(ids.contains);
    if (ids.contains(enMano)) enMano = null;
    retiradas.addAll(ids.where((id) => expansionesActivas.contains(cartas[id]!.expansion)));
    _cambio();
  }

  /// Saca de la caja las cartas de un lugar y las pone al fondo del mazo de expedición.
  void devolverLugar(String lugar) {
    final ids = retiradas.where((id) => cartas[id]?.lugar == lugar).toList()..shuffle(_rnd);
    retiradas.removeAll(ids);
    robo['expedicion']!.addAll(ids);
    _cambio();
  }

  /// Baraja los Misterios del Primigenio y pone el primero como activo (como en la preparación).
  void _prepararMisterios() {
    mazoMisterios
      ..clear()
      ..addAll(misterios.values
          .where((m) => m.primigenio == primigenio && expansionesActivas.contains(m.expansion))
          .map((m) => m.id))
      ..shuffle(_rnd);
    misteriosResueltos.clear();
    misteriosDescartados.clear();
    misterioActivo = mazoMisterios.isEmpty ? null : mazoMisterios.removeAt(0);
    etapaAventura = 0;
    aventuraActiva = null;
    aventurasHechas.clear();
    etapaAntartida = 0;
    antartidaActiva = null;
    antartidaHechas.clear();
    // Preludios con Aventura: si el Primigenio no es el de su expansión, se roba la Aventura de etapa I.
    grupoAventuraPreludio = null;
    if (opciones.contains('antartida') && primigenio != 'antiguos') {
      grupoAventuraPreludio = 'antartida';
    } else if (opciones.contains('tierras_sueno_tablero') && primigenio != 'hypnos') {
      grupoAventuraPreludio = 'sueno';
    }
    if (grupoAventuraPreludio != null) {
      etapaAntartida = 1;
      antartidaActiva = _robarAventura(grupoAventuraPreludio!, 1);
    }
  }

  String? _robarAventura(String grupo, int etapa) {
    final lista = aventuras.entries
        .where((e) => e.value.primigenio == grupo && e.value.etapa == etapa)
        .map((e) => e.key)
        .toList();
    return lista.isEmpty ? null : lista[_rnd.nextInt(lista.length)];
  }

  bool get hayAventuraAntartida => etapaAntartida > 0;
  bool get antartidaTerminada => etapaAntartida == 3 && antartidaActiva == null;

  void completarEtapaAntartida() {
    if (antartidaActiva == null) return;
    antartidaHechas.add(antartidaActiva!);
    if (etapaAntartida < 3) {
      etapaAntartida++;
      antartidaActiva = _robarAventura(grupoAventuraPreludio ?? 'antartida', etapaAntartida);
    } else {
      antartidaActiva = null;
    }
    _cambio();
  }

  void deshacerEtapaAntartida() {
    if (antartidaHechas.isEmpty) return;
    antartidaActiva = antartidaHechas.removeLast();
    etapaAntartida = aventuras[antartidaActiva]!.etapa;
    _cambio();
  }

  bool get tieneAventura => primigenioPorId(primigenio)?.aventuraFinal == true;
  bool get aventuraTerminada => tieneAventura && etapaAventura == 3 && aventuraActiva == null;

  /// Los investigadores cumplieron la condición de victoria (Misterios y, si toca, la Aventura).
  bool get victoria => misteriosCompletos && (!tieneAventura || aventuraTerminada);

  /// Saca al azar una carta de la etapa indicada de la Aventura.
  void _sacarAventura(int etapa) {
    final lista = aventuras.entries
        .where((e) => e.value.primigenio == primigenio && e.value.etapa == etapa)
        .map((e) => e.key)
        .toList();
    etapaAventura = etapa;
    aventuraActiva = lista.isEmpty ? null : lista[_rnd.nextInt(lista.length)];
  }

  /// La etapa activa de la Aventura se completó: entra la siguiente o se gana.
  void completarEtapaAventura() {
    if (aventuraActiva == null) return;
    aventurasHechas.add(aventuraActiva!);
    if (etapaAventura < 3) {
      _sacarAventura(etapaAventura + 1);
    } else {
      aventuraActiva = null;
    }
    _cambio();
  }

  /// Deshace la última etapa completada.
  void deshacerEtapaAventura() {
    if (aventurasHechas.isEmpty) return;
    final ultima = aventurasHechas.removeLast();
    aventuraActiva = ultima;
    etapaAventura = aventuras[ultima]!.etapa;
    _cambio();
  }

  int get misteriosNecesarios => primigenioPorId(primigenio)?.misteriosNecesarios ?? 3;
  bool get misteriosCompletos => misteriosResueltos.length >= misteriosNecesarios;

  void _siguienteMisterio() {
    misterioActivo = (!misteriosCompletos && mazoMisterios.isNotEmpty) ? mazoMisterios.removeAt(0) : null;
  }

  /// El Misterio activo se resolvió: cuenta para ganar y entra el siguiente.
  void resolverMisterio() {
    if (misterioActivo == null) return;
    misteriosResueltos.add(misterioActivo!);
    _siguienteMisterio();
    // Los Mi-go: tras los Misterios empieza la Aventura «Agujero en el Mundo» (etapa I)
    if (misteriosCompletos && tieneAventura && etapaAventura == 0) _sacarAventura(1);
    _cambio();
  }

  /// Se descarta sin contar como resuelto (lo piden algunos efectos) y entra otro.
  void descartarMisterio() {
    if (misterioActivo == null) return;
    misteriosDescartados.add(misterioActivo!);
    _siguienteMisterio();
    _cambio();
  }

  /// Deshace el último Misterio resuelto (por si se tocó sin querer).
  void deshacerResuelto() {
    if (misteriosResueltos.isEmpty || aventurasHechas.isNotEmpty) return;
    etapaAventura = 0;
    aventuraActiva = null;
    if (misterioActivo != null) mazoMisterios.insert(0, misterioActivo!);
    misterioActivo = misteriosResueltos.removeLast();
    _cambio();
  }

  void dejarEnJuego(Carta c) {
    if (enMano == c.id) enMano = null;
    if (!enJuego.contains(c.id)) enJuego.add(c.id);
    fichas.putIfAbsent(c.id, () => 0);
    _cambio();
  }

  void cambiarFichas(Carta c, int delta) {
    fichas[c.id] = max(0, (fichas[c.id] ?? 0) + delta);
    _cambio();
  }

  /// La carta en juego ya se resolvió: sale del tablero y va a los descartes.
  void resolverEnJuego(Carta c) {
    enJuego.remove(c.id);
    fichas.remove(c.id);
    descartes[c.mazo]!.add(c.id);
    _cambio();
  }

  /// Robé por error: la carta vuelve arriba de su mazo (desde la mano, descartes o en juego).
  void devolverArriba(Carta c) {
    descartes[c.mazo]?.remove(c.id);
    enJuego.remove(c.id);
    fichas.remove(c.id);
    if (enMano == c.id) enMano = null;
    robo[c.mazo]!
      ..remove(c.id)
      ..insert(0, c.id);
    _cambio();
  }

  void alFondo(Carta c) {
    if (enMano == c.id) enMano = null;
    robo[c.mazo]!.add(c.id);
    _cambio();
  }

  void devolverYBarajar(Carta c) {
    if (enMano == c.id) enMano = null;
    robo[c.mazo]!
      ..add(c.id)
      ..shuffle(_rnd);
    _cambio();
  }

  /// Saca una carta concreta de la pila de descartes y la devuelve al mazo.
  void recuperarDescarte(Carta c, {bool barajar = true}) {
    descartes[c.mazo]!.remove(c.id);
    if (barajar) {
      devolverYBarajar(c);
    } else {
      robo[c.mazo]!.insert(0, c.id);
      _cambio();
    }
  }

  void barajarDescartes(String mazo, {bool notificar = true}) {
    final p = robo[mazo]!;
    p
      ..addAll(descartes[mazo]!)
      ..shuffle(_rnd);
    descartes[mazo]!.clear();
    if (notificar) _cambio();
  }

  void barajarMazo(String mazo) {
    robo[mazo]!.shuffle(_rnd);
    _cambio();
  }

  /// Manda al fondo todas las cartas de expedición de un lugar
  /// (cuando ese lugar ya no debe ser la expedición activa).
  void quitarExpedicion(String lugar) {
    final p = robo['expedicion']!;
    final delLugar = p.where((id) => cartas[id]?.lugar == lugar).toList();
    p
      ..removeWhere((id) => cartas[id]?.lugar == lugar)
      ..addAll(delLugar);
    _cambio();
  }

  void _cambio() {
    notifyListeners();
    _guardar();
  }

  Future<void> _guardar() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _clave,
        jsonEncode({
          'exps': expansionesActivas.toList(),
          'primigenio': primigenio,
          'opciones': opciones.toList(),
          'robo': robo,
          'descartes': descartes,
          'etapaMitos': etapaMitos,
          'enJuego': enJuego,
          'fichas': fichas,
          'enMano': enMano,
          'retiradas': retiradas.toList(),
          'preludio': preludio,
          'misterios': {
            'mazo': mazoMisterios,
            'activo': misterioActivo,
            'resueltos': misteriosResueltos,
            'descartados': misteriosDescartados,
          },
          'aventura': {'etapa': etapaAventura, 'activa': aventuraActiva, 'hechas': aventurasHechas},
          'antartida': {
            'grupo': grupoAventuraPreludio,
            'etapa': etapaAntartida,
            'activa': antartidaActiva,
            'hechas': antartidaHechas,
          },
        }));
  }

  Future<void> _restaurar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final txt = prefs.getString(_clave);
      if (txt == null) return;
      final j = jsonDecode(txt);
      List<String> limpia(dynamic l) =>
          (l as List).cast<String>().where(cartas.containsKey).toList();
      expansionesActivas = (j['exps'] as List).cast<String>().toSet();
      primigenio = j['primigenio'];
      opciones = ((j['opciones'] ?? []) as List).cast<String>().toSet();
      (j['robo'] as Map).forEach((k, v) => robo[k] = limpia(v));
      (j['descartes'] as Map).forEach((k, v) => descartes[k] = limpia(v));
      ((j['etapaMitos'] ?? {}) as Map).forEach((k, v) => etapaMitos[k] = v as int);
      enJuego.addAll(limpia(j['enJuego'] ?? []));
      ((j['fichas'] ?? {}) as Map).forEach((k, v) => fichas[k] = v as int);
      retiradas.addAll(limpia(j['retiradas'] ?? []));
      final av = j['aventura'] as Map?;
      if (av != null) {
        etapaAventura = av['etapa'] as int;
        aventuraActiva = aventuras.containsKey(av['activa']) ? av['activa'] : null;
        aventurasHechas.addAll((av['hechas'] as List).cast<String>().where(aventuras.containsKey));
      }
      final ant = j['antartida'] as Map?;
      if (ant != null) {
        grupoAventuraPreludio = ant['grupo'] as String? ?? (ant['etapa'] as int > 0 ? 'antartida' : null);
        etapaAntartida = ant['etapa'] as int;
        antartidaActiva = aventuras.containsKey(ant['activa']) ? ant['activa'] : null;
        antartidaHechas.addAll((ant['hechas'] as List).cast<String>().where(aventuras.containsKey));
      }
      final pre = j['preludio'];
      preludio = preludios.containsKey(pre) ? pre : null;
      final mis = j['misterios'] as Map?;
      if (mis == null) {
        _prepararMisterios(); // partida guardada antes de existir los Misterios
      } else {
        bool existe(dynamic id) => misterios.containsKey(id);
        mazoMisterios.addAll((mis['mazo'] as List).cast<String>().where(existe));
        misterioActivo = existe(mis['activo']) ? mis['activo'] : null;
        misteriosResueltos.addAll((mis['resueltos'] as List).cast<String>().where(existe));
        misteriosDescartados.addAll((mis['descartados'] as List).cast<String>().where(existe));
      }
      final mano = j['enMano'] as String?;
      if (mano != null && cartas.containsKey(mano)) {
        robo.putIfAbsent(cartas[mano]!.mazo, () => []).insert(0, mano);
      }
      // Partidas guardadas antes de separar los especiales por mazo
      for (final mapa in [robo, descartes]) {
        final viejo = mapa.remove('especial');
        for (final id in viejo ?? const <String>[]) {
          mapa.putIfAbsent(cartas[id]!.mazo, () => []).add(id);
        }
      }
      for (final k in [...robo.keys, ...descartes.keys]) {
        robo.putIfAbsent(k, () => []);
        descartes.putIfAbsent(k, () => []);
      }
      for (final m in mazos) {
        robo.putIfAbsent(m.id, () => []);
        descartes.putIfAbsent(m.id, () => []);
      }
    } catch (_) {
      primigenio = null;
      robo.clear();
      descartes.clear();
    }
  }
}
