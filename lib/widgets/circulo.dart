import 'dart:math';

import 'package:flutter/material.dart';

import '../tema.dart';

/// Botón circular con anillo ocultista que gira cuando está elegido.
/// Se usa para Primigenios, expansiones y sus opciones.
class BotonCircular extends StatefulWidget {
  const BotonCircular({
    super.key,
    required this.contenido,
    required this.nombre,
    required this.diametro,
    required this.elegido,
    required this.alPulsar,
    this.subtitulo,
    this.tamanoTexto = 15,
    this.oscurecerNoElegido = true,
    this.insignia,
    this.colorAnillo,
    this.alMantener,
  });

  /// Al dejar presionado (p. ej. ver los descartes del mazo).
  final VoidCallback? alMantener;

  /// Lo que va dentro del círculo (imagen, icono...).
  final Widget contenido;
  final String nombre;
  final double diametro;
  final bool elegido;

  /// null = deshabilitado (se ve apagado).
  final VoidCallback? alPulsar;
  final String? subtitulo;
  final double tamanoTexto;
  final bool oscurecerNoElegido;

  /// Algo pequeño en la esquina inferior derecha (p. ej. el contador de cartas).
  final Widget? insignia;

  /// Color del anillo cuando no está elegido (por defecto, dorado).
  final Color? colorAnillo;

  @override
  State<BotonCircular> createState() => _BotonCircularState();
}

class _BotonCircularState extends State<BotonCircular> with SingleTickerProviderStateMixin {
  late final _giro = AnimationController(vsync: this, duration: const Duration(seconds: 24));

  @override
  void initState() {
    super.initState();
    if (widget.elegido) _giro.repeat();
  }

  @override
  void didUpdateWidget(BotonCircular old) {
    super.didUpdateWidget(old);
    if (widget.elegido && !_giro.isAnimating) _giro.repeat();
    if (!widget.elegido && _giro.isAnimating) _giro.stop();
  }

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.diametro;
    final activo = widget.alPulsar != null;
    final color = widget.elegido
        ? Paleta.acento
        : (widget.colorAnillo ?? Paleta.oro).withValues(alpha: activo ? 0.6 : 0.22);
    final interior = d * 0.78;
    final pequeno = d < 80;

    return GestureDetector(
      onTap: widget.alPulsar,
      onLongPress: widget.alMantener,
      child: Opacity(
        opacity: activo || widget.elegido ? 1 : 0.55,
        child: SizedBox(
          width: max(d, pequeno ? 84 : d),
          child: Column(
            children: [
              AnimatedScale(
                scale: widget.elegido ? 1.04 : 1,
                duration: const Duration(milliseconds: 200),
                child: SizedBox.square(
                  dimension: d,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: interior,
                        height: interior,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.elegido
                                  ? Paleta.acento.withValues(alpha: 0.45)
                                  : Colors.black.withValues(alpha: 0),
                              blurRadius: pequeno ? 14 : 28,
                              spreadRadius: pequeno ? 1 : 2,
                            ),
                          ],
                        ),
                      ),
                      RotationTransition(
                        turns: _giro,
                        child: CustomPaint(
                          size: Size.square(d),
                          painter: AnilloOcultista(color, marcas: pequeno ? 24 : 48),
                        ),
                      ),
                      Container(
                        width: interior,
                        height: interior,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Paleta.superficieAlta,
                          border: Border.all(color: color, width: pequeno ? 1.4 : 2),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(
                              alpha: widget.elegido || !widget.oscurecerNoElegido ? 0 : 0.35,
                            ),
                            BlendMode.darken,
                          ),
                          child: widget.contenido,
                        ),
                      ),
                      if (widget.insignia != null) Positioned(right: 0, bottom: 0, child: widget.insignia!),
                    ],
                  ),
                ),
              ),
              SizedBox(height: pequeno ? 6 : 10),
              Text(
                widget.nombre,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: fuenteTitulo,
                  fontSize: widget.tamanoTexto,
                  height: 1.2,
                  letterSpacing: 0.6,
                  color: widget.elegido ? Paleta.acento : Paleta.texto,
                  fontVariations: peso(widget.elegido ? 700 : 500),
                ),
              ),
              if (widget.subtitulo != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    widget.subtitulo!,
                    style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Paleta.textoTenue),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Doble círculo con marcas y pequeños rombos, al estilo de un sello arcano.
class AnilloOcultista extends CustomPainter {
  AnilloOcultista(this.color, {this.marcas = 48});
  final Color color;
  final int marcas;

  @override
  void paint(Canvas canvas, Size s) {
    final c = s.center(Offset.zero);
    final r = s.width / 2 - 2;
    final escala = s.width / 150;
    final fino = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, r, fino);
    canvas.drawCircle(c, r - 7 * escala, fino..color = color.withValues(alpha: 0.6));

    final marca = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..strokeWidth = 1.2;
    for (var i = 0; i < marcas; i++) {
      final a = i * 2 * pi / marcas;
      final largo = (i % 4 == 0 ? 7.0 : 3.5) * escala;
      canvas.drawLine(c + Offset.fromDirection(a, r), c + Offset.fromDirection(a, r - largo), marca);
    }
    final rombo = Paint()..color = color;
    for (var i = 0; i < 5; i++) {
      final a = -pi / 2 + i * 2 * pi / 5;
      final p = c + Offset.fromDirection(a, r - 3.5 * escala);
      final t = max(2.5, 4.0 * escala);
      canvas.drawPath(
        Path()
          ..moveTo(p.dx + cos(a) * t, p.dy + sin(a) * t)
          ..lineTo(p.dx + cos(a + pi / 2) * t * 0.6, p.dy + sin(a + pi / 2) * t * 0.6)
          ..lineTo(p.dx - cos(a) * t, p.dy - sin(a) * t)
          ..lineTo(p.dx - cos(a + pi / 2) * t * 0.6, p.dy - sin(a + pi / 2) * t * 0.6)
          ..close(),
        rombo,
      );
    }
  }

  @override
  bool shouldRepaint(AnilloOcultista old) => old.color != color || old.marcas != marcas;
}
