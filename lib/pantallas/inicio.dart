import 'package:flutter/material.dart';

import '../catalogo.dart';
import '../main.dart';
import '../tema.dart';
import '../widgets/circulo.dart';
import '../widgets/comunes.dart';
import 'carta.dart';
import 'descartes.dart';
import 'en_juego.dart';
import 'hoja_primigenio.dart';
import 'preludio.dart';
import 'preparacion.dart';
import 'terminar.dart';

/// Pantalla principal: un botón por mazo (equivale a la pantalla principal del APK).
class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: partida,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: Text('Contra ${nombrePrimigenio(partida.primigenio)}'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (v) => _menu(context, v),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'descartes', child: Text('Pila de descartes')),
                PopupMenuItem(value: 'expedicion', child: Text('Quitar expedición')),
                PopupMenuItem(value: 'terminar', child: Text('Terminar partida')),
                PopupMenuItem(value: 'nueva', child: Text('Nueva partida')),
              ],
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, box) {
            final d = ((box.maxWidth - 32 - 2 * 14) / 3).clamp(84.0, 124.0);
            final normales = [
              for (final m in partida.mazosPartida)
                if (m != 'mitos' && (partida.total(m) > 0 || (m == 'expedicion' && partida.retiradas.isNotEmpty)))
                  m,
            ];
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 14,
                  runSpacing: 18,
                  children: [for (final m in normales) _BotonMazo(mazo: m, diametro: d)],
                ),
                if (partida.total('mitos') > 0) ...[
                  const SizedBox(height: 26),
                  Center(child: _BotonMazo(mazo: 'mitos', diametro: d * 1.2)),
                ],
                if (partida.enJuego.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Etiqueta('Rumores activos'),
                  const FilaEnJuego(),
                ],
                if (partida.preludio != null) ...[
                  const SizedBox(height: 22),
                  const Etiqueta('Preludio'),
                  const FilaPreludio(),
                ],
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'Deja presionado un mazo para ver sus descartes',
                    style: TextStyle(fontSize: 13, color: Paleta.textoTenue),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: const BarraPrimigenio(),
      ),
    );
  }

  void _menu(BuildContext context, String v) {
    switch (v) {
      case 'descartes':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaDescartes()));
      case 'expedicion':
        _quitarExpedicion(context);
      case 'terminar':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PantallaTerminar()));
      case 'nueva':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('¿Empezar una nueva partida?'),
            content: const Text('Se perderá el estado de los mazos actuales.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PantallaPreparacion(desdePartida: true)),
                  );
                },
                child: const Text('Sí'),
              ),
            ],
          ),
        );
    }
  }

  void _quitarExpedicion(BuildContext context) {
    final actual = partida.expedicionActual;
    if (actual == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitar expedición'),
        content: Text('La expedición activa es «$actual». '
            'Sus cartas pasarán al fondo del mazo y la ficha irá al siguiente lugar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              partida.quitarExpedicion(actual);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Nueva expedición: ${partida.expedicionActual}')),
              );
            },
            child: const Text('Quitar'),
          ),
        ],
      ),
    );
  }
}

void _mitosAgotado(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Se acabó el Mazo de Mitos'),
      content: const Text(
          'Si hay que robar una carta de Mitos y el mazo está vacío, los investigadores pierden la partida.'),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Entendido'))],
    ),
  );
}

const _morado = Color(0xFF8A5CC0);
const _rojo = Color(0xFFC0473A);

String? _reversoDe(String mazo) {
  for (final c in partida.cartas.values) {
    if (c.mazo == mazo) return c.reverso;
  }
  return null;
}

class _BotonMazo extends StatelessWidget {
  const _BotonMazo({required this.mazo, required this.diametro});
  final String mazo;
  final double diametro;

