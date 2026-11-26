import 'package:flutter/material.dart';

import '../tema.dart';

class Cabecera extends StatelessWidget {
  const Cabecera({super.key, required this.atras});
  final bool atras;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 20, 8),
      child: Row(
        children: [
          if (atras)
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context))
          else
            const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset('assets/logo.webp', width: 34, height: 34),
          ),
          const SizedBox(width: 12),
          Text(
            'ELDRITCH ASSISTANT',
            style: TextStyle(
              fontFamily: fuenteTitulo,
              fontSize: 15,
              letterSpacing: 2.5,
              color: Paleta.texto.withValues(alpha: 0.85),
              fontVariations: peso(600),
            ),
          ),
        ],
      ),
    );
  }
}


class Etiqueta extends StatelessWidget {
  const Etiqueta(this.texto, {super.key});
  final String texto;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(
            fontFamily: fuenteTitulo,
            fontSize: 13,
            letterSpacing: 2.2,
            color: Paleta.acento,
            fontVariations: peso(700),
          ),
        ),
      );
}

/// Botón tipo píldora con la foto de la caja en un círculo (como los botones de mazo).

class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({super.key, required this.texto, required this.alPulsar});
  final String texto;
  final VoidCallback alPulsar;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(colors: [Paleta.acento, Paleta.acentoOscuro]),
        boxShadow: [BoxShadow(color: Paleta.acento.withValues(alpha: 0.25), blurRadius: 24)],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: alPulsar,
          child: SizedBox(
            height: 58,
            width: double.infinity,
            child: Center(
              child: Text(
                texto,
                style: TextStyle(
                  fontFamily: fuenteTitulo,
                  fontSize: 18,
                  letterSpacing: 4,
                  color: Colors.black,
                  fontVariations: peso(700),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
