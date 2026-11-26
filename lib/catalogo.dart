/// Catálogo fijo: expansiones, Primigenios y mazos de encuentros.
/// Para activar una expansión: generar su `assets/data/cartas_<id>.json`
/// con tools/, poner `disponible: true` aquí y añadir sus carpetas en pubspec.yaml.
library;

/// Cuántas cartas de Mitos de cada color lleva una etapa.
class EtapaMitos {
  final int verdes, amarillas, azules;
  const EtapaMitos(this.verdes, this.amarillas, this.azules);
  int get total => verdes + amarillas + azules;
}

class Primigenio {
  final String id;
  final String nombre;

  /// Etapas I, II y III del Mazo de Mitos (de la hoja del Primigenio).
  final List<EtapaMitos> mitos;

  /// Misterios que hay que resolver (segundo punto de su hoja).
  final int misteriosNecesarios;

  /// true si al resolverlos no se gana, sino que se voltea la hoja (Sicigia: «¡El portal se abre!»).
  final bool volteaAlResolver;

  /// true si tras los Misterios hay que completar una Aventura por etapas (Los Mi-go: «Agujero en el Mundo»).
  final bool aventuraFinal;
  const Primigenio(this.id, this.nombre,
      [this.mitos = const [],
      this.misteriosNecesarios = 3,
      this.volteaAlResolver = false,
      this.aventuraFinal = false]);
}

/// Opción dentro de una expansión (tablero lateral, preludio...).
class Opcion {
  final String id;
  final String nombre;
  const Opcion(this.id, this.nombre);
}

class Expansion {
  final String id;
  final String nombre;
  final List<Primigenio> primigenios;
  final List<Opcion> opciones;

  /// false mientras no se hayan extraído sus cartas.
  final bool disponible;

  /// Expansión hecha por fans (no oficial).
  final bool fan;
  const Expansion(this.id, this.nombre, this.primigenios,
      {this.opciones = const [], this.disponible = false, this.fan = false});
}

class MazoDef {
  final String id;
  final String nombre;

  /// Si es true, el mazo solo usa cartas del Primigenio elegido.
  final bool porPrimigenio;
  const MazoDef(this.id, this.nombre, {this.porPrimigenio = false});
}

const expansiones = <Expansion>[
  Expansion(
    'base',
    'Juego base',
    [
      Primigenio('azathoth', 'Azathoth', [EtapaMitos(1, 2, 1), EtapaMitos(2, 3, 1), EtapaMitos(2, 4, 0)]),
      Primigenio('yog_sothoth', 'Yog-Sothoth', [EtapaMitos(0, 2, 1), EtapaMitos(2, 3, 1), EtapaMitos(3, 4, 0)]),
      Primigenio('shub_niggurath', 'Shub-Niggurath',
          [EtapaMitos(1, 2, 1), EtapaMitos(3, 2, 1), EtapaMitos(2, 4, 0)]),
      Primigenio('cthulhu', 'Cthulhu', [EtapaMitos(0, 2, 2), EtapaMitos(1, 3, 0), EtapaMitos(3, 4, 0)]),
    ],
    disponible: true,
  ),
  Expansion(
    'saber_olvidado',
    'Saber olvidado',
    [Primigenio('yig', 'Yig', [EtapaMitos(1, 2, 1), EtapaMitos(2, 3, 1), EtapaMitos(2, 4, 0)])],
    disponible: true,
  ),
  Expansion(
    'montanas_locura',
    'Las montañas de la locura',
    [
      Primigenio('antiguos', 'El resurgir de los Antiguos',
          [EtapaMitos(2, 2, 1), EtapaMitos(3, 3, 1), EtapaMitos(4, 4, 0)], 4),
      Primigenio('ithaqua', 'Ithaqua', [EtapaMitos(0, 2, 2), EtapaMitos(4, 2, 0), EtapaMitos(2, 4, 0)], 3),
    ],
    // Preludio «Augurio de perdición desde la Antártida»: tablero de la Antártida y sus mazos
    opciones: [Opcion('antartida', 'Antártida')],
    disponible: true,
  ),
  Expansion(
    'vestigios_extranos',
    'Vestigios extraños',
    [Primigenio('syzygy', 'Sicigia', [EtapaMitos(0, 2, 2), EtapaMitos(3, 3, 0), EtapaMitos(3, 5, 0)], 2, true)],
    opciones: [Opcion('alineacion_cosmica', 'Alineación cósmica (preludio)')],
    disponible: true,
  ),
  Expansion(
    'bajo_piramides',
    'Bajo las pirámides',
    [Primigenio('abhoth', 'Abhoth'), Primigenio('nephren_ka', 'Nefren-Ka')],
    opciones: [Opcion('egipto', 'Egipto')],
  ),
  Expansion(
    'senales_carcosa',
    'Señales de Carcosa',
    [Primigenio('hastur', 'Hastur', [EtapaMitos(0, 2, 2), EtapaMitos(2, 3, 0), EtapaMitos(3, 5, 0)], 2)],
    disponible: true,
  ),
  Expansion(
    'tierras_sueno',
    'Las Tierras del Sueño',
    [
      Primigenio('atlach_nacha', 'Atlach-Nacha', [EtapaMitos(1, 2, 1), EtapaMitos(3, 2, 1), EtapaMitos(2, 4, 0)], 3),
      Primigenio('hypnos', 'Hypnos', [EtapaMitos(0, 2, 1), EtapaMitos(2, 3, 1), EtapaMitos(3, 4, 0)], 3),
    ],
    // Preludio «Sueños de otros mundos»: tablero de las Tierras del Sueño y sus mazos
    opciones: [Opcion('tierras_sueno_tablero', 'Tablero de las Tierras del Sueño')],
    disponible: true,
  ),
  Expansion(
    'ciudades_ruinas',
    'Ciudades en ruinas',
    [Primigenio('shudde_mell', "Shudde M'ell", [EtapaMitos(0, 2, 2), EtapaMitos(4, 2, 0), EtapaMitos(2, 4, 0)])],
    disponible: true,
  ),
  Expansion(
    'mascaras_nyarlathotep',
    'Las máscaras de Nyarlathotep',
    [Primigenio('nyarlathotep', 'Nyarlathotep'), Primigenio('antediluvium', 'Antediluvium')],
  ),
  // Fan (Michael Hunter): solo se usa al jugar contra los Mi-go
  Expansion(
    'hijos_yuggoth',
    'Los hijos de Yuggoth',
    [
      Primigenio('mi_go', 'Los Mi-go', [EtapaMitos(2, 2, 1), EtapaMitos(3, 3, 0), EtapaMitos(2, 4, 0)], 2, false, true),
    ],
    disponible: true,
    fan: true,
  ),
];

