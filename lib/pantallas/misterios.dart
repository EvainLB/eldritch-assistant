import 'package:flutter/material.dart';

import '../catalogo.dart';
import '../main.dart';
import '../tema.dart';
import '../widgets/comunes.dart';

/// Misterios del Primigenio, solo como referencia: el activo, cuántos van resueltos
/// y botones para resolverlo o descartarlo. Las fichas que pidan (Pistas, Portales,
/// Salud, Monstruos) se llevan en la mesa.
class PantallaMisterios extends StatelessWidget {
  const PantallaMisterios({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: partida,
      builder: (context, _) {
        final ao = primigenioPorId(partida.primigenio);
        final necesarios = partida.misteriosNecesarios;
        final resueltos = partida.misteriosResueltos.length;
        final activo = partida.misterios[partida.misterioActivo];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Misterios'),
            actions: [
              if (resueltos > 0)
                IconButton(
                  tooltip: 'Deshacer el último resuelto',
                  icon: const Icon(Icons.undo),
                  onPressed: () => _confirmar(
                    context,
                    '¿Deshacer el último Misterio resuelto?',
                    'Vuelve a quedar como Misterio activo.',
                    partida.deshacerResuelto,
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _Progreso(resueltos: resueltos, necesarios: necesarios),
                const SizedBox(height: 18),
                if (partida.misteriosCompletos && partida.tieneAventura && !partida.aventuraTerminada)
                  ..._aventura(
                    context,
                    titulo: 'Agujero en el Mundo',
                    imagen: partida.aventuras[partida.aventuraActiva]?.imagen,
                    etapa: partida.etapaAventura,
                    hayHechas: partida.aventurasHechas.isNotEmpty,
                    nota: 'Funciona como un Misterio: «avanzar el Misterio activo» también avanza esta Aventura.',
                    final_: 'Los investigadores ganan la partida.',
                    completar: partida.completarEtapaAventura,
                    deshacer: partida.deshacerEtapaAventura,
                  )
                else if (partida.misteriosCompletos)
                  _Aviso(
                    icono: ao?.volteaAlResolver == true ? Icons.flip_camera_android : Icons.emoji_events_outlined,
                    texto: ao?.volteaAlResolver == true
                        ? 'Se resolvieron $necesarios Misterios: da la vuelta a la hoja de ${ao!.nombre} '
                            'y sigue su Misterio final del dorso.'
                        : '¡Se resolvieron $necesarios Misterios: los investigadores ganan la partida!',
                  )
                else if (activo == null)
                  const _Aviso(
                    icono: Icons.info_outline,
                    texto: 'No quedan cartas de Misterio para este Primigenio.',
                  )
                else ...[
                  const Etiqueta('Misterio activo'),
                  GestureDetector(
                    onTap: () => _verGrande(context, activo.imagen),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(activo.imagen, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Toca la carta para verla en grande. Las fichas que pida van sobre la carta en la mesa.',
                    style: TextStyle(fontSize: 14, color: Paleta.textoTenue),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Descartar'),
                          onPressed: () => _confirmar(
                            context,
                            '¿Descartar este Misterio?',
                            'No cuenta como resuelto. Entra el siguiente Misterio.',
                            partida.descartarMisterio,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check),
                          label: const Text('Resuelto'),
                          onPressed: () => _confirmar(
                            context,
                            '¿Misterio resuelto?',
                            'Cuenta para los $necesarios que pide ${ao?.nombre ?? 'el Primigenio'}.',
                            partida.resolverMisterio,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (partida.hayAventuraAntartida) ...[
                  const SizedBox(height: 26),
                  if (partida.antartidaTerminada)
                    _Aviso(
                      icono: Icons.ac_unit,
                      texto: partida.grupoAventuraPreludio == 'sueno'
                          ? 'Aventura SUEÑOS DE OTROS MUNDOS completada.'
                          : 'Aventura ANTÁRTIDA completada.',
                    )
                  else
                    ..._aventura(
                      context,
                      titulo: partida.grupoAventuraPreludio == 'sueno' ? 'Sueños de otros mundos' : 'Aventura Antártida',
                      imagen: partida.aventuras[partida.antartidaActiva]?.imagen,
                      etapa: partida.etapaAntartida,
                      hayHechas: partida.antartidaHechas.isNotEmpty,
                      nota: 'Aventura del preludio: la carta dice cómo completarla y su recompensa.',
                      final_: 'Termina la Aventura del preludio.',
                      completar: partida.completarEtapaAntartida,
                      deshacer: partida.deshacerEtapaAntartida,
                    ),
                ],
                if (resueltos > 0) ...[
                  const SizedBox(height: 26),
                  const Etiqueta('Resueltos'),
                  for (final id in partida.misteriosResueltos)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () => _verGrande(context, partida.misterios[id]!.imagen),
                        child: Opacity(
                          opacity: 0.75,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(partida.misterios[id]!.imagen, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  /// Aventura por etapas (I, II, III): «Agujero en el Mundo» de los Mi-go o ANTÁRTIDA del preludio.
  List<Widget> _aventura(
    BuildContext context, {
    required String titulo,
    required String? imagen,
    required int etapa,
    required bool hayHechas,
    required String nota,
    required String final_,
    required VoidCallback completar,
    required VoidCallback deshacer,
  }) {
    final img = imagen;
    return [
      Etiqueta('$titulo · Etapa ${nombresEtapa[etapa - 1]}'),
      Row(
        children: [
          for (var i = 1; i <= 3; i++) ...[
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: i < etapa ? Paleta.acento : (i == etapa ? Paleta.oro : Paleta.borde),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (i < 3) const SizedBox(width: 6),
          ],
        ],
      ),
      const SizedBox(height: 12),
      if (img != null)
        GestureDetector(
          onTap: () => _verGrande(context, img),
          child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(img, fit: BoxFit.contain)),
        ),
      const SizedBox(height: 6),
      Text(nota, style: const TextStyle(fontSize: 14, color: Paleta.textoTenue)),
      const SizedBox(height: 14),
      Row(
        children: [
          if (hayHechas) ...[
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.undo),
                label: const Text('Deshacer etapa'),
                onPressed: () => _confirmar(context, '¿Deshacer la última etapa?',
                    'Vuelve a quedar activa la carta de la etapa anterior.', deshacer),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: FilledButton.icon(
              icon: const Icon(Icons.check),
              label: Text(etapa < 3 ? 'Etapa completada' : '¡Completada!'),
              onPressed: () => _confirmar(
                context,
                '¿Etapa ${nombresEtapa[etapa - 1]} completada?',
                etapa < 3 ? 'Se roba al azar una carta de la etapa ${nombresEtapa[etapa]}.' : final_,
                completar,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  void _confirmar(BuildContext context, String titulo, String texto, VoidCallback accion) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo),
        content: Text(texto),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              accion();
              Navigator.pop(ctx);
            },
            child: const Text('Sí'),
          ),
        ],
      ),
    );
  }

  void _verGrande(BuildContext context, String imagen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        barrierDismissible: true,
        pageBuilder: (ctx, _, _) => GestureDetector(
          onTap: () => Navigator.pop(ctx),
          child: InteractiveViewer(
            maxScale: 4,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Image.asset(imagen, fit: BoxFit.contain),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Círculos de progreso: uno por Misterio necesario.
class _Progreso extends StatelessWidget {
  const _Progreso({required this.resueltos, required this.necesarios});
  final int resueltos, necesarios;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Paleta.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Paleta.borde),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RESUELTOS',
                  style: TextStyle(
                    fontFamily: fuenteTitulo,
                    fontSize: 11,
                    letterSpacing: 2,
                    color: Paleta.oro,
                    fontVariations: peso(700),
                  ),
                ),
                Text('$resueltos de $necesarios', style: const TextStyle(fontFamily: fuenteTitulo, fontSize: 22)),
              ],
            ),
          ),
          for (var i = 0; i < necesarios; i++)
            Container(
              margin: const EdgeInsets.only(left: 8),
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < resueltos ? Paleta.acento : Colors.transparent,
                border: Border.all(color: i < resueltos ? Paleta.acento : Paleta.borde, width: 1.6),
              ),
              child: i < resueltos ? const Icon(Icons.check, size: 18, color: Colors.black) : null,
            ),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.icono, required this.texto});
  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Paleta.acento.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Paleta.acento.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Icon(icono, color: Paleta.acento, size: 30),
          const SizedBox(width: 14),
          Expanded(child: Text(texto, style: const TextStyle(fontSize: 17))),
        ],
      ),
    );
  }
}
