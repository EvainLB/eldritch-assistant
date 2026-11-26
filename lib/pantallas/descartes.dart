import 'package:flutter/material.dart';

import '../catalogo.dart';
import '../main.dart';
import 'carta.dart';

/// Galería de la pila de descartes, por mazo (equivale a "Gallery" del APK).
class PantallaDescartes extends StatelessWidget {
  const PantallaDescartes({super.key, this.mazoInicial});

  /// Pestaña con la que se abre (al dejar presionado un mazo).
  final String? mazoInicial;

  @override
  Widget build(BuildContext context) {
    final visibles = partida.mazosPartida.where((m) => partida.total(m) > 0).toList();
    return DefaultTabController(
      length: visibles.length,
      initialIndex: mazoInicial == null ? 0 : visibles.indexOf(mazoInicial!).clamp(0, visibles.length - 1),
      child: ListenableBuilder(
        listenable: partida,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            title: const Text('Pila de descartes'),
            bottom: TabBar(
              isScrollable: true,
              tabs: [
                for (final m in visibles) Tab(text: '${nombreMazo(m)} (${partida.descarte(m).length})'),
              ],
            ),
          ),
          body: TabBarView(
            children: [for (final m in visibles) _Rejilla(mazo: m)],
          ),
        ),
      ),
    );
  }
}

class _Rejilla extends StatelessWidget {
  const _Rejilla({required this.mazo});
  final String mazo;

  @override
  Widget build(BuildContext context) {
    final ids = partida.descarte(mazo).reversed.toList(); // la última descartada primero
    if (ids.isEmpty) {
      return const Center(child: Text('No hay cartas descartadas.'));
    }
    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 160,
              childAspectRatio: 673 / 1046,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: ids.length,
            itemBuilder: (context, i) {
              final c = partida.cartas[ids[i]]!;
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PantallaCarta(carta: c, desdeDescartes: true)),
                ),
                child: Image.asset(c.imagen, fit: BoxFit.cover),
              );
            },
          ),
        ),
        if (mazo != 'mitos')
        Padding(
          padding: const EdgeInsets.all(12),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.shuffle),
            label: const Text('Barajar los descartes en el mazo'),
            onPressed: () => partida.barajarDescartes(mazo),
          ),
        ),
      ],
    );
  }
}
