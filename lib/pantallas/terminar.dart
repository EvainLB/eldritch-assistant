import 'package:flutter/material.dart';

import '../catalogo.dart';
import '../main.dart';
import '../tema.dart';
import '../widgets/comunes.dart';
import 'preparacion.dart';

/// Resumen al terminar la partida: cómo acabó, Misterios, Mitos y encuentros.
class PantallaTerminar extends StatefulWidget {
  const PantallaTerminar({super.key});

  @override
  State<PantallaTerminar> createState() => _PantallaTerminarState();
}

class _PantallaTerminarState extends State<PantallaTerminar> {
  /// null = sin elegir, true = ganaron, false = perdieron.
  bool? _ganaron;

  @override
  void initState() {
    super.initState();
    if (partida.victoria && primigenioPorId(partida.primigenio)?.volteaAlResolver != true) {
      _ganaron = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = partida;
    final hoja = p.hojasPrimigenio[p.primigenio];
    final mitosRobadas = p.total('mitos') - p.pila('mitos').length;
    final encuentros = [
      for (final m in p.mazosPartida)
        if (m != 'mitos') p.descarte(m).length
    ].fold(0, (a, b) => a + b);
    final exps = [
      for (final e in expansiones)
        if (p.expansionesActivas.contains(e.id)) e.nombre
    ];
    final etapa = p.etapaMitosActual;

    final titulo = switch (_ganaron) {
      true => '¡Los investigadores triunfaron!',
      false => '${nombrePrimigenio(p.primigenio)} prevalece…',
      null => '¿Cómo terminó la partida?',
    };
    final color = switch (_ganaron) { true => Paleta.acento, false => const Color(0xFFC0473A), null => Paleta.oro };

    return Scaffold(
      appBar: AppBar(title: const Text('Terminar partida')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (hoja != null)
              Center(
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 30)],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      _ganaron == true ? Colors.grey : Colors.transparent,
                      _ganaron == true ? BlendMode.saturation : BlendMode.dst,
                    ),
                    child: Image.asset(hoja.retrato, fit: BoxFit.cover),
                  ),
                ),
              ),
            const SizedBox(height: 18),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: fuenteTitulo, fontSize: 24, color: color),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _Opcion(
                    texto: 'Ganamos',
                    icono: Icons.emoji_events_outlined,
                    elegida: _ganaron == true,
                    color: Paleta.acento,
                    alPulsar: () => setState(() => _ganaron = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Opcion(
                    texto: 'Perdimos',
                    icono: Icons.dangerous_outlined,
                    elegida: _ganaron == false,
                    color: const Color(0xFFC0473A),
                    alPulsar: () => setState(() => _ganaron = false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const Etiqueta('Resumen'),
            _Dato(Icons.auto_stories_outlined, 'Misterios resueltos',
                '${p.misteriosResueltos.length} de ${p.misteriosNecesarios}'),
            _Dato(Icons.blur_on, 'Cartas de Mitos robadas',
                '$mitosRobadas de ${p.total('mitos')}${etapa != null ? ' · Etapa ${nombresEtapa[etapa - 1]}' : ''}'),
            _Dato(Icons.style_outlined, 'Encuentros resueltos', '$encuentros'),
            if (p.enJuego.isNotEmpty) _Dato(Icons.push_pin_outlined, 'Rumores en juego', '${p.enJuego.length}'),
            _Dato(Icons.inventory_2_outlined, 'Expansiones', exps.join(', ')),
            if (p.preludio != null) const _Dato(Icons.auto_awesome, 'Preludio', 'Sí'),
            const SizedBox(height: 26),
            BotonPrincipal(
              texto: 'NUEVA PARTIDA',
              alPulsar: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PantallaPreparacion(desdePartida: true)),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Seguir jugando', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion(
      {required this.texto, required this.icono, required this.elegida, required this.color, required this.alPulsar});
  final String texto;
  final IconData icono;
  final bool elegida;
  final Color color;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: elegida ? color.withValues(alpha: 0.15) : Paleta.superficie,
      shape: StadiumBorder(side: BorderSide(color: elegida ? color : Paleta.borde, width: 1.4)),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: alPulsar,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icono, color: elegida ? color : Paleta.textoTenue),
              const SizedBox(width: 8),
              Text(texto, style: TextStyle(fontSize: 17, color: elegida ? color : Paleta.texto)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato(this.icono, this.nombre, this.valor);
  final IconData icono;
  final String nombre, valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 22, color: Paleta.oro),
          const SizedBox(width: 12),
          Expanded(child: Text(nombre, style: const TextStyle(fontSize: 16, color: Paleta.textoTenue))),
          const SizedBox(width: 12),
          Flexible(
            child: Text(valor, textAlign: TextAlign.right, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
