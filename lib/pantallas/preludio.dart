import 'package:flutter/material.dart';

import '../main.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

/// Muestra la carta de Preludio en grande. [alIniciar]: recién sorteado, con aviso de resolverlo en la preparación.
Future<void> verPreludio(NavigatorState nav, {bool alIniciar = false}) {
  final img = partida.preludios[partida.preludio];
  if (img == null) return Future.value();
  return nav.push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (_, _, _) => _PantallaPreludio(imagen: img, alIniciar: alIniciar),
      transitionsBuilder: (_, a, _, child) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(a), child: child),
      ),
    ),
  );
}

class _PantallaPreludio extends StatelessWidget {
  const _PantallaPreludio({required this.imagen, required this.alIniciar});
  final String imagen;
  final bool alIniciar;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PRELUDIO',
                          style: TextStyle(
                            fontFamily: fuenteTitulo,
                            fontSize: 12,
                            letterSpacing: 3,
                            color: Paleta.oro,
                            fontVariations: peso(700),
                          ),
                        ),
                        Text(
                          alIniciar ? 'Resuélvelo al preparar la partida' : 'Preludio de esta partida',
                          style: const TextStyle(fontSize: 17, color: Paleta.texto),
                        ),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close, size: 28), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),
            Expanded(
              child: InteractiveViewer(
                maxScale: 4,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Paleta.oro.withValues(alpha: 0.35), blurRadius: 30)],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(imagen, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
            ),
            if (alIniciar)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: BotonPrincipal(texto: 'LISTO', alPulsar: () => Navigator.pop(context)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Fila para la pantalla de mazos: el preludio en miniatura, para releerlo cuando quieran.
class FilaPreludio extends StatelessWidget {
  const FilaPreludio({super.key});

  @override
  Widget build(BuildContext context) {
    final img = partida.preludios[partida.preludio];
    if (img == null) return const SizedBox.shrink();
    return Material(
      color: Paleta.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Paleta.oro.withValues(alpha: 0.4)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => verPreludio(Navigator.of(context)),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(img, width: 52, height: 80, fit: BoxFit.cover, alignment: Alignment.topCenter),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text('Toca para leer el preludio', style: TextStyle(fontSize: 16, color: Paleta.texto)),
              ),
              const Icon(Icons.chevron_right, color: Paleta.oro),
            ],
          ),
        ),
      ),
    );
  }
}
