import 'dart:math';

import 'package:flutter/material.dart';

import '../catalogo.dart';
import '../main.dart';
import '../tema.dart';
import '../widgets/circulo.dart';
import 'armado_mitos.dart';
import 'preludio.dart';
import '../widgets/comunes.dart';

const _aleatorio = '__aleatorio__';

/// Segunda pantalla de preparación: elegir Primigenio (con retratos) y ver los mazos de Mitos.
class PantallaPrimigenio extends StatefulWidget {
  const PantallaPrimigenio(
      {super.key, required this.expansiones, required this.opciones, this.usarPreludio = false});
  final Set<String> expansiones;
  final Set<String> opciones;
  final bool usarPreludio;

  @override
  State<PantallaPrimigenio> createState() => _PantallaPrimigenioState();
}

class _PantallaPrimigenioState extends State<PantallaPrimigenio> {
  String _elegido = _aleatorio;

  List<Primigenio> get _disponibles => [
        for (final e in expansiones)
          if (widget.expansiones.contains(e.id)) ...e.primigenios
      ];

  void _comenzar() {
    var id = _elegido;
    if (id == _aleatorio) {
      final lista = _disponibles;
      id = lista[Random().nextInt(lista.length)].id;
    }
    final preludio = widget.usarPreludio ? partida.sortearPreludio(widget.expansiones, widget.opciones) : null;
    partida.nuevaPartida(widget.expansiones, id, opciones: widget.opciones, preludio: preludio);
    final nav = Navigator.of(context);
    // Después de armar el mazo se muestra el preludio para que hagan el acomodo.
    void mostrarPreludio() {
      if (preludio != null) verPreludio(nav, alIniciar: true);
    }

    if (partida.pila('mitos').isEmpty) {
      nav.popUntil((r) => r.isFirst);
      mostrarPreludio();
      return;
    }
    // Deja la pantalla de mazos debajo y muestra encima la animación de armado.
    nav.pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, _, _) => const PantallaArmadoMitos(),
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ),
      (r) => r.isFirst,
    ).then((_) => mostrarPreludio());
  }

  @override
  Widget build(BuildContext context) {
    final ancho = MediaQuery.sizeOf(context).width;
    final diametro = ((ancho - 40 - 24) / 2).clamp(110.0, 150.0);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Cabecera(atras: true),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  const Text(
                    'Elige al Primigenio',
                    style: TextStyle(fontFamily: fuenteTitulo, fontSize: 28, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '«No está muerto lo que yace eternamente…»',
                    style: TextStyle(fontSize: 17, fontStyle: FontStyle.italic, color: Paleta.textoTenue),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 22,
                    children: [
                      BotonCircular(
                        nombre: 'Aleatorio',
                        contenido: Image.asset('assets/primigenios/aleatorio.webp', fit: BoxFit.cover),
                        oscurecerNoElegido: false,
                        diametro: diametro,
                        elegido: _elegido == _aleatorio,
                        alPulsar: () => setState(() => _elegido = _aleatorio),
                      ),
                      for (final p in _disponibles)
                        BotonCircular(
                          nombre: p.nombre,
                          contenido: _retrato(partida.hojasPrimigenio[p.id]?.retrato),
                          diametro: diametro,
                          elegido: _elegido == p.id,
                          alPulsar: () => setState(() => _elegido = p.id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 36),
                  const Etiqueta('Mazo de Mitos'),
                  const SizedBox(height: 8),
                  const _MazosMitos(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: BotonPrincipal(texto: 'COMENZAR', alPulsar: _comenzar),
            ),
          ],
        ),
      ),
    );
  }
}


Widget _retrato(String? ruta) => ruta == null
    ? const Icon(Icons.help_outline, color: Paleta.textoTenue)
    : Image.asset(ruta, fit: BoxFit.cover);

/// Tres montones decorativos con el reverso de Mitos: verdes, amarillos y azules.
class _MazosMitos extends StatelessWidget {
  const _MazosMitos();

  static const _colores = {
    'verde': ('Verdes', Color(0xFF79B062)),
    'amarillo': ('Amarillos', Color(0xFFE0BC52)),
    'azul': ('Azules', Color(0xFF6A9BD6)),
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final e in _colores.entries)
          _Monton(
            nombre: e.value.$1,
            color: e.value.$2,
            cartas: partida.mitos.where((m) => m.color == e.key).toList(),
          ),
      ],
    );
  }
}

class _Monton extends StatelessWidget {
  const _Monton({required this.nombre, required this.color, required this.cartas});
  final String nombre;
  final Color color;
  final List cartas;

  @override
  Widget build(BuildContext context) {
    if (cartas.isEmpty) return const SizedBox.shrink();
    const w = 78.0, h = w * 1046 / 673;
    final reverso = cartas.first.reverso as String;

    return Column(
      children: [
        SizedBox(
          width: w + 16,
          height: h + 12,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (final (ang, dx) in const [(-0.10, -6.0), (0.07, 5.0), (0.0, 0.0)])
                Transform.translate(
                  offset: Offset(dx, 0),
                  child: Transform.rotate(
                    angle: ang,
                    child: Container(
                      width: w,
                      height: h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withValues(alpha: 0.85), width: 1.5),
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.18), blurRadius: 14)],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(reverso, fit: BoxFit.cover),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text('$nombre · ${cartas.length}', style: const TextStyle(fontSize: 15, color: Paleta.texto)),
          ],
        ),
      ],
    );
  }
}
