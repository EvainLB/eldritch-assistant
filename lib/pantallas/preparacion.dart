import 'package:flutter/material.dart';

import '../catalogo.dart';
import '../main.dart';
import '../tema.dart';
import '../widgets/circulo.dart';
import '../widgets/comunes.dart';
import 'primigenio.dart';

const _iconoOpcion = <String, IconData>{
  'antartida': Icons.ac_unit,
  'alineacion_cosmica': Icons.auto_awesome,
  'egipto': Icons.change_history,
  'tierras_sueno_tablero': Icons.nightlight_round,
};

const _nombreCorto = <String, String>{
  'alineacion_cosmica': 'Alineación cósmica',
  'tierras_sueno_tablero': 'Tierras del Sueño',
};

/// Elegir expansiones y Primigenio (equivale a "Select Expansions" del APK).
class PantallaPreparacion extends StatefulWidget {
  const PantallaPreparacion({super.key, this.desdePartida = false});
  final bool desdePartida;

  @override
  State<PantallaPreparacion> createState() => _PantallaPreparacionState();
}

class _PantallaPreparacionState extends State<PantallaPreparacion> {
  final Set<String> _exps = {'base'};
  final Set<String> _opciones = {};
  bool _usarPreludio = true;

  /// Solo hay Preludios en algunas expansiones (Vestigios, Carcosa, Ciudades en ruinas).
  bool get _hayPreludios => partida.preludios.keys.any((id) => _exps.contains(partida.expansionPreludio[id]));

  void _alternarExpansion(Expansion e, bool activa) {
    setState(() {
      if (activa) {
        _exps.add(e.id);
      } else {
        _exps.remove(e.id);
        _opciones.removeAll(e.opciones.map((o) => o.id));
      }
    });
  }

  Widget _expansion(Expansion e, double d) {
    final activa = _exps.contains(e.id);
    return SizedBox(
      width: d,
      child: Column(
        children: [
          BotonCircular(
            nombre: e.nombre,
            subtitulo: !e.disponible ? 'Pronto' : (e.fan ? 'Fan' : null),
            diametro: d,
            elegido: activa,
            oscurecerNoElegido: false,
            alPulsar: e.id == 'base' || !e.disponible ? null : () => _alternarExpansion(e, !activa),
            contenido: Padding(
              padding: EdgeInsets.all(d * 0.07),
              child: Image.asset('assets/cajas/${e.id}.webp', fit: BoxFit.contain),
            ),
          ),
          for (final o in e.opciones)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: BotonCircular(
                nombre: _nombreCorto[o.id] ?? o.nombre,
                tamanoTexto: 12,
                diametro: 58,
                elegido: _opciones.contains(o.id),
                oscurecerNoElegido: false,
                alPulsar: activa
                    ? () => setState(() => _opciones.contains(o.id) ? _opciones.remove(o.id) : _opciones.add(o.id))
                    : null,
                contenido: Icon(
                  _iconoOpcion[o.id] ?? Icons.extension,
                  size: 22,
                  color: _opciones.contains(o.id) ? Paleta.acento : Paleta.oro,
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _elegirPrimigenio() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaPrimigenio(
          expansiones: {..._exps},
          opciones: {..._opciones},
          usarPreludio: _usarPreludio && _hayPreludios,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Cabecera(atras: widget.desdePartida),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                children: [
                  const Text(
                    'Preparar partida',
                    style: TextStyle(fontFamily: fuenteTitulo, fontSize: 28, height: 1.2),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Elige las expansiones que van a jugar.',
                    style: TextStyle(fontSize: 17, color: Paleta.textoTenue),
                  ),
                  const SizedBox(height: 20),
                  _InterruptorPreludio(
                    activo: _usarPreludio,
                    disponible: _hayPreludios,
                    alCambiar: (v) => setState(() => _usarPreludio = v),
                  ),
                  const SizedBox(height: 24),
                  const Etiqueta('Expansiones'),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, c) {
                      final d = ((c.maxWidth - 24) / 2).clamp(110.0, 140.0);
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 24,
                        runSpacing: 26,
                        children: [for (final e in expansiones) _expansion(e, d)],
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: BotonPrincipal(texto: 'ELEGIR PRIMIGENIO', alPulsar: _elegirPrimigenio),
            ),
          ],
        ),
      ),
    );
  }
}

/// «Usar preludio»: si está activo, al empezar se sortea uno y se muestra.
class _InterruptorPreludio extends StatelessWidget {
  const _InterruptorPreludio({required this.activo, required this.disponible, required this.alCambiar});
  final bool activo, disponible;
  final ValueChanged<bool> alCambiar;

  @override
  Widget build(BuildContext context) {
    final on = activo && disponible;
    return Material(
      color: Paleta.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: on ? Paleta.oro.withValues(alpha: 0.6) : Paleta.borde),
      ),
      child: SwitchListTile(
        value: on,
        onChanged: disponible ? alCambiar : null,
        secondary: Icon(Icons.style_outlined, color: on ? Paleta.oro : Paleta.textoTenue),
        title: const Text('Usar preludio', style: TextStyle(fontSize: 18)),
        subtitle: Text(
          disponible
              ? (on ? 'Se sortea uno al empezar la partida' : 'Se juega sin preludio')
              : 'Activa Vestigios, Carcosa o Ciudades en ruinas',
          style: const TextStyle(color: Paleta.textoTenue),
        ),
      ),
    );
  }
}
