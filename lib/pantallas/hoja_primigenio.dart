import 'dart:math';

import 'package:flutter/material.dart';

import '../catalogo.dart';
import '../main.dart';
import '../tema.dart';
import 'misterios.dart';

/// Barra inferior de la pantalla de mazos: el Primigenio de la partida
/// y un botón para ver su hoja.
class BarraPrimigenio extends StatelessWidget {
  const BarraPrimigenio({super.key});

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: partida, builder: (context, _) => _construir(context));

  Widget _construir(BuildContext context) {
    final hoja = partida.hojasPrimigenio[partida.primigenio];
    if (hoja == null) return const SizedBox.shrink();
    void abrir() => Navigator.push(
          context,
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black87,
            transitionDuration: const Duration(milliseconds: 280),
            pageBuilder: (_, _, _) => const PantallaHojaPrimigenio(),
            transitionsBuilder: (_, a, _, child) => FadeTransition(
              opacity: a,
              child: ScaleTransition(scale: Tween(begin: 0.92, end: 1.0).animate(a), child: child),
            ),
          ),
        );

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: ShapeDecoration(
          color: Paleta.superficie,
          shape: StadiumBorder(side: BorderSide(color: Paleta.oro.withValues(alpha: 0.4))),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: abrir,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Paleta.oro, width: 1.6),
                  boxShadow: [BoxShadow(color: Paleta.oro.withValues(alpha: 0.25), blurRadius: 12)],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(hoja.retrato, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PRIMIGENIO',
                    style: TextStyle(
                      fontFamily: fuenteTitulo,
                      fontSize: 10,
                      letterSpacing: 2,
                      color: Paleta.oro,
                      fontVariations: peso(700),
                    ),
                  ),
                  Text(
                    nombrePrimigenio(partida.primigenio),
                    style: const TextStyle(fontFamily: fuenteTitulo, fontSize: 18),
                  ),
                ],
              ),
            ),
            Material(
              color: Paleta.superficieAlta,
              shape: StadiumBorder(side: BorderSide(color: Paleta.oro.withValues(alpha: 0.6))),
              child: InkWell(
                customBorder: const StadiumBorder(),
                onTap: abrir,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book_outlined, size: 18, color: Paleta.oro),
                      SizedBox(width: 6),
                      Text('Ver hoja', style: TextStyle(fontSize: 15, color: Paleta.texto)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hoja del Primigenio a pantalla completa. La flecha la voltea (anverso/reverso).
class PantallaHojaPrimigenio extends StatefulWidget {
  const PantallaHojaPrimigenio({super.key});

  @override
  State<PantallaHojaPrimigenio> createState() => _PantallaHojaPrimigenioState();
}

class _PantallaHojaPrimigenioState extends State<PantallaHojaPrimigenio> with SingleTickerProviderStateMixin {
  late final _giro = AnimationController(vsync: this, duration: const Duration(milliseconds: 550));
  bool _reverso = false;

  void _voltear() {
    setState(() => _reverso = !_reverso);
    _reverso ? _giro.forward() : _giro.reverse();
  }

  @override
  void dispose() {
    _giro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hoja = partida.hojasPrimigenio[partida.primigenio]!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: GestureDetector(
                // Deslizar de lado también voltea
                onHorizontalDragEnd: (d) {
                  if ((d.primaryVelocity ?? 0).abs() > 200) _voltear();
                },
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _giro,
                      builder: (context, _) {
                        final angulo = Curves.easeInOutCubic.transform(_giro.value) * pi;
                        final atras = angulo > pi / 2;
                        return Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0012)
                            ..rotateY(angulo),
                          child: Transform(
                            alignment: Alignment.center,
                            // Al pasar la mitad se muestra el reverso, sin quedar en espejo
                            transform: atras ? (Matrix4.identity()..rotateY(pi)) : Matrix4.identity(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(atras ? hoja.reversoHoja : hoja.hoja, fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _BotonRedondo(
                    icono: Icons.flip_camera_android,
                    texto: _reverso ? 'Ver anverso' : 'Ver reverso',
                    alPulsar: _voltear,
                  ),
                  ListenableBuilder(
                    listenable: partida,
                    builder: (context, _) => _BotonRedondo(
                      icono: Icons.auto_stories_outlined,
                      texto: 'Misterios ${partida.misteriosResueltos.length}/${partida.misteriosNecesarios}',
                      alPulsar: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PantallaMisterios()),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Botón redondo dorado con su texto debajo (Voltear, Misterios).
class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({required this.icono, required this.texto, required this.alPulsar});
  final IconData icono;
  final String texto;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Paleta.superficieAlta,
          shape: const CircleBorder(side: BorderSide(color: Paleta.oro, width: 1.4)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: alPulsar,
            child: SizedBox.square(dimension: 58, child: Icon(icono, color: Paleta.oro, size: 28)),
          ),
        ),
        const SizedBox(height: 6),
        Text(texto, style: const TextStyle(fontSize: 15, color: Paleta.textoTenue)),
      ],
    );
  }
}
