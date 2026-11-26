import 'dart:math';

import 'package:flutter/material.dart';

import '../tema.dart';

/// Pantalla de inicio mientras carga la app: el logo aparece entre niebla que se mueve.
class PantallaCarga extends StatefulWidget {
  const PantallaCarga({super.key});

  @override
  State<PantallaCarga> createState() => _PantallaCargaState();
}

class _PantallaCargaState extends State<PantallaCarga> with TickerProviderStateMixin {
  // Movimiento continuo de la niebla
  late final _niebla = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  // Entrada del logo y del título
  late final _entrada = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..forward();

  @override
  void dispose() {
    _niebla.dispose();
    _entrada.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: Listenable.merge([_niebla, _entrada]),
        builder: (context, _) {
          final t = _niebla.value * 2 * pi;
          final logoP = Curves.easeOutCubic.transform((_entrada.value / 0.75).clamp(0.0, 1.0));
          final tituloP = Curves.easeOut.transform(((_entrada.value - 0.45) / 0.55).clamp(0.0, 1.0));
          final pulso = 0.5 + 0.5 * sin(t * 2);

          return Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _Niebla(t)),
              // Viñeta para oscurecer los bordes
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 0.9,
                    colors: [Color(0x22000000), Color(0xF2000000)],
                    stops: [0.3, 1],
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Opacity(
                      opacity: logoP,
                      child: Transform.scale(
                        scale: 0.86 + 0.14 * logoP,
                        child: Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6E4AA8).withValues(alpha: 0.35 + 0.25 * pulso),
                                blurRadius: 50 + 20 * pulso,
                                spreadRadius: 4,
                              ),
                              BoxShadow(
                                color: Paleta.acento.withValues(alpha: 0.15 + 0.1 * pulso),
                                blurRadius: 90,
                              ),
                            ],
                          ),
                          child: Image.asset('assets/logo.webp'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    Opacity(
                      opacity: tituloP,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - tituloP)),
                        child: Column(
                          children: [
                            Text(
                              'ELDRITCH',
                              style: TextStyle(
                                fontFamily: fuenteTitulo,
                                fontSize: 30,
                                letterSpacing: 8 + 4 * (1 - tituloP),
                                color: Paleta.texto,
                                fontVariations: peso(700),
                                shadows: const [Shadow(color: Colors.black, blurRadius: 12)],
                              ),
                            ),
                            Text(
                              'ASSISTANT',
                              style: TextStyle(
                                fontFamily: fuenteTitulo,
                                fontSize: 16,
                                letterSpacing: 9,
                                color: Paleta.oro,
                                fontVariations: peso(600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Línea de carga tenue
              Positioned(
                left: 0,
                right: 0,
                bottom: 60,
                child: Opacity(
                  opacity: tituloP * 0.8,
                  child: const Center(
                    child: SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        minHeight: 2,
                        backgroundColor: Color(0x22FFFFFF),
                        color: Paleta.acento,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bancos de niebla: manchas grandes y difusas que se desplazan despacio.
class _Niebla extends CustomPainter {
  _Niebla(this.t);
  final double t;

  static const _manchas = [
    // (x, y, radio, color, velocidad, fase): jirones pequeños y oscuros que se cruzan
    (0.20, 0.28, 0.32, Color(0xFF4B2A78), 1.0, 0.0),
    (0.82, 0.22, 0.30, Color(0xFF1F5A50), 0.8, 1.7),
    (0.55, 0.78, 0.38, Color(0xFF3A1F5C), 0.6, 3.1),
    (0.12, 0.70, 0.28, Color(0xFF1A4A44), 1.2, 4.4),
    (0.88, 0.62, 0.32, Color(0xFF52306E), 0.9, 2.2),
    (0.45, 0.40, 0.26, Color(0xFF2B3F55), 1.4, 5.3),
    (0.70, 0.45, 0.22, Color(0xFF3D2266), 1.1, 0.9),
    (0.30, 0.55, 0.24, Color(0xFF173F3A), 0.7, 2.8),
    (0.60, 0.12, 0.25, Color(0xFF2E1A4A), 1.3, 4.0),
    (0.38, 0.92, 0.27, Color(0xFF22324A), 0.9, 1.2),
  ];

  @override
  void paint(Canvas canvas, Size s) {
    final lado = max(s.width, s.height);
    for (final (x, y, r, color, v, fase) in _manchas) {
      final c = Offset(
        s.width * (x + 0.14 * sin(t * v + fase)),
        s.height * (y + 0.07 * cos(t * v * 0.8 + fase)),
      );
      final radio = lado * r * (0.9 + 0.1 * sin(t * v * 1.3 + fase));
      final p = Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: 0.42), color.withValues(alpha: 0.12), color.withValues(alpha: 0)],
          stops: const [0, 0.55, 1],
        ).createShader(Rect.fromCircle(center: c, radius: radio))
        ..blendMode = BlendMode.plus;
      canvas.drawCircle(c, radio, p);
    }
  }

  @override
  bool shouldRepaint(_Niebla old) => old.t != t;
}
