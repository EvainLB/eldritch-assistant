import 'dart:math';

import 'package:flutter/material.dart';

import '../catalogo.dart';
import '../main.dart';
import '../tema.dart';

const coloresMitos = {
  'verde': Color(0xFF79B062),
  'amarillo': Color(0xFFE0BC52),
  'azul': Color(0xFF6A9BD6),
};

/// Animación al empezar: las cartas de Mitos salen disparadas de los tres montones
/// (verde, amarillo, azul) y forman el mazo, de la Etapa III (fondo) a la I (arriba).
/// Tocar la pantalla la salta.
class PantallaArmadoMitos extends StatefulWidget {
  const PantallaArmadoMitos({super.key});

  @override
  State<PantallaArmadoMitos> createState() => _PantallaArmadoMitosState();
}

class _PantallaArmadoMitosState extends State<PantallaArmadoMitos> with SingleTickerProviderStateMixin {
  static const _intervalo = 0.16; // s entre cartas
  static const _vuelo = 0.55; // s que tarda cada carta
  static const _pausaEtapa = 0.35; // s extra al cambiar de etapa
  static const _final = 1.4; // s mostrando el mazo terminado

  late final List<_Vuelo> _vuelos;
  late final double _duracion;
  late final AnimationController _ctrl;
  bool _cerrando = false;

