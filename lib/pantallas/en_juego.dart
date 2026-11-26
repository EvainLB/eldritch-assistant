import 'package:flutter/material.dart';

import '../main.dart';
import '../partida.dart';
import '../tema.dart';

const imagenFicha = 'assets/fichas/eldritch.webp';

/// Fila horizontal de cartas que siguen en el tablero (rumores, Mitos activos).
class FilaEnJuego extends StatelessWidget {
  const FilaEnJuego({super.key});

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: partida, builder: (context, _) => _construir(context));

  Widget _construir(BuildContext context) {
    final ids = partida.enJuego;
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        itemCount: ids.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = partida.cartas[ids[i]]!;
          final n = partida.fichas[c.id] ?? 0;
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PantallaEnJuego(carta: c)),
            ),
            child: SizedBox(
              width: 92,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 88,
                    height: 137,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF6B4E8C), width: 1.4),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF8A5CC0).withValues(alpha: 0.25), blurRadius: 12),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(c.imagen, fit: BoxFit.cover, alignment: Alignment.topCenter),
                  ),
                  if (n > 0)
                    Positioned(
                      right: -2,
                      bottom: -4,
                      child: _InsigniaFichas(cantidad: n),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InsigniaFichas extends StatelessWidget {
  const _InsigniaFichas({required this.cantidad});
  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 36,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black, blurRadius: 6)],
            ),
            child: Image.asset(imagenFicha),
          ),
          Text(
            '$cantidad',
            style: TextStyle(
              fontFamily: fuenteTitulo,
              fontSize: 17,
              color: Colors.white,
              fontVariations: peso(800),
              shadows: const [Shadow(color: Colors.black, blurRadius: 4), Shadow(color: Colors.black, blurRadius: 8)],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carta en juego: se ve grande y se ponen o quitan fichas Eldritch.
class PantallaEnJuego extends StatelessWidget {
  const PantallaEnJuego({super.key, required this.carta});
  final Carta carta;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: partida,
      builder: (context, _) {
        final n = partida.fichas[carta.id] ?? 0;
        return Scaffold(
          appBar: AppBar(title: const Text('En juego')),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: InteractiveViewer(
                    maxScale: 4,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Image.asset(carta.imagen, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Paleta.superficie,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Paleta.borde),
                  ),
                  child: Row(
                    children: [
                      _BotonRedondo(
                        icono: Icons.remove,
                        alPulsar: n > 0 ? () => partida.cambiarFichas(carta, -1) : null,
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(imagenFicha, width: 52, height: 52),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$n',
                                  style: TextStyle(
                                    fontFamily: fuenteTitulo,
                                    fontSize: 30,
                                    height: 1,
                                    fontVariations: peso(700),
                                  ),
                                ),
                                Text(
                                  n == 1 ? 'ficha Eldritch' : 'fichas Eldritch',
                                  style: const TextStyle(fontSize: 14, color: Paleta.textoTenue),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _BotonRedondo(icono: Icons.add, alPulsar: () => partida.cambiarFichas(carta, 1)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Resuelta: descartar'),
                      onPressed: () {
                        partida.resolverEnJuego(carta);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(content: Text('Carta resuelta y descartada')));
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BotonRedondo extends StatelessWidget {
  const _BotonRedondo({required this.icono, required this.alPulsar});
  final IconData icono;
  final VoidCallback? alPulsar;

  @override
  Widget build(BuildContext context) {
    final activo = alPulsar != null;
    return Material(
      color: activo ? const Color(0xFF2A1D3A) : Paleta.superficieAlta,
      shape: CircleBorder(
        side: BorderSide(color: activo ? const Color(0xFF8A5CC0) : Paleta.borde, width: 1.4),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: alPulsar,
        child: SizedBox.square(
          dimension: 52,
          child: Icon(icono, size: 26, color: activo ? Paleta.texto : Paleta.textoTenue),
        ),
      ),
    );
  }
}
