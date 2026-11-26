# Eldritch Assistant

Aplicación para el juego de mesa **Eldritch Horror** en español, pensada para **jugar sin manejar los mazos de
cartas físicas, conservando la caja y las expansiones** en la mesa.

## El propósito

En Eldritch Horror buena parte del tiempo se va en separar, barajar y acomodar mazos de encuentros, armar el
Mazo de Mitos por etapas y recordar qué expansión aporta qué. Con varias expansiones, además, la mesa se llena.

La app se encarga de eso: eliges las expansiones que tienes y el Primigenio, ella arma y baraja los mazos, y el
grupo se concentra en la historia. El tablero, las fichas, los investigadores y sus pertenencias siguen siendo
los de tu caja: la app **acompaña** al juego físico, no lo reemplaza.

App compañera no oficial, hecha por un fan. Hecha con **Flutter** para Android (también compila para web).

## Cómo se hizo

Yo no sé programar en Flutter. Este proyecto lo construí **dirigiendo a Claude (Anthropic) como asistente de programación**:
yo definí qué debía hacer la app, cómo debía verse y cómo funcionan las reglas del juego, preparé mis escaneos,
probé cada versión y pedí las correcciones. El código se escribió trabajando juntos, paso a paso.

## Qué hace

- Prepara la partida: expansiones, Primigenio (o aleatorio) y preludio opcional.
- Arma el **Mazo de Mitos** por etapas según la hoja del Primigenio, con su animación.
- Mazos de encuentros por región, Otros Mundos, Expedición, Investigación y especiales de cada Primigenio.
- Tableros secundarios (Antártida, Tierras del Sueño) y mazos propios de algunas expansiones
  (Ruinas místicas, Desastres, Devastación).
- Misterios, Aventuras por etapas y rumores en juego con fichas Eldritch.
- Hoja del Primigenio a pantalla completa, con volteo.
- Descartes, deshacer un robo por error y resumen al terminar la partida.
- La partida se guarda sola y la pantalla no se apaga mientras juegas.

Contempla el juego base, siete expansiones y una expansión hecha por fans (*Los hijos de Yuggoth*).

## Las cartas no están incluidas

Las cartas, hojas, cajas y fichas pertenecen a **Fantasy Flight Games / Edge** y a sus traductores y autores,
así que **no se publican en este repositorio**. Por eso, tal como se descarga, la app **no compila**:
le faltan las imágenes que declara `pubspec.yaml`.

Quien tenga el juego puede generarlas a partir de sus propios escaneos con los scripts de `tools/`
(Python con Pillow y PyMuPDF). Cada script explica al principio qué espera recibir; están ajustados
a la forma en que venían mis archivos, así que probablemente haya que adaptarlos.

## Estructura

| Carpeta | Contenido |
|---|---|
| `lib/` | La app: catálogo de expansiones, estado de la partida y pantallas |
| `assets/data/` | Índice de cartas (identificadores, mazo y rutas) |
| `tools/` | Scripts que recortan y organizan las cartas escaneadas |
| `test/` | Pruebas de armado de mazos (requieren las imágenes generadas) |

```
flutter pub get
flutter test
flutter build apk --release
```

## Aviso

Proyecto personal sin fines de lucro. No está afiliado ni respaldado por Fantasy Flight Games, Edge ni Asmodee.
*Eldritch Horror* y sus componentes son propiedad de sus respectivos dueños.

Las tipografías Cinzel y EB Garamond se distribuyen bajo la licencia OFL (ver `assets/fonts/`).
