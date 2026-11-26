import 'package:flutter/material.dart';

import '../catalogo.dart';
import '../main.dart';
import '../partida.dart';

/// Muestra una carta robada. Al volver atrás se descarta (como en el APK).
class PantallaCarta extends StatefulWidget {
  const PantallaCarta({super.key, required this.carta, this.desdeDescartes = false});
  final Carta carta;

  /// Si se abre desde la pila de descartes, solo se mira (no se descarta otra vez).
  final bool desdeDescartes;

  @override
  State<PantallaCarta> createState() => _PantallaCartaState();
}

class _PantallaCartaState extends State<PantallaCarta> {
  bool _resuelta = false;

  void _hacer(void Function() accion, String msg, {bool deshacer = false}) {
    _resuelta = true;
    final aviso = ScaffoldMessenger.of(context);
    accion();
    Navigator.pop(context);
    avisoDeshacer(aviso, widget.carta, msg, deshacer: deshacer);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.carta;
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_resuelta && !widget.desdeDescartes) {
          partida.descartar(c);
          avisoDeshacer(ScaffoldMessenger.of(context), c, 'Carta descartada', deshacer: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(c.lugar ??
              (c.mazo == 'mitos' && partida.etapaMitos[c.id] != null
                  ? 'Mitos · Etapa ${nombresEtapa[partida.etapaMitos[c.id]! - 1]}'
                  : nombreMazo(c.mazo))),
          actions: [
            if (!widget.desdeDescartes)
              PopupMenuButton<String>(
                onSelected: (v) => switch (v) {
                  'error' => _hacer(() => partida.devolverArriba(c), 'Carta devuelta arriba del mazo'),
                  'fondo' => _hacer(() => partida.alFondo(c), 'Carta al fondo del mazo'),
                  'barajar' => _hacer(() => partida.devolverYBarajar(c), 'Carta barajada en el mazo'),
                  _ => null,
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'error', child: Text('Robé por error: devolver arriba')),
                  const PopupMenuItem(value: 'fondo', child: Text('Poner al fondo del mazo')),
                  if (c.mazo != 'mitos') const PopupMenuItem(value: 'barajar', child: Text('Devolver y barajar')),
                ],
              )
            else
              PopupMenuButton<String>(
                onSelected: (v) => switch (v) {
                  'arriba' => _hacer(() => partida.recuperarDescarte(c, barajar: false),
                      'Carta devuelta arriba del mazo'),
                  'barajar' => _hacer(() => partida.recuperarDescarte(c), 'Carta barajada en el mazo'),
                  _ => null,
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'arriba', child: Text('Devolver arriba del mazo')),
                  if (c.mazo != 'mitos') const PopupMenuItem(value: 'barajar', child: Text('Devolver y barajar')),
                ],
              ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: InteractiveViewer(
                  maxScale: 4,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Image.asset(c.imagen, fit: BoxFit.contain),
                    ),
                  ),
                ),
              ),
              if (!widget.desdeDescartes)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      if (c.mazo == 'mitos') ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.push_pin_outlined),
                            label: const Text('Dejar en juego'),
                            onPressed: () => _hacer(() => partida.dejarEnJuego(c), 'Carta en juego', deshacer: true),
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check),
                          label: Text(c.mazo == 'mitos' ? 'Descartar' : 'Resuelta: descartar'),
                          onPressed: () => _hacer(() => partida.descartar(c), 'Carta descartada', deshacer: true),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso abajo tras resolver una carta. Con [deshacer], trae el botón «Deshacer»
/// que la regresa arriba de su mazo (por si se robó del mazo equivocado).
void avisoDeshacer(ScaffoldMessengerState aviso, Carta c, String msg, {bool deshacer = false}) {
  aviso
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text('$msg · ${c.lugar ?? nombreMazo(c.mazo)}'),
      duration: Duration(seconds: deshacer ? 6 : 3),
      action: deshacer
          ? SnackBarAction(label: 'DESHACER', onPressed: () => partida.devolverArriba(c))
          : null,
    ));
}