const mazos = <MazoDef>[
  MazoDef('americas', 'Américas'),
  MazoDef('europa', 'Europa'),
  MazoDef('asia', 'Asia y Australia'),
  MazoDef('general', 'Generales'),
  // Ciudades en ruinas: casillas devastadas
  MazoDef('devastacion', 'Devastación'),
  MazoDef('otros_mundos', 'Otros Mundos'),
  MazoDef('expedicion', 'Expedición'),
  // Solo con el preludio Alineación cósmica o contra Sicigia
  MazoDef('ruinas', 'Ruinas místicas'),
  // Tablero de la Antártida: con su preludio o contra El resurgir de los Antiguos
  MazoDef('puesto_avanzado', 'Puesto avanzado'),
  MazoDef('montanas', 'Montañas'),
  MazoDef('inv_antartida', 'Investigación Antártida'),
  // Tablero de las Tierras del Sueño: con su preludio o contra Hypnos
  MazoDef('sueno', 'Tierras del Sueño'),
  MazoDef('bosque', 'El Bosque Encantado'),
  MazoDef('kadath', 'La desconocida Kadath'),
  MazoDef('luna', 'La Luna'),
  MazoDef('subterraneo', 'El Mundo Subterráneo'),
  MazoDef('investigacion', 'Investigación', porPrimigenio: true),
  // Ciudades en ruinas: el investigador jefe roba y resuelve; luego se descarta
  MazoDef('desastres', 'Desastres'),
  MazoDef('mitos', 'Mitos'),
];

MazoDef mazoPorId(String id) => mazos.firstWhere((m) => m.id == id);

Primigenio? primigenioPorId(String? id) {
  for (final e in expansiones) {
    for (final p in e.primigenios) {
      if (p.id == id) return p;
    }
  }
  return null;
}

/// Mazos de Encuentro Especial (id de pila `esp_<clave>` -> nombre impreso en la carta).
const nombresEspeciales = {
  'resurgir_rlyeh': "El resurgir de R'lyeh",
  'llave_puerta': 'La llave y la puerta',
  'vacio_mundos': 'El vacío entre los mundos',
  'knyan': "K'n-Yan desenterrado",
  'barrera': 'Fortalecer la barrera',
  'sellar_portal': 'Sellar el portal',
  'ciudades_lago': 'Las ciudades del lago',
  'innombrable': 'El Innombrable',
  'rey_amarillo': 'El Rey Amarillo',
  'gharne': "Explorando G'harne",
  'susurra': 'El que susurra en la Oscuridad',
  'desapariciones': 'Desapariciones misteriosas',
  'dios_oscuro': 'Un Dios Oscuro',
  'hiperborea': 'Explorando Hiperbórea',
  'corona': 'Corona Borealis',
  'oniro': 'Onironauta',
  'sueno_en_sueno': 'Sueño dentro de un sueño',
};

/// Nombre a mostrar de un mazo (los especiales usan el nombre de su carta).
String nombreMazo(String mazoId) {
  if (mazoId.startsWith('esp_')) return nombresEspeciales[mazoId.substring(4)] ?? 'Especiales';
  return mazoPorId(mazoId).nombre;
}

const nombresEtapa = ['I', 'II', 'III'];

String nombrePrimigenio(String? id) {
  for (final e in expansiones) {
    for (final p in e.primigenios) {
      if (p.id == id) return p.nombre;
    }
  }
  return id ?? '';
}