  @override
  Widget build(BuildContext context) {
    final quedan = partida.pila(mazo).length;
    final total = partida.total(mazo);
    final esMitos = mazo == 'mitos';
    final etapa = partida.etapaMitosActual;
    final subtitulo = switch (mazo) {
      'expedicion' || 'ruinas' when partida.lugarActual(mazo) != null => partida.lugarActual(mazo),
      'mitos' when etapa != null => 'Etapa ${nombresEtapa[etapa - 1]} · quedan ${partida.quedanEnEtapa}',
      'mitos' => 'Mazo agotado',
      _ => null,
    };
    final reverso = _reversoDe(mazo);

    final circulo = BotonCircular(
        nombre: nombreMazo(mazo),
        subtitulo: subtitulo,
        diametro: diametro,
        elegido: false,
        oscurecerNoElegido: false,
        tamanoTexto: esMitos ? 16 : 13,
        colorAnillo: esMitos ? _morado : (mazo == 'desastres' ? _rojo : null),
        contenido: reverso == null ? const SizedBox() : Image.asset(reverso, fit: BoxFit.cover),
        insignia: _Contador(quedan: quedan, total: total, color: esMitos ? _morado : Paleta.oro),
        alPulsar: () {
          final c = partida.robar(mazo);
          if (c == null) {
            if (esMitos) _mitosAgotado(context);
            return;
          }
          Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaCarta(carta: c)));
        },
        alMantener: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PantallaDescartes(mazoInicial: mazo)),
        ),
    );

    return SizedBox(
      width: diametro,
      child: mazo == 'ruinas'
          ? Column(
              children: [
                circulo,
                const SizedBox(height: 8),
                BotonCircular(
                  nombre: 'Barajar',
                  diametro: 46,
                  tamanoTexto: 11,
                  elegido: false,
                  oscurecerNoElegido: false,
                  contenido: const Icon(Icons.shuffle, size: 18, color: Paleta.oro),
                  alPulsar: () {
                    partida.barajarTodo('ruinas');
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Ruinas místicas barajadas. Ficha en: ${partida.lugarActual('ruinas') ?? '—'}')));
                  },
                ),
              ],
            )
          : mazo != 'expedicion'
          ? circulo
          : Column(
              children: [
                circulo,
                const SizedBox(height: 8),
                BotonCircular(
                  nombre: 'Remover',
                  diametro: 46,
                  tamanoTexto: 11,
                  elegido: false,
                  oscurecerNoElegido: false,
                  contenido: const Icon(Icons.inventory_2_outlined, size: 18, color: Paleta.oro),
                  alPulsar: () => _elegirLugarARemover(context),
                ),
              ],
            ),
    );
  }
}

/// Lista de lugares de expedición para regresar sus cartas a la caja (o sacarlas de nuevo).
void _elegirLugarARemover(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Paleta.superficie,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (ctx) => ListenableBuilder(
      listenable: partida,
      builder: (ctx, _) {
        final lugares = partida.lugaresExpedicion().entries.toList()..sort((a, b) => a.key.compareTo(b.key));
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            children: [
              const Text('Remover cartas de expedición',
                  style: TextStyle(fontFamily: fuenteTitulo, fontSize: 20)),
              const SizedBox(height: 4),
              const Text('Regresa a la caja todas las cartas de un lugar cuando el juego lo pida.',
                  style: TextStyle(fontSize: 15, color: Paleta.textoTenue)),
              const SizedBox(height: 12),
              for (final e in lugares)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    e.value.enPartida > 0 ? Icons.place_outlined : Icons.inventory_2,
                    color: e.value.enPartida > 0 ? Paleta.oro : Paleta.textoTenue,
                  ),
                  title: Text(e.key, style: const TextStyle(fontSize: 18)),
                  subtitle: Text(
                    e.value.enPartida > 0
                        ? '${e.value.enPartida} ${e.value.enPartida == 1 ? 'carta' : 'cartas'} en la partida'
                        : 'En la caja',
                    style: const TextStyle(color: Paleta.textoTenue),
                  ),
                  trailing: e.value.enPartida > 0
                      ? OutlinedButton(
                          onPressed: () => _confirmarRemover(ctx, e.key, e.value.enPartida),
                          child: const Text('Remover'),
                        )
                      : TextButton(
                          onPressed: () => partida.devolverLugar(e.key),
                          child: const Text('Devolver'),
                        ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

void _confirmarRemover(BuildContext context, String lugar, int n) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('¿Remover $lugar?'),
      content: Text('Se regresan a la caja las $n cartas de «$lugar» '
          '(del mazo, de los descartes y de las que estén en juego). '
          'Si te equivocas, puedes devolverlas desde esta misma lista.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            partida.retirarLugar(lugar);
            Navigator.pop(ctx);
          },
          child: const Text('Remover'),
        ),
      ],
    ),
  );
}

/// Píldora "quedan/total" sobre el círculo del mazo.
class _Contador extends StatelessWidget {
  const _Contador({required this.quedan, required this.total, required this.color});
  final int quedan, total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: Paleta.fondo,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.8)),
      ),
      child: Text(
        '$quedan/$total',
        style: TextStyle(
          fontFamily: fuenteTitulo,
          fontSize: 12,
          color: quedan == 0 ? Paleta.textoTenue : Paleta.texto,
          fontVariations: peso(700),
        ),
      ),
    );
  }
}