  @override
  void initState() {
    super.initState();
    final rnd = Random();
    // Del fondo hacia arriba: la Etapa III vuela primero.
    final ids = partida.pila('mitos').reversed.toList();
    var t = 0.3;
    int? etapaPrevia;
    _vuelos = [];
    for (var i = 0; i < ids.length; i++) {
      final c = partida.cartas[ids[i]]!;
      final etapa = partida.etapaMitos[c.id] ?? 1;
      if (etapaPrevia != null && etapa != etapaPrevia) t += _pausaEtapa;
      etapaPrevia = etapa;
      _vuelos.add(_Vuelo(
        color: c.color ?? 'verde',
        etapa: etapa,
        inicio: t,
        giroInicial: (rnd.nextDouble() - 0.5) * 1.6,
        giroFinal: (rnd.nextDouble() - 0.5) * 0.12,
        desvio: Offset((rnd.nextDouble() - 0.5) * 6, 0),
        indice: i,
      ));
      t += _intervalo;
    }
    _duracion = t + _vuelo + _final;
    _ctrl = AnimationController(vsync: this, duration: Duration(milliseconds: (_duracion * 1000).round()))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _cerrar();
      })
      ..forward();
  }

  void _cerrar() {
    if (_cerrando || !mounted) return;
    _cerrando = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reverso = partida.mitos.isNotEmpty ? partida.mitos.first.reverso : null;
    final hoja = partida.hojasPrimigenio[partida.primigenio];

    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _cerrar,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, box) {
              final w = box.maxWidth, h = box.maxHeight;
              final ancho = min(120.0, w * 0.3);
              final alto = ancho * 1046 / 673;
              final centro = Offset(w / 2, h * 0.47);
              final pilas = {
                'verde': Offset(w * 0.2, h * 0.86),
                'amarillo': Offset(w * 0.5, h * 0.86),
                'azul': Offset(w * 0.8, h * 0.86),
              };

              return AnimatedBuilder(
                animation: _ctrl,
                builder: (context, _) {
                  final t = _ctrl.value * _duracion;
                  final volando = _vuelos.lastWhere((v) => v.inicio <= t, orElse: () => _vuelos.first);
                  final listo = _vuelos.isNotEmpty && t > _vuelos.last.inicio + _vuelo;
                  final quedan = {
                    for (final col in pilas.keys) col: _vuelos.where((v) => v.color == col && v.inicio > t).length,
                  };

                  return Stack(
                    children: [
                      // Encabezado: Primigenio y etapa en curso
                      Positioned(
                        top: 24,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            if (hoja != null)
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Paleta.acento, width: 2),
                                  boxShadow: [BoxShadow(color: Paleta.acento.withValues(alpha: 0.35), blurRadius: 24)],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(hoja.retrato, fit: BoxFit.cover),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              'Contra ${nombrePrimigenio(partida.primigenio)}',
                              style: const TextStyle(fontFamily: fuenteTitulo, fontSize: 24),
                            ),
                            const SizedBox(height: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: Text(
                                listo
                                    ? 'Mazo de Mitos listo · ${_vuelos.length} cartas'
                                    : 'Armando la Etapa ${nombresEtapa[volando.etapa - 1]}',
                                key: ValueKey(listo ? 0 : volando.etapa),
                                style: TextStyle(
                                  fontFamily: fuenteTitulo,
                                  fontSize: 14,
                                  letterSpacing: 2,
                                  color: listo ? Paleta.acento : Paleta.oro,
                                  fontVariations: peso(600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Hueco donde se forma el mazo
                      Positioned(
                        left: centro.dx - ancho / 2 - 6,
                        top: centro.dy - alto / 2 - 6,
                        child: Container(
                          width: ancho + 12,
                          height: alto + 12,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Paleta.borde),
                            boxShadow: listo
                                ? [BoxShadow(color: const Color(0xFF8A5CC0).withValues(alpha: 0.45), blurRadius: 40)]
                                : null,
                          ),
                        ),
                      ),
                      // Montones de origen
                      for (final e in pilas.entries)
                        Positioned(
                          left: e.value.dx - ancho * 0.32,
                          top: e.value.dy - alto * 0.32,
                          child: Opacity(
                            opacity: quedan[e.key]! > 0 ? 1 : 0.25,
                            child: _Carta(
                              reverso: reverso,
                              color: coloresMitos[e.key]!,
                              ancho: ancho * 0.64,
                            ),
                          ),
                        ),
                      // Cartas volando / ya apiladas
                      for (final v in _vuelos)
                        if (t >= v.inicio) _cartaEnVuelo(v, t, pilas[v.color]!, centro, ancho, alto, reverso),
                      // Pista para saltar
                      Positioned(
                        bottom: 8,
                        left: 0,
                        right: 0,
                        child: Text(
                          listo ? 'Toca para empezar' : 'Toca para saltar',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Paleta.textoTenue),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cartaEnVuelo(_Vuelo v, double t, Offset desde, Offset hasta, double ancho, double alto, String? reverso) {
    final p = Curves.easeOutCubic.transform(((t - v.inicio) / _vuelo).clamp(0.0, 1.0));
    // Arco: sube un poco antes de caer en el mazo
    final destino = hasta + v.desvio + Offset(0, -v.indice * 0.9);
    final recta = Offset.lerp(desde, destino, p)!;
    final arco = Offset(0, -sin(p * pi) * 70);
    final pos = recta + arco;
    final escala = 0.64 + (1 - 0.64) * p;
    final giro = v.giroInicial + (v.giroFinal - v.giroInicial) * p;

    return Positioned(
      left: pos.dx - ancho / 2,
      top: pos.dy - alto / 2,
      child: Transform.rotate(
        angle: giro,
        child: Transform.scale(
          scale: escala,
          child: _Carta(reverso: reverso, color: coloresMitos[v.color]!, ancho: ancho),
        ),
      ),
    );
  }
}

class _Vuelo {
  final String color;
  final int etapa;
  final double inicio;
  final double giroInicial, giroFinal;
  final Offset desvio;
  final int indice;
  _Vuelo({
    required this.color,
    required this.etapa,
    required this.inicio,
    required this.giroInicial,
    required this.giroFinal,
    required this.desvio,
    required this.indice,
  });
}

class _Carta extends StatelessWidget {
  const _Carta({required this.reverso, required this.color, required this.ancho});
  final String? reverso;
  final Color color;
  final double ancho;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ancho,
      height: ancho * 1046 / 673,
      decoration: BoxDecoration(
        color: const Color(0xFF2A1D3A),
        borderRadius: BorderRadius.circular(ancho * 0.07),
        border: Border.all(color: color, width: 2),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12),
          const BoxShadow(color: Colors.black54, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: reverso == null ? null : Image.asset(reverso!, fit: BoxFit.cover),
    );
  }
}
